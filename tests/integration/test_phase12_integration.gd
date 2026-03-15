## test_phase12_integration.gd
## Integration tests for Phase 12 — Case Conclusion & Prosecutor System.
## Tests cross-system interactions: theory → report, evidence → scoring,
## interrogation → alternatives, game_manager hooks, serialization.
extends GutTest


const TEST_CASE_FILE: String = "test_case_phase12.json"

var _test_case_data: Dictionary = {
	"id": "case_phase12",
	"title": "Phase 12 Integration",
	"description": "Tests conclusion system integration.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{
			"id": "p_victim",
			"name": "Daniel",
			"role": "VICTIM",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 0,
		},
		{
			"id": "p_mark",
			"name": "Mark Bennett",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 3,
		},
		{
			"id": "p_julia",
			"name": "Julia Ross",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 5,
		},
		{
			"id": "p_carol",
			"name": "Carol White",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 4,
		},
	],
	"evidence": [
		{
			"id": "ev_weapon",
			"name": "Murder Weapon",
			"description": "The weapon used.",
			"type": "PHYSICAL",
			"location_found": "loc_scene",
			"related_persons": ["p_mark"],
			"weight": 0.9,
			"importance_level": "CRITICAL",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_motive",
			"name": "Financial Records",
			"description": "Shows financial motive.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": ["p_mark"],
			"weight": 0.85,
			"importance_level": "CRITICAL",
			"legal_categories": ["MOTIVE"],
		},
		{
			"id": "ev_witness",
			"name": "Witness Statement",
			"description": "A witness account.",
			"type": "DOCUMENT",
			"location_found": "loc_scene",
			"related_persons": ["p_mark"],
			"weight": 0.7,
			"importance_level": "SUPPORTING",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_secondary",
			"name": "Phone Records",
			"description": "Call logs.",
			"type": "DIGITAL",
			"location_found": "loc_office",
			"related_persons": ["p_julia"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
			"legal_categories": ["CONNECTION"],
		},
		{
			"id": "ev_minor",
			"name": "Coffee Receipt",
			"description": "Trivial clue.",
			"type": "PHYSICAL",
			"location_found": "loc_cafe",
			"related_persons": [],
			"weight": 0.2,
			"importance_level": "OPTIONAL",
			"legal_categories": [],
		},
	],
	"locations": [
		{
			"id": "loc_scene",
			"name": "Crime Scene",
			"description": "Where it happened.",
			"type": "CRIME_SCENE",
			"evidence_ids": ["ev_weapon", "ev_witness"],
		},
		{
			"id": "loc_office",
			"name": "Office",
			"description": "Office building.",
			"type": "PUBLIC",
			"evidence_ids": ["ev_motive", "ev_secondary"],
		},
	],
	"events": [],
	"interrogation_triggers": [],
	"solution": {
		"suspect": "p_mark",
		"motive": "Financial gain",
		"weapon": "Murder Weapon",
		"time_minutes": 1320,
		"time_day": 1,
		"access": "Had a spare key",
	},
	"critical_evidence_ids": ["ev_weapon", "ev_motive"],
}


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
	ConclusionManager.reset()
	TheoryManager.reset()
	TimelineManager.reset()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Screen Registration
# =========================================================================

func test_screen_scenes_includes_phase12() -> void:
	assert_true(ScreenManager.SCREEN_SCENES.has("case_report"), "Should have case_report screen")
	assert_true(ScreenManager.SCREEN_SCENES.has("prosecutor_review"), "Should have prosecutor_review screen")
	assert_true(ScreenManager.SCREEN_SCENES.has("case_outcome"), "Should have case_outcome screen")
	assert_eq(ScreenManager.SCREEN_SCENES.size(), 16, "Should have 16 total screens")


# =========================================================================
# Autoload Registration
# =========================================================================

func test_conclusion_manager_autoload_exists() -> void:
	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	assert_not_null(concl_mgr, "ConclusionManager autoload should exist")


# =========================================================================
# Theory → Report Flow
# =========================================================================

