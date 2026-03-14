## test_interrogation_integration.gd
## Integration tests for the interrogation system.
## Tests the full pipeline: evidence → trigger → statement → contradiction,
## and the complete interrogation arc from open conversation to break.
extends GutTest


## Path to a test case JSON file for integration tests.
const TEST_CASE_FILE: String = "test_case_interr_integration.json"

## Test case data with a complete interrogation flow.
var _test_case_data: Dictionary = {
	"id": "case_interr_integ",
	"title": "Integration Test Case",
	"description": "Tests full interrogation pipeline.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{
			"id": "p_victim",
			"name": "Victim",
			"role": "VICTIM",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 0,
		},
		{
			"id": "p_suspect_a",
			"name": "Suspect Alpha",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 2,
		},
	],
	"evidence": [
		{
			"id": "ev_photo",
			"name": "Crime Scene Photo",
			"description": "Photo from the scene.",
			"type": "PHOTO",
			"location_found": "loc_scene",
			"related_persons": ["p_suspect_a"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_records",
			"name": "Phone Records",
			"description": "Call history.",
			"type": "DIGITAL",
			"location_found": "loc_office",
			"related_persons": ["p_suspect_a"],
			"weight": 0.7,
			"importance_level": "CRITICAL",
		},
		{
			"id": "ev_unlocked",
			"name": "Hidden Note",
			"description": "Unlocked by trigger.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": [],
			"weight": 0.3,
			"importance_level": "OPTIONAL",
		},
	],
	"statements": [
		{
			"id": "s_initial_claim",
			"person_id": "p_suspect_a",
			"text": "I was nowhere near the scene.",
			"day_given": 1,
			"related_evidence": [],
			"contradicting_evidence": ["ev_photo"],
		},
		{
			"id": "s_photo_admission",
			"person_id": "p_suspect_a",
			"text": "OK I was nearby but I did not go in.",
			"day_given": 1,
			"related_evidence": ["ev_photo"],
		},
		{
			"id": "s_records_revelation",
			"person_id": "p_suspect_a",
			"text": "I called him that evening to discuss business.",
			"day_given": 1,
			"related_evidence": ["ev_records"],
		},
	],
	"events": [],
	"locations": [
		{
			"id": "loc_scene",
			"name": "Crime Scene",
			"searchable": true,
			"evidence_pool": [],
		},
		{
			"id": "loc_office",
			"name": "Office",
			"searchable": true,
			"evidence_pool": [],
		},
	],
	"event_triggers": [],
	"interrogation_topics": [
		{
			"id": "topic_whereabouts",
			"person_id": "p_suspect_a",
			"topic_name": "Whereabouts on the night",
			"trigger_conditions": [],
			"statements": ["s_initial_claim"],
			"required_evidence": [],
		},
	],
	"actions": [],
	"insights": [],
	"interrogation_triggers": [
		{
			"id": "trig_photo",
			"person_id": "p_suspect_a",
			"evidence_id": "ev_photo",
			"requires_statement_id": "s_initial_claim",
			"impact_level": "MAJOR",
			"reaction_type": "ADMISSION",
			"dialogue": "OK I was nearby but I did not go in.",
			"new_statement_id": "s_photo_admission",
			"unlocks": ["ev_unlocked"],
			"pressure_points": 1,
		},
		{
			"id": "trig_records",
			"person_id": "p_suspect_a",
			"evidence_id": "ev_records",
			"requires_statement_id": "",
			"impact_level": "MAJOR",
			"reaction_type": "REVELATION",
			"dialogue": "I called him that evening to discuss business.",
			"new_statement_id": "s_records_revelation",
			"unlocks": [],
			"pressure_points": 1,
		},
	],
}


# --- Setup / Teardown --- #

func before_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	DirAccess.make_dir_recursive_absolute("res://data/cases")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_test_case_data, "\t"))
	file.close()


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)
	InterrogationManager.reset()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Evidence → Trigger → Statement → Contradiction Pipeline
# =========================================================================

