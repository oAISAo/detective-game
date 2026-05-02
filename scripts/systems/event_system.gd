## EventSystem.gd
## Unified event trigger system for TIMED, CONDITIONAL, and DAY_START triggers.
## Phase 3: Centralized event evaluation, action dispatching, and notification integration.
## All events use EventTriggerData with a consistent structure.
extends BaseSubsystem


# --- Signals --- #

## Emitted when a trigger fires.
signal trigger_fired(trigger_id: String, trigger_data: EventTriggerData)

## Emitted when a conditional trigger fires in response to a game state change.
signal conditional_trigger_fired(trigger_id: String, actions: Array[String])

## Emitted when a timed trigger fires during night processing.
signal timed_trigger_fired(trigger_id: String, target_day: int)

## Emitted when a day-start trigger fires during morning processing.
signal day_start_trigger_fired(trigger_id: String, actions: Array[String])

## Emitted when a trigger action is dispatched (for UI/notification integration).
signal action_dispatched(action_string: String, source_trigger_id: String)


# --- State --- #

## Tracks which triggers have already fired (by ID) so they don't repeat.
var _fired_triggers: Array[String] = []

## Queue of pending actions from triggers that fired during night processing.
## These are delivered during the next morning briefing.
var _pending_morning_actions: Array[Dictionary] = []

## History of all trigger firings for debugging.
var _trigger_history: Array[Dictionary] = []


# --- Lifecycle --- #

func _ready() -> void:
	super()
	# Defer signal connections to ensure GameManager is initialized regardless of autoload order
	_connect_game_manager_signals.call_deferred()


func _connect_game_manager_signals() -> void:
	if GameManager and GameManager.has_signal("evidence_discovered"):
		GameManager.evidence_discovered.connect(_on_evidence_discovered)
	if GameManager and GameManager.has_signal("insight_discovered"):
		GameManager.insight_discovered.connect(_on_insight_discovered)
	if GameManager and GameManager.has_signal("location_visited"):
		GameManager.location_visited.connect(_on_location_visited)
	if GameManager and GameManager.has_signal("mandatory_action_completed"):
		GameManager.mandatory_action_completed.connect(_on_mandatory_action_completed)


# --- Query Functions --- #

## Returns whether a specific trigger has fired.
func has_trigger_fired(trigger_id: String) -> bool:
	return trigger_id in _fired_triggers


## Returns all fired trigger IDs.
func get_fired_triggers() -> Array[String]:
	return _fired_triggers.duplicate()


## Returns the trigger history for debugging.
func get_trigger_history() -> Array[Dictionary]:
	return _trigger_history.duplicate()


## Returns all pending morning actions (from timed triggers that fired overnight).
func get_pending_morning_actions() -> Array[Dictionary]:
	return _pending_morning_actions.duplicate()


## Clears pending morning actions (called after briefing is delivered).
func clear_pending_morning_actions() -> void:
	_pending_morning_actions.clear()


# --- Trigger Evaluation: DAY_START --- #

## Evaluates all DAY_START triggers for the current day.
## Returns an array of human-readable briefing strings to include in the morning briefing.
## Also dispatches all actions (unlock_location, unlock_evidence, etc.) as side-effects.
func evaluate_day_start_triggers() -> Array[String]:
	var results: Array[String] = []

	if CaseManager.case_loaded_flag:
		var triggers: Array[EventTriggerData] = CaseManager.get_triggers_by_type("DAY_START")
		for trigger: EventTriggerData in triggers:
			if trigger.id in _fired_triggers:
				continue
			if trigger.trigger_day != -1 and trigger.trigger_day != GameManager.current_day:
				continue
			if _check_conditions(trigger.conditions):
				_fire_trigger(trigger, "DAY_START")
				_dispatch_trigger_actions(trigger)
				for action_str: String in trigger.actions:
					var briefing_line: String = _action_to_briefing_text(action_str)
					if not briefing_line.is_empty():
						results.append(briefing_line)
				day_start_trigger_fired.emit(trigger.id, trigger.actions)

	# Always drain pending morning actions from timed triggers that fired overnight
	for pending: Dictionary in _pending_morning_actions:
		var actions: Array = pending.get("actions", [])
		var trigger_id: String = pending.get("trigger_id", "")
		for action_str in actions:
			_dispatch_action(action_str as String, trigger_id)
			action_dispatched.emit(action_str as String, trigger_id)
			var briefing_line: String = _action_to_briefing_text(action_str as String)
			if not briefing_line.is_empty():
				results.append(briefing_line)
	clear_pending_morning_actions()

	return results


