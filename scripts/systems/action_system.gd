## ActionSystem.gd
## Manages the data-driven action economy: availability checking,
## prerequisite validation, action execution, and result processing.
## Phase 2: Core action system with requirement/result parsing.
extends Node


# --- Signals --- #

## Emitted when an action is successfully executed.
signal action_executed(action_id: String, action_data: ActionData)

## Emitted when an action fails validation (requirements not met).
signal action_unavailable(action_id: String, reasons: Array[String])

## Emitted when a delayed action is submitted (lab, surveillance, warrant).
signal delayed_action_submitted(action_id: String, type: String)

## Emitted when an action result is applied.
signal action_result_applied(result_type: String, result_value: String)


# --- State --- #

## IDs of all actions the player has executed this investigation.
var executed_actions: Array[String] = []

## IDs of actions executed today (reset each day).
var actions_executed_today: Array[String] = []


# --- Lifecycle --- #

func _ready() -> void:
	print("[ActionSystem] Initialized.")


# --- Action Availability --- #

## Checks whether the given action can be performed right now.
## Returns an empty array if available, or a list of reasons it's unavailable.
func check_availability(action_id: String) -> Array[String]:
	var reasons: Array[String] = []

	var action: ActionData = CaseManager.get_action(action_id)
	if action == null:
		reasons.append("Action not found: %s" % action_id)
		return reasons

	# Check if it's a major action and player has slots
	if action.time_cost > 0 and not GameManager.has_actions_remaining():
		reasons.append("No action slots remaining today.")

	# Check if action was already executed (one-time actions)
	if action_id in executed_actions and action.time_cost > 0:
		reasons.append("Action already completed: %s" % action.name)

	# Check time slot — major actions require Daytime phase
	if action.time_cost > 0:
		if not GameManager.is_daytime():
			reasons.append("Major actions can only be performed during Daytime.")

	# Check interrogation limits
	if action.type == Enums.ActionType.INTERROGATION:
		if not action.target.is_empty() and not GameManager.can_interrogate_today(action.target):
			reasons.append("Already interrogated %s today." % action.target)

	# Check requirements
	var req_failures: Array[String] = _check_requirements(action.requirements)
	reasons.append_array(req_failures)

	return reasons


## Returns all currently available actions from the case data.
func get_available_actions() -> Array[ActionData]:
	var available: Array[ActionData] = []
	var all_actions: Array[ActionData] = CaseManager.get_all_actions()

	for action: ActionData in all_actions:
		var reasons: Array[String] = check_availability(action.id)
		if reasons.is_empty():
			available.append(action)

	return available


## Returns all passive (free) actions from the case data.
## Passive actions are always available regardless of time slot or action slots.
func get_passive_actions() -> Array[ActionData]:
	var passive: Array[ActionData] = []
	var all_actions: Array[ActionData] = CaseManager.get_all_actions()

	for action: ActionData in all_actions:
		if action.time_cost == 0:
			passive.append(action)

	return passive


## Returns all major actions available this time slot.
func get_available_major_actions() -> Array[ActionData]:
	var major: Array[ActionData] = []
	var all_actions: Array[ActionData] = CaseManager.get_all_actions()

	for action: ActionData in all_actions:
		if action.time_cost > 0:
			var reasons: Array[String] = check_availability(action.id)
			if reasons.is_empty():
				major.append(action)

	return major


# --- Action Execution --- #

## Attempts to execute an action by ID.
## Returns true if the action was successfully executed, false otherwise.
func execute_action(action_id: String) -> bool:
	var reasons: Array[String] = check_availability(action_id)
	if not reasons.is_empty():
		action_unavailable.emit(action_id, reasons)
		return false

	var action: ActionData = CaseManager.get_action(action_id)
	if action == null:
		return false

	# Consume action slot for major actions
	if action.time_cost > 0:
		if not GameManager.use_action():
			return false

	# Track execution
	if action_id not in executed_actions:
		executed_actions.append(action_id)
	actions_executed_today.append(action_id)

	# Handle interrogation tracking
	if action.type == Enums.ActionType.INTERROGATION and not action.target.is_empty():
		GameManager.record_interrogation(action.target)

	# Handle location visit tracking
	if action.type == Enums.ActionType.VISIT_LOCATION and not action.target.is_empty():
		GameManager.visit_location(action.target)

	# Apply results
	_apply_results(action.results)

	# Log the action
	GameManager._log_action("Action: %s" % action.name)

	action_executed.emit(action_id, action)
	return true


# --- Requirement Checking --- #

