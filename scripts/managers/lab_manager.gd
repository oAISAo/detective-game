## LabManager.gd
## Manages forensic lab request submissions, tracking, and query.
## Lab requests are evidence transformations: input evidence + analysis → output evidence.
## DaySystem handles completion processing during morning phase; this manager
## provides the submission API and request lifecycle tracking.
extends BaseSubsystem


# --- Signals --- #

## Emitted when a new lab request is submitted.
signal lab_submitted(request_id: String, input_evidence_id: String)

## Emitted when a lab request is completed (output evidence discovered).
signal lab_completed(request_id: String, output_evidence_id: String)

## Emitted when a lab request is cancelled.
signal lab_cancelled(request_id: String)


# --- Constants --- #

## Default number of days for lab processing.
const DEFAULT_PROCESSING_DAYS: int = 1

## Maximum concurrent lab requests.
const MAX_CONCURRENT_REQUESTS: int = 3


# --- State --- #

## All lab requests tracked by this manager: { request_id: Dictionary }
var _requests: Dictionary = {}

## Auto-incrementing ID counter.
var _next_id: int = 1


# --- Lifecycle --- #

func _ready() -> void:
	super()
	var day_sys: Node = get_node_or_null("/root/DaySystem")
	if day_sys and day_sys.has_signal("lab_result_ready"):
		day_sys.lab_result_ready.connect(_on_lab_result_ready)


# --- Submission --- #

## Submits a lab request for the given evidence.
## Returns the request dictionary on success, or empty dictionary on failure.
func submit_request(
	input_evidence_id: String,
	analysis_type: String,
	output_evidence_id: String,
	processing_days: int = DEFAULT_PROCESSING_DAYS
) -> Dictionary:
	# Validate input evidence exists and is discovered
	if not GameManager.has_evidence(input_evidence_id):
		push_error("[LabManager] Evidence not discovered: %s" % input_evidence_id)
		return {}

	# Check if already submitted
	if is_evidence_submitted(input_evidence_id):
		push_warning("[LabManager] Evidence already submitted for analysis: %s" % input_evidence_id)
		return {}

	# Check concurrent limit
	if get_pending_count() >= MAX_CONCURRENT_REQUESTS:
		push_warning("[LabManager] Maximum concurrent requests reached (%d)." % MAX_CONCURRENT_REQUESTS)
		return {}

	# Validate processing days
	if processing_days < 1:
		processing_days = DEFAULT_PROCESSING_DAYS

	var request_id: String = "lab_%d" % _next_id
	_next_id += 1

	var request: Dictionary = {
		"id": request_id,
		"input_evidence_id": input_evidence_id,
		"analysis_type": analysis_type,
		"day_submitted": GameManager.current_day,
		"completion_day": GameManager.current_day + processing_days,
		"output_evidence_id": output_evidence_id,
		"status": "pending",
	}

	_requests[request_id] = request

	# Add to GameManager for DaySystem processing
	GameManager.active_lab_requests.append(request.duplicate())

	lab_submitted.emit(request_id, input_evidence_id)
	# Update the input evidence's lab_status to PROCESSING
	var ev: EvidenceData = CaseManager.get_evidence(input_evidence_id)
	if ev:
		ev.lab_status = Enums.LabStatus.PROCESSING
	var ev_name: String = ev.name if ev else input_evidence_id
	GameManager.log_action("Lab request submitted: %s (%s)" % [analysis_type, ev_name])
	return request.duplicate()


## Cancels a pending lab request. Returns true on success.
func cancel_request(request_id: String) -> bool:
	if request_id not in _requests:
		push_warning("[LabManager] Request not found: %s" % request_id)
		return false

	var request: Dictionary = _requests[request_id]
	if request.get("status", "") != "pending":
		push_warning("[LabManager] Cannot cancel non-pending request: %s" % request_id)
		return false

	request["status"] = "cancelled"
	_requests[request_id] = request

	# Remove from GameManager active list
	_remove_from_game_manager(request_id)

	lab_cancelled.emit(request_id)
	return true


