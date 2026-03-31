## TimelineManager.gd
## Manages the timeline reconstruction: placed events, hypotheses,
## overlap detection, and evidence attachment.
## Phase 9: Pure data layer — no UI dependency.
extends Node


# --- Signals --- #

signal entry_placed(entry: Dictionary)
signal entry_removed(entry_id: String)
signal entry_moved(entry_id: String, new_time: int)
signal hypothesis_added(hypothesis: Dictionary)
signal hypothesis_removed(hypothesis_id: String)
signal hypothesis_updated(hypothesis_id: String)
signal overlap_detected(overlap: Dictionary)
signal timeline_cleared
signal state_loaded


# --- Constants --- #

## Snaps all times to the nearest N minutes.
const SNAP_MINUTES: int = 5

## Minimum time in minutes (6:00 AM = 360).
const MIN_TIME: int = 0

## Maximum time in minutes (23:55 PM = 1435).
const MAX_TIME: int = 1435


# --- State --- #

## Placed timeline entries: { entry_id: {id, event_id, time_minutes, day} }
var _entries: Dictionary = {}

## Player hypothesis events: { hyp_id: {id, description, time_minutes, day, location, involved_persons, attached_evidence} }
var _hypotheses: Dictionary = {}

## Extra evidence attached to placed entries: { entry_id: [evidence_ids] }
var _attached_evidence: Dictionary = {}

## Counter for generating unique entry IDs.
var _next_entry_id: int = 1

## Counter for generating unique hypothesis IDs.
var _next_hypothesis_id: int = 1


# --- Lifecycle --- #

func _ready() -> void:
	print("[TimelineManager] Initialized.")


# --- Time Utilities --- #

## Snaps a time in minutes to the nearest SNAP_MINUTES increment.
static func snap_time(minutes: int) -> int:
	var remainder: int = minutes % SNAP_MINUTES
	if remainder >= SNAP_MINUTES / 2.0:
		return clampi(minutes + SNAP_MINUTES - remainder, MIN_TIME, MAX_TIME)
	return clampi(minutes - remainder, MIN_TIME, MAX_TIME)


## Parses a time string like "20:15" into minutes from midnight (1215).
static func parse_time_string(time_str: String) -> int:
	if time_str.is_empty():
		return 0
	var parts: PackedStringArray = time_str.split(":")
	if parts.size() < 2:
		return 0
	return int(parts[0]) * 60 + int(parts[1])


## Formats minutes from midnight into "HH:MM" string.
static func format_time(minutes: int) -> String:
	var h: int = minutes / 60
	var m: int = minutes % 60
	return "%02d:%02d" % [h, m]


# --- Entry Management --- #

## Places a case event on the timeline. Returns the entry dictionary.
func place_event(event_id: String, time_minutes: int, day: int) -> Dictionary:
	var event: EventData = CaseManager.get_event(event_id)
	if event == null:
		push_error("[TimelineManager] Event not found: %s" % event_id)
		return {}

	var snapped: int = snap_time(time_minutes)
	var entry_id: String = "tl_%d" % _next_entry_id
	_next_entry_id += 1

	var entry: Dictionary = {
		"id": entry_id,
		"event_id": event_id,
		"time_minutes": snapped,
		"day": day,
	}

	_entries[entry_id] = entry
	entry_placed.emit(entry)
	_check_overlaps_for_day(day)
	return entry


## Removes a placed entry from the timeline.
func remove_entry(entry_id: String) -> bool:
	if entry_id not in _entries:
		push_warning("[TimelineManager] Entry not found: %s" % entry_id)
		return false

	var day: int = _entries[entry_id]["day"]
	_entries.erase(entry_id)
	_attached_evidence.erase(entry_id)
	entry_removed.emit(entry_id)
	_check_overlaps_for_day(day)
	return true


## Moves a placed entry to a new time (snapped). Returns true on success.
func move_entry(entry_id: String, new_time_minutes: int) -> bool:
	if entry_id not in _entries:
		push_warning("[TimelineManager] Entry not found: %s" % entry_id)
		return false

	var snapped: int = snap_time(new_time_minutes)
	_entries[entry_id]["time_minutes"] = snapped
	entry_moved.emit(entry_id, snapped)
	_check_overlaps_for_day(_entries[entry_id]["day"])
	return true


