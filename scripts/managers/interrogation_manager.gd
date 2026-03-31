## InterrogationManager.gd
## Manages evidence-driven interrogation sessions with three phases:
## 1. Statement Intake — suspect tells their story, individual claims logged
## 2. Interrogation — player selects a focus (statement/topic) and presents evidence
## 3. Pressure — earned through contradictions, unlocks escalation
extends Node


# --- Signals --- #

signal interrogation_started(person_id: String)
signal phase_changed(new_phase: Enums.InterrogationPhase)
signal trigger_fired(trigger_id: String, result: Dictionary)
signal statement_recorded(statement_id: String)
signal pressure_changed(person_id: String, current_pressure: int, threshold: int)
signal break_moment_reached(person_id: String)
signal interrogation_ended(person_id: String)
signal focus_changed(focus: Dictionary)
signal contradiction_logged(statement_id: String, evidence_id: String)
signal state_loaded


# --- Session State --- #

var _current_person_id: String = ""
var _current_phase: Enums.InterrogationPhase = Enums.InterrogationPhase.INACTIVE
var _current_pressure: int = 0
var _current_focus: Dictionary = {}  # { "type": "statement"|"topic", "id": "..." }
var _session_contradictions: Array[Dictionary] = []  # [{ statement_id, evidence_id }]
var _session_statements: Array[String] = []
var _unlocked_topic_ids: Array[String] = []


# --- Persistent State (across sessions) --- #

var _fired_triggers: Dictionary = {}  # { person_id: [trigger_ids] }
var _heard_statements: Array[String] = []
var _accumulated_pressure: Dictionary = {}  # { person_id: int }
var _break_moments: Dictionary = {}  # { person_id: bool }


func _ready() -> void:
	print("[InterrogationManager] Initialized.")


func reset() -> void:
	_current_person_id = ""
	_current_phase = Enums.InterrogationPhase.INACTIVE
	_current_pressure = 0
	_current_focus = {}
	_session_contradictions.clear()
	_session_statements.clear()
	_unlocked_topic_ids.clear()
	_fired_triggers.clear()
	_heard_statements.clear()
	_accumulated_pressure.clear()
	_break_moments.clear()


# =========================================================================
# Session Lifecycle
# =========================================================================

func start_interrogation(person_id: String) -> bool:
	if is_active():
		push_warning("[InterrogationManager] Cannot start: already interrogating %s" % _current_person_id)
		return false

	if not GameManager.can_interrogate_today(person_id):
		push_warning("[InterrogationManager] Cannot interrogate %s: daily limit reached" % person_id)
		return false

	var person: PersonData = CaseManager.get_person(person_id)
	if person == null:
		push_error("[InterrogationManager] Person not found: %s" % person_id)
		return false

	_current_person_id = person_id
	_current_focus = {}
	_session_contradictions.clear()
	_session_statements.clear()
	_unlocked_topic_ids.clear()
	_current_pressure = _accumulated_pressure.get(person_id, 0)

	GameManager.record_interrogation(person_id)

	# Start in statement intake phase — suspect tells their story first
	var session: InterrogationSessionData = CaseManager.get_interrogation_session(person_id)
	if session and not session.initial_statement_ids.is_empty():
		_current_phase = Enums.InterrogationPhase.STATEMENT_INTAKE
		for stmt_id: String in session.initial_statement_ids:
			_record_statement(stmt_id)
	else:
		# No initial statements defined — skip straight to interrogation
		_current_phase = Enums.InterrogationPhase.INTERROGATION

	interrogation_started.emit(person_id)
	phase_changed.emit(_current_phase)
	print("[InterrogationManager] Interrogation started with %s (phase: %s)" % [
		person_id,
		"STATEMENT_INTAKE" if _current_phase == Enums.InterrogationPhase.STATEMENT_INTAKE else "INTERROGATION",
	])
	return true


func end_interrogation() -> void:
	if not is_active():
		push_warning("[InterrogationManager] Cannot end: no active interrogation")
		return

	var person_id: String = _current_person_id
	_accumulated_pressure[person_id] = _current_pressure

	_current_phase = Enums.InterrogationPhase.ENDED
	phase_changed.emit(_current_phase)
	interrogation_ended.emit(person_id)
	print("[InterrogationManager] Interrogation ended with %s" % person_id)

	# Clear session state after signal handlers have read it
	_clear_session_state.call_deferred()