## Converts a raw action string to human-readable briefing text.
## Returns empty string for actions that should not appear in the briefing.
func _action_to_briefing_text(action_str: String) -> String:
	var parsed: PackedStringArray = ActionStringParser.parse(action_str)
	var action_type: String = parsed[0]
	var action_value: String = parsed[1]

	if action_type.is_empty():
		# Plain text — show as-is
		return action_str

	match action_type:
		ActionStringParser.ACT_UNLOCK_LOCATION:
			var loc: LocationData = CaseManager.get_location(action_value)
			var loc_name: String = loc.name if loc else action_value
			return "New location available: %s" % loc_name
		ActionStringParser.ACT_UNLOCK_EVIDENCE:
			var ev: EvidenceData = CaseManager.get_evidence(action_value)
			var ev_name: String = ev.name if ev else action_value
			return "New evidence: %s" % ev_name
		ActionStringParser.ACT_UNLOCK_INTERROGATION:
			var person: PersonData = CaseManager.get_person(action_value)
			var person_name: String = person.name if person else action_value
			return "New suspect available for questioning: %s" % person_name
		ActionStringParser.ACT_DELIVER_LAB_RESULTS:
			var ev: EvidenceData = CaseManager.get_evidence(action_value)
			var ev_name: String = ev.name if ev else action_value
			return "Lab results ready: %s" % ev_name
		ActionStringParser.ACT_UNLOCK_WARRANT:
			return "Warrant available: %s" % action_value
		ActionStringParser.ACT_NOTIFY:
			return action_value
		ActionStringParser.ACT_ADD_MANDATORY, ActionStringParser.ACT_SHOW_DIALOGUE:
			# Internal actions — don't show in briefing
			return ""
		_:
			return action_value


# --- Trigger Evaluation: TIMED --- #

## Evaluates all TIMED triggers for a specific day.
## Called during night processing to queue actions for the next morning.
func evaluate_timed_triggers(target_day: int) -> void:
	if not CaseManager.case_loaded_flag:
		return

	var triggers: Array[EventTriggerData] = CaseManager.get_triggers_by_type("TIMED")
	for trigger: EventTriggerData in triggers:
		if trigger.id in _fired_triggers:
			continue
		if trigger.trigger_day != target_day:
			continue
		if _check_conditions(trigger.conditions):
			_fire_trigger(trigger, "TIMED")
			# Queue actions for the morning briefing
			_pending_morning_actions.append({
				"trigger_id": trigger.id,
				"actions": trigger.actions.duplicate(),
				"target_day": target_day,
			})
			timed_trigger_fired.emit(trigger.id, target_day)


# --- Trigger Evaluation: CONDITIONAL --- #

## Evaluates all CONDITIONAL triggers against the current game state.
## Called when game state changes (evidence discovered, location visited, etc.).
func evaluate_conditional_triggers() -> void:
	if not CaseManager.case_loaded_flag:
		return

	var triggers: Array[EventTriggerData] = CaseManager.get_triggers_by_type("CONDITIONAL")
	for trigger: EventTriggerData in triggers:
		if trigger.id in _fired_triggers:
			continue
		if trigger.trigger_day != -1 and trigger.trigger_day != GameManager.current_day:
			continue
		if _check_conditions(trigger.conditions):
			_fire_trigger(trigger, "CONDITIONAL")
			conditional_trigger_fired.emit(trigger.id, trigger.actions)
			# Dispatch actions immediately for conditional triggers
			_dispatch_trigger_actions(trigger)


# --- Manual Trigger (Debug) --- #

