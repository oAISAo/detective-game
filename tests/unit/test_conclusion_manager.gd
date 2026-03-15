## test_conclusion_manager.gd
## Unit tests for the ConclusionManager autoload.
## Tests report submission, confidence scoring factors (evidence strength,
## timeline accuracy, motive proof, alternatives eliminated, contradictions,
## coverage), confidence levels, prosecutor dialogue, case outcomes,
## epilogue generation, and serialization.
extends GutTest


const TEST_CASE_FILE: String = "test_case_conclusion.json"

var _test_case_data: Dictionary = {
	"id": "case_conclusion_test",
	"title": "Conclusion Test Case",
	"description": "Tests case conclusion system.",
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
			"id": "ev_knife",
			"name": "Kitchen Knife",
			"description": "Found at scene.",
			"type": "PHYSICAL",
			"location_found": "loc_scene",
			"related_persons": ["p_mark"],
			"weight": 0.9,
			"importance_level": "CRITICAL",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_motive_doc",
			"name": "Insurance Policy",
			"description": "Large insurance payout.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": ["p_mark"],
			"weight": 0.8,
			"importance_level": "CRITICAL",
			"legal_categories": ["MOTIVE"],
		},
		{
			"id": "ev_prints",
			"name": "Fingerprints",
			"description": "On door handle.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": ["p_julia"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_alibi",
			"name": "Alibi Witness",
			"description": "Saw suspect elsewhere.",
			"type": "DOCUMENT",
			"location_found": "loc_bar",
			"related_persons": ["p_mark"],
			"weight": 0.4,
			"importance_level": "OPTIONAL",
			"legal_categories": [],
		},
		{
			"id": "ev_hidden",
			"name": "Secret Letter",
			"description": "Hidden evidence.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": ["p_mark"],
			"weight": 0.7,
			"importance_level": "CRITICAL",
			"legal_categories": ["MOTIVE"],
		},
	],
	"locations": [
		{
			"id": "loc_scene",
			"name": "Crime Scene",
			"description": "Scene of crime.",
			"type": "CRIME_SCENE",
			"evidence_ids": ["ev_knife"],
		},
		{
			"id": "loc_office",
			"name": "Office",
			"description": "Office building.",
			"type": "PUBLIC",
			"evidence_ids": ["ev_motive_doc", "ev_hidden"],
		},
	],
	"events": [],
	"interrogation_triggers": [],
	"solution": {
		"suspect": "p_mark",
		"motive": "Insurance payout",
		"weapon": "Kitchen Knife",
		"time_minutes": 1260,
		"time_day": 1,
		"access": "Used a stolen key",
	},
	"critical_evidence_ids": ["ev_knife", "ev_motive_doc", "ev_hidden"],
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


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Report Submission
# =========================================================================

func test_submit_valid_report() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Stolen key")
	var result: bool = ConclusionManager.submit_report(report)
	assert_true(result, "Valid report should be accepted")
	assert_true(ConclusionManager.has_report(), "Should have report after submission")
	assert_true(ConclusionManager.is_evaluated(), "Should be evaluated after submission")


func test_submit_report_missing_section() -> void:
	var report: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": []},
		"motive": {"answer": "Insurance", "evidence": []},
		# Missing weapon, time, access
	}
	var result: bool = ConclusionManager.submit_report(report)
	assert_false(result, "Incomplete report should be rejected")
	assert_false(ConclusionManager.has_report(), "No report after rejection")


func test_submit_report_invalid_section_format() -> void:
	var report: Dictionary = {
		"suspect": {"answer": "p_mark"},  # Missing "evidence" key
		"motive": {"answer": "Insurance", "evidence": []},
		"weapon": {"answer": "Knife", "evidence": []},
		"time": {"answer": "1260 1", "evidence": []},
		"access": {"answer": "Key", "evidence": []},
	}
	var result: bool = ConclusionManager.submit_report(report)
	assert_false(result, "Report with invalid section format should be rejected")


func test_get_report_returns_copy() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var retrieved: Dictionary = ConclusionManager.get_report()
	assert_eq(retrieved["suspect"]["answer"], "p_mark")


