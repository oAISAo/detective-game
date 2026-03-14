## InterrogationManager.gd
## Manages interrogation sessions: three-phase flow, trigger evaluation,
## pressure tracking, personality modifiers, and statement collection.
## Phase 7: Evidence-confrontation interrogation mechanic.
extends Node


# --- Signals --- #

## Emitted when an interrogation session begins.
signal interrogation_started(person_id: String)

## Emitted when the interrogation phase changes.
signal phase_changed(new_phase: Enums.InterrogationPhase)

## Emitted when an evidence trigger fires during confrontation.
signal trigger_fired(trigger_id: String, result: Dictionary)

## Emitted when a new statement is recorded during interrogation.
signal statement_recorded(statement_id: String)

## Emitted when pressure changes for the current suspect.
signal pressure_changed(person_id: String, current_pressure: int, threshold: int)

## Emitted when a suspect reaches their break moment.
signal break_moment_reached(person_id: String)

## Emitted when the interrogation session ends.
signal interrogation_ended(person_id: String)


# --- Session State --- #

## ID of the suspect currently being interrogated.
var _current_person_id: String = ""

## Current phase of the interrogation.
var _current_phase: Enums.InterrogationPhase = Enums.InterrogationPhase.INACTIVE

## Current accumulated pressure for this session's suspect.
var _current_pressure: int = 0

## IDs of triggers that have been fired (persists across sessions).
var _fired_triggers: Dictionary = {}  # { person_id: [trigger_ids] }

## IDs of statements collected during current session.
var _session_statements: Array[String] = []

## All statements heard across all sessions (persists).
var _heard_statements: Array[String] = []

## Per-suspect accumulated pressure (persists across sessions).
var _accumulated_pressure: Dictionary = {}  # { person_id: int }

## Whether a break moment has occurred for each suspect (persists).
var _break_moments: Dictionary = {}  # { person_id: bool }


# --- Lifecycle --- #

func _ready() -> void:
	print("[InterrogationManager] Initialized.")


## Resets all interrogation state.
func reset() -> void:
	_current_person_id = ""
	_current_phase = Enums.InterrogationPhase.INACTIVE
	_current_pressure = 0
	_fired_triggers.clear()
	_session_statements.clear()
	_heard_statements.clear()
	_accumulated_pressure.clear()
	_break_moments.clear()


# --- Public API: Session Lifecycle --- #

## Starts an interrogation with the given suspect.
## Returns true if the session started successfully.
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
	_current_phase = Enums.InterrogationPhase.OPEN_CONVERSATION
	_session_statements.clear()

	# Load persisted pressure for this suspect
	_current_pressure = _accumulated_pressure.get(person_id, 0)

	# Record the interrogation with GameManager (enforces daily limit)
	GameManager.record_interrogation(person_id)

	interrogation_started.emit(person_id)
	phase_changed.emit(_current_phase)
	print("[InterrogationManager] Interrogation started with %s" % person_id)
	return true


## Ends the current interrogation session.
func end_interrogation() -> void:
	if not is_active():
		push_warning("[InterrogationManager] Cannot end: no active interrogation")
		return

	var person_id: String = _current_person_id

	# Persist accumulated pressure
	_accumulated_pressure[person_id] = _current_pressure

	_current_phase = Enums.InterrogationPhase.ENDED
	phase_changed.emit(_current_phase)

	interrogation_ended.emit(person_id)
	print("[InterrogationManager] Interrogation ended with %s" % person_id)

	# Clear session state
	_current_person_id = ""
	_current_phase = Enums.InterrogationPhase.INACTIVE
	_session_statements.clear()


## Advances to the next interrogation phase.
## Returns the new phase, or INACTIVE if advancement is not possible.
func advance_phase() -> Enums.InterrogationPhase:
	if not is_active():
		push_warning("[InterrogationManager] Cannot advance phase: no active interrogation")
		return Enums.InterrogationPhase.INACTIVE

	match _current_phase:
		Enums.InterrogationPhase.OPEN_CONVERSATION:
			_current_phase = Enums.InterrogationPhase.EVIDENCE_CONFRONTATION
		Enums.InterrogationPhase.EVIDENCE_CONFRONTATION:
			_current_phase = Enums.InterrogationPhase.PSYCHOLOGICAL_PRESSURE
		_:
			push_warning("[InterrogationManager] Cannot advance from phase: %s" % _current_phase)
			return _current_phase

	phase_changed.emit(_current_phase)
	return _current_phase


# --- Public API: Evidence Confrontation --- #