## Resets transient session state after an interrogation ends.
func _clear_session_state() -> void:
	_current_person_id = ""
	_current_phase = Enums.InterrogationPhase.INACTIVE
	_current_focus = {}
	_session_contradictions.clear()
	_session_statements.clear()
	_unlocked_topic_ids.clear()


func advance_to_interrogation() -> Enums.InterrogationPhase:
	if _current_phase == Enums.InterrogationPhase.INTERROGATION:
		return _current_phase
	if _current_phase != Enums.InterrogationPhase.STATEMENT_INTAKE:
		push_warning("[InterrogationManager] Can only advance to interrogation from statement intake")
		return _current_phase

	_current_phase = Enums.InterrogationPhase.INTERROGATION
	phase_changed.emit(_current_phase)
	return _current_phase


# =========================================================================
# Focus Selection
# =========================================================================

func select_focus(focus_type: String, focus_id: String) -> void:
	if not is_active():
		push_error("[InterrogationManager] Cannot select focus: no active interrogation")
		return

	if focus_type != "statement" and focus_type != "topic":
		push_error("[InterrogationManager] Invalid focus type: %s" % focus_type)
		return

	_current_focus = {"type": focus_type, "id": focus_id}
	focus_changed.emit(_current_focus)


func clear_focus() -> void:
	_current_focus = {}
	focus_changed.emit(_current_focus)


func get_current_focus() -> Dictionary:
	return _current_focus.duplicate()


# =========================================================================
# Evidence Confrontation
# =========================================================================

func present_evidence(evidence_id: String) -> Dictionary:
	if not is_active():
		push_error("[InterrogationManager] Cannot present evidence: no active interrogation")
		return {}

	if _current_focus.is_empty():
		return {"triggered": false, "reason": "no_focus"}

	# Look for a trigger matching this evidence AND the current focus
	var trigger: InterrogationTriggerData = CaseManager.get_trigger_by_evidence_and_focus(
		_current_person_id, evidence_id, _current_focus
	)

	# Fallback: try the old global lookup for backward compatibility
	if trigger == null:
		trigger = CaseManager.get_trigger_by_evidence(_current_person_id, evidence_id)
		# Only accept global triggers that have no target set (legacy data)
		if trigger != null and (not trigger.target_statement_id.is_empty() or not trigger.target_topic_id.is_empty()):
			trigger = null

	if trigger == null:
		return {"triggered": false, "reason": "wrong_evidence"}

	var person_fired: Array = _fired_triggers.get(_current_person_id, [])
	if trigger.id in person_fired:
		return {"triggered": false, "already_fired": true}

	var result: Dictionary = _evaluate_trigger(trigger)

	# Record trigger as fired
	if not _fired_triggers.has(_current_person_id):
		_fired_triggers[_current_person_id] = []
	_fired_triggers[_current_person_id].append(trigger.id)

	# Record new statement
	if not result.get("new_statement_id", "").is_empty():
		_record_statement(result["new_statement_id"])

	# Unlock evidence or topics
	for unlock_id: String in result.get("unlocks", []):
		if unlock_id.begins_with("topic_"):
			_unlocked_topic_ids.append(unlock_id)
		else:
			GameManager.discover_evidence(unlock_id)

	# Log contradiction only if the suspect resisted (not admissions/revelations)
	var focus_id: String = _current_focus.get("id", "")
	if _current_focus.get("type", "") == "statement":
		var reaction: Enums.ReactionType = result.get("reaction_type", Enums.ReactionType.DENIAL)
		if reaction not in [Enums.ReactionType.ADMISSION, Enums.ReactionType.REVELATION, Enums.ReactionType.PARTIAL_CONFESSION]:
			_log_contradiction(focus_id, evidence_id)

	# Apply pressure
	var pressure_added: int = result.get("pressure_added", 0)
	if pressure_added > 0:
		_current_pressure += pressure_added
		_accumulated_pressure[_current_person_id] = _current_pressure
		var person: PersonData = CaseManager.get_person(_current_person_id)
		var threshold: int = person.pressure_threshold if person else 0
		pressure_changed.emit(_current_person_id, _current_pressure, threshold)

	trigger_fired.emit(trigger.id, result)
	return result