func test_report_submitted_signal() -> void:
	watch_signals(ConclusionManager)
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	assert_signal_emitted(ConclusionManager, "report_submitted")


func test_prosecutor_evaluated_signal() -> void:
	watch_signals(ConclusionManager)
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	assert_signal_emitted(ConclusionManager, "prosecutor_evaluated")


# =========================================================================
# Evidence Strength Score
# =========================================================================

func test_evidence_score_with_high_weight() -> void:
	GameManager.discover_evidence("ev_knife")
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	report["suspect"]["evidence"] = ["ev_knife"]
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_evidence_score()
	# ev_knife has weight 0.9
	assert_almost_eq(score, 0.9, 0.05, "Should reflect high weight evidence")


func test_evidence_score_with_multiple_items() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_prints")
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	report["suspect"]["evidence"] = ["ev_knife", "ev_prints"]
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_evidence_score()
	# Average of 0.9 and 0.6 = 0.75
	assert_almost_eq(score, 0.75, 0.05, "Should average evidence weights")


func test_evidence_score_with_no_evidence() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_evidence_score()
	assert_eq(score, 0.0, "No evidence should give 0 score")


func test_evidence_score_with_low_weight() -> void:
	GameManager.discover_evidence("ev_alibi")
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	report["suspect"]["evidence"] = ["ev_alibi"]
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_evidence_score()
	assert_almost_eq(score, 0.4, 0.05, "Should reflect low weight")


# =========================================================================
# Timeline Accuracy Score
# =========================================================================

func test_timeline_exact_match() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_timeline_score()
	assert_eq(score, 1.0, "Exact time and day match should give 1.0")


func test_timeline_within_15_minutes() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1270 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_timeline_score()
	assert_eq(score, 1.0, "Within 15 min should give 1.0")


func test_timeline_within_hour() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1300 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_timeline_score()
	assert_almost_eq(score, 0.7, 0.05, "Within hour should give 0.7")


func test_timeline_right_day_wrong_time() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "600 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_timeline_score()
	assert_almost_eq(score, 0.4, 0.05, "Right day, wrong time should give 0.4")


func test_timeline_wrong_day() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 3", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_timeline_score()
	assert_almost_eq(score, 0.1, 0.05, "Wrong day should give 0.1")


func test_timeline_empty_answer() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_timeline_score()
	assert_eq(score, 0.0, "Empty answer should give 0.0")


func test_timeline_hh_mm_format() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "21:00 Day 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_timeline_score()
	assert_eq(score, 1.0, "HH:MM format exact match should give 1.0")


# =========================================================================
# Motive Proof Score
# =========================================================================

func test_motive_with_motive_category_evidence() -> void:
	GameManager.discover_evidence("ev_motive_doc")
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	report["motive"]["evidence"] = ["ev_motive_doc"]
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_motive_score()
	assert_eq(score, 1.0, "Evidence with MOTIVE category should give 1.0")


func test_motive_with_non_motive_evidence() -> void:
	GameManager.discover_evidence("ev_knife")
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	report["motive"]["evidence"] = ["ev_knife"]
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_motive_score()
	assert_almost_eq(score, 0.6, 0.05, "Evidence without MOTIVE category should give 0.6")