# --- Query --- #

## Returns a specific request by ID, or empty dictionary if not found.
func get_request(request_id: String) -> Dictionary:
	if request_id in _requests:
		return _requests[request_id].duplicate()
	return {}


## Returns all pending lab requests.
func get_pending_requests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for req: Dictionary in _requests.values():
		if req.get("status", "") == "pending":
			result.append(req.duplicate())
	return result


## Returns all completed lab requests.
func get_completed_requests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for req: Dictionary in _requests.values():
		if req.get("status", "") == "completed":
			result.append(req.duplicate())
	return result


## Returns the number of pending requests.
func get_pending_count() -> int:
	var count: int = 0
	for req: Dictionary in _requests.values():
		if req.get("status", "") == "pending":
			count += 1
	return count


## Returns the total number of requests (all statuses).
func get_request_count() -> int:
	return _requests.size()


## Returns whether the given evidence is already submitted for analysis.
func is_evidence_submitted(evidence_id: String) -> bool:
	for req: Dictionary in _requests.values():
		if req.get("input_evidence_id", "") == evidence_id and req.get("status", "") == "pending":
			return true
	return false


## Returns the estimated completion day for a request, or -1 if not found.
func get_estimated_completion(request_id: String) -> int:
	if request_id in _requests:
		return _requests[request_id].get("completion_day", -1)
	return -1


## Returns whether the manager has any data (pending or completed).
func has_content() -> bool:
	return not _requests.is_empty()


# --- Debug --- #

## Completes all pending lab requests instantly. Returns completed requests.
func complete_all_instantly() -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	for request_id: String in _requests.keys():
		var req: Dictionary = _requests[request_id]
		if req.get("status", "") != "pending":
			continue
		req["status"] = "completed"
		_requests[request_id] = req
		var output_id: String = req.get("output_evidence_id", "")
		var input_id: String = req.get("input_evidence_id", "")
		if not output_id.is_empty():
			if not input_id.is_empty():
				GameManager.upgrade_evidence(input_id, output_id)
			else:
				GameManager.discover_evidence(output_id)
		completed.append(req.duplicate())
		lab_completed.emit(request_id, output_id)

	# Clear GameManager active list
	GameManager.active_lab_requests.clear()
	return completed


# --- Internal --- #

## Called when DaySystem completes a lab request.
func _on_lab_result_ready(lab_request_id: String, output_evidence_id: String) -> void:
	if lab_request_id in _requests:
		_requests[lab_request_id]["status"] = "completed"
		# Update the input evidence's lab_status to COMPLETED
		var input_id: String = _requests[lab_request_id].get("input_evidence_id", "")
		if not input_id.is_empty():
			var ev: EvidenceData = CaseManager.get_evidence(input_id)
			if ev:
				ev.lab_status = Enums.LabStatus.COMPLETED
		lab_completed.emit(lab_request_id, output_evidence_id)


## Removes a request from GameManager.active_lab_requests by ID.
func _remove_from_game_manager(request_id: String) -> void:
	var remaining: Array = []
	for req in GameManager.active_lab_requests:
		var r: Dictionary = req as Dictionary
		if r.get("id", "") != request_id:
			remaining.append(r)
	GameManager.active_lab_requests = remaining


# --- Serialization --- #

## Returns the lab manager state for saving.
func serialize() -> Dictionary:
	return {
		"requests": _requests.duplicate(true),
		"next_id": _next_id,
	}


## Restores lab manager state from saved data.
func deserialize(data: Dictionary) -> void:
	_requests = data.get("requests", {}).duplicate(true)
	_next_id = data.get("next_id", 1)


## Resets all lab manager state for a new game.
func reset() -> void:
	_requests.clear()
	_next_id = 1
