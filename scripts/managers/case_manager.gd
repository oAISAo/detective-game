## CaseManager.gd
## Manages case data loading from JSON and provides query functions
## for accessing evidence, persons, statements, events, and locations.
extends Node


# --- Signals --- #

## Emitted when a case is successfully loaded.
signal case_loaded(case_id: String)

## Emitted when case loading fails.
signal case_load_failed(error: String)


# --- State --- #

## The currently loaded case data (raw dictionary from JSON).
var _case_data: Dictionary = {}

## Evidence lookup: { evidence_id: Dictionary }
var _evidence: Dictionary = {}

## Person lookup: { person_id: Dictionary }
var _persons: Dictionary = {}

## Statement lookup: { statement_id: Dictionary }
var _statements: Dictionary = {}

## Event lookup: { event_id: Dictionary }
var _events: Dictionary = {}

## Location lookup: { location_id: Dictionary }
var _locations: Dictionary = {}

## Event trigger lookup: { trigger_id: Dictionary }
var _event_triggers: Dictionary = {}

## Whether a case is currently loaded.
var case_loaded_flag: bool = false


# --- Lifecycle --- #

func _ready() -> void:
	print("[CaseManager] Initialized.")


# --- Case Loading --- #

## Loads a case from a JSON file at the given path.
## Path should be relative to the data/cases directory, e.g. "case_01.json"
func load_case(case_filename: String) -> bool:
	var path: String = "res://data/cases/%s" % case_filename
	
	if not FileAccess.file_exists(path):
		var error_msg: String = "Case file not found: %s" % path
		push_error(error_msg)
		case_load_failed.emit(error_msg)
		return false
	
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var error_msg: String = "Failed to open case file: %s" % path
		push_error(error_msg)
		case_load_failed.emit(error_msg)
		return false
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_text)
	if parse_result != OK:
		var error_msg: String = "JSON parse error in %s at line %d: %s" % [
			path, json.get_error_line(), json.get_error_message()
		]
		push_error(error_msg)
		case_load_failed.emit(error_msg)
		return false
	
	_case_data = json.data
	_build_lookups()
	case_loaded_flag = true
	
	var case_id: String = _case_data.get("id", "unknown")
	case_loaded.emit(case_id)
	print("[CaseManager] Case loaded: %s" % case_id)
	return true


## Clears all loaded case data.
func unload_case() -> void:
	_case_data.clear()
	_evidence.clear()
	_persons.clear()
	_statements.clear()
	_events.clear()
	_locations.clear()
	_event_triggers.clear()
	case_loaded_flag = false
	print("[CaseManager] Case unloaded.")


## Builds internal lookup dictionaries from the raw case data.
func _build_lookups() -> void:
	_evidence.clear()
	_persons.clear()
	_statements.clear()
	_events.clear()
	_locations.clear()
	_event_triggers.clear()
	
	for item: Dictionary in _case_data.get("evidence", []):
		_evidence[item.get("id", "")] = item
	
	for item: Dictionary in _case_data.get("persons", []):
		_persons[item.get("id", "")] = item
	
	for item: Dictionary in _case_data.get("statements", []):
		_statements[item.get("id", "")] = item
	
	for item: Dictionary in _case_data.get("events", []):
		_events[item.get("id", "")] = item
	
	for item: Dictionary in _case_data.get("locations", []):
		_locations[item.get("id", "")] = item
	
	for item: Dictionary in _case_data.get("event_triggers", []):
		_event_triggers[item.get("id", "")] = item


# --- Query Functions --- #

## Returns the raw case data dictionary.
func get_case_data() -> Dictionary:
	return _case_data


## Returns evidence data by ID, or an empty dictionary if not found.
func get_evidence(evidence_id: String) -> Dictionary:
	return _evidence.get(evidence_id, {})


## Returns person data by ID, or an empty dictionary if not found.
func get_person(person_id: String) -> Dictionary:
	return _persons.get(person_id, {})


## Returns statement data by ID, or an empty dictionary if not found.
func get_statement(statement_id: String) -> Dictionary:
	return _statements.get(statement_id, {})


## Returns event data by ID, or an empty dictionary if not found.
func get_event(event_id: String) -> Dictionary:
	return _events.get(event_id, {})


## Returns location data by ID, or an empty dictionary if not found.
func get_location(location_id: String) -> Dictionary:
	return _locations.get(location_id, {})


## Returns event trigger data by ID, or an empty dictionary if not found.
func get_event_trigger(trigger_id: String) -> Dictionary:
	return _event_triggers.get(trigger_id, {})


## Returns all statements made by a specific person.
func get_statements_by_person(person_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for stmt: Dictionary in _statements.values():
		if stmt.get("person_id", "") == person_id:
			result.append(stmt)
	return result


## Returns all events that occur on a specific day.
func get_events_for_day(day: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for evt: Dictionary in _events.values():
		if evt.get("day", -1) == day:
			result.append(evt)
	return result


## Returns all evidence related to a specific person.
func get_evidence_for_person(person_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ev: Dictionary in _evidence.values():
		var related: Array = ev.get("related_persons", [])
		if person_id in related:
			result.append(ev)
	return result


## Returns all evidence found at a specific location.
func get_evidence_by_location(location_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ev: Dictionary in _evidence.values():
		if ev.get("location_found", "") == location_id:
			result.append(ev)
	return result


## Returns all event triggers of a specific type.
func get_triggers_by_type(trigger_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for trigger: Dictionary in _event_triggers.values():
		if trigger.get("trigger_type", "") == trigger_type:
			result.append(trigger)
	return result


## Returns all event triggers for a specific day.
func get_triggers_for_day(day: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for trigger: Dictionary in _event_triggers.values():
		if trigger.get("trigger_day", -1) == day:
			result.append(trigger)
	return result


## Returns all person IDs marked as suspects.
func get_suspects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for person: Dictionary in _persons.values():
		if person.get("role", "") == "SUSPECT":
			result.append(person)
	return result


## Returns all location data as an array.
func get_all_locations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.assign(_locations.values())
	return result


## Returns all evidence data as an array.
func get_all_evidence() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.assign(_evidence.values())
	return result