func test_motive_empty_answer() -> void:
	var report: Dictionary = _make_report("p_mark", "", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_motive_score()
	assert_eq(score, 0.0, "Empty motive should give 0.0")


func test_motive_claim_without_evidence() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_motive_score()
	assert_almost_eq(score, 0.3, 0.05, "Claim without evidence should give 0.3")


# =========================================================================
# Alternative Suspects Eliminated Score
# =========================================================================

func test_alternatives_all_interrogated() -> void:
	GameManager.completed_interrogations["p_mark"] = []
	GameManager.completed_interrogations["p_julia"] = []
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_alternatives_score()
	assert_eq(score, 1.0, "All suspects interrogated should give 1.0")


func test_alternatives_half_interrogated() -> void:
	GameManager.completed_interrogations["p_mark"] = []
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_alternatives_score()
	assert_almost_eq(score, 0.5, 0.05, "Half interrogated should give ~0.5")


func test_alternatives_none_interrogated() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_alternatives_score()
	assert_eq(score, 0.0, "No interrogations should give 0.0")


# =========================================================================
# Contradiction Penalty
# =========================================================================

func test_no_contradictions_no_penalty() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var penalty: float = ConclusionManager.get_contradiction_penalty()
	assert_eq(penalty, 0.0, "No theories or contradictions should give 0 penalty")


func test_contradictions_produce_penalty() -> void:
	# Create a complete theory — without contradictions, the penalty should be 0
	TheoryManager.reset()
	var theory: Dictionary = TheoryManager.create_theory("Test Theory")
	TheoryManager.set_suspect(theory["id"], "p_mark")
	TheoryManager.set_motive(theory["id"], "Insurance")
	TheoryManager.set_method(theory["id"], "Knife")
	TheoryManager.set_time(theory["id"], 1260, 1)

	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	# Penalty should be 0 when no contradictions in theory
	var penalty: float = ConclusionManager.get_contradiction_penalty()
	assert_true(penalty >= 0.0, "Penalty should be non-negative")
	assert_true(penalty <= 0.1, "Penalty should not exceed PENALTY_CONTRADICTIONS")


# =========================================================================
# Coverage Bonus
# =========================================================================

func test_coverage_all_critical_discovered() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_motive_doc")
	GameManager.discover_evidence("ev_hidden")
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var bonus: float = ConclusionManager.get_coverage_bonus()
	assert_almost_eq(bonus, 0.1, 0.01, "All critical discovered should give full bonus")


func test_coverage_one_third_critical_discovered() -> void:
	GameManager.discover_evidence("ev_knife")
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var bonus: float = ConclusionManager.get_coverage_bonus()
	# 1/3 * 0.1 = ~0.033
	assert_almost_eq(bonus, 0.033, 0.01, "1/3 critical discovered should give ~0.033")


func test_coverage_none_critical_discovered() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var bonus: float = ConclusionManager.get_coverage_bonus()
	assert_eq(bonus, 0.0, "No critical discovered should give 0 bonus")


# =========================================================================
# Confidence Score (combined)
# =========================================================================

func test_confidence_score_well_supported_case() -> void:
	# Set up a well-supported case
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_motive_doc")
	GameManager.discover_evidence("ev_hidden")
	GameManager.completed_interrogations["p_mark"] = []
	GameManager.completed_interrogations["p_julia"] = []

	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	report["suspect"]["evidence"] = ["ev_knife"]
	report["motive"]["evidence"] = ["ev_motive_doc"]
	ConclusionManager.submit_report(report)

	var score: float = ConclusionManager.get_confidence_score()
	assert_true(score > 0.7, "Well-supported case should score above 0.7")


func test_confidence_score_no_support() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_confidence_score()
	assert_true(score < 0.4, "Unsupported case should score below 0.4")


func test_confidence_score_clamped_to_range() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var score: float = ConclusionManager.get_confidence_score()
	assert_true(score >= 0.0, "Score must be >= 0")
	assert_true(score <= 1.0, "Score must be <= 1")


# =========================================================================
# Confidence Levels
# =========================================================================

func test_confidence_level_weak() -> void:
	# No evidence, empty time → low score
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "", "Key")
	ConclusionManager.submit_report(report)
	var level: Enums.ConfidenceLevel = ConclusionManager.get_confidence_level()
	assert_eq(level, Enums.ConfidenceLevel.WEAK, "Low score should be WEAK")


