## CaseManager.gd
## Manages case data loading from JSON and provides typed query functions
## for accessing evidence, persons, statements, events, and locations.
## Phase 1: Upgraded from raw dictionaries to typed Resource objects.
extends Node


# --- Signals --- #

## Emitted when a case is successfully loaded.
signal case_loaded(case_id: String)

## Emitted when case loading fails.
signal case_load_failed(error: String)

## Emitted when case validation produces warnings.
signal case_validation_warnings(warnings: Array[String])


# --- State --- #

## The currently loaded case as a typed CaseData resource.
var _case: CaseData = null

## Evidence lookup: { evidence_id: EvidenceData }
var _evidence: Dictionary = {}

## Person lookup: { person_id: PersonData }
var _persons: Dictionary = {}

## Statement lookup: { statement_id: StatementData }
var _statements: Dictionary = {}

## Event lookup: { event_id: EventData }
var _events: Dictionary = {}

## Location lookup: { location_id: LocationData }
var _locations: Dictionary = {}

## Event trigger lookup: { trigger_id: EventTriggerData }
var _event_triggers: Dictionary = {}

## Interrogation topic lookup: { topic_id: InterrogationTopicData }
var _interrogation_topics: Dictionary = {}

## Interrogation trigger lookup: { trigger_id: InterrogationTriggerData }
var _interrogation_triggers: Dictionary = {}

## Action lookup: { action_id: ActionData }
var _actions: Dictionary = {}

## Insight lookup: { insight_id: InsightData }
var _insights: Dictionary = {}

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

	# Convert raw JSON dictionary to typed CaseData resource
	_case = CaseData.from_dict(json.data)

	# Validate the case data
	var validation_errors: Array[String] = _case.validate()
	if not validation_errors.is_empty():
		for err: String in validation_errors:
			push_warning("[CaseManager] Validation: %s" % err)
		case_validation_warnings.emit(validation_errors)

	# Build fast-access lookup dictionaries
	_build_lookups()
	case_loaded_flag = true

	case_loaded.emit(_case.id)
	print("[CaseManager] Case loaded: %s" % _case.id)
	return true


## Clears all loaded case data.
func unload_case() -> void:
	_case = null
	_evidence.clear()
	_persons.clear()
	_statements.clear()
	_events.clear()
	_locations.clear()
	_event_triggers.clear()
	_interrogation_topics.clear()
	_interrogation_triggers.clear()
	_actions.clear()
	_insights.clear()
	case_loaded_flag = false
	print("[CaseManager] Case unloaded.")


## Builds internal lookup dictionaries from the typed CaseData resource.
func _build_lookups() -> void:
	_evidence.clear()
	_persons.clear()
	_statements.clear()
	_events.clear()
	_locations.clear()
	_event_triggers.clear()
	_interrogation_topics.clear()
	_interrogation_triggers.clear()
	_actions.clear()
	_insights.clear()

	if _case == null:
		return

	for item: EvidenceData in _case.evidence:
		_evidence[item.id] = item

	for item: PersonData in _case.persons:
		_persons[item.id] = item

	for item: StatementData in _case.statements:
		_statements[item.id] = item

	for item: EventData in _case.events:
		_events[item.id] = item

	for item: LocationData in _case.locations:
		_locations[item.id] = item

	for item: EventTriggerData in _case.event_triggers:
		_event_triggers[item.id] = item

	for item: InterrogationTopicData in _case.interrogation_topics:
		_interrogation_topics[item.id] = item

	for item: InterrogationTriggerData in _case.interrogation_triggers:
		_interrogation_triggers[item.id] = item

	for item: ActionData in _case.actions:
		_actions[item.id] = item

	for item: InsightData in _case.insights:
		_insights[item.id] = item


# --- Query Functions: Single Item --- #

## Returns the typed CaseData resource, or null if no case is loaded.
func get_case_data() -> CaseData:
	return _case

## Returns evidence data by ID, or null if not found.
func get_evidence(evidence_id: String) -> EvidenceData:
	return _evidence.get(evidence_id, null)

## Returns person data by ID, or null if not found.
func get_person(person_id: String) -> PersonData:
	return _persons.get(person_id, null)

## Returns statement data by ID, or null if not found.
func get_statement(statement_id: String) -> StatementData:
	return _statements.get(statement_id, null)

## Returns event data by ID, or null if not found.
func get_event(event_id: String) -> EventData:
	return _events.get(event_id, null)

## Returns location data by ID, or null if not found.
func get_location(location_id: String) -> LocationData:
	return _locations.get(location_id, null)

## Returns event trigger data by ID, or null if not found.
func get_event_trigger(trigger_id: String) -> EventTriggerData:
	return _event_triggers.get(trigger_id, null)

## Returns interrogation topic data by ID, or null if not found.
func get_interrogation_topic(topic_id: String) -> InterrogationTopicData:
	return _interrogation_topics.get(topic_id, null)

## Returns interrogation trigger data by ID, or null if not found.
func get_interrogation_trigger(trigger_id: String) -> InterrogationTriggerData:
	return _interrogation_triggers.get(trigger_id, null)

