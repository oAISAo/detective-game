## test_case_manager.gd
## Unit tests for the CaseManager autoload singleton.
## Phase 1: Verify JSON → typed Resource loading and all query functions.
extends GutTest


## Path to a test case JSON file.
const TEST_CASE_FILE: String = "test_case.json"

## Comprehensive test case data covering all resource types.
var _test_case_data: Dictionary = {
	"id": "case_test_01",
	"title": "Test Case",
	"description": "A test case for unit testing.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{
			"id": "p_victim",
			"name": "Daniel Whitfield",
			"role": "VICTIM",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 0,
		},
		{
			"id": "p_julia",
			"name": "Julia Ross",
			"role": "SUSPECT",
			"personality_traits": ["MANIPULATIVE", "CALM"],
			"relationships": [{"person_b": "p_victim", "type": "SPOUSE"}],
			"pressure_threshold": 5,
		},
		{
			"id": "p_mark",
			"name": "Mark Bennett",
			"role": "SUSPECT",
			"personality_traits": ["ANXIOUS"],
			"relationships": [{"person_b": "p_victim", "type": "COWORKER"}],
			"pressure_threshold": 3,
		},
	],
	"evidence": [
		{
			"id": "ev_fingerprint",
			"name": "Fingerprint on Wine Glass",
			"description": "A fingerprint found on a wine glass at the crime scene.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": ["p_julia"],
			"weight": 0.8,
			"importance_level": "CRITICAL",
		},
		{
			"id": "ev_camera",
			"name": "Parking Camera Footage",
			"description": "Security camera footage from the parking lot.",
			"type": "RECORDING",
			"location_found": "loc_parking",
			"related_persons": ["p_mark"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_document",
			"name": "Financial Records",
			"description": "Records showing irregular transactions.",
			"type": "FINANCIAL",
			"location_found": "loc_office",
			"related_persons": ["p_mark", "p_victim"],
			"weight": 0.7,
			"importance_level": "CRITICAL",
		},
	],
	"statements": [
		{
			"id": "s_julia_01",
			"person_id": "p_julia",
			"text": "I was home all evening.",
			"day_given": 1,
			"related_evidence": [],
		},
		{
			"id": "s_mark_01",
			"person_id": "p_mark",
			"text": "I left the office at 19:30.",
			"day_given": 1,
			"related_evidence": ["ev_camera"],
		},
	],
	"events": [
		{
			"id": "evt_argument",
			"description": "Loud argument heard from apartment",
			"time": "20:15",
			"day": 1,
			"location": "loc_apartment",
			"involved_persons": ["p_victim"],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_elevator",
			"description": "Julia enters building via elevator",
			"time": "20:32",
			"day": 1,
			"location": "loc_hallway",
			"involved_persons": ["p_julia"],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_morning_briefing",
			"description": "Day 2 morning briefing",
			"time": "08:00",
			"day": 2,
			"location": "",
			"involved_persons": [],
			"certainty_level": "CONFIRMED",
		},
	],
	"locations": [
		{
			"id": "loc_apartment",
			"name": "Victim's Apartment",
			"searchable": true,
			"evidence_pool": ["ev_fingerprint"],
		},
		{
			"id": "loc_parking",
			"name": "Parking Lot",
			"searchable": true,
			"evidence_pool": ["ev_camera"],
		},
		{
			"id": "loc_office",
			"name": "Victim's Office",
			"searchable": true,
			"evidence_pool": ["ev_document"],
		},
	],
	"event_triggers": [
		{
			"id": "trigger_day2_briefing",
			"trigger_type": "DAY_START",
			"trigger_day": 2,
			"conditions": [],
			"actions": ["show_morning_briefing"],
			"result_events": ["evt_morning_briefing"],
		},
		{
			"id": "trigger_financial_reveal",
			"trigger_type": "CONDITIONAL",
			"trigger_day": -1,
			"conditions": ["evidence_discovered:ev_document"],
			"actions": ["unlock_event"],
			"result_events": [],
		},
	],
	"interrogation_topics": [
		{
			"id": "topic_julia_alibi",
			"person_id": "p_julia",
			"topic_name": "Evening alibi",
			"trigger_conditions": [],
			"required_evidence": ["ev_camera"],
			"impact_level": "MAJOR",
		},
	],
	"actions": [
		{
			"id": "act_interrogate_julia",
			"name": "Interrogate Julia",
			"type": "INTERROGATION",
			"time_cost": 1,
			"target": "p_julia",
		},
	],
	"insights": [
		{
			"id": "insight_alibi_lie",
			"description": "Julia lied about being home",
			"source_evidence": ["ev_camera", "s_julia_01"],
			"unlocks_topic": "topic_julia_alibi",
		},
	],
}