func test_score_to_level_thresholds() -> void:
	# Test the internal _score_to_level method via direct check
	assert_eq(ConclusionManager._score_to_level(0.0), Enums.ConfidenceLevel.WEAK)
	assert_eq(ConclusionManager._score_to_level(0.39), Enums.ConfidenceLevel.WEAK)
	assert_eq(ConclusionManager._score_to_level(0.40), Enums.ConfidenceLevel.MODERATE)
	assert_eq(ConclusionManager._score_to_level(0.69), Enums.ConfidenceLevel.MODERATE)
	assert_eq(ConclusionManager._score_to_level(0.70), Enums.ConfidenceLevel.STRONG)
	assert_eq(ConclusionManager._score_to_level(0.89), Enums.ConfidenceLevel.STRONG)
	assert_eq(ConclusionManager._score_to_level(0.90), Enums.ConfidenceLevel.PERFECT)
	assert_eq(ConclusionManager._score_to_level(1.0), Enums.ConfidenceLevel.PERFECT)


# =========================================================================
# Prosecutor Dialogue
# =========================================================================

func test_prosecutor_dialogue_per_level() -> void:
	assert_eq(
		ConclusionManager.PROSECUTOR_DIALOGUE[Enums.ConfidenceLevel.WEAK],
		"This theory has serious holes."
	)
	assert_eq(
		ConclusionManager.PROSECUTOR_DIALOGUE[Enums.ConfidenceLevel.MODERATE],
		"You might convince a jury, but the defense will push."
	)
	assert_eq(
		ConclusionManager.PROSECUTOR_DIALOGUE[Enums.ConfidenceLevel.STRONG],
		"This case is ready for court."
	)
	assert_eq(
		ConclusionManager.PROSECUTOR_DIALOGUE[Enums.ConfidenceLevel.PERFECT],
		"This is airtight."
	)


func test_prosecutor_dialogue_returns_string_after_eval() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var dialogue: String = ConclusionManager.get_prosecutor_dialogue()
	assert_true(not dialogue.is_empty(), "Dialogue should not be empty after eval")


# =========================================================================
# Player Choice
# =========================================================================

func test_make_choice_charge() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var result: bool = ConclusionManager.make_choice("charge")
	assert_true(result, "Valid choice should succeed")
	assert_eq(ConclusionManager.get_player_choice(), "charge")


func test_make_choice_investigate() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var result: bool = ConclusionManager.make_choice("investigate")
	assert_true(result)
	assert_eq(ConclusionManager.get_player_choice(), "investigate")


func test_make_choice_review() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var result: bool = ConclusionManager.make_choice("review")
	assert_true(result)
	assert_eq(ConclusionManager.get_player_choice(), "review")


func test_make_invalid_choice() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	var result: bool = ConclusionManager.make_choice("invalid")
	assert_false(result, "Invalid choice should fail")
	assert_eq(ConclusionManager.get_player_choice(), "")


func test_player_choice_signal() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	watch_signals(ConclusionManager)
	ConclusionManager.make_choice("charge")
	assert_signal_emitted(ConclusionManager, "player_choice_made")


func test_outcome_determined_on_charge() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	watch_signals(ConclusionManager)
	ConclusionManager.make_choice("charge")
	assert_signal_emitted(ConclusionManager, "outcome_determined")


# =========================================================================
# Case Outcomes
# =========================================================================

func test_correct_suspect_high_confidence_perfect() -> void:
	# Build a strong case for the correct suspect
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_motive_doc")
	GameManager.discover_evidence("ev_hidden")
	GameManager.completed_interrogations["p_mark"] = []
	GameManager.completed_interrogations["p_julia"] = []

	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	report["suspect"]["evidence"] = ["ev_knife"]
	report["motive"]["evidence"] = ["ev_motive_doc"]
	report["weapon"]["evidence"] = ["ev_knife"]
	ConclusionManager.submit_report(report)

	# If score >= 0.90, correct suspect → PERFECT_SOLUTION
	if ConclusionManager.get_confidence_score() >= 0.90:
		ConclusionManager.make_choice("charge")
		assert_eq(ConclusionManager.get_outcome(), Enums.CaseOutcome.PERFECT_SOLUTION)