func test_evidence_trigger_statement_contradiction_pipeline() -> void:
	GameManager.discover_evidence("ev_photo")

	# Start interrogation
	InterrogationManager.start_interrogation("p_suspect_a")

	# Phase 1: Open conversation — discuss alibi topic
	var topic_result: Dictionary = InterrogationManager.discuss_topic("topic_whereabouts")
	assert_eq(topic_result.get("statements", []).size(), 1, "Topic should produce a statement")
	assert_has(InterrogationManager.get_heard_statements(), "s_initial_claim")

	# Verify contradiction is detected (ev_photo contradicts s_initial_claim)
	var contradictions: Array[Dictionary] = InterrogationManager.get_contradicted_statements()
	assert_eq(contradictions.size(), 1, "Should detect contradiction")
	assert_eq(contradictions[0]["statement_id"], "s_initial_claim")

	# Phase 2: Advance to confrontation and present evidence
	InterrogationManager.advance_phase()
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.EVIDENCE_CONFRONTATION)

	var trigger_result: Dictionary = InterrogationManager.present_evidence("ev_photo")
	assert_true(trigger_result.get("triggered", false), "Trigger should fire")
	assert_eq(trigger_result["trigger_id"], "trig_photo")
	assert_eq(trigger_result["reaction_type"], Enums.ReactionType.ADMISSION)
	assert_false(trigger_result.get("weakened", true), "Should not be weakened (prereq met)")

	# New statement recorded
	assert_has(InterrogationManager.get_heard_statements(), "s_photo_admission")

	# Evidence unlocked
	assert_true(GameManager.has_evidence("ev_unlocked"), "Triggered unlock should discover evidence")

	# Pressure increased
	assert_eq(InterrogationManager.get_current_pressure(), 1)

	InterrogationManager.end_interrogation()


# =========================================================================
# Full Interrogation Arc: Open → Confrontation → Pressure → Break
# =========================================================================

func test_full_interrogation_arc_to_break() -> void:
	GameManager.discover_evidence("ev_photo")
	GameManager.discover_evidence("ev_records")

	# Start interrogation
	InterrogationManager.start_interrogation("p_suspect_a")
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.OPEN_CONVERSATION)

	# Phase 1: Discuss topic
	InterrogationManager.discuss_topic("topic_whereabouts")

	# Phase 2: Evidence Confrontation
	InterrogationManager.advance_phase()
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.EVIDENCE_CONFRONTATION)

	# Present first evidence → +1 pressure
	var result1: Dictionary = InterrogationManager.present_evidence("ev_photo")
	assert_true(result1.get("triggered", false))
	assert_eq(InterrogationManager.get_current_pressure(), 1)

	# Phase 3: Psychological pressure
	InterrogationManager.advance_phase()
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.PSYCHOLOGICAL_PRESSURE)

	# Present second evidence → +1 pressure → threshold (2) reached
	watch_signals(InterrogationManager)
	var result2: Dictionary = InterrogationManager.present_evidence("ev_records")
	assert_true(result2.get("triggered", false))
	assert_eq(InterrogationManager.get_current_pressure(), 2)

	# Break moment
	assert_true(result2.get("break_moment", false), "Should trigger break moment")
	assert_signal_emitted_with_parameters(
		InterrogationManager, "break_moment_reached", ["p_suspect_a"]
	)
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.BREAK_MOMENT)
	assert_true(InterrogationManager.has_break_moment("p_suspect_a"))

	# End session
	InterrogationManager.end_interrogation()

	# Verify state persisted
	assert_eq(InterrogationManager.get_pressure_for_person("p_suspect_a"), 2)
	assert_true(InterrogationManager.has_break_moment("p_suspect_a"))
	var fired: Array = InterrogationManager.get_fired_triggers_for_person("p_suspect_a")
	assert_eq(fired.size(), 2)


# =========================================================================
# GameManager Serialization Integration
# =========================================================================

func test_game_manager_serializes_interrogation_state() -> void:
	GameManager.discover_evidence("ev_photo")
	InterrogationManager.start_interrogation("p_suspect_a")
	InterrogationManager.discuss_topic("topic_whereabouts")
	InterrogationManager.advance_phase()
	InterrogationManager.present_evidence("ev_photo")
	InterrogationManager.end_interrogation()

	var saved: Dictionary = GameManager.serialize()
	assert_true(saved.has("interrogation_manager"), "Serialized state should include interrogation_manager")

	# Reset and restore
	GameManager.new_game()
	InterrogationManager.reset()
	GameManager.deserialize(saved)

	assert_eq(InterrogationManager.get_pressure_for_person("p_suspect_a"), 1)
	assert_has(InterrogationManager.get_heard_statements(), "s_initial_claim")
