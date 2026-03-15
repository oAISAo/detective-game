## test_warrant_manager.gd
## Unit tests for the WarrantManager autoload.
## Tests category validation, warrant approval/denial, judge feedback,
## arrest mechanics, and serialization.
extends GutTest


const TEST_CASE_FILE: String = "test_case_warrant.json"

var _test_case_data: Dictionary = {
	"id": "case_warrant_test",
	"title": "Warrant Test Case",
	"description": "Tests warrant manager.",
	"start_day": 1,
	"end_day": 5,
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
			"id": "ev_presence",
			"name": "CCTV Footage",
			"description": "Shows suspect at scene.",
			"type": "DIGITAL",
			"location_found": "loc_scene",
			"related_persons": ["p_mark"],
			"weight": 0.7,
			"importance_level": "KEY",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_motive",
			"name": "Insurance Policy",
			"description": "Large insurance payout.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": ["p_mark"],
			"weight": 0.8,
			"importance_level": "KEY",
			"legal_categories": ["MOTIVE"],
		},
		{
			"id": "ev_opportunity",
			"name": "Key Copy",
			"description": "Copy of victim's key.",
			"type": "PHYSICAL",
			"location_found": "loc_scene",
			"related_persons": ["p_mark"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
			"legal_categories": ["OPPORTUNITY"],
		},
		{
			"id": "ev_connection",
			"name": "Phone Records",
			"description": "Calls to victim before death.",
			"type": "DIGITAL",
			"location_found": "loc_office",
			"related_persons": ["p_mark"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
			"legal_categories": ["CONNECTION"],
		},
		{
			"id": "ev_multi",
			"name": "Witness Statement",
			"description": "Saw suspect with victim.",
			"type": "TESTIMONIAL",
			"location_found": "loc_scene",
			"related_persons": ["p_mark"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
			"legal_categories": ["PRESENCE", "OPPORTUNITY"],
		},
		{
			"id": "ev_no_cat",
			"name": "Random Note",
			"description": "Unrelated note.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": [],
			"weight": 0.1,
			"importance_level": "OPTIONAL",
			"legal_categories": [],
		},
	],
	"statements": [],
	"events": [],
	"locations": [
		{"id": "loc_scene", "name": "Crime Scene", "searchable": true, "evidence_pool": []},
		{"id": "loc_office", "name": "Office", "searchable": true, "evidence_pool": []},
	],
	"event_triggers": [],
	"interrogation_topics": [],
	"actions": [],
	"insights": [],
	"interrogation_triggers": [],
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
	WarrantManager.reset()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Legal Category Extraction
# =========================================================================

func test_get_evidence_categories_single() -> void:
	var ids: Array[String] = ["ev_presence"]
	var cats: Array[int] = WarrantManager.get_evidence_categories(ids)
	assert_eq(cats.size(), 1)
	assert_has(cats, Enums.LegalCategory.PRESENCE)


func test_get_evidence_categories_multiple_evidence() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	var cats: Array[int] = WarrantManager.get_evidence_categories(ids)
	assert_eq(cats.size(), 2)
	assert_has(cats, Enums.LegalCategory.PRESENCE)
	assert_has(cats, Enums.LegalCategory.MOTIVE)


func test_get_evidence_categories_deduplicates() -> void:
	var ids: Array[String] = ["ev_presence", "ev_multi"]
	var cats: Array[int] = WarrantManager.get_evidence_categories(ids)
	# ev_presence has PRESENCE, ev_multi has PRESENCE + OPPORTUNITY
	# After dedup: PRESENCE, OPPORTUNITY
	assert_eq(cats.size(), 2)


func test_get_evidence_categories_multi_category_evidence() -> void:
	var ids: Array[String] = ["ev_multi"]
	var cats: Array[int] = WarrantManager.get_evidence_categories(ids)
	assert_eq(cats.size(), 2, "One evidence can have multiple categories")
	assert_has(cats, Enums.LegalCategory.PRESENCE)
	assert_has(cats, Enums.LegalCategory.OPPORTUNITY)


func test_get_evidence_categories_no_categories() -> void:
	var ids: Array[String] = ["ev_no_cat"]
	var cats: Array[int] = WarrantManager.get_evidence_categories(ids)
	assert_eq(cats.size(), 0)


func test_get_evidence_categories_unknown_evidence_ignored() -> void:
	var ids: Array[String] = ["nonexistent"]
	var cats: Array[int] = WarrantManager.get_evidence_categories(ids)
	assert_eq(cats.size(), 0)


func test_get_category_count() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive", "ev_opportunity"]
	assert_eq(WarrantManager.get_category_count(ids), 3)


func test_get_required_categories() -> void:
	assert_eq(WarrantManager.get_required_categories(Enums.WarrantType.SEARCH), 2)
	assert_eq(WarrantManager.get_required_categories(Enums.WarrantType.SURVEILLANCE), 2)
	assert_eq(WarrantManager.get_required_categories(Enums.WarrantType.DIGITAL), 2)
	assert_eq(WarrantManager.get_required_categories(Enums.WarrantType.ARREST), 3)


# =========================================================================
# Warrant Approval
# =========================================================================

func test_warrant_approved_with_sufficient_categories() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_mark", ids
	)
	assert_true(result["approved"])
	assert_true(result["warrant_id"].begins_with("warrant_"))


func test_warrant_denied_with_insufficient_categories() -> void:
	var ids: Array[String] = ["ev_presence"]
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_mark", ids
	)
	assert_false(result["approved"])
	assert_false(result["feedback"].is_empty(), "Should have judge feedback")