## Returns a specific entry, or empty dictionary if not found.
func get_entry(entry_id: String) -> Dictionary:
	return _entries.get(entry_id, {})


## Returns all placed entries as an array.
func get_all_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for eid: String in _entries:
		result.append(_entries[eid])
	return result


## Returns all placed entries for a specific day.
func get_entries_for_day(day: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for eid: String in _entries:
		if _entries[eid]["day"] == day:
			result.append(_entries[eid])
	return result


## Returns the total number of placed entries.
func get_entry_count() -> int:
	return _entries.size()


# --- Hypothesis Management --- #

## Creates a player hypothesis event. Returns the hypothesis dictionary.
func add_hypothesis(description: String, time_minutes: int, day: int,
		location: String = "", involved_persons: Array[String] = []) -> Dictionary:
	var snapped: int = snap_time(time_minutes)
	var hyp_id: String = "hyp_%d" % _next_hypothesis_id
	_next_hypothesis_id += 1

	var hypothesis: Dictionary = {
		"id": hyp_id,
		"description": description,
		"time_minutes": snapped,
		"day": day,
		"location": location,
		"involved_persons": involved_persons.duplicate(),
		"attached_evidence": [] as Array[String],
	}

	_hypotheses[hyp_id] = hypothesis
	hypothesis_added.emit(hypothesis)
	_check_overlaps_for_day(day)
	return hypothesis


## Updates a hypothesis event.
func update_hypothesis(hyp_id: String, description: String, time_minutes: int,
		day: int, location: String = "", involved_persons: Array[String] = []) -> bool:
	if hyp_id not in _hypotheses:
		push_warning("[TimelineManager] Hypothesis not found: %s" % hyp_id)
		return false

	var snapped: int = snap_time(time_minutes)
	_hypotheses[hyp_id]["description"] = description
	_hypotheses[hyp_id]["time_minutes"] = snapped
	_hypotheses[hyp_id]["day"] = day
	_hypotheses[hyp_id]["location"] = location
	_hypotheses[hyp_id]["involved_persons"] = involved_persons.duplicate()
	hypothesis_updated.emit(hyp_id)
	_check_overlaps_for_day(day)
	return true


## Removes a hypothesis event.
func remove_hypothesis(hyp_id: String) -> bool:
	if hyp_id not in _hypotheses:
		push_warning("[TimelineManager] Hypothesis not found: %s" % hyp_id)
		return false

	var day: int = _hypotheses[hyp_id]["day"]
	_hypotheses.erase(hyp_id)
	hypothesis_removed.emit(hyp_id)
	_check_overlaps_for_day(day)
	return true


## Returns a specific hypothesis, or empty dictionary.
func get_hypothesis(hyp_id: String) -> Dictionary:
	return _hypotheses.get(hyp_id, {})


## Returns all hypotheses as an array.
func get_all_hypotheses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for hid: String in _hypotheses:
		result.append(_hypotheses[hid])
	return result


## Returns the total number of hypotheses.
func get_hypothesis_count() -> int:
	return _hypotheses.size()


# --- Evidence Attachment --- #

## Attaches evidence to a placed entry. Returns true on success.
func attach_evidence(entry_id: String, evidence_id: String) -> bool:
	if entry_id not in _entries:
		push_warning("[TimelineManager] Entry not found: %s" % entry_id)
		return false

	if entry_id not in _attached_evidence:
		_attached_evidence[entry_id] = [] as Array[String]

	var list: Array = _attached_evidence[entry_id]
	if evidence_id in list:
		return false  # already attached

	list.append(evidence_id)
	return true


## Detaches evidence from a placed entry. Returns true on success.
func detach_evidence(entry_id: String, evidence_id: String) -> bool:
	if entry_id not in _attached_evidence:
		return false

	var list: Array = _attached_evidence[entry_id]
	var idx: int = list.find(evidence_id)
	if idx < 0:
		return false

	list.remove_at(idx)
	return true


## Returns evidence attached to an entry.
func get_attached_evidence(entry_id: String) -> Array[String]:
	if entry_id not in _attached_evidence:
		return [] as Array[String]
	var result: Array[String] = []
	result.assign(_attached_evidence[entry_id])
	return result


# --- Overlap Detection --- #

## Returns all overlaps for a given day. An overlap occurs when the same
## person appears at two different locations at the same time.
func get_overlaps(day: int) -> Array[Dictionary]:
	var overlaps: Array[Dictionary] = []
	var time_person_map: Dictionary = {}  # { "person_id:time" : [{location, source_id, source_type}] }

	_collect_entries_into_map(day, time_person_map)
	_collect_hypotheses_into_map(day, time_person_map)

	for key: String in time_person_map:
		var entries_at: Array = time_person_map[key]
		if entries_at.size() < 2:
			continue
		# Check if different locations involved
		var locations: Array[String] = []
		for e: Dictionary in entries_at:
			if e["location"] not in locations and not e["location"].is_empty():
				locations.append(e["location"])
		if locations.size() >= 2:
			var parts: PackedStringArray = key.split(":")
			overlaps.append({
				"person_id": parts[0],
				"time_minutes": int(parts[1]),
				"locations": locations,
			})
	return overlaps


## Collects placed entries into the time-person map for overlap detection.
func _collect_entries_into_map(day: int, map: Dictionary) -> void:
	for eid: String in _entries:
		var entry: Dictionary = _entries[eid]
		if entry["day"] != day:
			continue
		var event: EventData = CaseManager.get_event(entry["event_id"])
		if event == null:
			continue
		for person_id: String in event.involved_persons:
			var key: String = "%s:%d" % [person_id, entry["time_minutes"]]
			if key not in map:
				map[key] = []
			map[key].append({"location": event.location, "source_id": eid, "source_type": "entry"})


## Collects hypotheses into the time-person map for overlap detection.
func _collect_hypotheses_into_map(day: int, map: Dictionary) -> void:
	for hid: String in _hypotheses:
		var hyp: Dictionary = _hypotheses[hid]
		if hyp["day"] != day:
			continue
		for person_id: String in hyp["involved_persons"]:
			var key: String = "%s:%d" % [person_id, hyp["time_minutes"]]
			if key not in map:
				map[key] = []
			map[key].append({"location": hyp["location"], "source_id": hid, "source_type": "hypothesis"})


## Checks overlaps for a day and emits signals for any found.
func _check_overlaps_for_day(day: int) -> void:
	var overlaps: Array[Dictionary] = get_overlaps(day)
	for overlap: Dictionary in overlaps:
		overlap_detected.emit(overlap)


# --- Board State --- #

## Returns true if the timeline has any content.
func has_content() -> bool:
	return not _entries.is_empty() or not _hypotheses.is_empty()


## Clears all timeline data.
func clear_timeline() -> void:
	_entries.clear()
	_hypotheses.clear()
	_attached_evidence.clear()
	_next_entry_id = 1
	_next_hypothesis_id = 1
	timeline_cleared.emit()


# --- Serialization --- #

## Returns the timeline state as a dictionary for saving.
func serialize() -> Dictionary:
	var entries_arr: Array[Dictionary] = []
	for eid: String in _entries:
		entries_arr.append(_entries[eid].duplicate())

	var hyp_arr: Array[Dictionary] = []
	for hid: String in _hypotheses:
		hyp_arr.append(_hypotheses[hid].duplicate())

	var attached_arr: Dictionary = {}
	for eid: String in _attached_evidence:
		attached_arr[eid] = (_attached_evidence[eid] as Array).duplicate()

	return {
		"entries": entries_arr,
		"hypotheses": hyp_arr,
		"attached_evidence": attached_arr,
		"next_entry_id": _next_entry_id,
		"next_hypothesis_id": _next_hypothesis_id,
	}


## Restores the timeline state from a saved dictionary.
func deserialize(data: Dictionary) -> void:
	clear_timeline()

	for entry_dict: Dictionary in data.get("entries", []):
		var eid: String = entry_dict.get("id", "")
		if not eid.is_empty():
			_entries[eid] = entry_dict

	for hyp_dict: Dictionary in data.get("hypotheses", []):
		var hid: String = hyp_dict.get("id", "")
		if not hid.is_empty():
			_hypotheses[hid] = hyp_dict

	var att: Dictionary = data.get("attached_evidence", {})
	for key: String in att:
		_attached_evidence[key] = att[key]

	_next_entry_id = data.get("next_entry_id", _entries.size() + 1)
	_next_hypothesis_id = data.get("next_hypothesis_id", _hypotheses.size() + 1)
	state_loaded.emit()


## Resets all timeline state for a new game.
func reset() -> void:
	clear_timeline()