func test_theory_data_flows_to_report() -> void:
	var theory: Dictionary = TheoryManager.create_theory("My Theory")
	TheoryManager.set_suspect(theory["id"], "p_mark")
	TheoryManager.set_motive(theory["id"], "Financial gain")
	TheoryManager.set_method(theory["id"], "Murder Weapon")
	TheoryManager.set_time(theory["id"], 1320, 1)

	# Build report from theory data
	var report: Dictionary = {
		"suspect": {"answer": theory["suspect_id"], "evidence": []},
		"motive": {"answer": theory["motive"], "evidence": []},
		"weapon": {"answer": theory["method"], "evidence": []},
		"time": {"answer": "%d %d" % [theory["time_minutes"], theory["time_day"]], "evidence": []},
		"access": {"answer": "Had a spare key", "evidence": []},
	}

	# Need to re-get theory since set_* returns bool, not updated dict
	var updated: Dictionary = TheoryManager.get_all_theories()[0]
	report["suspect"]["answer"] = updated.get("suspect_id", "")
	report["motive"]["answer"] = updated.get("motive", "")
	report["weapon"]["answer"] = updated.get("method", "")

	var result: bool = ConclusionManager.submit_report(report)
	assert_true(result, "Report from theory should be accepted")
	assert_true(ConclusionManager.is_evaluated(), "Should be evaluated")


# =========================================================================
# Evidence → Scoring Integration
# =========================================================================

func test_evidence_discovery_affects_scoring() -> void:
	# Without any evidence discovered → low score
	var report1: Dictionary = _make_report("p_mark", "Financial gain", "Weapon", "1320 1", "Key")
	ConclusionManager.submit_report(report1)
	var score_without: float = ConclusionManager.get_confidence_score()

	ConclusionManager.reset()

	# With evidence discovered → higher score
	GameManager.discover_evidence("ev_weapon")
	GameManager.discover_evidence("ev_motive")
	var report2: Dictionary = _make_report("p_mark", "Financial gain", "Weapon", "1320 1", "Key")
	report2["suspect"]["evidence"] = ["ev_weapon"]
	report2["motive"]["evidence"] = ["ev_motive"]
	ConclusionManager.submit_report(report2)
	var score_with: float = ConclusionManager.get_confidence_score()

	assert_true(score_with > score_without, "Evidence should increase score")


func test_evidence_weight_influences_score() -> void:
	# High weight evidence
	GameManager.discover_evidence("ev_weapon")
	var report_high: Dictionary = _make_report("p_mark", "Financial gain", "Weapon", "1320 1", "Key")
	report_high["suspect"]["evidence"] = ["ev_weapon"]
	ConclusionManager.submit_report(report_high)
	var ev_score_high: float = ConclusionManager.get_evidence_score()

	ConclusionManager.reset()

	# Low weight evidence
	GameManager.discover_evidence("ev_minor")
	var report_low: Dictionary = _make_report("p_mark", "Financial gain", "Weapon", "1320 1", "Key")
	report_low["suspect"]["evidence"] = ["ev_minor"]
	ConclusionManager.submit_report(report_low)
	var ev_score_low: float = ConclusionManager.get_evidence_score()

	assert_true(ev_score_high > ev_score_low, "Higher weight evidence should increase score")


# =========================================================================
# Interrogation → Alternatives Score Integration
# =========================================================================

func test_interrogation_records_affect_alternatives() -> void:
	var report: Dictionary = _make_report("p_mark", "Financial gain", "Weapon", "1320 1", "Key")

	# No interrogations
	ConclusionManager.submit_report(report)
	var none_score: float = ConclusionManager.get_alternatives_score()
	ConclusionManager.reset()

	# Interrogate all 3 suspects
	GameManager.completed_interrogations["p_mark"] = []
	GameManager.completed_interrogations["p_julia"] = []
	GameManager.completed_interrogations["p_carol"] = []
	ConclusionManager.submit_report(report)
	var all_score: float = ConclusionManager.get_alternatives_score()

	assert_true(all_score > none_score, "More interrogations should increase score")
	assert_eq(all_score, 1.0, "All interrogated should be 1.0")


# =========================================================================
# Coverage Bonus Integration
# =========================================================================

func test_critical_evidence_coverage_bonus() -> void:
	var report: Dictionary = _make_report("p_mark", "Financial gain", "Weapon", "1320 1", "Key")

	# No critical evidence discovered
	ConclusionManager.submit_report(report)
	var no_bonus: float = ConclusionManager.get_coverage_bonus()
	ConclusionManager.reset()

	# All critical evidence discovered
	GameManager.discover_evidence("ev_weapon")
	GameManager.discover_evidence("ev_motive")
	ConclusionManager.submit_report(report)
	var full_bonus: float = ConclusionManager.get_coverage_bonus()

	assert_eq(no_bonus, 0.0, "No coverage should be 0")
	assert_almost_eq(full_bonus, 0.1, 0.01, "Full coverage should be 0.1")


