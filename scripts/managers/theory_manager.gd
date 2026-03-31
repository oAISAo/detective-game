## TheoryManager.gd
## Manages crime theories as structured 5-step narratives.
## Phase 10: Pure data layer — no UI dependency.
extends Node


# --- Signals --- #

signal theory_created(theory_id: String)
signal theory_updated(theory_id: String)
signal theory_removed(theory_id: String)
signal theories_cleared
signal inconsistency_detected(theory_id: String, inconsistencies: Array)
signal state_loaded


# --- Constants --- #

## Maximum evidence items attachable per step.
const MAX_EVIDENCE_PER_STEP: int = 3

## The five narrative steps of a theory.
const STEP_NAMES: Array[String] = [
	"suspect", "motive", "time", "method", "timeline",
]


# --- State --- #

## All theories: { theory_id: Dictionary }
var _theories: Dictionary = {}

## Counter for generating unique theory IDs.
var _next_id: int = 1


# --- Lifecycle --- #

func _ready() -> void:
	print("[TheoryManager] Initialized.")


# --- Theory CRUD --- #

## Creates a new blank theory. Returns the theory data dictionary.
func create_theory(name: String) -> Dictionary:
	var theory_id: String = "theory_%d" % _next_id
	_next_id += 1

	var theory: Dictionary = _make_blank_theory(theory_id, name)
	_theories[theory_id] = theory
	theory_created.emit(theory_id)
	return theory


## Returns a blank theory structure.
func _make_blank_theory(theory_id: String, name: String) -> Dictionary:
	return {
		"id": theory_id,
		"name": name,
		"suspect_id": "",
		"suspect_evidence": [],
		"motive": "",
		"motive_evidence": [],
		"time_minutes": -1,
		"time_day": -1,
		"time_evidence": [],
		"method": "",
		"method_evidence": [],
		"timeline_entry_ids": [],
	}


## Removes a theory by ID.
func remove_theory(theory_id: String) -> bool:
	if theory_id not in _theories:
		push_warning("[TheoryManager] Theory not found: %s" % theory_id)
		return false

	_theories.erase(theory_id)
	theory_removed.emit(theory_id)
	return true


## Returns a specific theory, or empty dict if not found.
func get_theory(theory_id: String) -> Dictionary:
	return _theories.get(theory_id, {})


## Returns all theories as an array of dictionaries.
func get_all_theories() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for tid: String in _theories:
		result.append(_theories[tid])
	return result


## Returns the total number of theories.
func get_theory_count() -> int:
	return _theories.size()


# --- Step Setters --- #

## Sets the suspect for a theory.
func set_suspect(theory_id: String, suspect_id: String) -> bool:
	if theory_id not in _theories:
		push_warning("[TheoryManager] Theory not found: %s" % theory_id)
		return false
	_theories[theory_id]["suspect_id"] = suspect_id
	theory_updated.emit(theory_id)
	return true


## Sets the motive description for a theory.
func set_motive(theory_id: String, motive: String) -> bool:
	if theory_id not in _theories:
		push_warning("[TheoryManager] Theory not found: %s" % theory_id)
		return false
	_theories[theory_id]["motive"] = motive
	theory_updated.emit(theory_id)
	return true


## Sets the crime time for a theory.
func set_time(theory_id: String, time_minutes: int, day: int) -> bool:
	if theory_id not in _theories:
		push_warning("[TheoryManager] Theory not found: %s" % theory_id)
		return false
	_theories[theory_id]["time_minutes"] = time_minutes
	_theories[theory_id]["time_day"] = day
	theory_updated.emit(theory_id)
	return true


## Sets the method/weapon description for a theory.
func set_method(theory_id: String, method: String) -> bool:
	if theory_id not in _theories:
		push_warning("[TheoryManager] Theory not found: %s" % theory_id)
		return false
	_theories[theory_id]["method"] = method
	theory_updated.emit(theory_id)
	return true


## Sets timeline entry IDs (step 5 — links to TimelineManager entries).
func set_timeline_links(theory_id: String, entry_ids: Array[String]) -> bool:
	if theory_id not in _theories:
		push_warning("[TheoryManager] Theory not found: %s" % theory_id)
		return false
	_theories[theory_id]["timeline_entry_ids"] = entry_ids
	theory_updated.emit(theory_id)
	return true


# --- Evidence Attachment --- #

## Attaches evidence to a step. Returns true on success.
func attach_evidence(theory_id: String, step: String, evidence_id: String) -> bool:
	if theory_id not in _theories:
		push_warning("[TheoryManager] Theory not found: %s" % theory_id)
		return false
	var key: String = _step_evidence_key(step)
	if key.is_empty():
		push_error("[TheoryManager] Invalid step: %s" % step)
		return false

	var ev_list: Array = _theories[theory_id][key]
	if evidence_id in ev_list:
		return false
	if ev_list.size() >= MAX_EVIDENCE_PER_STEP:
		push_warning("[TheoryManager] Max evidence reached for step '%s'." % step)
		return false

	ev_list.append(evidence_id)
	theory_updated.emit(theory_id)
	return true


## Detaches evidence from a step. Returns true on success.
func detach_evidence(theory_id: String, step: String, evidence_id: String) -> bool:
	if theory_id not in _theories:
		push_warning("[TheoryManager] Theory not found: %s" % theory_id)
		return false
	var key: String = _step_evidence_key(step)
	if key.is_empty():
		push_error("[TheoryManager] Invalid step: %s" % step)
		return false

	var ev_list: Array = _theories[theory_id][key]
	var idx: int = ev_list.find(evidence_id)
	if idx < 0:
		return false

	ev_list.remove_at(idx)
	theory_updated.emit(theory_id)
	return true