func get_rejection_text() -> String:
	var session: InterrogationSessionData = CaseManager.get_interrogation_session(_current_person_id)
	if session and not session.rejection_texts.is_empty():
		var idx: int = randi() % session.rejection_texts.size()
		return session.rejection_texts[idx]
	return _get_default_rejection_text()


func _get_default_rejection_text() -> String:
	var defaults: Array[String] = [
		"He barely reacts to that.",
		"That doesn't seem to shake his story.",
		"He dismisses it immediately.",
		"She looks at you blankly.",
		"That doesn't get a reaction.",
	]
	return defaults[randi() % defaults.size()]


# =========================================================================
# Apply Pressure
# =========================================================================

func apply_pressure() -> Dictionary:
	if not is_active():
		push_error("[InterrogationManager] Cannot apply pressure: no active interrogation")
		return {}

	var session: InterrogationSessionData = CaseManager.get_interrogation_session(_current_person_id)
	var gate: int = session.pressure_gate if session else 1
	var contradiction_count: int = _session_contradictions.size()

	if contradiction_count < gate:
		return {
			"success": false,
			"reason": "insufficient_contradictions",
			"current": contradiction_count,
			"required": gate,
		}

	_current_phase = Enums.InterrogationPhase.PRESSURE
	phase_changed.emit(_current_phase)

	if _check_break_moment():
		var break_dialogue: String = session.break_dialogue if session else ""
		_process_break_effects(session)
		return {
			"success": true,
			"break_moment": true,
			"dialogue": break_dialogue,
		}

	var pressure_dialogue: String = session.pressure_dialogue if session else ""
	return {
		"success": true,
		"break_moment": false,
		"dialogue": pressure_dialogue,
	}


func can_apply_pressure() -> bool:
	if not is_active():
		return false
	var session: InterrogationSessionData = CaseManager.get_interrogation_session(_current_person_id)
	var gate: int = session.pressure_gate if session else 1
	return _session_contradictions.size() >= gate


func get_pressure_dialogue() -> String:
	var session: InterrogationSessionData = CaseManager.get_interrogation_session(_current_person_id)
	return session.pressure_dialogue if session else ""


func get_break_dialogue() -> String:
	var session: InterrogationSessionData = CaseManager.get_interrogation_session(_current_person_id)
	return session.break_dialogue if session else ""


# =========================================================================
# Topic Discussion
# =========================================================================

func discuss_topic(topic_id: String) -> Dictionary:
	if not is_active():
		push_error("[InterrogationManager] Cannot discuss topic: no active interrogation")
		return {}

	var topic: InterrogationTopicData = CaseManager.get_interrogation_topic(topic_id)
	if topic == null:
		push_error("[InterrogationManager] Topic not found: %s" % topic_id)
		return {}

	if topic.person_id != _current_person_id:
		push_error("[InterrogationManager] Topic %s does not belong to %s" % [topic_id, _current_person_id])
		return {}

	var produced_statements: Array[String] = []
	for stmt_id: String in topic.statements:
		_record_statement(stmt_id)
		produced_statements.append(stmt_id)

	for unlock_id: String in topic.unlock_evidence:
		GameManager.discover_evidence(unlock_id)

	return {
		"topic_id": topic_id,
		"statements": produced_statements,
		"unlocks": topic.unlock_evidence.duplicate(),
		"dialogue": topic.dialogue,
	}


func get_available_topics() -> Array[InterrogationTopicData]:
	if not is_active():
		return []

	var result: Array[InterrogationTopicData] = []

	# Base topics from session data (always available)
	var session: InterrogationSessionData = CaseManager.get_interrogation_session(_current_person_id)
	if session:
		for topic_id: String in session.base_topic_ids:
			var topic: InterrogationTopicData = CaseManager.get_interrogation_topic(topic_id)
			if topic and topic not in result:
				result.append(topic)

	# Dynamically unlocked topics from triggers
	for topic_id: String in _unlocked_topic_ids:
		var topic: InterrogationTopicData = CaseManager.get_interrogation_topic(topic_id)
		if topic and topic not in result:
			result.append(topic)

	# Conditionally available topics (from case data)
	var all_topics: Array[InterrogationTopicData] = CaseManager.get_topics_for_person(_current_person_id)
	for topic: InterrogationTopicData in all_topics:
		if topic not in result and _is_topic_available(topic):
			result.append(topic)

	return result


