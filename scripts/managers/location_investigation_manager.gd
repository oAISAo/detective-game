## LocationInvestigationManager.gd
## Manages runtime investigation state at locations.
## Tracks per-object investigation states, handles evidence discovery from objects,
## manages location visit accounting (first visit vs return), and calculates completion.
extends BaseSubsystem


# --- Constants --- #

## Structured error codes for investigation start attempts.
const START_ERROR_NONE: String = ""
const START_ERROR_UNKNOWN_LOCATION: String = "unknown_location"
const START_ERROR_NO_ACTIONS: String = "no_actions"

## User-facing fallback messages for investigation start failures.
const START_ERROR_MESSAGE_UNKNOWN_LOCATION: String = "This location is unavailable right now."
const START_ERROR_MESSAGE_NO_ACTIONS: String = "You have no actions remaining today. Use 'End Day' to proceed."

## Location-level status values for map-facing UI and logs.
const LOCATION_STATUS_NEW: String = "new"
const LOCATION_STATUS_OPEN: String = "open"
const LOCATION_STATUS_EXHAUSTED: String = "exhausted"

## Typed status buckets for map cards.
enum MapCardStatus {
	NEW,
	OPEN,
	EXHAUSTED,
}


# --- Signals --- #

## Emitted when an object's investigation state changes.
signal object_state_changed(location_id: String, object_id: String, new_state: Enums.InvestigationState)

## Emitted when evidence is discovered through investigation.
signal evidence_found(evidence_id: String, object_id: String, method: String)

## Emitted when a location investigation begins.
signal investigation_started(location_id: String, is_first_visit: bool)

## Emitted when a location reaches full completion (all objects fully examined).
signal location_completed(location_id: String)
signal state_loaded


# --- State --- #

## Runtime investigation states: { location_id: { object_id: InvestigationState } }
var _object_states: Dictionary = {}

## Actions performed per object: { "location_id:object_id": ["action1", "action2"] }
var _performed_actions: Dictionary = {}

## Whether the player is currently at a location.
var current_location_id: String = ""

## Last structured result from start_investigation_with_result.
var _last_start_investigation_result: Dictionary = {}


# --- Lifecycle --- #

func _ready() -> void:
	super()


## Resets all investigation state for a new game.
func reset() -> void:
	_object_states.clear()
	_performed_actions.clear()
	current_location_id = ""
	_last_start_investigation_result.clear()


# --- Location Visit --- #

## Starts investigation at a location.
## Every visit costs 1 action.
## Returns true if investigation started successfully.
func start_investigation(location_id: String) -> bool:
	var result: Dictionary = start_investigation_with_result(location_id)
	return result.get("success", false)


## Starts an investigation and returns a structured result.
## Result fields:
## - success: bool
## - error_code: String
## - error_message: String
## - location_id: String
## - is_first_visit: bool
## - action_cost: int
func start_investigation_with_result(location_id: String) -> Dictionary:
	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		push_error("[LocationInvestigationManager] Unknown location: %s" % location_id)
		return _record_start_result(_build_start_result(
			false,
			START_ERROR_UNKNOWN_LOCATION,
			START_ERROR_MESSAGE_UNKNOWN_LOCATION,
			location_id,
			false,
			0
		))

	var is_first_visit: bool = not GameManager.has_visited_location(location_id)
	var action_cost: int = _get_visit_action_cost()
	if action_cost > 0 and not GameManager.has_actions_remaining():
		push_warning("[LocationInvestigationManager] No actions remaining for location visit.")
		return _record_start_result(_build_start_result(
			false,
			START_ERROR_NO_ACTIONS,
			START_ERROR_MESSAGE_NO_ACTIONS,
			location_id,
			is_first_visit,
			action_cost
		))

	_apply_visit_cost(location_id, is_first_visit, action_cost)

	# Initialize object states if not yet tracked
	_ensure_location_initialized(location_id)

	current_location_id = location_id
	investigation_started.emit(location_id, is_first_visit)
	return _record_start_result(_build_start_result(
		true,
		START_ERROR_NONE,
		"",
		location_id,
		is_first_visit,
		action_cost
	))


## Starts investigation using the map policy.
## This keeps map action-cost rules owned by the manager.
func start_map_investigation(location_id: String) -> Dictionary:
	return start_investigation_with_result(location_id)


## Returns the last structured start result.
func get_last_start_investigation_result() -> Dictionary:
	return _last_start_investigation_result.duplicate(true)


## Leaves the current location.
func leave_location() -> void:
	current_location_id = ""


## Returns true if the player is currently at a location.
func is_at_location() -> bool:
	return not current_location_id.is_empty()


# --- Object Investigation --- #