## Presents evidence to the current suspect.
## Returns a result dictionary with keys: triggered, trigger_id, reaction_type,
## dialogue, new_statement_id, unlocks, pressure_added, weakened.
## Returns empty dict if no trigger matched.
func present_evidence(evidence_id: String) -> Dictionary:
	if not is_active():
		push_error("[InterrogationManager] Cannot present evidence: no active interrogation")
		return {}

	var trigger: InterrogationTriggerData = CaseManager.get_trigger_by_evidence(
		_current_person_id, evidence_id
	)
	if trigger == null:
		return {"triggered": false}

	# Check if already fired
	var person_fired: Array = _fired_triggers.get(_current_person_id, [])
	if trigger.id in person_fired:
		return {"triggered": false, "already_fired": true}

	# Evaluate prerequisite and apply personality modifiers
	var result: Dictionary = _evaluate_trigger(trigger)

	# Record the trigger as fired
	if not _fired_triggers.has(_current_person_id):
		_fired_triggers[_current_person_id] = []
	_fired_triggers[_current_person_id].append(trigger.id)

	# Record the new statement if present
	if not result.get("new_statement_id", "").is_empty():
		_record_statement(result["new_statement_id"])

	# Unlock evidence
	for unlock_id: String in result.get("unlocks", []):
		GameManager.discover_evidence(unlock_id)

	# Apply pressure
	var pressure_added: int = result.get("pressure_added", 0)
	if pressure_added > 0:
		_current_pressure += pressure_added
		_accumulated_pressure[_current_person_id] = _current_pressure
		var person: PersonData = CaseManager.get_person(_current_person_id)
		var threshold: int = person.pressure_threshold if person else 0
		pressure_changed.emit(_current_person_id, _current_pressure, threshold)

		# Check for break moment
		if _check_break_moment():
			result["break_moment"] = true

	trigger_fired.emit(trigger.id, result)
	return result


## Discusses an interrogation topic by ID.
## Returns a result dictionary with produced statement IDs and unlock info.
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

	# Record statements produced by this topic
	var produced_statements: Array[String] = []
	for stmt_id: String in topic.statements:
		_record_statement(stmt_id)
		produced_statements.append(stmt_id)

	# Unlock evidence from topic
	for unlock_id: String in topic.unlock_evidence:
		GameManager.discover_evidence(unlock_id)

	return {
		"topic_id": topic_id,
		"statements": produced_statements,
		"unlocks": topic.unlock_evidence.duplicate(),
	}


# --- Public API: Topic Availability --- #

## Returns available topics for the current suspect based on conditions.
func get_available_topics() -> Array[InterrogationTopicData]:
	if not is_active():
		return []

	var all_topics: Array[InterrogationTopicData] = CaseManager.get_topics_for_person(_current_person_id)
	var available: Array[InterrogationTopicData] = []

	for topic: InterrogationTopicData in all_topics:
		if _is_topic_available(topic):
			available.append(topic)

	return available


# --- Public API: Getters --- #

## Returns true if an interrogation is currently active.
func is_active() -> bool:
	return _current_phase != Enums.InterrogationPhase.INACTIVE and \
		_current_phase != Enums.InterrogationPhase.ENDED


## Returns the current interrogation phase.
func get_current_phase() -> Enums.InterrogationPhase:
	return _current_phase


## Returns the ID of the person currently being interrogated.
func get_current_person_id() -> String:
	return _current_person_id


## Returns the current accumulated pressure for the active suspect.
func get_current_pressure() -> int:
	return _current_pressure


## Returns the accumulated pressure for a specific suspect.
func get_pressure_for_person(person_id: String) -> int:
	return _accumulated_pressure.get(person_id, 0)


## Returns statement IDs collected in the current session.
func get_session_statements() -> Array[String]:
	return _session_statements.duplicate()


## Returns all statement IDs heard across all sessions.
func get_heard_statements() -> Array[String]:
	return _heard_statements.duplicate()


## Returns trigger IDs fired for a specific person.
func get_fired_triggers_for_person(person_id: String) -> Array:
	return _fired_triggers.get(person_id, []).duplicate()


## Returns true if the suspect has reached their break moment.
func has_break_moment(person_id: String) -> bool:
	return _break_moments.get(person_id, false)


