## LocationInvestigationManager.gd
## Manages runtime investigation state at locations.
## Tracks per-object investigation states, handles evidence discovery from objects,
## manages location visit accounting (first visit vs return), and calculates completion.
extends Node


# --- Signals --- #

## Emitted when an object's investigation state changes.
signal object_state_changed(location_id: String, object_id: String, new_state: Enums.InvestigationState)

## Emitted when evidence is discovered through investigation.
signal evidence_found(evidence_id: String, object_id: String, method: String)

## Emitted when a location investigation begins.
signal investigation_started(location_id: String, is_first_visit: bool)

## Emitted when a location reaches full completion (all objects fully examined).
signal location_completed(location_id: String)


# --- State --- #

## Runtime investigation states: { location_id: { object_id: InvestigationState } }
var _object_states: Dictionary = {}

## Actions performed per object: { "location_id:object_id": ["action1", "action2"] }
var _performed_actions: Dictionary = {}

## Whether the player is currently at a location.
var current_location_id: String = ""


# --- Lifecycle --- #

func _ready() -> void:
	print("[LocationInvestigationManager] Initialized.")


## Resets all investigation state for a new game.
func reset() -> void:
	_object_states.clear()
	_performed_actions.clear()
	current_location_id = ""


# --- Location Visit --- #

## Starts investigation at a location. Handles first visit vs return.
## For first visits, costs 1 action. For returns, the caller decides full vs quick.
## Returns true if investigation started successfully.
func start_investigation(location_id: String, full_investigation: bool = true) -> bool:
	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		push_error("[LocationInvestigationManager] Unknown location: %s" % location_id)
		return false

	var is_first_visit: bool = not GameManager.has_visited_location(location_id)

	if is_first_visit:
		# First visit always costs an action
		if not GameManager.has_actions_remaining():
			push_warning("[LocationInvestigationManager] No actions remaining for first visit.")
			return false
		GameManager.use_action()
		GameManager.visit_location(location_id)
	elif full_investigation:
		# Return visit with full investigation costs an action
		if not GameManager.has_actions_remaining():
			push_warning("[LocationInvestigationManager] No actions remaining for full investigation.")
			return false
		GameManager.use_action()

	# Quick return visits (full_investigation=false) are free

	# Initialize object states if not yet tracked
	_ensure_location_initialized(location_id)

	current_location_id = location_id
	investigation_started.emit(location_id, is_first_visit)
	return true


## Leaves the current location.
func leave_location() -> void:
	current_location_id = ""


## Returns true if the player is currently at a location.
func is_at_location() -> bool:
	return not current_location_id.is_empty()


# --- Object Investigation --- #

## Performs a visual inspection on an object. Returns discovered evidence IDs.
func inspect_object(location_id: String, object_id: String) -> Array[String]:
	var object_data: InvestigableObjectData = _get_object(location_id, object_id)
	if object_data == null:
		return []

	var action_key: String = "%s:%s" % [location_id, object_id]
	if "visual_inspection" in _performed_actions.get(action_key, []):
		return []

	# Record the action
	if action_key not in _performed_actions:
		_performed_actions[action_key] = []
	_performed_actions[action_key].append("visual_inspection")

	# Discover evidence that doesn't require tools
	var discovered: Array[String] = []
	if "visual_inspection" in object_data.available_actions:
		if object_data.tool_requirements.is_empty():
			# No tools required — visual inspection reveals evidence directly
			for ev_id: String in object_data.evidence_results:
				if GameManager.discover_evidence(ev_id):
					discovered.append(ev_id)
					evidence_found.emit(ev_id, object_id, "visual_inspection")

	# Update investigation state
	_update_object_state(location_id, object_id, object_data)
	return discovered


## Uses a tool on an object. Returns discovered evidence IDs.
func use_tool_on_object(location_id: String, object_id: String, tool_id: String) -> Array[String]:
	var object_data: InvestigableObjectData = _get_object(location_id, object_id)
	if object_data == null:
		return []

	var tool_mgr: Node = get_node_or_null("/root/ToolManager")
	if tool_mgr == null:
		push_error("[LocationInvestigationManager] ToolManager not found.")
		return []

	var action_key: String = "%s:%s" % [location_id, object_id]
	var tool_action: String = "tool:%s" % tool_id
	if tool_action in _performed_actions.get(action_key, []):
		return []

	# Validate tool compatibility
	var error: String = tool_mgr.validate_tool_use(tool_id, object_data)
	if not error.is_empty():
		push_warning("[LocationInvestigationManager] %s" % error)
		return []

	# Record the action
	if action_key not in _performed_actions:
		_performed_actions[action_key] = []
	_performed_actions[action_key].append(tool_action)

	# Use tool to reveal evidence
	var tool_results: Array[String] = tool_mgr.use_tool(tool_id, object_data)
	var discovered: Array[String] = []
	for ev_id: String in tool_results:
		if GameManager.discover_evidence(ev_id):
			discovered.append(ev_id)
			evidence_found.emit(ev_id, object_id, tool_id)

	# Update investigation state
	_update_object_state(location_id, object_id, object_data)
	return discovered


## Returns the current investigation state for an object.
func get_object_state(location_id: String, object_id: String) -> Enums.InvestigationState:
	if location_id not in _object_states:
		return Enums.InvestigationState.NOT_INSPECTED
	return _object_states[location_id].get(object_id, Enums.InvestigationState.NOT_INSPECTED)