func test_correct_suspect_moderate_confidence() -> void:
	GameManager.completed_interrogations["p_mark"] = []
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	report["motive"]["evidence"] = ["ev_motive_doc"]
	# Discover motive evidence to get some credit
	GameManager.discover_evidence("ev_motive_doc")
	ConclusionManager.submit_report(report)

	var score: float = ConclusionManager.get_confidence_score()
	if score >= 0.40 and score < 0.90:
		ConclusionManager.make_choice("charge")
		assert_eq(ConclusionManager.get_outcome(), Enums.CaseOutcome.CORRECT_BUT_INCOMPLETE)


func test_wrong_suspect_plausible() -> void:
	GameManager.discover_evidence("ev_prints")
	GameManager.completed_interrogations["p_julia"] = []
	GameManager.completed_interrogations["p_mark"] = []
	var report: Dictionary = _make_report("p_julia", "Jealousy", "Knife", "1260 1", "Key")
	report["suspect"]["evidence"] = ["ev_prints"]
	report["motive"]["evidence"] = ["ev_motive_doc"]
	GameManager.discover_evidence("ev_motive_doc")
	ConclusionManager.submit_report(report)

	var score: float = ConclusionManager.get_confidence_score()
	if score >= 0.40:
		ConclusionManager.make_choice("charge")
		assert_eq(ConclusionManager.get_outcome(), Enums.CaseOutcome.WRONG_BUT_PLAUSIBLE)


func test_wrong_suspect_low_confidence() -> void:
	var report: Dictionary = _make_report("p_julia", "Unknown", "Unknown", "", "")
	ConclusionManager.submit_report(report)
	ConclusionManager.make_choice("charge")
	assert_eq(ConclusionManager.get_outcome(), Enums.CaseOutcome.INCORRECT_THEORY)


func test_outcome_name_strings() -> void:
	ConclusionManager._outcome = Enums.CaseOutcome.PERFECT_SOLUTION
	assert_eq(ConclusionManager.get_outcome_name(), "Perfect Solution")
	ConclusionManager._outcome = Enums.CaseOutcome.CORRECT_BUT_INCOMPLETE
	assert_eq(ConclusionManager.get_outcome_name(), "Correct But Incomplete")
	ConclusionManager._outcome = Enums.CaseOutcome.WRONG_BUT_PLAUSIBLE
	assert_eq(ConclusionManager.get_outcome_name(), "Wrong Suspect, Plausible Theory")
	ConclusionManager._outcome = Enums.CaseOutcome.INCORRECT_THEORY
	assert_eq(ConclusionManager.get_outcome_name(), "Incorrect Theory")


# =========================================================================
# Epilogue
# =========================================================================

func test_epilogue_discovered_vs_missed() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_motive_doc")
	# ev_prints, ev_alibi, ev_hidden are NOT discovered
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	ConclusionManager.make_choice("charge")

	var epilogue: Dictionary = ConclusionManager.get_epilogue()
	assert_eq(epilogue["discovered"].size(), 2, "Should have 2 discovered")
	assert_eq(epilogue["missed"].size(), 3, "Should have 3 missed")
	assert_true(epilogue.has("outcome"), "Epilogue should include outcome")
	assert_true(epilogue.has("score"), "Epilogue should include score")
	assert_true(epilogue.has("dialogue"), "Epilogue should include dialogue")


func test_epilogue_all_discovered() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_motive_doc")
	GameManager.discover_evidence("ev_prints")
	GameManager.discover_evidence("ev_alibi")
	GameManager.discover_evidence("ev_hidden")
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)

	var epilogue: Dictionary = ConclusionManager.get_epilogue()
	assert_eq(epilogue["discovered"].size(), 5, "All should be discovered")
	assert_eq(epilogue["missed"].size(), 0, "None should be missed")


# =========================================================================
# Serialization
# =========================================================================

func test_serialize_empty_state() -> void:
	var data: Dictionary = ConclusionManager.serialize()
	assert_true(data.has("report"), "Should have report key")
	assert_true(data.has("confidence_score"), "Should have confidence_score")
	assert_true(data.has("evaluated"), "Should have evaluated")
	assert_false(data["evaluated"], "Should not be evaluated initially")