## Returns statements with contradiction markers for the current suspect.
func get_contradicted_statements() -> Array[Dictionary]:
	if not is_active():
		return []

	var statements: Array[StatementData] = CaseManager.get_statements_by_person(_current_person_id)
	var contradicted: Array[Dictionary] = []

	for stmt: StatementData in statements:
		if stmt.contradicting_evidence.is_empty():
			continue
		# Check if player has discovered any contradicting evidence
		for ev_id: String in stmt.contradicting_evidence:
			if GameManager.has_evidence(ev_id):
				contradicted.append({
					"statement_id": stmt.id,
					"statement_text": stmt.text,
					"contradicting_evidence_id": ev_id,
				})
				break  # One contradiction is enough to flag

	return contradicted


# --- Internal: Trigger Evaluation --- #

## Evaluates a trigger considering prerequisites and personality modifiers.
## Returns the result dictionary for present_evidence.
func _evaluate_trigger(trigger: InterrogationTriggerData) -> Dictionary:
	var weakened: bool = _is_trigger_weakened(trigger)
	var person: PersonData = CaseManager.get_person(_current_person_id)

	# Determine effective impact and pressure
	var effective_impact: Enums.ImpactLevel = trigger.impact_level
	var effective_pressure: int = trigger.pressure_points
	var effective_reaction: Enums.ReactionType = trigger.reaction_type

	# Weaken if prerequisite statement not heard
	if weakened:
		effective_impact = _downgrade_impact(effective_impact)
		effective_pressure = effective_pressure / 2  # Integer division floors

	# Apply personality modifiers
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


## Returns true if the trigger is weakened (prerequisite not met).
func _is_trigger_weakened(trigger: InterrogationTriggerData) -> bool:
	if trigger.requires_statement_id.is_empty():
		return false
	return trigger.requires_statement_id not in _heard_statements


## Downgrades impact by one level.
func _downgrade_impact(impact: Enums.ImpactLevel) -> Enums.ImpactLevel:
	match impact:
		Enums.ImpactLevel.BREAKPOINT:
			return Enums.ImpactLevel.MAJOR
		Enums.ImpactLevel.MAJOR:
			return Enums.ImpactLevel.MINOR
		_:
			return Enums.ImpactLevel.MINOR


## Applies personality trait modifiers to the reaction type.
## Aggressive: DENIAL → ANGER. Anxious: SILENCE → PANIC.
## Manipulative: MINOR triggers → DEFLECTION.
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


## Applies personality trait modifiers to pressure points.
## Calm: MINOR triggers don't generate pressure.
func _apply_personality_pressure_modifier(
	person: PersonData, pressure: int, impact: Enums.ImpactLevel
) -> int:
	if Enums.PersonalityTrait.CALM in person.personality_traits:
		if impact == Enums.ImpactLevel.MINOR:
			return 0
	return pressure


# --- Internal: Pressure System --- #

## Checks if the current suspect has reached their break moment.
## Returns true if a break moment was triggered.
func _check_break_moment() -> bool:
	if _break_moments.get(_current_person_id, false):
		return false  # Already broken

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


# --- Internal: Statement Recording --- #

## Records a statement as heard during the current session.
func _record_statement(statement_id: String) -> void:
	if statement_id.is_empty():
		return

	if statement_id not in _session_statements:
		_session_statements.append(statement_id)

	if statement_id not in _heard_statements:
		_heard_statements.append(statement_id)
		statement_recorded.emit(statement_id)


# --- Internal: Topic Availability --- #

## Returns true if a topic's conditions are met.
func _is_topic_available(topic: InterrogationTopicData) -> bool:
	# Check requires_statement_id prerequisite
	if not topic.requires_statement_id.is_empty():
		if topic.requires_statement_id not in _heard_statements:
			return false

	# Check required_evidence
	for ev_id: String in topic.required_evidence:
		if not GameManager.has_evidence(ev_id):
			return false

	# Check trigger_conditions (format: "condition_type:value")
	for condition: String in topic.trigger_conditions:
		if not _evaluate_topic_condition(condition):
			return false

	return true


## Evaluates a single topic condition string.
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


# --- Serialization --- #

## Serializes the interrogation state for save/load.
func serialize() -> Dictionary:
	return {
		"fired_triggers": _fired_triggers.duplicate(true),
		"heard_statements": _heard_statements.duplicate(),
		"accumulated_pressure": _accumulated_pressure.duplicate(),
		"break_moments": _break_moments.duplicate(),
	}


## Restores interrogation state from a saved dictionary.
func deserialize(data: Dictionary) -> void:
	_fired_triggers = data.get("fired_triggers", {})
	_heard_statements.assign(data.get("heard_statements", []))
	_accumulated_pressure = data.get("accumulated_pressure", {})
	_break_moments = data.get("break_moments", {})