## Performs an inspection on an object. Returns discovered evidence IDs.
## Handles both visual_inspection and examine_device actions.
func inspect_object(location_id: String, object_id: String) -> Array[String]:
	var object_data: InvestigableObjectData = _get_object(location_id, object_id)
	if object_data == null:
		return []

	var action_key: String = "%s:%s" % [location_id, object_id]
	if "visual_inspection" in _performed_actions.get(action_key, []):
		return []

	# Record the action — also record any examine_device action so the state
	# machine counts it as completed.
	if action_key not in _performed_actions:
		_performed_actions[action_key] = []
	_performed_actions[action_key].append("visual_inspection")
	if "examine_device" in object_data.available_actions:
		_performed_actions[action_key].append("examine_device")

	# Discover evidence via inspection (visual_inspection or examine_device)
	var discovered: Array[String] = []
	var inspectable_actions: Array[String] = ["visual_inspection", "examine_device"]
	var has_inspection: bool = false
	for action: String in object_data.available_actions:
		if action in inspectable_actions:
			has_inspection = true
			break

	if has_inspection:
		for ev_id: String in object_data.evidence_results:
			# Only discover evidence matching visual/comparison methods
			var ev: EvidenceData = CaseManager.get_evidence(ev_id)
			if ev and ev.discovery_method not in [
				Enums.DiscoveryMethod.VISUAL, Enums.DiscoveryMethod.COMPARISON
			]:
				continue
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

	# Use tool to reveal evidence (only TOOL/LAB discovery method)
	var tool_results: Array[String] = tool_mgr.use_tool(tool_id, object_data)
	var discovered: Array[String] = []
	for ev_id: String in tool_results:
		var ev: EvidenceData = CaseManager.get_evidence(ev_id)
		if ev and ev.discovery_method not in [
			Enums.DiscoveryMethod.TOOL, Enums.DiscoveryMethod.LAB
		]:
			continue
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


## Returns the derived display status for an object, combining investigation state with lab lifecycle.
## This is used by UI to show whether an object still has pending lab work.
func get_object_display_status(location_id: String, object_id: String) -> Enums.ObjectDisplayStatus:
	var base_state: Enums.InvestigationState = get_object_state(location_id, object_id)

	if base_state == Enums.InvestigationState.NOT_INSPECTED:
		return Enums.ObjectDisplayStatus.NOT_INSPECTED

	# Check if any evidence from this object is pending in the lab
	var object_data: InvestigableObjectData = _get_object(location_id, object_id)
	if object_data == null:
		return Enums.ObjectDisplayStatus.NOT_INSPECTED

	var has_pending_lab: bool = false
	var has_completed_lab: bool = false
	var has_lab_eligible: bool = false

	for ev_id: String in object_data.evidence_results:
		var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(ev_id)
		if lab_req == null:
			continue
		has_lab_eligible = true
		var ev: EvidenceData = CaseManager.get_evidence(ev_id)
		if ev == null:
			continue
		if ev.lab_status == Enums.LabStatus.PROCESSING:
			has_pending_lab = true
		elif ev.lab_status == Enums.LabStatus.COMPLETED:
			has_completed_lab = true

	if has_pending_lab:
		return Enums.ObjectDisplayStatus.AWAITING_LAB_RESULTS

	if has_lab_eligible and has_completed_lab and base_state == Enums.InvestigationState.FULLY_EXAMINED:
		return Enums.ObjectDisplayStatus.FULLY_PROCESSED

	if base_state == Enums.InvestigationState.FULLY_EXAMINED:
		if has_lab_eligible and not has_completed_lab:
			# Lab eligible but not yet submitted — still partially examined from lab perspective
			return Enums.ObjectDisplayStatus.PARTIALLY_EXAMINED
		return Enums.ObjectDisplayStatus.FULLY_PROCESSED

	return Enums.ObjectDisplayStatus.PARTIALLY_EXAMINED


## Returns the derived display status hint text for an object.
## Provides state-aware investigation messaging for the UI detail panel.
func get_object_status_hint(location_id: String, object_id: String) -> String:
	var status: Enums.ObjectDisplayStatus = get_object_display_status(location_id, object_id)
	match status:
		Enums.ObjectDisplayStatus.NOT_INSPECTED:
			return "This area has not been examined yet."
		Enums.ObjectDisplayStatus.PARTIALLY_EXAMINED:
			# Check if this object has lab-eligible evidence that hasn't been submitted
			var object_data: InvestigableObjectData = _get_object(location_id, object_id)
			if object_data:
				for ev_id: String in object_data.evidence_results:
					var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(ev_id)
					if lab_req and GameManager.has_evidence(ev_id):
						var ev: EvidenceData = CaseManager.get_evidence(ev_id)
						if ev and ev.lab_status == Enums.LabStatus.NOT_SUBMITTED:
							return "Evidence recovered. Submit to the forensic lab for further analysis."
			return "Further examination may reveal more evidence."
		Enums.ObjectDisplayStatus.AWAITING_LAB_RESULTS:
			return "Forensic analysis is in progress. Results will arrive in a future briefing."
		Enums.ObjectDisplayStatus.FULLY_PROCESSED:
			return "No further leads are currently available at this target."
	return ""


