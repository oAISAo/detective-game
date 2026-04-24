## LocationInvestigationManager.gd
## Manages runtime investigation state at locations.
## Tracks per-object investigation states, handles evidence discovery from objects,
## manages location visit accounting (first visit vs return), and calculates completion.
##
## Dependencies: CaseManager (location/evidence/lab-request lookups),
## GameManager (evidence discovery, action slots, visit tracking).
extends BaseSubsystem


# --- Constants --- #

## Structured error codes for investigation start attempts.
const START_ERROR_NONE: String = ""
const START_ERROR_UNKNOWN_LOCATION: String = "unknown_location"

## User-facing fallback messages for investigation start failures.
const START_ERROR_MESSAGE_UNKNOWN_LOCATION: String = "This location is unavailable right now."
const INVESTIGATION_ERROR_MESSAGE_NO_ACTIONS: String = "You have no actions remaining today. Use 'End Day' to proceed."

## Canonical action identifiers used for tracking performed actions.
const ACTION_VISUAL_INSPECTION: String = "visual_inspection"
const ACTION_EXAMINE_DEVICE: String = "examine_device"

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


# --- Lifecycle --- #

func _ready() -> void:
	super()


## Resets all investigation state for a new game.
func reset() -> void:
	_object_states.clear()
	_performed_actions.clear()
	current_location_id = ""


# --- Location Visit --- #

## Starts investigation at a location.
## Location entry is free; investigation actions spend slots on the detail screen.
## Returns a structured result: { success, error_code, error_message, location_id, is_first_visit }.
func start_investigation(location_id: String) -> Dictionary:
	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		push_error("[LocationInvestigationManager] Unknown location: %s" % location_id)
		return {
			"success": false,
			"error_code": START_ERROR_UNKNOWN_LOCATION,
			"error_message": START_ERROR_MESSAGE_UNKNOWN_LOCATION,
			"location_id": location_id,
			"is_first_visit": false,
		}

	var is_first_visit: bool = not GameManager.has_visited_location(location_id)
	if is_first_visit:
		GameManager.visit_location(location_id)

	_ensure_location_initialized(location_id)

	current_location_id = location_id
	investigation_started.emit(location_id, is_first_visit)
	return {
		"success": true,
		"error_code": START_ERROR_NONE,
		"error_message": "",
		"location_id": location_id,
		"is_first_visit": is_first_visit,
	}


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
	if ACTION_VISUAL_INSPECTION in _performed_actions.get(action_key, []):
		return []

	var inspectable_actions: Array[String] = [ACTION_VISUAL_INSPECTION, ACTION_EXAMINE_DEVICE]
	var has_inspection: bool = false
	for action: String in object_data.available_actions:
		if action in inspectable_actions:
			has_inspection = true
			break

	if not has_inspection:
		return []

	if not _consume_investigation_action("inspection"):
		return []

	# Record the action. Both visual_inspection and examine_device are treated as
	# a single "inspection" action — recording both ensures _update_object_state()
	# correctly counts the inspection as completed regardless of which label the
	# object uses in available_actions.
	if action_key not in _performed_actions:
		_performed_actions[action_key] = []
	_performed_actions[action_key].append(ACTION_VISUAL_INSPECTION)
	if ACTION_EXAMINE_DEVICE in object_data.available_actions:
		_performed_actions[action_key].append(ACTION_EXAMINE_DEVICE)

	# Discover evidence via inspection (visual_inspection or examine_device)
	var discovered: Array[String] = []
	for ev_id: String in object_data.evidence_results:
		# Only discover evidence matching visual/comparison methods
		var ev: EvidenceData = CaseManager.get_evidence(ev_id)
		if ev and ev.discovery_method not in [
			Enums.DiscoveryMethod.VISUAL, Enums.DiscoveryMethod.COMPARISON
		]:
			continue
		# Notify before discover_evidence emits the evidence_discovered signal.
		# This guarantees the "Evidence Found" notification is queued before any
		# conditional trigger (e.g. location unlock) appends its own notification.
		if ev and not GameManager.has_evidence(ev_id):
			NotificationManager.notify_evidence(ev.name)
		if GameManager.discover_evidence(ev_id):
			discovered.append(ev_id)
			evidence_found.emit(ev_id, object_id, "visual_inspection")

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
## Priority rule: FULLY_EXAMINED always maps to FULLY_PROCESSED. The map tab has exactly one
## action per object — once examined, it's done regardless of lab submission state.
## AWAITING_LAB_RESULTS can only apply to PARTIALLY_EXAMINED objects (future use).
func get_object_display_status(location_id: String, object_id: String) -> Enums.ObjectDisplayStatus:
	var base_state: Enums.InvestigationState = get_object_state(location_id, object_id)

	if base_state == Enums.InvestigationState.NOT_INSPECTED:
		return Enums.ObjectDisplayStatus.NOT_INSPECTED

	# Map-tab objects have exactly one action. Once the inspection is done, the object
	# is always "Fully processed" — lab submission is an Evidence-tab concern.
	# This check must come before the pending-lab check so FULLY_EXAMINED objects
	# are never incorrectly demoted to AWAITING_LAB_RESULTS.
	if base_state == Enums.InvestigationState.FULLY_EXAMINED:
		return Enums.ObjectDisplayStatus.FULLY_PROCESSED

	# For any non-fully-examined object, check if evidence is pending in the lab.
	# This path is reserved for PARTIALLY_EXAMINED objects (future multi-step objects).
	var object_data: InvestigableObjectData = _get_object(location_id, object_id)
	if object_data == null:
		return Enums.ObjectDisplayStatus.NOT_INSPECTED

	for ev_id: String in object_data.evidence_results:
		var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(ev_id)
		if lab_req == null:
			continue
		var ev: EvidenceData = CaseManager.get_evidence(ev_id)
		if ev != null and ev.lab_status == Enums.LabStatus.PROCESSING:
			return Enums.ObjectDisplayStatus.AWAITING_LAB_RESULTS

	return Enums.ObjectDisplayStatus.PARTIALLY_EXAMINED


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

	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		return MapCardStatus.NEW

	# Calculate completion based on VISIBLE objects only for status determination
	# This allows EXHAUSTED → NEW transition when hidden objects become visible
	var visible_objects: Array[InvestigableObjectData] = get_visible_objects(location)
	var visible_total: int = 0
	var visible_found: int = 0

	for obj: InvestigableObjectData in visible_objects:
		visible_total += obj.evidence_results.size()
		for ev_id: String in obj.evidence_results:
			if is_evidence_discovered(ev_id):
				visible_found += 1

	# All visible evidence found = check for hidden objects
	if visible_total > 0 and visible_found == visible_total:
		# All visible targets inspected - check if there are uninspected hidden objects
		var total_completion: Dictionary = get_location_completion(location_id)
		if total_completion["total"] > total_completion["found"]:
			# There are undiscovered hidden objects - show NEW to signal new content
			return MapCardStatus.NEW
		# No hidden objects and all evidence found
		return MapCardStatus.EXHAUSTED

	return MapCardStatus.OPEN