# =========================================================================
# Getters
# =========================================================================

func is_active() -> bool:
	return _current_phase != Enums.InterrogationPhase.INACTIVE and \
		_current_phase != Enums.InterrogationPhase.ENDED


func get_current_phase() -> Enums.InterrogationPhase:
	return _current_phase


func get_current_person_id() -> String:
	return _current_person_id


func get_current_pressure() -> int:
	return _current_pressure


func get_pressure_for_person(person_id: String) -> int:
	return _accumulated_pressure.get(person_id, 0)


func get_session_statements() -> Array[String]:
	return _session_statements.duplicate()


func get_heard_statements() -> Array[String]:
	return _heard_statements.duplicate()


func get_fired_triggers_for_person(person_id: String) -> Array:
	return _fired_triggers.get(person_id, []).duplicate()


func has_break_moment(person_id: String) -> bool:
	return _break_moments.get(person_id, false)


func get_session_contradictions() -> Array[Dictionary]:
	return _session_contradictions.duplicate()


func get_initial_dialogue() -> String:
	var session: InterrogationSessionData = CaseManager.get_interrogation_session(_current_person_id)
	return session.initial_dialogue if session else ""


func get_contradicted_statements() -> Array[Dictionary]:
	if not is_active():
		return []

	var statements: Array[StatementData] = CaseManager.get_statements_by_person(_current_person_id)
	var contradicted: Array[Dictionary] = []

	for stmt: StatementData in statements:
		if stmt.contradicting_evidence.is_empty():
			continue
		for ev_id: String in stmt.contradicting_evidence:
			if GameManager.has_evidence(ev_id):
				contradicted.append({
					"statement_id": stmt.id,
					"statement_text": stmt.text,
					"contradicting_evidence_id": ev_id,
				})
				break

	return contradicted


# =========================================================================
# Internal: Trigger Evaluation
# =========================================================================

func _evaluate_trigger(trigger: InterrogationTriggerData) -> Dictionary:
	var weakened: bool = _is_trigger_weakened(trigger)
	var person: PersonData = CaseManager.get_person(_current_person_id)

	var effective_impact: Enums.ImpactLevel = trigger.impact_level
	var effective_pressure: int = trigger.pressure_points
	var effective_reaction: Enums.ReactionType = trigger.reaction_type

	if weakened:
		effective_impact = _downgrade_impact(effective_impact)
		effective_pressure = effective_pressure / 2

	if person:
		effective_reaction = _apply_personality_modifier(person, effective_reaction, effective_impact)
		effective_pressure = _apply_personality_pressure_modifier(person, effective_pressure, effective_impact)

	return {
		"triggered": true,
		"trigger_id": trigger.id,
		"reaction_type": effective_reaction,
		"dialogue": trigger.dialogue,
		"new_statement_id": trigger.new_statement_id,
		"unlocks": trigger.unlocks.duplicate(),
		"pressure_added": effective_pressure,
		"weakened": weakened,
		"impact_level": effective_impact,
		"deflection_target_id": trigger.deflection_target_id,
	}


func _is_trigger_weakened(trigger: InterrogationTriggerData) -> bool:
	if trigger.requires_statement_id.is_empty():
		return false
	return trigger.requires_statement_id not in _heard_statements


func _downgrade_impact(impact: Enums.ImpactLevel) -> Enums.ImpactLevel:
	match impact:
		Enums.ImpactLevel.BREAKPOINT:
			return Enums.ImpactLevel.MAJOR
		Enums.ImpactLevel.MAJOR:
			return Enums.ImpactLevel.MINOR
		_:
			return Enums.ImpactLevel.MINOR


