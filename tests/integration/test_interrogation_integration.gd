## test_interrogation_integration.gd
## Integration tests for the interrogation system.
## Tests the full pipeline: evidence → focus → trigger → statement → contradiction,
## and the complete interrogation arc from statement intake to break.
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
			"target_statement_id": "s_initial_claim",
			"target_topic_id": "",
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
			"target_statement_id": "",
			"target_topic_id": "general",
			"impact_level": "MAJOR",
			"reaction_type": "REVELATION",
			"dialogue": "I called him that evening to discuss business.",
			"new_statement_id": "s_records_revelation",
			"unlocks": [],
			"pressure_points": 1,
		},
	],
	"interrogation_sessions": [
		{
			"person_id": "p_suspect_a",
			"initial_dialogue": "Suspect Alpha sits down nervously.",
			"initial_statement_ids": ["s_initial_claim"],
			"base_topic_ids": ["topic_whereabouts"],
			"pressure_gate": 1,
			"rejection_texts": [
				"He shrugs dismissively.",
			],
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
# Evidence → Focus → Trigger → Statement → Contradiction Pipeline
# =========================================================================

func test_evidence_trigger_statement_contradiction_pipeline() -> void:
	GameManager.discover_evidence("ev_photo")

	# Start interrogation — s_initial_claim auto-heard from session data
	InterrogationManager.start_interrogation("p_suspect_a")
	assert_has(InterrogationManager.get_heard_statements(), "s_initial_claim")

	# Verify contradiction is detected (ev_photo contradicts s_initial_claim)
	var contradictions: Array[Dictionary] = InterrogationManager.get_contradicted_statements()
	assert_eq(contradictions.size(), 1, "Should detect contradiction")
	assert_eq(contradictions[0]["statement_id"], "s_initial_claim")

	# Advance to interrogation and set focus on the contradicted statement
	InterrogationManager.advance_to_interrogation()
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION)

	InterrogationManager.select_focus("statement", "s_initial_claim")
	var trigger_result: Dictionary = InterrogationManager.present_evidence("ev_photo")
	assert_true(trigger_result.get("triggered", false), "Trigger should fire")
	assert_eq(trigger_result["trigger_id"], "trig_photo")
	assert_eq(trigger_result["reaction_type"], Enums.ReactionType.ADMISSION)
	# Prerequisite is auto-heard, so trigger fires at full strength

	# New statement recorded
	assert_has(InterrogationManager.get_heard_statements(), "s_photo_admission")

	# Evidence unlocked
	assert_true(GameManager.has_evidence("ev_unlocked"), "Triggered unlock should discover evidence")

	# Pressure increased
	assert_eq(InterrogationManager.get_current_pressure(), 1)

	# Contradiction logged via focus
	var session_contras: Array[Dictionary] = InterrogationManager.get_session_contradictions()
	assert_eq(session_contras.size(), 1)
	assert_eq(session_contras[0]["statement_id"], "s_initial_claim")

	InterrogationManager.end_interrogation()


# =========================================================================
# Full Interrogation Arc: Statement Intake → Interrogation → Break
# =========================================================================

func test_full_interrogation_arc_to_break() -> void:
	GameManager.discover_evidence("ev_photo")
	GameManager.discover_evidence("ev_records")

	# Start interrogation — s_initial_claim auto-heard
	InterrogationManager.start_interrogation("p_suspect_a")
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION)

	# Present first evidence with focus → +1 pressure
	InterrogationManager.select_focus("statement", "s_initial_claim")
	var result1: Dictionary = InterrogationManager.present_evidence("ev_photo")
	assert_true(result1.get("triggered", false))
	assert_eq(InterrogationManager.get_current_pressure(), 1)

	# Present second evidence (target_statement_id is empty, so use any statement as focus)
	InterrogationManager.select_focus("statement", "s_photo_admission")
	var result2: Dictionary = InterrogationManager.present_evidence("ev_records")
	assert_true(result2.get("triggered", false))
	assert_eq(InterrogationManager.get_current_pressure(), 2)

	# Break moment (threshold = 2) — triggered via apply_pressure
	watch_signals(InterrogationManager)
	var pressure_result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(pressure_result.get("break_moment", false), "Should trigger break moment")
	assert_signal_emitted_with_parameters(
		InterrogationManager, "break_moment_reached", ["p_suspect_a"]
	)
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION)
	assert_true(InterrogationManager.has_break_moment("p_suspect_a"))

	# End session
	InterrogationManager.end_interrogation()

	# Verify state persisted
	assert_eq(InterrogationManager.get_pressure_for_person("p_suspect_a"), 2)
	assert_true(InterrogationManager.has_break_moment("p_suspect_a"))
	var fired: Array = InterrogationManager.get_fired_triggers_for_person("p_suspect_a")
	assert_eq(fired.size(), 2)


# =========================================================================
# Apply Pressure Gating Integration
# =========================================================================

func test_apply_pressure_gating_in_full_flow() -> void:
	GameManager.discover_evidence("ev_photo")

	InterrogationManager.start_interrogation("p_suspect_a")
	InterrogationManager.advance_to_interrogation()

	# Before any contradictions, can't apply pressure
	assert_false(InterrogationManager.can_apply_pressure())

	# Present evidence with focus → logs contradiction
	InterrogationManager.select_focus("statement", "s_initial_claim")
	InterrogationManager.present_evidence("ev_photo")

	# pressure_gate is 1, and we have 1 contradiction now
	assert_true(InterrogationManager.can_apply_pressure())
	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(result.get("success", false))
	assert_eq(InterrogationManager.get_current_phase(), Enums.InterrogationPhase.INTERROGATION)

	InterrogationManager.end_interrogation()


# =========================================================================
# GameManager Serialization Integration
# =========================================================================

func test_game_manager_serializes_interrogation_state() -> void:
	GameManager.discover_evidence("ev_photo")
	InterrogationManager.start_interrogation("p_suspect_a")
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_initial_claim")
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
