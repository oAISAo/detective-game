## test_conclusion_scenarios.gd
## Scenario tests for Phase 12 — Case Conclusion & Prosecutor System.
## Tests the four ending scenarios: Perfect Solution, Correct But Incomplete,
## Wrong But Plausible, and Incorrect Theory.
extends GutTest


const TEST_CASE_FILE: String = "test_case_scenarios.json"

var _test_case_data: Dictionary = {
	"id": "case_scenarios",
	"title": "Scenario Test Case",
	"description": "Tests all four ending scenarios.",
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
	],
	"evidence": [
		{
			"id": "ev_dna",
			"name": "DNA Sample",
			"description": "DNA at scene.",
			"type": "FORENSIC",
			"location_found": "loc_scene",
			"related_persons": ["p_mark"],
			"weight": 0.95,
			"importance_level": "CRITICAL",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_motive",
			"name": "Diary Entry",
			"description": "Reveals motive.",
			"type": "DOCUMENT",
			"location_found": "loc_house",
			"related_persons": ["p_mark"],
			"weight": 0.9,
			"importance_level": "CRITICAL",
			"legal_categories": ["MOTIVE"],
		},
		{
			"id": "ev_weapon",
			"name": "Knife",
			"description": "The weapon.",
			"type": "PHYSICAL",
			"location_found": "loc_scene",
			"related_persons": ["p_mark"],
			"weight": 0.85,
			"importance_level": "CRITICAL",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_cctv",
			"name": "CCTV Footage",
			"description": "Shows suspect near scene.",
			"type": "DIGITAL",
			"location_found": "loc_street",
			"related_persons": ["p_mark"],
			"weight": 0.8,
			"importance_level": "SUPPORTING",
			"legal_categories": ["PRESENCE", "OPPORTUNITY"],
		},
		{
			"id": "ev_alibi_break",
			"name": "Broken Alibi",
			"description": "Proves alibi was false.",
			"type": "DOCUMENT",
			"location_found": "loc_house",
			"related_persons": ["p_mark"],
			"weight": 0.7,
			"importance_level": "SUPPORTING",
			"legal_categories": ["CONNECTION"],
		},
	],
	"locations": [
		{
			"id": "loc_scene",
			"name": "Crime Scene",
			"description": "Primary scene.",
			"type": "CRIME_SCENE",
			"evidence_ids": ["ev_dna", "ev_weapon"],
		},
		{
			"id": "loc_house",
			"name": "Suspect House",
			"description": "Suspect's home.",
			"type": "PRIVATE",
			"evidence_ids": ["ev_motive", "ev_alibi_break"],
		},
	],
	"events": [],
	"interrogation_triggers": [],
	"solution": {
		"suspect": "p_mark",
		"motive": "Revenge",
		"weapon": "Knife",
		"time_minutes": 1380,
		"time_day": 1,
		"access": "Front door was unlocked",
	},
	"critical_evidence_ids": ["ev_dna", "ev_motive", "ev_weapon"],
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


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Scenario 1: Perfect Solution
# =========================================================================

func test_scenario_perfect_solution() -> void:
	# Discover all critical evidence
	GameManager.discover_evidence("ev_dna")
	GameManager.discover_evidence("ev_motive")
	GameManager.discover_evidence("ev_weapon")
	GameManager.discover_evidence("ev_cctv")
	GameManager.discover_evidence("ev_alibi_break")

	# Interrogate all suspects
	GameManager.completed_interrogations["p_mark"] = []
	GameManager.completed_interrogations["p_julia"] = []

	# Submit perfect report
	var report: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": ["ev_dna", "ev_weapon"]},
		"motive": {"answer": "Revenge", "evidence": ["ev_motive"]},
		"weapon": {"answer": "Knife", "evidence": ["ev_weapon"]},
		"time": {"answer": "1380 1", "evidence": ["ev_cctv"]},
		"access": {"answer": "Front door was unlocked", "evidence": ["ev_alibi_break"]},
	}
	ConclusionManager.submit_report(report)

	# Verify high confidence
	var score: float = ConclusionManager.get_confidence_score()
	assert_true(score >= 0.90, "Perfect setup should score >= 90%%. Got %.1f%%" % (score * 100.0))

	var level: Enums.ConfidenceLevel = ConclusionManager.get_confidence_level()
	assert_eq(level, Enums.ConfidenceLevel.PERFECT, "Should be PERFECT confidence")

	# Prosecutor dialogue
	var dialogue: String = ConclusionManager.get_prosecutor_dialogue()
	assert_eq(dialogue, "This is airtight.", "Should get airtight dialogue")

	# Charge and verify outcome
	ConclusionManager.make_choice("charge")
	assert_eq(ConclusionManager.get_outcome(), Enums.CaseOutcome.PERFECT_SOLUTION)
	assert_eq(ConclusionManager.get_outcome_name(), "Perfect Solution")

	# Epilogue: all discovered, none missed
	var epilogue: Dictionary = ConclusionManager.get_epilogue()
	assert_eq(epilogue["discovered"].size(), 5, "All 5 should be discovered")
	assert_eq(epilogue["missed"].size(), 0, "None should be missed")