## Returns the names of suspects relevant to discovered evidence at a location.
func get_suspect_relevance_tags(location_id: String) -> Array[String]:
	var location: LocationData = CaseManager.get_location(location_id)
	if location == null:
		return []
	var person_ids: Dictionary = {}
	for ev_id: String in location.evidence_pool:
		if not is_evidence_discovered(ev_id):
			continue
		# Resolve the actual evidence object (raw or upgraded)
		var ev: EvidenceData = CaseManager.get_evidence(ev_id)
		if ev == null:
			var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(ev_id)
			if lab_req != null:
				ev = CaseManager.get_evidence(lab_req.output_evidence_id)
		if ev:
			for pid: String in ev.related_persons:
				if pid != "p_victim":
					person_ids[pid] = true
	var names: Array[String] = []
	for pid: String in person_ids.keys():
		var person: Resource = CaseManager.get_person(pid)
		if person:
			var pname: String = person.get("name") if person.get("name") else pid
			var parts: PackedStringArray = pname.split(" ")
			names.append(parts[0])
	return names


## Returns all actions performed on an object.
func get_performed_actions(location_id: String, object_id: String) -> Array:
	var key: String = "%s:%s" % [location_id, object_id]
	return _performed_actions.get(key, [])


# --- Location Completion --- #

## Returns true if evidence has been discovered, either directly or via lab upgrade.
func is_evidence_discovered(ev_id: String) -> bool:
	if GameManager.has_evidence(ev_id):
		return true
	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(ev_id)
	return lab_req != null and GameManager.has_evidence(lab_req.output_evidence_id)


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
			if is_evidence_discovered(ev_id):
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


## Returns an array of investigable objects that are currently visible at a location.
## Objects are hidden if their discovery_condition requirements are not met.
func get_visible_objects(location: LocationData) -> Array[InvestigableObjectData]:
	if location == null:
		return []
	var visible: Array[InvestigableObjectData] = []
	for obj: InvestigableObjectData in location.investigable_objects:
		if _is_object_visible(obj):
			visible.append(obj)
	return visible


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

## Checks if an object should be visible based on its discovery_condition.
## Returns true if the object has no condition or all required evidence is discovered.
func _is_object_visible(obj: InvestigableObjectData) -> bool:
	if obj.discovery_condition.is_empty():
		return true

	var requires_evidence: Array = obj.discovery_condition.get("requires_evidence", [])
	if requires_evidence.is_empty():
		return true

	# All required evidence must be discovered for the object to be visible
	for evidence_id: String in requires_evidence:
		if not GameManager.has_evidence(evidence_id):
			return false

	return true


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


## Public accessor for object data by location and object ID.
func get_object(location_id: String, object_id: String) -> InvestigableObjectData:
	return _get_object(location_id, object_id)


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
		if action == ACTION_VISUAL_INSPECTION or action == ACTION_EXAMINE_DEVICE:
			has_inspectable = true
			break
	if has_inspectable:
		total_actions += 1
		if ACTION_VISUAL_INSPECTION in actions_done or ACTION_EXAMINE_DEVICE in actions_done:
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


## Spends one investigation action slot. Returns true when spending succeeded.
func _consume_investigation_action(action_name: String) -> bool:
	if not GameManager.has_actions_remaining():
		push_warning("[LocationInvestigationManager] No actions remaining for %s." % action_name)
		return false
	return GameManager.use_action()


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