# =========================================================================
# Full Flow: Theory → Report → Score → Choice → Outcome
# =========================================================================

func test_full_conclusion_flow_correct_suspect() -> void:
	# Discover evidence
	GameManager.discover_evidence("ev_weapon")
	GameManager.discover_evidence("ev_motive")
	GameManager.discover_evidence("ev_witness")

	# Interrogate suspects
	GameManager.completed_interrogations["p_mark"] = []
	GameManager.completed_interrogations["p_julia"] = []
	GameManager.completed_interrogations["p_carol"] = []

	# Create theory
	var theory: Dictionary = TheoryManager.create_theory("Correct Theory")
	TheoryManager.set_suspect(theory["id"], "p_mark")
	TheoryManager.set_motive(theory["id"], "Financial gain")
	TheoryManager.set_method(theory["id"], "Murder Weapon")
	TheoryManager.set_time(theory["id"], 1320, 1)

	# Submit report
	var report: Dictionary = _make_report("p_mark", "Financial gain", "Murder Weapon", "1320 1", "Had a spare key")
	report["suspect"]["evidence"] = ["ev_weapon", "ev_witness"]
	report["motive"]["evidence"] = ["ev_motive"]

	var submitted: bool = ConclusionManager.submit_report(report)
	assert_true(submitted, "Report should be accepted")
	assert_true(ConclusionManager.is_evaluated(), "Should be evaluated")

	# Check score is reasonably high
	var score: float = ConclusionManager.get_confidence_score()
	assert_true(score > 0.5, "Well-supported case should score above 0.5")

	# Make choice
	ConclusionManager.make_choice("charge")
	assert_eq(ConclusionManager.get_player_choice(), "charge")

	# Check outcome — should be correct
	var outcome: Enums.CaseOutcome = ConclusionManager.get_outcome()
	assert_true(
		outcome == Enums.CaseOutcome.PERFECT_SOLUTION or
		outcome == Enums.CaseOutcome.CORRECT_BUT_INCOMPLETE,
		"Correct suspect should give PERFECT or CORRECT_BUT_INCOMPLETE"
	)


func test_full_conclusion_flow_wrong_suspect() -> void:
	var report: Dictionary = _make_report("p_julia", "Unknown", "Something", "600 2", "")
	ConclusionManager.submit_report(report)
	ConclusionManager.make_choice("charge")

	var outcome: Enums.CaseOutcome = ConclusionManager.get_outcome()
	assert_true(
		outcome == Enums.CaseOutcome.WRONG_BUT_PLAUSIBLE or
		outcome == Enums.CaseOutcome.INCORRECT_THEORY,
		"Wrong suspect should give WRONG or INCORRECT"
	)


# =========================================================================
# GameManager Integration
# =========================================================================

func test_new_game_resets_conclusion() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	assert_true(ConclusionManager.has_report())

	GameManager.new_game()
	assert_false(ConclusionManager.has_report(), "new_game should reset ConclusionManager")
	assert_false(ConclusionManager.is_evaluated())


func test_serialize_deserialize_with_game_manager() -> void:
	GameManager.discover_evidence("ev_weapon")
	var report: Dictionary = _make_report("p_mark", "Gain", "Weapon", "1320 1", "Key")
	report["suspect"]["evidence"] = ["ev_weapon"]
	ConclusionManager.submit_report(report)
	ConclusionManager.make_choice("charge")

	# GameManager serialization should include conclusion state
	var full_state: Dictionary = GameManager.serialize()
	assert_true(full_state.has("conclusion_manager"), "Should serialize conclusion manager")

	var conclusion_data: Dictionary = full_state["conclusion_manager"]
	assert_true(conclusion_data["evaluated"], "Saved state should show evaluated")

	# Reset and restore
	GameManager.new_game()
	CaseManager.load_case(TEST_CASE_FILE)
	GameManager.deserialize(full_state)

	assert_true(ConclusionManager.is_evaluated(), "Should restore evaluated state")
	assert_eq(ConclusionManager.get_player_choice(), "charge")


# =========================================================================
# Epilogue Summary Integration
# =========================================================================

