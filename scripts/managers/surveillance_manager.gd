## SurveillanceManager.gd
## Manages surveillance operation installation, tracking, and query.
## Surveillance produces observation events that feed into the timeline.
## DaySystem handles result delivery during morning phase; this manager
## provides the installation API and operation lifecycle tracking.
extends Node


# --- Signals --- #

## Emitted when surveillance is installed on a target.
signal surveillance_installed(surveillance_id: String, target_person: String)

## Emitted when surveillance results are received.
signal surveillance_result_received(surveillance_id: String, event_ids: Array[String])

## Emitted when a surveillance operation expires.
signal surveillance_expired(surveillance_id: String)

## Emitted when surveillance is cancelled.
signal surveillance_cancelled(surveillance_id: String)


# --- Constants --- #

## Maximum concurrent surveillance operations.
const MAX_CONCURRENT: int = 2

## Default number of active days for surveillance.
const DEFAULT_ACTIVE_DAYS: int = 2


# --- State --- #

## All surveillance operations tracked: { surveillance_id: Dictionary }
var _operations: Dictionary = {}

## Results received: { surveillance_id: Array[Array[String]] }
var _received_results: Dictionary = {}

## Auto-incrementing ID counter.
var _next_id: int = 1


# --- Lifecycle --- #

func _ready() -> void:
	var day_sys: Node = get_node_or_null("/root/DaySystem")
	if day_sys and day_sys.has_signal("surveillance_result"):
		day_sys.surveillance_result.connect(_on_surveillance_result)
	print("[SurveillanceManager] Initialized.")


# --- Installation --- #

## Installs surveillance on a target person.
## Returns the operation dictionary on success, or empty dictionary on failure.
func install_surveillance(
	target_person: String,
	surveillance_type: Enums.SurveillanceType,
	active_days: int = DEFAULT_ACTIVE_DAYS,
	result_events: Array[String] = []
) -> Dictionary:
	# Validate target person exists
	var person: PersonData = CaseManager.get_person(target_person)
	if person == null:
		push_error("[SurveillanceManager] Person not found: %s" % target_person)
		return {}

	# Check if already under surveillance
	if is_person_under_surveillance(target_person):
		push_warning("[SurveillanceManager] Person already under surveillance: %s" % target_person)
		return {}

	# Check concurrent limit
	if get_active_count() >= MAX_CONCURRENT:
		push_warning("[SurveillanceManager] Maximum concurrent surveillance reached (%d)." % MAX_CONCURRENT)
		return {}

	if active_days < 1:
		active_days = DEFAULT_ACTIVE_DAYS

	var surv_id: String = "surv_%d" % _next_id
	_next_id += 1

	var operation: Dictionary = {
		"id": surv_id,
		"target_person": target_person,
		"type": surveillance_type,
		"day_installed": GameManager.current_day,
		"active_days": active_days,
		"result_events": result_events.duplicate(),
		"status": "active",
	}

	_operations[surv_id] = operation

	# Add to GameManager for DaySystem processing
	GameManager.active_surveillance.append(operation.duplicate())

	surveillance_installed.emit(surv_id, target_person)
	GameManager._log_action("Surveillance installed: %s on %s" % [
		_surveillance_type_name(surveillance_type), target_person
	])
	return operation.duplicate()


## Cancels an active surveillance operation. Returns true on success.
func cancel_surveillance(surveillance_id: String) -> bool:
	if surveillance_id not in _operations:
		push_warning("[SurveillanceManager] Operation not found: %s" % surveillance_id)
		return false

	var op: Dictionary = _operations[surveillance_id]
	if op.get("status", "") != "active":
		push_warning("[SurveillanceManager] Cannot cancel non-active operation: %s" % surveillance_id)
		return false

	op["status"] = "cancelled"
	_operations[surveillance_id] = op

	# Remove from GameManager active list
	_remove_from_game_manager(surveillance_id)

	surveillance_cancelled.emit(surveillance_id)
	return true


# --- Query --- #

## Returns a specific operation by ID, or empty dictionary if not found.
func get_operation(surveillance_id: String) -> Dictionary:
	if surveillance_id in _operations:
		return _operations[surveillance_id].duplicate()
	return {}


## Returns all active surveillance operations.
func get_active_operations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for op: Dictionary in _operations.values():
		if op.get("status", "") == "active":
			result.append(op.duplicate())
	return result


## Returns all operations for a specific person.
func get_operations_for_person(person_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for op: Dictionary in _operations.values():
		if op.get("target_person", "") == person_id:
			result.append(op.duplicate())
	return result


## Returns the number of active operations.
func get_active_count() -> int:
	var count: int = 0
	for op: Dictionary in _operations.values():
		if op.get("status", "") == "active":
			count += 1
	return count


## Returns the total number of operations (all statuses).
func get_operation_count() -> int:
	return _operations.size()


## Returns whether the given person is currently under surveillance.
func is_person_under_surveillance(person_id: String) -> bool:
	for op: Dictionary in _operations.values():
		if op.get("target_person", "") == person_id and op.get("status", "") == "active":
			return true
	return false


## Returns results received for a specific operation.
func get_results_for_operation(surveillance_id: String) -> Array:
	return _received_results.get(surveillance_id, []).duplicate(true)


## Returns whether the manager has any data.
func has_content() -> bool:
	return not _operations.is_empty()


# --- Debug --- #

## Completes all active surveillance instantly, returning all result events.
func complete_all_instantly() -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	for surv_id: String in _operations.keys():
		var op: Dictionary = _operations[surv_id]
		if op.get("status", "") != "active":
			continue
		op["status"] = "expired"
		_operations[surv_id] = op
		completed.append(op.duplicate())
		surveillance_expired.emit(surv_id)

	GameManager.active_surveillance.clear()
	return completed


# --- Internal --- #

## Called when DaySystem delivers surveillance results.
func _on_surveillance_result(surveillance_id: String, result_event_ids: Array[String]) -> void:
	if surveillance_id not in _received_results:
		_received_results[surveillance_id] = []
	_received_results[surveillance_id].append(result_event_ids.duplicate())
	surveillance_result_received.emit(surveillance_id, result_event_ids)


## Removes an operation from GameManager.active_surveillance by ID.
func _remove_from_game_manager(surveillance_id: String) -> void:
	var remaining: Array = []
	for surv in GameManager.active_surveillance:
		var s: Dictionary = surv as Dictionary
		if s.get("id", "") != surveillance_id:
			remaining.append(s)
	GameManager.active_surveillance = remaining


## Returns a display name for a surveillance type.
func _surveillance_type_name(surv_type: Enums.SurveillanceType) -> String:
	match surv_type:
		Enums.SurveillanceType.PHONE_TAP:
			return "Phone Tap"
		Enums.SurveillanceType.HOME_SURVEILLANCE:
			return "Home Surveillance"
		Enums.SurveillanceType.FINANCIAL_MONITORING:
			return "Financial Monitoring"
	return "Unknown"


# --- Serialization --- #

## Returns the surveillance manager state for saving.
func serialize() -> Dictionary:
	return {
		"operations": _operations.duplicate(true),
		"received_results": _received_results.duplicate(true),
		"next_id": _next_id,
	}


## Restores surveillance manager state from saved data.
func deserialize(data: Dictionary) -> void:
	_operations = data.get("operations", {}).duplicate(true)
	_received_results = data.get("received_results", {}).duplicate(true)
	_next_id = data.get("next_id", 1)


## Resets all surveillance manager state for a new game.
func reset() -> void:
	_operations.clear()
	_received_results.clear()
	_next_id = 1
