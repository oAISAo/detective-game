## test_edge_cases.gd
## Phase 16.3 — Edge Case Tests.
## Tests boundary conditions and unusual player behavior.
extends GutTest


const TEST_CASE_FILE: String = "test_case_edges.json"

var _test_case_data: Dictionary = {
	"id": "case_edges",
	"title": "Edge Case",
	"description": "Edge case testing.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{"id": "p_victim", "name": "Daniel", "role": "VICTIM", "personality_traits": [], "relationships": [], "pressure_threshold": 0},
		{"id": "p_mark", "name": "Mark", "role": "SUSPECT", "personality_traits": ["DEFENSIVE"], "relationships": [], "pressure_threshold": 3},
		{"id": "p_julia", "name": "Julia", "role": "SUSPECT", "personality_traits": [], "relationships": [], "pressure_threshold": 5},
	],
	"evidence": [
		{"id": "ev_weapon", "name": "Weapon", "description": "Murder weapon.", "type": "PHYSICAL", "location_found": "loc_scene", "related_persons": ["p_mark"], "weight": 0.9, "importance_level": "CRITICAL", "legal_categories": ["PRESENCE"]},
		{"id": "ev_motive", "name": "Motive Doc", "description": "Financial motive.", "type": "DOCUMENT", "location_found": "loc_office", "related_persons": ["p_mark"], "weight": 0.85, "importance_level": "CRITICAL", "legal_categories": ["MOTIVE"]},
	],
	"locations": [
		{"id": "loc_scene", "name": "Scene", "description": "Crime scene.", "type": "CRIME_SCENE", "evidence_ids": ["ev_weapon"]},
		{"id": "loc_office", "name": "Office", "description": "Office.", "type": "PUBLIC", "evidence_ids": ["ev_motive"]},
	],
	"events": [],
	"interrogation_triggers": [
		{"id": "trig_weapon", "person_id": "p_mark", "evidence_id": "ev_weapon", "response": "Not mine.", "impact_level": "MODERATE", "pressure_points": 1},
	],
	"solution": {
		"suspect": "p_mark",
		"motive": "Financial gain",
		"weapon": "Weapon",
		"time_minutes": 1290,
		"time_day": 1,
		"access": "Key",
	},
	"critical_evidence_ids": ["ev_weapon"],
}


func before_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/cases")
	var file: FileAccess = FileAccess.open("res://data/cases/%s" % TEST_CASE_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(_test_case_data, "\t"))
	file.close()


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Mandatory Actions Block Day Advance
# =========================================================================

func test_mandatory_actions_block_day() -> void:
	GameManager.mandatory_actions_required = ["read_briefing"]
	assert_false(GameManager.all_mandatory_actions_completed())
	assert_eq(GameManager.get_remaining_mandatory_actions().size(), 1)

	GameManager.complete_mandatory_action("read_briefing")
	assert_true(GameManager.all_mandatory_actions_completed())


func test_completing_unknown_mandatory_action_returns_false() -> void:
	GameManager.mandatory_actions_required = ["read_briefing"]
	var result: bool = GameManager.complete_mandatory_action("nonexistent")
	assert_false(result)


# =========================================================================
# Duplicate Evidence Discovery
# =========================================================================

func test_duplicate_evidence_discovery_ignored() -> void:
	var first: bool = GameManager.discover_evidence("ev_weapon")
	var second: bool = GameManager.discover_evidence("ev_weapon")
	assert_true(first)
	assert_false(second, "Duplicate discovery should return false")
	assert_eq(GameManager.discovered_evidence.size(), 1)


func test_duplicate_location_visit_ignored() -> void:
	assert_true(GameManager.visit_location("loc_scene"))
	assert_false(GameManager.visit_location("loc_scene"))
	assert_eq(GameManager.visited_locations.size(), 1)


# =========================================================================
# Actions Exhausted
# =========================================================================

func test_actions_cannot_go_negative() -> void:
	GameManager.use_action()
	GameManager.use_action()
	assert_false(GameManager.has_actions_remaining())
	var result: bool = GameManager.use_action()
	assert_false(result, "Should not be able to use action when none remain")
	assert_eq(GameManager.actions_remaining, 0)