## Returns action data by ID, or null if not found.
func get_action(action_id: String) -> ActionData:
	return _actions.get(action_id, null)

## Returns insight data by ID, or null if not found.
func get_insight(insight_id: String) -> InsightData:
	return _insights.get(insight_id, null)


# --- Query Functions: Filtered Lists --- #

## Returns all statements made by a specific person.
func get_statements_by_person(person_id: String) -> Array[StatementData]:
	var result: Array[StatementData] = []
	for stmt: StatementData in _statements.values():
		if stmt.person_id == person_id:
			result.append(stmt)
	return result


## Returns all events that occur on a specific day.
func get_events_for_day(day: int) -> Array[EventData]:
	var result: Array[EventData] = []
	for evt: EventData in _events.values():
		if evt.day == day:
			result.append(evt)
	return result


## Returns all evidence related to a specific person.
func get_evidence_for_person(person_id: String) -> Array[EvidenceData]:
	var result: Array[EvidenceData] = []
	for ev: EvidenceData in _evidence.values():
		if person_id in ev.related_persons:
			result.append(ev)
	return result


## Returns all evidence found at a specific location.
func get_evidence_by_location(location_id: String) -> Array[EvidenceData]:
	var result: Array[EvidenceData] = []
	for ev: EvidenceData in _evidence.values():
		if ev.location_found == location_id:
			result.append(ev)
	return result


## Returns all event triggers of a specific type.
func get_triggers_by_type(trigger_type_str: String) -> Array[EventTriggerData]:
	var target: int = EnumHelper.parse_enum(Enums.TriggerType, trigger_type_str)
	var result: Array[EventTriggerData] = []
	for trigger: EventTriggerData in _event_triggers.values():
		if trigger.trigger_type == target:
			result.append(trigger)
	return result


## Returns all event triggers for a specific day.
func get_triggers_for_day(day: int) -> Array[EventTriggerData]:
	var result: Array[EventTriggerData] = []
	for trigger: EventTriggerData in _event_triggers.values():
		if trigger.trigger_day == day:
			result.append(trigger)
	return result


## Returns all persons marked as suspects.
func get_suspects() -> Array[PersonData]:
	var result: Array[PersonData] = []
	for person: PersonData in _persons.values():
		if person.role == Enums.PersonRole.SUSPECT:
			result.append(person)
	return result


## Returns all interrogation topics for a specific person.
func get_topics_for_person(person_id: String) -> Array[InterrogationTopicData]:
	var result: Array[InterrogationTopicData] = []
	for topic: InterrogationTopicData in _interrogation_topics.values():
		if topic.person_id == person_id:
			result.append(topic)
	return result


## Returns all interrogation triggers for a specific person.
func get_interrogation_triggers_for_person(person_id: String) -> Array[InterrogationTriggerData]:
	var result: Array[InterrogationTriggerData] = []
	for trigger: InterrogationTriggerData in _interrogation_triggers.values():
		if trigger.person_id == person_id:
			result.append(trigger)
	return result


## Returns the interrogation trigger for a specific person and evidence combination.
## Returns null if no matching trigger exists.
func get_trigger_by_evidence(person_id: String, evidence_id: String) -> InterrogationTriggerData:
	for trigger: InterrogationTriggerData in _interrogation_triggers.values():
		if trigger.person_id == person_id and trigger.evidence_id == evidence_id:
			return trigger
	return null


## Returns all actions of a specific type.
func get_actions_by_type(action_type: Enums.ActionType) -> Array[ActionData]:
	var result: Array[ActionData] = []
	for action: ActionData in _actions.values():
		if action.type == action_type:
			result.append(action)
	return result


# --- Query Functions: Full Collections --- #

## Returns all location data as an array.
func get_all_locations() -> Array[LocationData]:
	var result: Array[LocationData] = []
	for loc in _locations.values():
		result.append(loc)
	return result

## Returns all evidence data as an array.
func get_all_evidence() -> Array[EvidenceData]:
	var result: Array[EvidenceData] = []
	for ev in _evidence.values():
		result.append(ev)
	return result

## Returns all person data as an array.
func get_all_persons() -> Array[PersonData]:
	var result: Array[PersonData] = []
	for p in _persons.values():
		result.append(p)
	return result

## Returns all statement data as an array.
func get_all_statements() -> Array[StatementData]:
	var result: Array[StatementData] = []
	for s in _statements.values():
		result.append(s)
	return result

## Returns all event data as an array.
func get_all_events() -> Array[EventData]:
	var result: Array[EventData] = []
	for e in _events.values():
		result.append(e)
	return result

## Returns all action data as an array.
func get_all_actions() -> Array[ActionData]:
	var result: Array[ActionData] = []
	for a in _actions.values():
		result.append(a)
	return result

## Returns all insight data as an array.
func get_all_insights() -> Array[InsightData]:
	var result: Array[InsightData] = []
	for i in _insights.values():
		result.append(i)
	return result

## Returns all interrogation trigger data as an array.
func get_all_interrogation_triggers() -> Array[InterrogationTriggerData]:
	var result: Array[InterrogationTriggerData] = []
	for t in _interrogation_triggers.values():
		result.append(t)
	return result