## Manually fires a trigger by ID, ignoring conditions. Returns true if found.
func force_trigger(trigger_id: String) -> bool:
	if not CaseManager.case_loaded_flag:
		return false

	var trigger: EventTriggerData = CaseManager.get_event_trigger(trigger_id)
	if trigger == null:
		push_warning("[EventSystem] Trigger not found: %s" % trigger_id)
		return false

	if trigger.id in _fired_triggers:
		push_warning("[EventSystem] Trigger already fired: %s" % trigger_id)
		return false

	_fire_trigger(trigger, "MANUAL")
	_dispatch_trigger_actions(trigger)
	return true


## Resets a specific trigger so it can fire again (debug use).
func reset_trigger(trigger_id: String) -> void:
	_fired_triggers.erase(trigger_id)


# --- Condition Checking --- #

## Checks whether all conditions in a condition array are met.
## Condition format: "condition_type:value"
## Supported: evidence_discovered, location_visited, action_completed,
##            warrant_obtained, day, lab_complete, insight_discovered,
##            interrogation_completed, trigger_fired
func _check_conditions(conditions: Array[String]) -> bool:
	for condition: String in conditions:
		var parsed: PackedStringArray = ActionStringParser.parse(condition)
		var cond_type: String = parsed[0]
		var cond_value: String = parsed[1]

		if cond_type.is_empty():
			push_warning("[EventSystem] Malformed condition (no colon): '%s'" % condition)
			return false

		match cond_type:
			ActionStringParser.COND_EVIDENCE_DISCOVERED:
				if not GameManager.has_evidence(cond_value):
					return false
			ActionStringParser.COND_LOCATION_VISITED:
				if not GameManager.has_visited_location(cond_value):
					return false
			ActionStringParser.COND_ACTION_COMPLETED:
				var action_sys: Node = get_node_or_null("/root/ActionSystem")
				if action_sys and cond_value in action_sys.executed_actions:
					pass  # condition met
				elif cond_value in GameManager.mandatory_actions_completed:
					pass  # fallback for mandatory-only tracking
				else:
					return false
			ActionStringParser.COND_WARRANT_OBTAINED:
				if cond_value not in GameManager.warrants_obtained:
					return false
			ActionStringParser.COND_DAY:
				if GameManager.current_day != int(cond_value):
					return false
			ActionStringParser.COND_DAY_GTE:
				if GameManager.current_day < int(cond_value):
					return false
			ActionStringParser.COND_LAB_COMPLETE:
				var lab_mgr: Node = get_node_or_null("/root/LabManager")
				if lab_mgr and lab_mgr.has_method("get_request"):
					var req: Dictionary = lab_mgr.get_request(cond_value)
					if req.is_empty() or req.get("status", "") != "completed":
						return false
				else:
					# Fallback: request must have existed and no longer be active
					var was_active: bool = false
					for req in GameManager.active_lab_requests:
						if (req as Dictionary).get("id", "") == cond_value:
							was_active = true
							break
					if was_active:
						return false
			ActionStringParser.COND_INSIGHT_DISCOVERED:
				if cond_value not in GameManager.discovered_insights:
					return false
			ActionStringParser.COND_INTERROGATION_COMPLETED:
				if cond_value not in GameManager.completed_interrogations:
					return false
			ActionStringParser.COND_TRIGGER_FIRED:
				if cond_value not in _fired_triggers:
					return false

	return true


# --- Action Dispatching --- #

## Dispatches all actions from a trigger, creating notifications and applying effects.
func _dispatch_trigger_actions(trigger: EventTriggerData) -> void:
	for action_str: String in trigger.actions:
		_dispatch_action(action_str, trigger.id)
		action_dispatched.emit(action_str, trigger.id)