## Returns whether any object at a location has evidence pending in the lab.
func has_pending_lab_at_location(location_id: String) -> bool:
	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		return false
	for obj: InvestigableObjectData in location.investigable_objects:
		var status: Enums.ObjectDisplayStatus = get_object_display_status(location_id, obj.id)
		if status == Enums.ObjectDisplayStatus.AWAITING_LAB_RESULTS:
			return true
	return false


## Returns a location-level status string for the map view.
func get_location_status(location_id: String) -> String:
	match get_location_card_status(location_id):
		MapCardStatus.NEW:
			return LOCATION_STATUS_NEW
		MapCardStatus.OPEN:
			return LOCATION_STATUS_OPEN
		MapCardStatus.EXHAUSTED:
			return LOCATION_STATUS_EXHAUSTED
		_:
			return LOCATION_STATUS_NEW


## Returns a typed status bucket for map cards.
func get_location_card_status(location_id: String) -> MapCardStatus:
	if not GameManager.has_visited_location(location_id):
		return MapCardStatus.NEW
	if has_pending_lab_at_location(location_id):
		return MapCardStatus.OPEN
	var completion: Dictionary = get_location_completion(location_id)
	if completion["total"] > 0 and completion["found"] == completion["total"]:
		return MapCardStatus.EXHAUSTED
	return MapCardStatus.OPEN


## Returns the names of suspects relevant to discovered evidence at a location.
func get_suspect_relevance_tags(location_id: String) -> Array[String]:
	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		return []
	var person_ids: Dictionary = {}
	for ev_id: String in location.evidence_pool:
		if not GameManager.has_evidence(ev_id):
			# Check if raw was upgraded
			var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(ev_id)
			if lab_req == null or not GameManager.has_evidence(lab_req.output_evidence_id):
				continue
			# Use the output evidence for related persons
			var ev: EvidenceData = CaseManager.get_evidence(lab_req.output_evidence_id)
			if ev:
				for pid: String in ev.related_persons:
					if pid != "p_victim":
						person_ids[pid] = true
		else:
			var ev: EvidenceData = CaseManager.get_evidence(ev_id)
			if ev:
				for pid: String in ev.related_persons:
					if pid != "p_victim":
						person_ids[pid] = true
	var names: Array[String] = []
	for pid: String in person_ids.keys():
		var person: Resource = CaseManager.get_person(pid)
		if person:
			var pname: String = person.get("name") if person.get("name") else pid
			# Use first name only
			var parts: PackedStringArray = pname.split(" ")
			names.append(parts[0])
	return names


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
			else:
				# Check if this raw evidence was upgraded to an analyzed version
				var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(ev_id)
				if lab_req != null and GameManager.has_evidence(lab_req.output_evidence_id):
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

	# Calculate what actions are possible.
	# We count two categories: inspection (visual_inspection / examine_device)
	# and tool-based actions (one per tool requirement).
	var total_actions: int = 0
	var completed_actions: int = 0

	# Count inspection action (visual_inspection or examine_device count as one)
	var has_inspectable: bool = false
	for action: String in object_data.available_actions:
		if action == "visual_inspection" or action == "examine_device":
			has_inspectable = true
			break
	if has_inspectable:
		total_actions += 1
		if "visual_inspection" in actions_done or "examine_device" in actions_done:
			completed_actions += 1

	# Count tool-based actions
	for tool_req: String in object_data.tool_requirements:
		total_actions += 1
		if "tool:%s" % tool_req in actions_done:
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


## Calculates the action cost for a visit based on current visit context.
func _get_visit_action_cost() -> int:
	return 1


## Applies visit-side effects for action spending and first-visit markers.
func _apply_visit_cost(location_id: String, is_first_visit: bool, action_cost: int) -> void:
	if action_cost > 0:
		GameManager.use_action()
	if is_first_visit:
		GameManager.visit_location(location_id)


## Builds a structured start result dictionary.
func _build_start_result(
	success: bool,
	error_code: String,
	error_message: String,
	location_id: String,
	is_first_visit: bool,
	action_cost: int
) -> Dictionary:
	return {
		"success": success,
		"error_code": error_code,
		"error_message": error_message,
		"location_id": location_id,
		"is_first_visit": is_first_visit,
		"action_cost": action_cost,
	}


## Persists the last structured result and returns a copy.
func _record_start_result(result: Dictionary) -> Dictionary:
	_last_start_investigation_result = result.duplicate(true)
	return _last_start_investigation_result.duplicate(true)


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
	state_loaded.emit()