func test_epilogue_reflects_game_state() -> void:
	GameManager.discover_evidence("ev_weapon")
	GameManager.discover_evidence("ev_motive")
	# ev_witness, ev_secondary, ev_minor NOT discovered

	var report: Dictionary = _make_report("p_mark", "Financial gain", "Weapon", "1320 1", "Key")
	ConclusionManager.submit_report(report)
	ConclusionManager.make_choice("charge")

	var epilogue: Dictionary = ConclusionManager.get_epilogue()
	assert_eq(epilogue["discovered"].size(), 2, "Should have 2 discovered")
	assert_eq(epilogue["missed"].size(), 3, "Should have 3 missed")

	# Check epilogue contains all expected keys
	assert_true(epilogue.has("outcome"))
	assert_true(epilogue.has("score"))
	assert_true(epilogue.has("dialogue"))


# =========================================================================
# Player Choice Flow
# =========================================================================

func test_investigate_choice_does_not_determine_outcome() -> void:
	var report: Dictionary = _make_report("p_mark", "Gain", "Weapon", "1320 1", "Key")
	ConclusionManager.submit_report(report)
	watch_signals(ConclusionManager)
	ConclusionManager.make_choice("investigate")
	assert_signal_not_emitted(ConclusionManager, "outcome_determined",
		"Investigate should not determine outcome")


func test_review_choice_does_not_determine_outcome() -> void:
	var report: Dictionary = _make_report("p_mark", "Gain", "Weapon", "1320 1", "Key")
	ConclusionManager.submit_report(report)
	watch_signals(ConclusionManager)
	ConclusionManager.make_choice("review")
	assert_signal_not_emitted(ConclusionManager, "outcome_determined",
		"Review should not determine outcome")


# =========================================================================
# Solution Data Integration
# =========================================================================

func test_solution_data_loaded_correctly() -> void:
	var case_data: CaseData = CaseManager.get_case_data()
	assert_not_null(case_data)
	assert_eq(case_data.solution_suspect, "p_mark")
	assert_eq(case_data.solution_time_minutes, 1320)
	assert_eq(case_data.solution_time_day, 1)
	assert_eq(case_data.critical_evidence_ids.size(), 2)


# =========================================================================
# Scoring Factor Weights
# =========================================================================

func test_weight_constants_sum_correctly() -> void:
	var base_sum: float = (
		ConclusionManager.WEIGHT_EVIDENCE +
		ConclusionManager.WEIGHT_TIMELINE +
		ConclusionManager.WEIGHT_MOTIVE +
		ConclusionManager.WEIGHT_ALTERNATIVES
	)
	assert_almost_eq(base_sum, 0.9, 0.001, "Base factor weights should sum to 0.9")
	assert_almost_eq(ConclusionManager.PENALTY_CONTRADICTIONS, 0.1, 0.001)
	assert_almost_eq(ConclusionManager.BONUS_COVERAGE, 0.1, 0.001)


# =========================================================================
# Edge Cases
# =========================================================================

func test_report_after_reset_works() -> void:
	var report1: Dictionary = _make_report("p_mark", "A", "B", "C", "D")
	ConclusionManager.submit_report(report1)
	ConclusionManager.reset()

	var report2: Dictionary = _make_report("p_julia", "X", "Y", "1320 1", "Z")
	var result: bool = ConclusionManager.submit_report(report2)
	assert_true(result, "Should accept new report after reset")
	var r: Dictionary = ConclusionManager.get_report()
	assert_eq(r["suspect"]["answer"], "p_julia", "Should have new report data")


func test_multiple_choices_override() -> void:
	var report: Dictionary = _make_report("p_mark", "A", "B", "1320 1", "D")
	ConclusionManager.submit_report(report)
	ConclusionManager.make_choice("review")
	assert_eq(ConclusionManager.get_player_choice(), "review")
	ConclusionManager.make_choice("charge")
	assert_eq(ConclusionManager.get_player_choice(), "charge")


# =========================================================================
# Helpers
# =========================================================================

func _make_report(suspect: String, motive: String, weapon: String, time: String, access: String) -> Dictionary:
	return {
		"suspect": {"answer": suspect, "evidence": []},
		"motive": {"answer": motive, "evidence": []},
		"weapon": {"answer": weapon, "evidence": []},
		"time": {"answer": time, "evidence": []},
		"access": {"answer": access, "evidence": []},
	}