## Dispatches a single trigger action string.
## Actions are formatted as "action_type:value" or plain text (notification).
func _dispatch_action(action_str: String, source_trigger_id: String) -> void:
	var parsed: PackedStringArray = ActionStringParser.parse(action_str)
	var action_type: String = parsed[0]
	var action_value: String = parsed[1]

	if action_type.is_empty():
		# Plain text action — treat as a story notification
		NotificationManager.notify_story(action_str)
		GameManager.log_action("Event: %s (from %s)" % [action_str, source_trigger_id])
		return

	match action_type:
		ActionStringParser.ACT_UNLOCK_EVIDENCE:
			GameManager.discover_evidence(action_value)
			var ev: EvidenceData = CaseManager.get_evidence(action_value)
			var ev_name: String = ev.name if ev else action_value
			NotificationManager.notify_evidence(ev_name, action_value, ev.description if ev else "")
		ActionStringParser.ACT_UNLOCK_EVENT:
			# Events are informational — log and notify
			NotificationManager.notify_story("New event: %s" % action_value)
		ActionStringParser.ACT_UNLOCK_LOCATION:
			GameManager.unlock_location(action_value)
			# Notification is provided by the accompanying explicit "notify:" action in each
			# trigger, so no automatic popup is emitted here. This prevents duplicate
			# notifications when a trigger has both unlock_location and notify actions.
		ActionStringParser.ACT_UNLOCK_INTERROGATION:
			GameManager.unlock_interrogation(action_value)
			var person: PersonData = CaseManager.get_person(action_value)
			var person_name: String = person.name if person else action_value
			NotificationManager.notify_story("New suspect available for questioning: %s" % person_name)
		ActionStringParser.ACT_DELIVER_LAB_RESULTS:
			var ev: EvidenceData = CaseManager.get_evidence(action_value)
			var ev_name: String = ev.name if ev else action_value
			NotificationManager.notify_lab_result(ev_name, action_value)
		ActionStringParser.ACT_UNLOCK_WARRANT:
			NotificationManager.notify_warrant("Warrant available: %s" % action_value)
		ActionStringParser.ACT_ADD_MANDATORY:
			if action_value not in GameManager.mandatory_actions_required:
				GameManager.mandatory_actions_required.append(action_value)
		ActionStringParser.ACT_SHOW_DIALOGUE:
			# Queue dialogue for the dialogue system
			_queue_dialogue(action_value, source_trigger_id)
		ActionStringParser.ACT_NOTIFY:
			NotificationManager.notify_story(action_value)
		_:
			# Unknown action — just notify
			NotificationManager.notify_story(action_str)


## Queues a dialogue entry for the DialogueSystem.
func _queue_dialogue(dialogue_key: String, source_trigger: String) -> void:
	var dialogue_sys: Node = get_node_or_null("/root/DialogueSystem")
	if dialogue_sys and dialogue_sys.has_method("queue_dialogue"):
		dialogue_sys.call("queue_dialogue", dialogue_key, source_trigger)
	else:
		# Fallback: send as notification
		NotificationManager.notify_story(dialogue_key)


# --- Internal --- #

## Records a trigger as fired and adds to history.
func _fire_trigger(trigger: EventTriggerData, source: String) -> void:
	_fired_triggers.append(trigger.id)
	var history_entry: Dictionary = {
		"trigger_id": trigger.id,
		"source": source,
		"day": GameManager.current_day,
		"phase": GameManager.current_phase,
		"timestamp": Time.get_unix_time_from_system(),
	}
	_trigger_history.append(history_entry)
	trigger_fired.emit(trigger.id, trigger)


# --- Signal Handlers for Conditional Evaluation --- #

func _on_evidence_discovered(_evidence_id: String) -> void:
	evaluate_conditional_triggers()


func _on_insight_discovered(_insight_id: String) -> void:
	evaluate_conditional_triggers()


func _on_location_visited(_location_id: String) -> void:
	evaluate_conditional_triggers()


func _on_mandatory_action_completed(_action_id: String) -> void:
	evaluate_conditional_triggers()


# --- Serialization --- #

## Returns state for save/load.
func serialize() -> Dictionary:
	return {
		"fired_triggers": _fired_triggers.duplicate(),
		"pending_morning_actions": _pending_morning_actions.duplicate(true),
		"trigger_history": _trigger_history.duplicate(true),
	}


## Restores state from saved data.
func deserialize(data: Dictionary) -> void:
	_fired_triggers.assign(data.get("fired_triggers", []))
	_pending_morning_actions.assign(data.get("pending_morning_actions", []))
	_trigger_history.assign(data.get("trigger_history", []))


## Resets all EventSystem state for a new game.
func reset() -> void:
	_fired_triggers.clear()
	_pending_morning_actions.clear()
	_trigger_history.clear()