func _apply_personality_modifier(
	person: PersonData, reaction: Enums.ReactionType, impact: Enums.ImpactLevel
) -> Enums.ReactionType:
	if Enums.PersonalityTrait.AGGRESSIVE in person.personality_traits:
		if reaction == Enums.ReactionType.DENIAL:
			return Enums.ReactionType.ANGER

	if Enums.PersonalityTrait.ANXIOUS in person.personality_traits:
		if reaction == Enums.ReactionType.SILENCE:
			return Enums.ReactionType.PANIC

	if Enums.PersonalityTrait.MANIPULATIVE in person.personality_traits:
		if impact == Enums.ImpactLevel.MINOR:
			return Enums.ReactionType.DEFLECTION

	return reaction


func _apply_personality_pressure_modifier(
	person: PersonData, pressure: int, impact: Enums.ImpactLevel
) -> int:
	if Enums.PersonalityTrait.CALM in person.personality_traits:
		if impact == Enums.ImpactLevel.MINOR:
			return 0
	return pressure


# =========================================================================
# Internal: Pressure & Break
# =========================================================================

func _check_break_moment() -> bool:
	if _break_moments.get(_current_person_id, false):
		return false

	var person: PersonData = CaseManager.get_person(_current_person_id)
	if person == null or person.pressure_threshold <= 0:
		return false

	if _current_pressure >= person.pressure_threshold:
		_break_moments[_current_person_id] = true
		_current_phase = Enums.InterrogationPhase.BREAK_MOMENT
		phase_changed.emit(_current_phase)
		break_moment_reached.emit(_current_person_id)
		print("[InterrogationManager] Break moment reached for %s" % _current_person_id)
		return true

	return false


func _process_break_effects(session: InterrogationSessionData) -> void:
	if session == null:
		return

	for stmt_id: String in session.break_statement_ids:
		_record_statement(stmt_id)

	for unlock_id: String in session.break_unlocks:
		if unlock_id.begins_with("topic_"):
			_unlocked_topic_ids.append(unlock_id)
		else:
			GameManager.discover_evidence(unlock_id)


func _log_contradiction(statement_id: String, evidence_id: String) -> void:
	for c: Dictionary in _session_contradictions:
		if c.get("statement_id", "") == statement_id and c.get("evidence_id", "") == evidence_id:
			return
	_session_contradictions.append({"statement_id": statement_id, "evidence_id": evidence_id})
	contradiction_logged.emit(statement_id, evidence_id)


# =========================================================================
# Internal: Statement Recording
# =========================================================================

func _record_statement(statement_id: String) -> void:
	if statement_id.is_empty():
		return

	if statement_id not in _session_statements:
		_session_statements.append(statement_id)

	if statement_id not in _heard_statements:
		_heard_statements.append(statement_id)
		statement_recorded.emit(statement_id)


# =========================================================================
# Internal: Topic Availability
# =========================================================================

func _is_topic_available(topic: InterrogationTopicData) -> bool:
	if not topic.requires_statement_id.is_empty():
		if topic.requires_statement_id not in _heard_statements:
			return false

	for ev_id: String in topic.required_evidence:
		if not GameManager.has_evidence(ev_id):
			return false

	for condition: String in topic.trigger_conditions:
		if not _evaluate_topic_condition(condition):
			return false

	return true


func _evaluate_topic_condition(condition: String) -> bool:
	var parts: PackedStringArray = condition.split(":", true, 1)
	if parts.size() < 2:
		push_warning("[InterrogationManager] Invalid condition format: %s" % condition)
		return false

	var condition_type: String = parts[0]
	var condition_value: String = parts[1]

	match condition_type:
		"evidence":
			return GameManager.has_evidence(condition_value)
		"statement":
			return condition_value in _heard_statements
		"location":
			return GameManager.has_visited_location(condition_value)
		_:
			push_warning("[InterrogationManager] Unknown condition type: %s" % condition_type)
			return false


# =========================================================================
# Serialization
# =========================================================================

func serialize() -> Dictionary:
	return {
		"fired_triggers": _fired_triggers.duplicate(true),
		"heard_statements": _heard_statements.duplicate(),
		"accumulated_pressure": _accumulated_pressure.duplicate(),
		"break_moments": _break_moments.duplicate(),
	}


func deserialize(data: Dictionary) -> void:
	_fired_triggers = data.get("fired_triggers", {})
	_heard_statements.assign(data.get("heard_statements", []))
	_accumulated_pressure = data.get("accumulated_pressure", {})
	_break_moments = data.get("break_moments", {})
	state_loaded.emit()