# --- Setup / Teardown --- #

func before_all() -> void:
	# Write test case JSON to disk
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	var dir: DirAccess = DirAccess.open("res://data/cases")
	if dir == null:
		DirAccess.make_dir_recursive_absolute("res://data/cases")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_test_case_data, "\t"))
	file.close()


func before_each() -> void:
	CaseManager.unload_case()


func after_all() -> void:
	# Clean up test case file
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


# --- Case Loading --- #

func test_load_case_succeeds() -> void:
	var result: bool = CaseManager.load_case(TEST_CASE_FILE)
	assert_true(result, "Should load test case successfully")
	assert_true(CaseManager.case_loaded_flag, "case_loaded_flag should be true")


func test_load_case_emits_signal() -> void:
	watch_signals(CaseManager)
	CaseManager.load_case(TEST_CASE_FILE)
	assert_signal_emitted_with_parameters(CaseManager, "case_loaded", ["case_test_01"])


func test_load_nonexistent_case_fails() -> void:
	var result: bool = CaseManager.load_case("nonexistent.json")
	assert_false(result, "Should fail for nonexistent file")
	assert_false(CaseManager.case_loaded_flag)
	assert_push_error("Case file not found")


func test_unload_case_clears_data() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	CaseManager.unload_case()
	assert_false(CaseManager.case_loaded_flag)
	assert_null(CaseManager.get_evidence("ev_fingerprint"), "Should return null after unload")


func test_get_case_data_returns_typed_resource() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var case_data: CaseData = CaseManager.get_case_data()
	assert_not_null(case_data)
	assert_eq(case_data.id, "case_test_01")
	assert_eq(case_data.title, "Test Case")
	assert_eq(case_data.start_day, 1)
	assert_eq(case_data.end_day, 4)


# --- Query: Evidence (typed returns) --- #

func test_get_evidence_returns_typed_resource() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var ev: EvidenceData = CaseManager.get_evidence("ev_fingerprint")
	assert_not_null(ev)
	assert_eq(ev.name, "Fingerprint on Wine Glass")
	assert_eq(ev.type, Enums.EvidenceType.FORENSIC)
	assert_eq(ev.location_found, "loc_apartment")
	assert_almost_eq(ev.weight, 0.8, 0.001)
	assert_eq(ev.importance_level, Enums.ImportanceLevel.CRITICAL)


func test_get_evidence_returns_null_for_invalid_id() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var ev: EvidenceData = CaseManager.get_evidence("ev_nonexistent")
	assert_null(ev, "Should return null for invalid ID")


# --- Query: Person (typed returns) --- #

func test_get_person_returns_typed_resource() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var person: PersonData = CaseManager.get_person("p_julia")
	assert_not_null(person)
	assert_eq(person.name, "Julia Ross")
	assert_eq(person.role, Enums.PersonRole.SUSPECT)
	assert_eq(person.personality_traits.size(), 2)
	assert_eq(person.relationships.size(), 1)
	assert_eq(person.pressure_threshold, 5)


func test_get_person_returns_null_for_invalid_id() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	assert_null(CaseManager.get_person("p_nonexistent"))


func test_person_relationships_are_typed() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var person: PersonData = CaseManager.get_person("p_julia")
	var rel: RelationshipData = person.relationships[0]
	assert_eq(rel.person_a, "p_julia")
	assert_eq(rel.person_b, "p_victim")
	assert_eq(rel.type, Enums.RelationshipType.SPOUSE)


# --- Query: Statements by Person (typed returns) --- #

func test_get_statements_by_person() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var stmts: Array[StatementData] = CaseManager.get_statements_by_person("p_mark")
	assert_eq(stmts.size(), 1)
	assert_eq(stmts[0].id, "s_mark_01")
	assert_eq(stmts[0].text, "I left the office at 19:30.")


func test_get_statements_by_person_returns_empty_for_unknown() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var stmts: Array[StatementData] = CaseManager.get_statements_by_person("p_unknown")
	assert_eq(stmts.size(), 0)


# --- Query: Events by Day (typed returns) --- #

func test_get_events_for_day() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var day1_events: Array[EventData] = CaseManager.get_events_for_day(1)
	assert_eq(day1_events.size(), 2, "Day 1 should have 2 events")

	var day2_events: Array[EventData] = CaseManager.get_events_for_day(2)
	assert_eq(day2_events.size(), 1, "Day 2 should have 1 event")


func test_get_events_for_empty_day() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var day3_events: Array[EventData] = CaseManager.get_events_for_day(3)
	assert_eq(day3_events.size(), 0, "Day 3 should have no events")