## Validates all requirements in a requirements array.
## Returns an empty array if all requirements are met, or a list of failure reasons.
func _check_requirements(requirements: Array[String]) -> Array[String]:
	var failures: Array[String] = []

	for req: String in requirements:
		var parts: PackedStringArray = req.split(":", true, 1)
		if parts.size() < 2:
			failures.append("Invalid requirement format: %s" % req)
			continue
		var req_type: String = parts[0].strip_edges()
		var req_value: String = parts[1].strip_edges()

		match req_type:
			"evidence":
				if not GameManager.has_evidence(req_value):
					failures.append("Requires evidence: %s" % req_value)
			"location":
				if not GameManager.has_visited_location(req_value):
					failures.append("Requires visiting location: %s" % req_value)
			"warrant":
				if req_value not in GameManager.warrants_obtained:
					failures.append("Requires warrant: %s" % req_value)
			"action_completed":
				if req_value not in executed_actions:
					failures.append("Requires completing action: %s" % req_value)
			"insight":
				if req_value not in GameManager.discovered_insights:
					failures.append("Requires insight: %s" % req_value)
			"day":
				if GameManager.current_day < int(req_value):
					failures.append("Not available until day %s" % req_value)
			_:
				# Unknown requirement type — pass for forward compatibility
				push_warning("[ActionSystem] Unknown requirement type: %s" % req_type)

	return failures


# --- Result Processing --- #

## Applies all results from an action's results array.
func _apply_results(results: Array[String]) -> void:
	for result: String in results:
		var parts: PackedStringArray = result.split(":", true, 1)
		if parts.size() < 2:
			push_warning("[ActionSystem] Invalid result format: %s" % result)
			continue
		var result_type: String = parts[0].strip_edges()
		var result_value: String = parts[1].strip_edges()

		_apply_single_result(result_type, result_value)
		action_result_applied.emit(result_type, result_value)


## Applies a single result entry.
func _apply_single_result(result_type: String, result_value: String) -> void:
	match result_type:
		"evidence":
			GameManager.discover_evidence(result_value)
		"insight":
			GameManager.discover_insight(result_value)
		"location":
			GameManager.visit_location(result_value)
		"warrant":
			if result_value not in GameManager.warrants_obtained:
				GameManager.warrants_obtained.append(result_value)
				GameManager._log_action("Warrant obtained: %s" % result_value)
		"mandatory":
			GameManager.complete_mandatory_action(result_value)
		"lab_request":
			_submit_lab_request(result_value)
		"surveillance":
			_submit_surveillance(result_value)
		_:
			push_warning("[ActionSystem] Unknown result type: %s" % result_type)


## Submits a lab request by evidence ID. Creates the request and adds it to GameManager.
func _submit_lab_request(evidence_id: String) -> void:
	var request: Dictionary = {
		"id": "lab_%s_%d" % [evidence_id, GameManager.current_day],
		"input_evidence_id": evidence_id,
		"analysis_type": "standard",
		"day_submitted": GameManager.current_day,
		"completion_day": GameManager.current_day + 1,
		"output_evidence_id": "%s_analyzed" % evidence_id,
	}
	GameManager.active_lab_requests.append(request)
	GameManager._log_action("Lab request submitted: %s (results Day %d)" % [
		evidence_id, request["completion_day"]
	])
	delayed_action_submitted.emit(request["id"], "lab_request")


## Submits a surveillance operation. Creates the entry and adds it to GameManager.
func _submit_surveillance(target_person: String) -> void:
	var surv: Dictionary = {
		"id": "surv_%s_%d" % [target_person, GameManager.current_day],
		"target_person": target_person,
		"type": "PHONE_TAP",
		"day_installed": GameManager.current_day,
		"active_days": 2,
		"result_events": [],
	}
	GameManager.active_surveillance.append(surv)
	GameManager._log_action("Surveillance installed: %s (active %d days)" % [
		target_person, surv["active_days"]
	])
	delayed_action_submitted.emit(surv["id"], "surveillance")


# --- Daily Reset --- #

## Resets daily tracking. Called by DaySystem during night processing.
func on_new_day() -> void:
	actions_executed_today.clear()


# --- Serialization --- #

## Returns state for save/load.
func serialize() -> Dictionary:
	return {
		"executed_actions": executed_actions.duplicate(),
		"actions_executed_today": actions_executed_today.duplicate(),
	}


## Restores state from saved data.
func deserialize(data: Dictionary) -> void:
	executed_actions.assign(data.get("executed_actions", []))
	actions_executed_today.assign(data.get("actions_executed_today", []))


## Resets all ActionSystem state for a new game.
func reset() -> void:
	executed_actions.clear()
	actions_executed_today.clear()