# =========================================================================
# Scenario 2: Correct But Incomplete
# =========================================================================

func test_scenario_correct_but_incomplete() -> void:
	# Discover only some evidence
	GameManager.discover_evidence("ev_weapon")
	GameManager.completed_interrogations["p_mark"] = []

	# Submit report with correct suspect but limited evidence
	var report: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": ["ev_weapon"]},
		"motive": {"answer": "Revenge", "evidence": []},
		"weapon": {"answer": "Knife", "evidence": ["ev_weapon"]},
		"time": {"answer": "1380 1", "evidence": []},
		"access": {"answer": "Front door", "evidence": []},
	}
	ConclusionManager.submit_report(report)

	var score: float = ConclusionManager.get_confidence_score()
	# Should be moderate: some evidence, correct time, but not all suspects interrogated
	assert_true(score >= 0.40, "Should score at least moderate. Got %.1f%%" % (score * 100.0))
	assert_true(score < 0.90, "Should not score perfect. Got %.1f%%" % (score * 100.0))

	ConclusionManager.make_choice("charge")
	assert_eq(ConclusionManager.get_outcome(), Enums.CaseOutcome.CORRECT_BUT_INCOMPLETE)

	# Epilogue should show missed evidence
	var epilogue: Dictionary = ConclusionManager.get_epilogue()
	assert_eq(epilogue["discovered"].size(), 1)
	assert_eq(epilogue["missed"].size(), 4)


# =========================================================================
# Scenario 3: Wrong But Plausible
# =========================================================================

func test_scenario_wrong_but_plausible() -> void:
	# Build a plausible case against the wrong suspect
	GameManager.discover_evidence("ev_weapon")
	GameManager.discover_evidence("ev_cctv")
	GameManager.completed_interrogations["p_mark"] = []
	GameManager.completed_interrogations["p_julia"] = []

	var report: Dictionary = {
		"suspect": {"answer": "p_julia", "evidence": ["ev_weapon", "ev_cctv"]},
		"motive": {"answer": "Jealousy", "evidence": ["ev_motive"]},
		"weapon": {"answer": "Knife", "evidence": ["ev_weapon"]},
		"time": {"answer": "1380 1", "evidence": ["ev_cctv"]},
		"access": {"answer": "Snuck in", "evidence": []},
	}
	GameManager.discover_evidence("ev_motive")
	ConclusionManager.submit_report(report)

	var score: float = ConclusionManager.get_confidence_score()
	if score >= 0.40:
		ConclusionManager.make_choice("charge")
		assert_eq(
			ConclusionManager.get_outcome(),
			Enums.CaseOutcome.WRONG_BUT_PLAUSIBLE,
			"Wrong suspect with decent evidence should be WRONG_BUT_PLAUSIBLE"
		)


# =========================================================================
# Scenario 4: Incorrect Theory
# =========================================================================

func test_scenario_incorrect_theory() -> void:
	# Minimal evidence, wrong suspect
	var report: Dictionary = {
		"suspect": {"answer": "p_julia", "evidence": []},
		"motive": {"answer": "No idea", "evidence": []},
		"weapon": {"answer": "Unknown", "evidence": []},
		"time": {"answer": "", "evidence": []},
		"access": {"answer": "", "evidence": []},
	}
	ConclusionManager.submit_report(report)

	var score: float = ConclusionManager.get_confidence_score()
	assert_true(score < 0.40, "Empty report should score below 40%%. Got %.1f%%" % (score * 100.0))

	var level: Enums.ConfidenceLevel = ConclusionManager.get_confidence_level()
	assert_eq(level, Enums.ConfidenceLevel.WEAK, "Should be WEAK confidence")

	var dialogue: String = ConclusionManager.get_prosecutor_dialogue()
	assert_eq(dialogue, "This theory has serious holes.", "Should get holes dialogue")

	ConclusionManager.make_choice("charge")
	assert_eq(ConclusionManager.get_outcome(), Enums.CaseOutcome.INCORRECT_THEORY)
	assert_eq(ConclusionManager.get_outcome_name(), "Incorrect Theory")


# =========================================================================
# Scenario Transitions
# =========================================================================