# --- Query: Evidence by Person (typed returns) --- #

func test_get_evidence_for_person() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var julia_evidence: Array[EvidenceData] = CaseManager.get_evidence_for_person("p_julia")
	assert_eq(julia_evidence.size(), 1)
	assert_eq(julia_evidence[0].id, "ev_fingerprint")


func test_get_evidence_for_person_multiple() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var mark_evidence: Array[EvidenceData] = CaseManager.get_evidence_for_person("p_mark")
	assert_eq(mark_evidence.size(), 2, "Mark should be related to camera and financial records")


# --- Query: Evidence by Location (typed returns) --- #

func test_get_evidence_by_location() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var apt_evidence: Array[EvidenceData] = CaseManager.get_evidence_by_location("loc_apartment")
	assert_eq(apt_evidence.size(), 1)
	assert_eq(apt_evidence[0].id, "ev_fingerprint")


func test_get_evidence_by_location_returns_empty_for_unknown() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var result: Array[EvidenceData] = CaseManager.get_evidence_by_location("loc_unknown")
	assert_eq(result.size(), 0)


# --- Query: Suspects (typed returns) --- #

func test_get_suspects() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var suspects: Array[PersonData] = CaseManager.get_suspects()
	assert_eq(suspects.size(), 2, "Should have 2 suspects")


# --- Query: Event Triggers (typed returns) --- #

func test_get_triggers_by_type() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var day_start_triggers: Array[EventTriggerData] = CaseManager.get_triggers_by_type("DAY_START")
	assert_eq(day_start_triggers.size(), 1)

	var conditional_triggers: Array[EventTriggerData] = CaseManager.get_triggers_by_type("CONDITIONAL")
	assert_eq(conditional_triggers.size(), 1)


func test_get_triggers_for_day() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var day2_triggers: Array[EventTriggerData] = CaseManager.get_triggers_for_day(2)
	assert_eq(day2_triggers.size(), 1)
	assert_eq(day2_triggers[0].id, "trigger_day2_briefing")


# --- Query: New Phase 1 query functions --- #

func test_get_interrogation_topic() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var topic: InterrogationTopicData = CaseManager.get_interrogation_topic("topic_julia_alibi")
	assert_not_null(topic)
	assert_eq(topic.person_id, "p_julia")
	assert_eq(topic.topic_name, "Evening alibi")
	assert_eq(topic.impact_level, Enums.ImpactLevel.MAJOR)


func test_get_topics_for_person() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var topics: Array[InterrogationTopicData] = CaseManager.get_topics_for_person("p_julia")
	assert_eq(topics.size(), 1)


func test_get_action() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var action: ActionData = CaseManager.get_action("act_interrogate_julia")
	assert_not_null(action)
	assert_eq(action.name, "Interrogate Julia")
	assert_eq(action.type, Enums.ActionType.INTERROGATION)


func test_get_insight() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var insight: InsightData = CaseManager.get_insight("insight_alibi_lie")
	assert_not_null(insight)
	assert_eq(insight.description, "Julia lied about being home")
	assert_eq(insight.source_evidence.size(), 2)


func test_get_all_evidence_returns_typed_array() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var all_ev: Array[EvidenceData] = CaseManager.get_all_evidence()
	assert_eq(all_ev.size(), 3)


func test_get_all_locations_returns_typed_array() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var all_loc: Array[LocationData] = CaseManager.get_all_locations()
	assert_eq(all_loc.size(), 3)


func test_get_all_persons_returns_typed_array() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var all_p: Array[PersonData] = CaseManager.get_all_persons()
	assert_eq(all_p.size(), 3)


# --- Evidence Location Resolution --- #

func test_evidence_location_resolves_to_name() -> void:
	CaseManager.load_case_folder("riverside_apartment")
	var ev: EvidenceData = CaseManager.get_evidence("ev_knife")
	assert_not_null(ev, "ev_knife should exist")
	assert_eq(ev.location_found, "loc_victim_apartment")
	var loc: LocationData = CaseManager.get_location(ev.location_found)
	assert_not_null(loc, "Location should be resolvable")
	assert_eq(loc.name, "Victim's Apartment",
		"Location ID should resolve to human-readable name")
	CaseManager.unload_case()


func test_evidence_data_has_image_field() -> void:
	CaseManager.load_case_folder("riverside_apartment")
	var ev: EvidenceData = CaseManager.get_evidence("ev_knife")
	assert_not_null(ev)
	assert_false(ev.image.is_empty(),
		"Evidence should have an image path set")
	assert_true(ev.image.ends_with(".png"),
		"Evidence image should be a png path")
	CaseManager.unload_case()