## Returns the evidence key name for a step.
func _step_evidence_key(step: String) -> String:
	match step:
		"suspect": return "suspect_evidence"
		"motive": return "motive_evidence"
		"time": return "time_evidence"
		"method": return "method_evidence"
	return ""


## Returns evidence IDs attached to a step.
func get_step_evidence(theory_id: String, step: String) -> Array[String]:
	if theory_id not in _theories:
		return []
	var key: String = _step_evidence_key(step)
	if key.is_empty():
		return []
	var result: Array[String] = []
	for eid in _theories[theory_id][key]:
		result.append(eid as String)
	return result


# --- Analysis --- #

## Returns the strength of a specific step.
func get_step_strength(theory_id: String, step: String) -> Enums.TheoryStrength:
	var evidence: Array[String] = get_step_evidence(theory_id, step)
	if step == "timeline":
		var theory: Dictionary = get_theory(theory_id)
		var count: int = theory.get("timeline_entry_ids", []).size()
		return _count_to_strength(count)
	return _count_to_strength(evidence.size())


## Converts an evidence count to a strength enum.
func _count_to_strength(count: int) -> Enums.TheoryStrength:
	if count <= 0:
		return Enums.TheoryStrength.NONE
	elif count == 1:
		return Enums.TheoryStrength.WEAK
	elif count == 2:
		return Enums.TheoryStrength.MODERATE
	return Enums.TheoryStrength.STRONG


## Returns true if all 5 steps have content.
func is_complete(theory_id: String) -> bool:
	if theory_id not in _theories:
		return false
	var t: Dictionary = _theories[theory_id]
	if t["suspect_id"].is_empty():
		return false
	if t["motive"].is_empty():
		return false
	if t["time_minutes"] < 0 or t["time_day"] < 0:
		return false
	if t["method"].is_empty():
		return false
	if t["timeline_entry_ids"].is_empty():
		return false
	return true


## Returns timeline inconsistencies for a theory.
## Checks if the theory's suspect appears elsewhere at the claimed time.
func get_inconsistencies(theory_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if theory_id not in _theories:
		return result

	var t: Dictionary = _theories[theory_id]
	var suspect_id: String = t["suspect_id"]
	var theory_time: int = t["time_minutes"]
	var theory_day: int = t["time_day"]

	if suspect_id.is_empty() or theory_time < 0 or theory_day < 0:
		return result

	var tl_mgr: Node = get_node_or_null("/root/TimelineManager")
	if tl_mgr == null:
		return result

	var entries: Array[Dictionary] = tl_mgr.get_entries_for_day(theory_day)
	for entry: Dictionary in entries:
		if not _entry_conflicts(entry, suspect_id, theory_time):
			continue
		result.append({
			"type": "timeline_conflict",
			"entry_id": entry["id"],
			"description": _build_conflict_description(entry, suspect_id, theory_time),
		})

	var hypotheses: Array[Dictionary] = tl_mgr.get_all_hypotheses()
	for hyp: Dictionary in hypotheses:
		if hyp.get("day", -1) != theory_day:
			continue
		if not _hypothesis_conflicts(hyp, suspect_id, theory_time):
			continue
		result.append({
			"type": "timeline_conflict",
			"entry_id": hyp["id"],
			"description": _build_hyp_conflict_description(hyp, suspect_id),
		})

	if not result.is_empty():
		inconsistency_detected.emit(theory_id, result)

	return result


## Checks if a timeline entry conflicts with the theory.
func _entry_conflicts(entry: Dictionary, suspect_id: String, theory_time: int) -> bool:
	var event_id: String = entry.get("event_id", "")
	var event: EventData = CaseManager.get_event(event_id)
	if event == null:
		return false
	if suspect_id not in event.involved_persons:
		return false
	if entry.get("time_minutes", -1) != theory_time:
		return false
	return true


## Checks if a hypothesis conflicts with the theory.
func _hypothesis_conflicts(hyp: Dictionary, suspect_id: String, time: int) -> bool:
	if hyp.get("time_minutes", -1) != time:
		return false
	var persons: Array = hyp.get("involved_persons", [])
	return suspect_id in persons


## Builds a conflict description for a timeline entry.
func _build_conflict_description(entry: Dictionary, suspect_id: String, time: int) -> String:
	var event_id: String = entry.get("event_id", "")
	var event: EventData = CaseManager.get_event(event_id)
	var event_desc: String = event.description if event else event_id
	return "Suspect '%s' is placed at '%s' at time %d" % [suspect_id, event_desc, time]


## Builds a conflict description for a hypothesis.
func _build_hyp_conflict_description(hyp: Dictionary, suspect_id: String) -> String:
	return "Suspect '%s' appears in hypothesis: %s" % [suspect_id, hyp.get("description", "")]


# --- Housekeeping --- #

## Clears all theories.
func clear_theories() -> void:
	_theories.clear()
	_next_id = 1
	theories_cleared.emit()


## Returns true if at least one theory exists.
func has_content() -> bool:
	return not _theories.is_empty()


# --- Serialization --- #

## Returns the theory state as a dictionary for saving.
func serialize() -> Dictionary:
	var theories_array: Array[Dictionary] = []
	for tid: String in _theories:
		theories_array.append(_theories[tid].duplicate(true))

	return {
		"theories": theories_array,
		"next_id": _next_id,
	}


## Restores theory state from a saved dictionary.
func deserialize(data: Dictionary) -> void:
	clear_theories()
	var theories_array: Array = data.get("theories", [])
	for td in theories_array:
		var theory: Dictionary = td as Dictionary
		var tid: String = theory.get("id", "")
		if not tid.is_empty():
			_theories[tid] = theory

	_next_id = data.get("next_id", _theories.size() + 1)
	state_loaded.emit()


## Resets all theory state for a new game.
func reset() -> void:
	clear_theories()
