## test_case_manager.gd
## Unit tests for the CaseManager autoload singleton.
## Phase 0: Verify JSON loading, query functions, and error handling.
extends GutTest


## Path to a test case JSON file.
const TEST_CASE_FILE: String = "test_case.json"

## Minimal test case data for testing.
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
	assert_eq(CaseManager.get_evidence("ev_fingerprint").size(), 0, "Should return empty after unload")


# --- Query: Evidence --- #

func test_get_evidence_returns_correct_data() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var ev: Dictionary = CaseManager.get_evidence("ev_fingerprint")
	assert_eq(ev.get("name", ""), "Fingerprint on Wine Glass")
	assert_eq(ev.get("type", ""), "FORENSIC")


func test_get_evidence_returns_empty_for_invalid_id() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var ev: Dictionary = CaseManager.get_evidence("ev_nonexistent")
	assert_eq(ev.size(), 0, "Should return empty dict for invalid ID")


# --- Query: Person --- #

func test_get_person_returns_correct_data() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var person: Dictionary = CaseManager.get_person("p_julia")
	assert_eq(person.get("name", ""), "Julia Ross")
	assert_eq(person.get("role", ""), "SUSPECT")


func test_get_person_returns_empty_for_invalid_id() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var person: Dictionary = CaseManager.get_person("p_nonexistent")
	assert_eq(person.size(), 0)


# --- Query: Statements by Person --- #

func test_get_statements_by_person() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var stmts: Array[Dictionary] = CaseManager.get_statements_by_person("p_mark")
	assert_eq(stmts.size(), 1)
	assert_eq(stmts[0].get("id", ""), "s_mark_01")


func test_get_statements_by_person_returns_empty_for_unknown() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var stmts: Array[Dictionary] = CaseManager.get_statements_by_person("p_unknown")
	assert_eq(stmts.size(), 0)


# --- Query: Events by Day --- #

func test_get_events_for_day() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var day1_events: Array[Dictionary] = CaseManager.get_events_for_day(1)
	assert_eq(day1_events.size(), 2, "Day 1 should have 2 events")

	var day2_events: Array[Dictionary] = CaseManager.get_events_for_day(2)
	assert_eq(day2_events.size(), 1, "Day 2 should have 1 event")


func test_get_events_for_empty_day() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var day3_events: Array[Dictionary] = CaseManager.get_events_for_day(3)
	assert_eq(day3_events.size(), 0, "Day 3 should have no events")


# --- Query: Evidence by Person --- #

func test_get_evidence_for_person() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var julia_evidence: Array[Dictionary] = CaseManager.get_evidence_for_person("p_julia")
	assert_eq(julia_evidence.size(), 1)
	assert_eq(julia_evidence[0].get("id", ""), "ev_fingerprint")


func test_get_evidence_for_person_multiple() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var mark_evidence: Array[Dictionary] = CaseManager.get_evidence_for_person("p_mark")
	assert_eq(mark_evidence.size(), 2, "Mark should be related to camera and financial records")


# --- Query: Evidence by Location --- #

func test_get_evidence_by_location() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var apt_evidence: Array[Dictionary] = CaseManager.get_evidence_by_location("loc_apartment")
	assert_eq(apt_evidence.size(), 1)
	assert_eq(apt_evidence[0].get("id", ""), "ev_fingerprint")


func test_get_evidence_by_location_returns_empty_for_unknown() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var result: Array[Dictionary] = CaseManager.get_evidence_by_location("loc_unknown")
	assert_eq(result.size(), 0)


# --- Query: Suspects --- #

func test_get_suspects() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var suspects: Array[Dictionary] = CaseManager.get_suspects()
	assert_eq(suspects.size(), 2, "Should have 2 suspects")


# --- Query: Event Triggers --- #

func test_get_triggers_by_type() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var day_start_triggers: Array[Dictionary] = CaseManager.get_triggers_by_type("DAY_START")
	assert_eq(day_start_triggers.size(), 1)

	var conditional_triggers: Array[Dictionary] = CaseManager.get_triggers_by_type("CONDITIONAL")
	assert_eq(conditional_triggers.size(), 1)


func test_get_triggers_for_day() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var day2_triggers: Array[Dictionary] = CaseManager.get_triggers_for_day(2)
	assert_eq(day2_triggers.size(), 1)
	assert_eq(day2_triggers[0].get("id", ""), "trigger_day2_briefing")