func test_warrant_denied_with_no_evidence() -> void:
	var ids: Array[String] = []
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_mark", ids
	)
	assert_false(result["approved"])
	assert_true(result["feedback"].contains("haven't provided"), "Should mention no evidence")


func test_warrant_denied_with_no_category_evidence() -> void:
	var ids: Array[String] = ["ev_no_cat"]
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_mark", ids
	)
	assert_false(result["approved"])


func test_warrant_approved_emits_signal() -> void:
	watch_signals(WarrantManager)
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	assert_signal_emitted(WarrantManager, "warrant_approved")


func test_warrant_denied_emits_signal() -> void:
	watch_signals(WarrantManager)
	var ids: Array[String] = ["ev_presence"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	assert_signal_emitted(WarrantManager, "warrant_denied")


func test_warrant_approved_adds_to_game_manager() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_mark", ids
	)
	assert_has(GameManager.warrants_obtained, result["warrant_id"])


func test_warrant_denied_not_in_game_manager() -> void:
	var ids: Array[String] = ["ev_presence"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	assert_eq(GameManager.warrants_obtained.size(), 0)


func test_can_approve_warrant_true() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	assert_true(WarrantManager.can_approve_warrant(Enums.WarrantType.SEARCH, ids))


func test_can_approve_warrant_false() -> void:
	var ids: Array[String] = ["ev_presence"]
	assert_false(WarrantManager.can_approve_warrant(Enums.WarrantType.SEARCH, ids))


func test_arrest_warrant_requires_three_categories() -> void:
	var two_cats: Array[String] = ["ev_presence", "ev_motive"]
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.ARREST, "p_mark", two_cats
	)
	assert_false(result["approved"], "ARREST requires 3 categories")

	var three_cats: Array[String] = ["ev_presence", "ev_motive", "ev_opportunity"]
	var result2: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.ARREST, "p_mark", three_cats
	)
	assert_true(result2["approved"], "Should approve with 3 categories")


func test_warrant_with_multi_category_evidence() -> void:
	# ev_multi has PRESENCE + OPPORTUNITY = 2 categories from one piece
	var ids: Array[String] = ["ev_multi"]
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_mark", ids
	)
	assert_true(result["approved"], "Multi-category evidence should count")


func test_warrant_generates_unique_ids() -> void:
	var ids: Array[String] = ["ev_presence"]
	var r1: Dictionary = WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	var r2: Dictionary = WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	assert_ne(r1["warrant_id"], r2["warrant_id"])


# =========================================================================
# Judge Feedback
# =========================================================================

func test_judge_feedback_mentions_missing_categories() -> void:
	var ids: Array[String] = ["ev_presence"]
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_mark", ids
	)
	# Has PRESENCE, missing MOTIVE, OPPORTUNITY, CONNECTION
	assert_true(result["feedback"].contains("one more category"))


func test_judge_feedback_multiple_missing() -> void:
	var ids: Array[String] = ["ev_presence"]
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.ARREST, "p_mark", ids
	)
	# Needs 3, has 1, missing 2
	assert_true(result["feedback"].contains("2 more categories"))


func test_get_judge_feedback_sufficient_evidence() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	var feedback: String = WarrantManager.get_judge_feedback(Enums.WarrantType.SEARCH, ids)
	assert_true(feedback.contains("sufficient"))


func test_get_judge_feedback_insufficient_evidence() -> void:
	var ids: Array[String] = ["ev_presence"]
	var feedback: String = WarrantManager.get_judge_feedback(Enums.WarrantType.SEARCH, ids)
	assert_true(feedback.contains("one more category"))


func test_judge_feedback_suggests_category_names() -> void:
	var ids: Array[String] = ["ev_presence"]
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_mark", ids
	)
	# Should suggest missing categories by name
	var has_suggestion: bool = (
		result["feedback"].contains("Motive")
		or result["feedback"].contains("Opportunity")
		or result["feedback"].contains("Connection")
	)
	assert_true(has_suggestion, "Feedback should suggest missing category names")