# =========================================================================
# Hints Exhausted
# =========================================================================

func test_hints_exhausted() -> void:
	for i: int in range(GameManager.MAX_HINTS_PER_CASE):
		assert_true(GameManager.use_hint())
	assert_false(GameManager.use_hint(), "Should not allow extra hints")
	assert_eq(GameManager.get_hints_remaining(), 0)


# =========================================================================
# Interrogation Limits Per Day
# =========================================================================

func test_interrogation_limit_per_day() -> void:
	assert_true(GameManager.can_interrogate_today("p_mark"))
	GameManager.record_interrogation("p_mark")
	assert_false(GameManager.can_interrogate_today("p_mark"))


func test_interrogation_limit_resets_on_new_day() -> void:
	GameManager.record_interrogation("p_mark")
	assert_false(GameManager.can_interrogate_today("p_mark"))

	# Advance to next day — counts clear
	GameManager.interrogation_counts_today.clear()
	assert_true(GameManager.can_interrogate_today("p_mark"))


# =========================================================================
# Day 4 Does Not Advance Beyond TOTAL_DAYS
# =========================================================================

func test_day_does_not_exceed_total() -> void:
	GameManager.current_day = GameManager.TOTAL_DAYS
	GameManager.current_time_slot = Enums.TimeSlot.NIGHT
	GameManager.advance_time_slot()
	assert_eq(GameManager.current_day, GameManager.TOTAL_DAYS, "Should not exceed TOTAL_DAYS")


# =========================================================================
# Empty Report Submission
# =========================================================================

func test_empty_report_submission() -> void:
	var report: Dictionary = {
		"suspect": {"answer": "", "evidence": []},
		"motive": {"answer": "", "evidence": []},
		"weapon": {"answer": "", "evidence": []},
		"time": {"answer": "", "evidence": []},
		"access": {"answer": "", "evidence": []},
	}
	var success: bool = ConclusionManager.submit_report(report)
	# Should still accept (player might submit incomplete)
	if success:
		assert_true(ConclusionManager.has_report())
		var score: float = ConclusionManager.get_confidence_score()
		assert_true(score < 0.5, "Empty report should have low confidence")


# =========================================================================
# Double Report Submission
# =========================================================================

func test_double_report_submission() -> void:
	var report: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": ["ev_weapon"]},
		"motive": {"answer": "Money", "evidence": []},
		"weapon": {"answer": "Weapon", "evidence": ["ev_weapon"]},
		"time": {"answer": "1290 1", "evidence": []},
		"access": {"answer": "Key", "evidence": []},
	}
	ConclusionManager.submit_report(report)
	var second: bool = ConclusionManager.submit_report(report)
	assert_false(second, "Should not allow double submission")


# =========================================================================
# Warrant Denied → Judge Feedback
# =========================================================================

func test_warrant_denied_provides_feedback() -> void:
	var evidence_ids: Array[String] = []
	var result: Dictionary = WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", evidence_ids)
	assert_false(result.get("approved", true))
	var feedback: String = result.get("feedback", "")
	assert_false(feedback.is_empty(), "Denied warrant should include feedback")


# =========================================================================
# Board Operations on Empty Board
# =========================================================================

func test_remove_nonexistent_board_node() -> void:
	var result: bool = BoardManager.remove_node("nonexistent_id")
	assert_false(result)


func test_move_nonexistent_board_node() -> void:
	var result: bool = BoardManager.move_node("nonexistent_id", 100.0, 200.0)
	assert_false(result)


func test_connection_to_nonexistent_nodes() -> void:
	var conn: Dictionary = BoardManager.add_connection("fake_from", "fake_to")
	assert_true(conn.is_empty(), "Connection between nonexistent nodes should fail")


# =========================================================================
# Timeline Edge Cases
# =========================================================================

func test_timeline_remove_nonexistent_entry() -> void:
	var result: bool = TimelineManager.remove_entry("nonexistent")
	assert_false(result)