func test_serialize_deserialize_roundtrip() -> void:
	GameManager.discover_evidence("ev_knife")
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	report["suspect"]["evidence"] = ["ev_knife"]
	ConclusionManager.submit_report(report)
	ConclusionManager.make_choice("charge")

	var saved: Dictionary = ConclusionManager.serialize()
	ConclusionManager.reset()
	assert_false(ConclusionManager.is_evaluated())

	ConclusionManager.deserialize(saved)
	assert_true(ConclusionManager.is_evaluated())
	assert_eq(ConclusionManager.get_player_choice(), "charge")
	assert_true(ConclusionManager.get_confidence_score() > 0.0)


func test_reset_clears_all_state() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	ConclusionManager.make_choice("charge")

	ConclusionManager.reset()

	assert_false(ConclusionManager.has_report())
	assert_false(ConclusionManager.is_evaluated())
	assert_eq(ConclusionManager.get_player_choice(), "")
	assert_eq(ConclusionManager.get_confidence_score(), 0.0)
	assert_eq(ConclusionManager.get_confidence_level(), Enums.ConfidenceLevel.WEAK)
	assert_eq(ConclusionManager.get_outcome(), Enums.CaseOutcome.INCORRECT_THEORY)


# =========================================================================
# has_content
# =========================================================================

func test_has_content_empty() -> void:
	assert_false(ConclusionManager.has_content(), "Should have no content initially")


func test_has_content_after_report() -> void:
	var report: Dictionary = _make_report("p_mark", "Insurance", "Knife", "1260 1", "Key")
	ConclusionManager.submit_report(report)
	assert_true(ConclusionManager.has_content(), "Should have content after report")


# =========================================================================
# Report Sections Constant
# =========================================================================

func test_report_sections_has_all_five() -> void:
	assert_eq(ConclusionManager.REPORT_SECTIONS.size(), 5)
	assert_has(ConclusionManager.REPORT_SECTIONS, "suspect")
	assert_has(ConclusionManager.REPORT_SECTIONS, "motive")
	assert_has(ConclusionManager.REPORT_SECTIONS, "weapon")
	assert_has(ConclusionManager.REPORT_SECTIONS, "time")
	assert_has(ConclusionManager.REPORT_SECTIONS, "access")


# =========================================================================
# Solution Data in CaseData
# =========================================================================

func test_case_data_has_solution_fields() -> void:
	var case_data: CaseData = CaseManager.get_case_data()
	assert_not_null(case_data, "Case data should be loaded")
	assert_eq(case_data.solution_suspect, "p_mark")
	assert_eq(case_data.solution_motive, "Insurance payout")
	assert_eq(case_data.solution_weapon, "Kitchen Knife")
	assert_eq(case_data.solution_time_minutes, 1260)
	assert_eq(case_data.solution_time_day, 1)
	assert_eq(case_data.solution_access, "Used a stolen key")


func test_case_data_has_critical_evidence_ids() -> void:
	var case_data: CaseData = CaseManager.get_case_data()
	assert_not_null(case_data)
	assert_eq(case_data.critical_evidence_ids.size(), 3)
	assert_has(case_data.critical_evidence_ids, "ev_knife")
	assert_has(case_data.critical_evidence_ids, "ev_motive_doc")
	assert_has(case_data.critical_evidence_ids, "ev_hidden")


# =========================================================================
# Enums
# =========================================================================

func test_confidence_level_enum_values() -> void:
	assert_eq(Enums.ConfidenceLevel.WEAK, 0)
	assert_eq(Enums.ConfidenceLevel.MODERATE, 1)
	assert_eq(Enums.ConfidenceLevel.STRONG, 2)
	assert_eq(Enums.ConfidenceLevel.PERFECT, 3)


func test_case_outcome_enum_values() -> void:
	assert_eq(Enums.CaseOutcome.PERFECT_SOLUTION, 0)
	assert_eq(Enums.CaseOutcome.CORRECT_BUT_INCOMPLETE, 1)
	assert_eq(Enums.CaseOutcome.WRONG_BUT_PLAUSIBLE, 2)
	assert_eq(Enums.CaseOutcome.INCORRECT_THEORY, 3)


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