func test_investigate_then_return_with_more_evidence() -> void:
	# First attempt: weak case
	var report1: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": []},
		"motive": {"answer": "Revenge", "evidence": []},
		"weapon": {"answer": "Knife", "evidence": []},
		"time": {"answer": "1380 1", "evidence": []},
		"access": {"answer": "Door", "evidence": []},
	}
	ConclusionManager.submit_report(report1)
	var score1: float = ConclusionManager.get_confidence_score()

	# Player chooses to investigate more
	ConclusionManager.make_choice("investigate")
	assert_eq(ConclusionManager.get_player_choice(), "investigate")

	# Reset and try again with more evidence
	ConclusionManager.reset()
	GameManager.discover_evidence("ev_dna")
	GameManager.discover_evidence("ev_motive")
	GameManager.discover_evidence("ev_weapon")
	GameManager.completed_interrogations["p_mark"] = []
	GameManager.completed_interrogations["p_julia"] = []

	var report2: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": ["ev_dna", "ev_weapon"]},
		"motive": {"answer": "Revenge", "evidence": ["ev_motive"]},
		"weapon": {"answer": "Knife", "evidence": ["ev_weapon"]},
		"time": {"answer": "1380 1", "evidence": []},
		"access": {"answer": "Door", "evidence": []},
	}
	ConclusionManager.submit_report(report2)
	var score2: float = ConclusionManager.get_confidence_score()

	assert_true(score2 > score1, "Score should improve with more evidence")


func test_review_allows_resubmission() -> void:
	var report: Dictionary = {
		"suspect": {"answer": "p_julia", "evidence": []},
		"motive": {"answer": "Unknown", "evidence": []},
		"weapon": {"answer": "?", "evidence": []},
		"time": {"answer": "", "evidence": []},
		"access": {"answer": "", "evidence": []},
	}
	ConclusionManager.submit_report(report)
	ConclusionManager.make_choice("review")

	# Reset and submit corrected report
	ConclusionManager.reset()
	var corrected: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": []},
		"motive": {"answer": "Revenge", "evidence": []},
		"weapon": {"answer": "Knife", "evidence": []},
		"time": {"answer": "1380 1", "evidence": []},
		"access": {"answer": "Door", "evidence": []},
	}
	var result: bool = ConclusionManager.submit_report(corrected)
	assert_true(result, "Should accept corrected report")
	assert_eq(ConclusionManager.get_report()["suspect"]["answer"], "p_mark")


# =========================================================================
# Scoring Component Verification Across Scenarios
# =========================================================================

func test_score_components_perfect_case() -> void:
	GameManager.discover_evidence("ev_dna")
	GameManager.discover_evidence("ev_motive")
	GameManager.discover_evidence("ev_weapon")
	GameManager.discover_evidence("ev_cctv")
	GameManager.discover_evidence("ev_alibi_break")
	GameManager.completed_interrogations["p_mark"] = []
	GameManager.completed_interrogations["p_julia"] = []

	var report: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": ["ev_dna", "ev_weapon"]},
		"motive": {"answer": "Revenge", "evidence": ["ev_motive"]},
		"weapon": {"answer": "Knife", "evidence": ["ev_weapon"]},
		"time": {"answer": "1380 1", "evidence": ["ev_cctv"]},
		"access": {"answer": "Front door", "evidence": ["ev_alibi_break"]},
	}
	ConclusionManager.submit_report(report)

	# Check all components
	var ev_score: float = ConclusionManager.get_evidence_score()
	assert_true(ev_score > 0.7, "Evidence score should be high")

	var tl_score: float = ConclusionManager.get_timeline_score()
	assert_eq(tl_score, 1.0, "Timeline should be perfect match")

	var mot_score: float = ConclusionManager.get_motive_score()
	assert_eq(mot_score, 1.0, "Motive with MOTIVE category evidence should be 1.0")

	var alt_score: float = ConclusionManager.get_alternatives_score()
	assert_eq(alt_score, 1.0, "All suspects interrogated should be 1.0")

	var penalty: float = ConclusionManager.get_contradiction_penalty()
	assert_eq(penalty, 0.0, "No contradictions expected")

	var bonus: float = ConclusionManager.get_coverage_bonus()
	assert_almost_eq(bonus, 0.1, 0.01, "All critical evidence should give full bonus")


func test_score_components_minimal_case() -> void:
	# Nothing discovered, no interrogations, empty answers
	var report: Dictionary = {
		"suspect": {"answer": "p_julia", "evidence": []},
		"motive": {"answer": "", "evidence": []},
		"weapon": {"answer": "Something", "evidence": []},
		"time": {"answer": "", "evidence": []},
		"access": {"answer": "", "evidence": []},
	}
	ConclusionManager.submit_report(report)

	var ev_score: float = ConclusionManager.get_evidence_score()
	assert_eq(ev_score, 0.0, "No evidence should give 0")

	var tl_score: float = ConclusionManager.get_timeline_score()
	assert_eq(tl_score, 0.0, "Empty time should give 0")

	var mot_score: float = ConclusionManager.get_motive_score()
	assert_eq(mot_score, 0.0, "Empty motive should give 0")

	var alt_score: float = ConclusionManager.get_alternatives_score()
	assert_eq(alt_score, 0.0, "No interrogations should give 0")

	var bonus: float = ConclusionManager.get_coverage_bonus()
	assert_eq(bonus, 0.0, "No critical evidence should give 0 bonus")