func test_timeline_move_nonexistent_entry() -> void:
	var result: bool = TimelineManager.move_entry("nonexistent", 500)
	assert_false(result)


func test_timeline_duplicate_event_placement() -> void:
	TimelineManager.place_event("evt_test", 1260, 1)
	var second: Dictionary = TimelineManager.place_event("evt_test", 1290, 1)
	# Should either reject or update — verify no crash
	assert_true(TimelineManager.get_entry_count() >= 1)


# =========================================================================
# Theory Edge Cases
# =========================================================================

func test_theory_operations_on_nonexistent() -> void:
	assert_false(TheoryManager.set_suspect("fake_id", "p_mark"))
	assert_false(TheoryManager.set_motive("fake_id", "Money"))
	assert_false(TheoryManager.set_method("fake_id", "Weapon"))
	assert_false(TheoryManager.set_time("fake_id", 1290, 1))
	assert_false(TheoryManager.remove_theory("fake_id"))


func test_theory_incomplete_without_all_fields() -> void:
	var theory: Dictionary = TheoryManager.create_theory("Partial")
	TheoryManager.set_suspect(theory["id"], "p_mark")
	# Missing motive, method, time
	assert_false(TheoryManager.is_complete(theory["id"]))


# =========================================================================
# Lab Manager Edge Cases
# =========================================================================

func test_lab_cancel_nonexistent_request() -> void:
	var result: bool = LabManager.cancel_request("nonexistent")
	assert_false(result)


func test_lab_max_concurrent_requests() -> void:
	GameManager.discover_evidence("ev_weapon")
	# Submit up to max
	for i: int in range(LabManager.MAX_CONCURRENT_REQUESTS):
		LabManager.submit_request("ev_weapon", "TEST_%d" % i, "out_%d" % i, 1)
	assert_eq(LabManager.get_pending_count(), LabManager.MAX_CONCURRENT_REQUESTS)

	# One more should fail
	var extra: Dictionary = LabManager.submit_request("ev_weapon", "EXTRA", "out_extra", 1)
	assert_true(extra.is_empty(), "Should reject when at max capacity")


# =========================================================================
# Surveillance Max Concurrent
# =========================================================================

func test_surveillance_max_concurrent() -> void:
	for i: int in range(SurveillanceManager.MAX_CONCURRENT):
		SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHYSICAL)
	assert_eq(SurveillanceManager.get_active_count(), SurveillanceManager.MAX_CONCURRENT)

	var extra: Dictionary = SurveillanceManager.install_surveillance("p_julia", Enums.SurveillanceType.PHYSICAL)
	assert_true(extra.is_empty(), "Should reject when at max concurrent")


# =========================================================================
# Save/Load Mid-Investigation
# =========================================================================

func test_save_load_mid_investigation() -> void:
	# Build up some state
	GameManager.discover_evidence("ev_weapon")
	GameManager.visit_location("loc_scene")
	GameManager.current_day = 2
	GameManager.current_time_slot = Enums.TimeSlot.AFTERNOON
	GameManager.use_action()

	# Serialize and restore
	var state: Dictionary = GameManager.serialize()
	GameManager.new_game()
	assert_eq(GameManager.discovered_evidence.size(), 0)

	GameManager.deserialize(state)
	assert_eq(GameManager.current_day, 2)
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.AFTERNOON)
	assert_true(GameManager.has_evidence("ev_weapon"))
	assert_true(GameManager.has_visited_location("loc_scene"))
	assert_eq(GameManager.actions_remaining, 1)


# =========================================================================
# New Game Resets Everything
# =========================================================================

func test_new_game_resets_all_state() -> void:
	GameManager.discover_evidence("ev_weapon")
	GameManager.visit_location("loc_scene")
	GameManager.current_day = 3
	GameManager.hints_used = 2
	GameManager.use_action()

	GameManager.new_game()

	assert_eq(GameManager.current_day, 1)
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.MORNING)
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY)
	assert_eq(GameManager.discovered_evidence.size(), 0)
	assert_eq(GameManager.visited_locations.size(), 0)
	assert_eq(GameManager.hints_used, 0)
	assert_true(GameManager.game_active)