## Returns all actions performed on an object.
func get_performed_actions(location_id: String, object_id: String) -> Array:
	var key: String = "%s:%s" % [location_id, object_id]
	return _performed_actions.get(key, [])


# --- Location Completion --- #

## Returns the completion counts for a location: { "found": int, "total": int }.
func get_location_completion(location_id: String) -> Dictionary:
	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		return {"found": 0, "total": 0}

	var total: int = 0
	var found: int = 0
	for obj: InvestigableObjectData in location.investigable_objects:
		total += obj.evidence_results.size()
		for ev_id: String in obj.evidence_results:
			if GameManager.has_evidence(ev_id):
				found += 1

	return {"found": found, "total": total}


## Returns true if all evidence at a location has been discovered.
func is_location_complete(location_id: String) -> bool:
	var completion: Dictionary = get_location_completion(location_id)
	return completion["total"] > 0 and completion["found"] == completion["total"]


## Returns the number of fully examined objects at a location.
func get_examined_object_count(location_id: String) -> Dictionary:
	_ensure_location_initialized(location_id)
	var states: Dictionary = _object_states.get(location_id, {})
	var total: int = states.size()
	var examined: int = 0
	for obj_id: String in states:
		if states[obj_id] == Enums.InvestigationState.FULLY_EXAMINED:
			examined += 1
	return {"examined": examined, "total": total}


# --- Debug Tools --- #

## Marks all objects at a location as fully examined and discovers all evidence.
func debug_examine_all(location_id: String) -> void:
	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		return
	_ensure_location_initialized(location_id)
	for obj: InvestigableObjectData in location.investigable_objects:
		_object_states[location_id][obj.id] = Enums.InvestigationState.FULLY_EXAMINED
		for ev_id: String in obj.evidence_results:
			GameManager.discover_evidence(ev_id)
	location_completed.emit(location_id)


## Reveals all evidence at a location without changing object states.
func debug_reveal_all_evidence(location_id: String) -> void:
	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		return
	for obj: InvestigableObjectData in location.investigable_objects:
		for ev_id: String in obj.evidence_results:
			GameManager.discover_evidence(ev_id)


# --- Internal --- #

## Ensures a location's objects are initialized in the state tracker.
func _ensure_location_initialized(location_id: String) -> void:
	if location_id in _object_states:
		return
	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		return
	_object_states[location_id] = {}
	for obj: InvestigableObjectData in location.investigable_objects:
		_object_states[location_id][obj.id] = Enums.InvestigationState.NOT_INSPECTED


## Gets an InvestigableObjectData by location and object ID.
func _get_object(location_id: String, object_id: String) -> InvestigableObjectData:
	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		push_error("[LocationInvestigationManager] Unknown location: %s" % location_id)
		return null
	for obj: InvestigableObjectData in location.investigable_objects:
		if obj.id == object_id:
			return obj
	push_error("[LocationInvestigationManager] Unknown object '%s' at location '%s'" % [object_id, location_id])
	return null


## Updates an object's investigation state based on performed actions.
func _update_object_state(location_id: String, object_id: String, object_data: InvestigableObjectData) -> void:
	_ensure_location_initialized(location_id)
	var action_key: String = "%s:%s" % [location_id, object_id]
	var actions_done: Array = _performed_actions.get(action_key, [])

	# Calculate what actions are possible
	var total_actions: int = 0
	var completed_actions: int = 0

	# Count visual inspection
	if "visual_inspection" in object_data.available_actions:
		total_actions += 1
		if "visual_inspection" in actions_done:
			completed_actions += 1

	# Count tool-based actions
	for tool_req: String in object_data.tool_requirements:
		total_actions += 1
		if "tool:%s" % tool_req in actions_done:
			completed_actions += 1

	# Count non-visual non-tool actions
	for action: String in object_data.available_actions:
		if action != "visual_inspection" and not action.begins_with("tool:"):
			total_actions += 1
			if action in actions_done:
				completed_actions += 1

	var old_state: Enums.InvestigationState = _object_states[location_id].get(
		object_id, Enums.InvestigationState.NOT_INSPECTED
	)
	var new_state: Enums.InvestigationState

	if completed_actions == 0:
		new_state = Enums.InvestigationState.NOT_INSPECTED
	elif completed_actions >= total_actions:
		new_state = Enums.InvestigationState.FULLY_EXAMINED
	else:
		new_state = Enums.InvestigationState.PARTIALLY_EXAMINED

	_object_states[location_id][object_id] = new_state

	if new_state != old_state:
		object_state_changed.emit(location_id, object_id, new_state)

	# Check if location is now complete
	if new_state == Enums.InvestigationState.FULLY_EXAMINED:
		if is_location_complete(location_id):
			location_completed.emit(location_id)


# --- Serialization --- #

## Serializes investigation state.
func serialize() -> Dictionary:
	return {
		"object_states": _object_states.duplicate(true),
		"performed_actions": _performed_actions.duplicate(true),
		"current_location_id": current_location_id,
	}


## Restores investigation state from saved data.
func deserialize(data: Dictionary) -> void:
	_object_states = data.get("object_states", {})
	_performed_actions = data.get("performed_actions", {})
	current_location_id = data.get("current_location_id", "")