# =========================================================================
# Arrest Mechanics
# =========================================================================

func test_arrest_suspect_with_sufficient_evidence() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive", "ev_opportunity"]
	var result: Dictionary = WarrantManager.arrest_suspect("p_mark", ids)
	assert_true(result["success"])
	assert_true(WarrantManager.is_arrested("p_mark"))


func test_arrest_suspect_insufficient_evidence() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	var result: Dictionary = WarrantManager.arrest_suspect("p_mark", ids)
	assert_false(result["success"])
	assert_false(WarrantManager.is_arrested("p_mark"))


func test_arrest_emits_signal() -> void:
	watch_signals(WarrantManager)
	var ids: Array[String] = ["ev_presence", "ev_motive", "ev_opportunity"]
	WarrantManager.arrest_suspect("p_mark", ids)
	assert_signal_emitted(WarrantManager, "suspect_arrested")


func test_arrest_already_arrested_fails() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive", "ev_opportunity"]
	WarrantManager.arrest_suspect("p_mark", ids)
	var result: Dictionary = WarrantManager.arrest_suspect("p_mark", ids)
	assert_false(result["success"])
	assert_true(result["feedback"].contains("already"))


func test_arrest_unknown_person_fails() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive", "ev_opportunity"]
	var result: Dictionary = WarrantManager.arrest_suspect("p_nonexistent", ids)
	assert_false(result["success"])
	assert_push_error("[WarrantManager] Person not found: p_nonexistent")


func test_get_arrested_suspects() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive", "ev_opportunity"]
	WarrantManager.arrest_suspect("p_mark", ids)
	var arrested: Array[String] = WarrantManager.get_arrested_suspects()
	assert_eq(arrested.size(), 1)
	assert_has(arrested, "p_mark")


func test_is_arrested_false_initially() -> void:
	assert_false(WarrantManager.is_arrested("p_mark"))


# =========================================================================
# Query
# =========================================================================

func test_get_warrant_returns_data() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_mark", ids
	)
	var warrant: Dictionary = WarrantManager.get_warrant(result["warrant_id"])
	assert_eq(warrant["type"], Enums.WarrantType.SEARCH)
	assert_eq(warrant["target"], "p_mark")
	assert_true(warrant["approved"])


func test_get_warrant_nonexistent_returns_empty() -> void:
	assert_true(WarrantManager.get_warrant("nonexistent").is_empty())


func test_get_approved_warrants() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	var approved: Array[Dictionary] = WarrantManager.get_approved_warrants()
	assert_eq(approved.size(), 1)


func test_get_denied_warrants() -> void:
	var ids: Array[String] = ["ev_presence"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	var denied: Array[Dictionary] = WarrantManager.get_denied_warrants()
	assert_eq(denied.size(), 1)


func test_get_warrant_count() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	WarrantManager.request_warrant(Enums.WarrantType.DIGITAL, "p_mark", ids)
	assert_eq(WarrantManager.get_warrant_count(), 2)


func test_has_content_false_initially() -> void:
	assert_false(WarrantManager.has_content())


func test_has_content_true_after_warrant() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	assert_true(WarrantManager.has_content())


func test_has_content_true_after_arrest() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive", "ev_opportunity"]
	WarrantManager.arrest_suspect("p_mark", ids)
	assert_true(WarrantManager.has_content())


# =========================================================================
# Serialization
# =========================================================================

func test_serialize_deserialize_round_trip() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	WarrantManager.request_warrant(Enums.WarrantType.DIGITAL, "p_mark", ids)

	var data: Dictionary = WarrantManager.serialize()
	WarrantManager.reset()
	assert_eq(WarrantManager.get_warrant_count(), 0)

	WarrantManager.deserialize(data)
	assert_eq(WarrantManager.get_warrant_count(), 2)


func test_serialize_preserves_arrests() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive", "ev_opportunity"]
	WarrantManager.arrest_suspect("p_mark", ids)

	var data: Dictionary = WarrantManager.serialize()
	WarrantManager.reset()
	WarrantManager.deserialize(data)
	assert_true(WarrantManager.is_arrested("p_mark"))


func test_serialize_preserves_denied() -> void:
	var ids: Array[String] = ["ev_presence"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)

	var data: Dictionary = WarrantManager.serialize()
	WarrantManager.reset()
	WarrantManager.deserialize(data)
	assert_eq(WarrantManager.get_denied_warrants().size(), 1)


func test_reset_clears_all_state() -> void:
	var ids: Array[String] = ["ev_presence", "ev_motive"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	WarrantManager.reset()
	assert_eq(WarrantManager.get_warrant_count(), 0)
	assert_false(WarrantManager.has_content())
	assert_eq(WarrantManager.get_arrested_suspects().size(), 0)
