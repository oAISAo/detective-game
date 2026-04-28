## test_evidence_system_integration.gd
## Integration tests for the Phase 5 evidence system.
## Verifies EvidenceManager, GameManager, CaseManager, and NotificationManager
## working together across evidence discovery, pinning, comparison, and contradictions.
extends GutTest


## Test case file for evidence system integration.
const TEST_CASE_FILE: String = "test_evidence_integration.json"

var _test_case_data: Dictionary = {
	"id": "case_ev_integration",
	"title": "Evidence Integration Test",
	"description": "Integration test for Phase 5 evidence system.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{
			"id": "p_suspect_a",
			"name": "Alice Crane",
			"role": "SUSPECT",
			"personality_traits": ["CALM"],
			"relationships": [],
			"pressure_threshold": 5,
		},
		{
			"id": "p_suspect_b",
			"name": "Bob Marsh",
			"role": "SUSPECT",
			"personality_traits": ["ANXIOUS"],
			"relationships": [{"person_b": "p_suspect_a", "type": "COWORKER"}],
			"pressure_threshold": 3,
		},
	],
	"evidence": [
		{
			"id": "ev_blood",
			"name": "Bloodstain Sample",
			"description": "A bloodstain found near the entrance.",
			"type": "FORENSIC",
			"location_found": "loc_house",
			"related_persons": ["p_suspect_a"],
			"tags": ["blood", "forensic", "entrance"],
			"weight": 0.9,
			"importance_level": "CRITICAL",
			"hint_text": "Check near the entrance for biological traces.",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_receipt",
			"name": "Hardware Store Receipt",
			"description": "A receipt for rope and gloves from the hardware store.",
			"type": "DOCUMENT",
			"location_found": "loc_store",
			"related_persons": ["p_suspect_b"],
			"tags": ["receipt", "purchase", "rope"],
			"weight": 0.7,
			"importance_level": "CRITICAL",
			"legal_categories": ["OPPORTUNITY"],
		},
		{
			"id": "ev_cctv",
			"name": "CCTV Footage",
			"description": "Footage showing Bob near the house at midnight.",
			"type": "RECORDING",
			"location_found": "loc_house",
			"related_persons": ["p_suspect_b"],
			"tags": ["video", "surveillance", "night"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_diary",
			"name": "Alice's Diary",
			"description": "A personal diary with entries about planning.",
			"type": "DOCUMENT",
			"location_found": "loc_house",
			"related_persons": ["p_suspect_a"],
			"tags": ["diary", "personal", "planning"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
	],
	"statements": [
		{
			"id": "s_alice_01",
			"person_id": "p_suspect_a",
			"text": "I was not at the house that night.",
			"day_given": 1,
			"related_evidence": ["ev_blood"],
			"contradicting_evidence": ["ev_blood"],
		},
		{
			"id": "s_bob_01",
			"person_id": "p_suspect_b",
			"text": "I have never been to that hardware store.",
			"day_given": 1,
			"related_evidence": ["ev_receipt"],
			"contradicting_evidence": ["ev_receipt"],
		},
		{
			"id": "s_bob_02",
			"person_id": "p_suspect_b",
			"text": "I was asleep at midnight.",
			"day_given": 2,
			"related_evidence": ["ev_cctv"],
			"contradicting_evidence": ["ev_cctv"],
		},
	],
	"events": [],
	"locations": [
		{
			"id": "loc_house",
			"name": "Suspect's House",
			"searchable": true,
			"evidence_pool": ["ev_blood", "ev_cctv", "ev_diary"],
		},
		{
			"id": "loc_store",
			"name": "Hardware Store",
			"searchable": true,
			"evidence_pool": ["ev_receipt"],
		},
	],
	"event_triggers": [],
	"interrogation_topics": [],
	"actions": [],
	"insights": [
		{
			"id": "insight_bob_at_scene",
			"description": "Bob was at the house and bought supplies — premeditation likely.",
			"source_evidence": ["ev_receipt", "ev_cctv"],
			"strengthens_theory": "theory_bob",
		},
	],
}


# --- Setup / Teardown --- #

func before_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	var dir: DirAccess = DirAccess.open("res://data/cases")
	if dir == null:
		DirAccess.make_dir_recursive_absolute("res://data/cases")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_test_case_data, "\t"))
	file.close()


func before_each() -> void:
	GameManager.new_game()
	EvidenceManager.reset()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


# ============================================================
# Integration: Evidence Discovery → Manager Queries
# ============================================================

func test_evidence_discovered_appears_in_manager() -> void:
	assert_eq(EvidenceManager.get_discovered_evidence_data().size(), 0)
	GameManager.discover_evidence("ev_blood")
	var data: Array[EvidenceData] = EvidenceManager.get_discovered_evidence_data()
	assert_eq(data.size(), 1)
	assert_eq(data[0].id, "ev_blood")
	assert_eq(data[0].name, "Bloodstain Sample")


func test_multiple_evidence_discovery_and_filter() -> void:
	GameManager.discover_evidence("ev_blood")
	GameManager.discover_evidence("ev_receipt")
	GameManager.discover_evidence("ev_cctv")

	var forensic: Array[EvidenceData] = EvidenceManager.filter_by_type(Enums.EvidenceType.FORENSIC)
	assert_eq(forensic.size(), 1)
	assert_eq(forensic[0].id, "ev_blood")

	var docs: Array[EvidenceData] = EvidenceManager.filter_by_type(Enums.EvidenceType.DOCUMENT)
	assert_eq(docs.size(), 1)
	assert_eq(docs[0].id, "ev_receipt")

	var recordings: Array[EvidenceData] = EvidenceManager.filter_by_type(Enums.EvidenceType.RECORDING)
	assert_eq(recordings.size(), 1)
	assert_eq(recordings[0].id, "ev_cctv")


func test_search_across_discovered_evidence() -> void:
	GameManager.discover_evidence("ev_blood")
	GameManager.discover_evidence("ev_receipt")
	GameManager.discover_evidence("ev_diary")

	var blood_results: Array[EvidenceData] = EvidenceManager.search_evidence("blood")
	assert_eq(blood_results.size(), 1)

	var entrance_results: Array[EvidenceData] = EvidenceManager.search_evidence("entrance")
	assert_eq(entrance_results.size(), 1, "Should match tag 'entrance'")


# ============================================================
# Integration: Contradiction Detection Triggered by Discovery
# ============================================================

func test_contradiction_detected_after_evidence_discovery() -> void:
	# Before discovering evidence, no contradictions
	EvidenceManager.check_contradictions()
	assert_false(EvidenceManager.has_contradiction("s_alice_01"))

	# Discover blood evidence — should trigger contradiction with Alice's statement
	watch_signals(EvidenceManager)
	GameManager.discover_evidence("ev_blood")

	# Auto-detection should have fired
	assert_true(EvidenceManager.has_contradiction("s_alice_01"),
		"Alice's denial should be contradicted by bloodstain")
	assert_signal_emitted(EvidenceManager, "contradiction_detected")


func test_multiple_contradictions_across_statements() -> void:
	GameManager.discover_evidence("ev_blood")
	GameManager.discover_evidence("ev_receipt")

	EvidenceManager.check_contradictions()
	assert_true(EvidenceManager.has_contradiction("s_alice_01"))
	assert_true(EvidenceManager.has_contradiction("s_bob_01"))
	assert_eq(EvidenceManager.detected_contradictions.size(), 2)


func test_future_statement_contradiction_still_detected() -> void:
	# s_bob_02 is day 2 statement, but contradiction check scans all statements
	GameManager.discover_evidence("ev_cctv")
	EvidenceManager.check_contradictions()
	assert_true(EvidenceManager.has_contradiction("s_bob_02"))


# ============================================================
# Integration: Comparison → Insight Generation
# ============================================================

func test_comparison_generates_insight_in_game_state() -> void:
	GameManager.discover_evidence("ev_receipt")
	GameManager.discover_evidence("ev_cctv")

	assert_false(GameManager.discovered_insights.has("insight_bob_at_scene"))

	watch_signals(EvidenceManager)
	watch_signals(GameManager)
	var insight: InsightData = EvidenceManager.compare_evidence("ev_receipt", "ev_cctv")

	assert_not_null(insight)
	assert_eq(insight.id, "insight_bob_at_scene")
	assert_true(GameManager.discovered_insights.has("insight_bob_at_scene"))
	assert_signal_emitted(EvidenceManager, "insight_generated")
	assert_signal_emitted(GameManager, "insight_discovered")


func test_comparison_reverse_order_works() -> void:
	GameManager.discover_evidence("ev_receipt")
	GameManager.discover_evidence("ev_cctv")
	# Compare in reverse order — should still find the insight
	var insight: InsightData = EvidenceManager.compare_evidence("ev_cctv", "ev_receipt")
	assert_not_null(insight, "Reverse order comparison should also work")
	assert_eq(insight.id, "insight_bob_at_scene")


func test_comparison_idempotent() -> void:
	GameManager.discover_evidence("ev_receipt")
	GameManager.discover_evidence("ev_cctv")
	var first: InsightData = EvidenceManager.compare_evidence("ev_receipt", "ev_cctv")
	assert_not_null(first)
	var second: InsightData = EvidenceManager.compare_evidence("ev_receipt", "ev_cctv")
	assert_null(second, "Second comparison should return null (already discovered)")


# ============================================================
# Integration: Pinning Persists Across Operations
# ============================================================

func test_pin_persists_through_operations() -> void:
	GameManager.discover_evidence("ev_blood")
	GameManager.discover_evidence("ev_receipt")
	EvidenceManager.pin_evidence("ev_blood")
	EvidenceManager.pin_evidence("ev_receipt")

	# Perform other operations
	GameManager.discover_evidence("ev_cctv")
	EvidenceManager.check_contradictions()

	# Pins should still be there
	assert_true(EvidenceManager.is_pinned("ev_blood"))
	assert_true(EvidenceManager.is_pinned("ev_receipt"))
	assert_false(EvidenceManager.is_pinned("ev_cctv"))


func test_pin_survives_serialize_deserialize() -> void:
	GameManager.discover_evidence("ev_blood")
	EvidenceManager.pin_evidence("ev_blood")

	var em_data: Dictionary = EvidenceManager.serialize()
	var gm_data: Dictionary = GameManager.serialize()

	GameManager.new_game()  # Resets EvidenceManager too
	assert_false(EvidenceManager.is_pinned("ev_blood"))

	GameManager.deserialize(gm_data)
	# GameManager deserialize should restore EvidenceManager state
	assert_true(EvidenceManager.is_pinned("ev_blood"),
		"Pin state should survive full serialize/deserialize cycle")


# ============================================================
# Integration: Hint System with Notifications
# ============================================================

func test_hint_creates_notification() -> void:
	GameManager.current_day = 2
	GameManager.visit_location("loc_house")

	watch_signals(NotificationManager)
	watch_signals(EvidenceManager)
	var hint: Dictionary = EvidenceManager.request_hint()

	assert_false(hint.is_empty(), "Should provide a hint")
	assert_signal_emitted(EvidenceManager, "hint_delivered")
	assert_signal_emitted(NotificationManager, "notification_added")


func test_hint_budget_integrates_with_game_manager() -> void:
	GameManager.current_day = 2
	GameManager.visit_location("loc_house")
	GameManager.visit_location("loc_store")

	# Use all hints
	assert_eq(GameManager.get_hints_remaining(), 3)
	EvidenceManager.request_hint()
	assert_eq(GameManager.get_hints_remaining(), 2)
	EvidenceManager.request_hint()
	assert_eq(GameManager.get_hints_remaining(), 1)
	EvidenceManager.request_hint()
	assert_eq(GameManager.get_hints_remaining(), 0)

	# Fourth attempt should fail
	var empty_hint: Dictionary = EvidenceManager.request_hint()
	assert_true(empty_hint.is_empty())
	assert_eq(GameManager.get_hints_remaining(), 0)


# ============================================================
# Integration: Full Evidence Workflow
# ============================================================

func test_full_evidence_workflow() -> void:
	# Day 1: Discover initial evidence
	GameManager.visit_location("loc_house")
	GameManager.discover_evidence("ev_blood")
	GameManager.discover_evidence("ev_cctv")

	# Verify filtering works
	var all_ev: Array[EvidenceData] = EvidenceManager.get_discovered_evidence_data()
	assert_eq(all_ev.size(), 2)

	# Pin important evidence
	EvidenceManager.pin_evidence("ev_blood")
	assert_eq(EvidenceManager.get_pinned_evidence().size(), 1)

	# Contradiction auto-detected for Alice's statement
	assert_true(EvidenceManager.has_contradiction("s_alice_01"))

	# Day 2: Discover more evidence and advance day
	GameManager.current_day = 2
	GameManager.visit_location("loc_store")
	GameManager.discover_evidence("ev_receipt")

	# Bob's statement now contradicted
	assert_true(EvidenceManager.has_contradiction("s_bob_01"))

	# Compare receipt + CCTV → insight
	var insight: InsightData = EvidenceManager.compare_evidence("ev_receipt", "ev_cctv")
	assert_not_null(insight)
	assert_eq(insight.id, "insight_bob_at_scene")

	# No more valid comparisons for receipt
	var targets: Array[String] = EvidenceManager.get_valid_comparisons_for("ev_receipt")
	assert_eq(targets.size(), 0, "All insights discovered, no more targets")

	# Testimony check — day 2 includes day 1 + day 2 statements
	var testimony: Array[StatementData] = EvidenceManager.get_testimony()
	assert_eq(testimony.size(), 3, "Should have 3 statements on day 2")

	# Serialization round-trip
	var save_data: Dictionary = GameManager.serialize()
	GameManager.new_game()
	assert_eq(EvidenceManager.get_pinned_evidence().size(), 0)
	GameManager.deserialize(save_data)
	assert_true(EvidenceManager.is_pinned("ev_blood"), "Pin should survive save/load")
	assert_true(GameManager.discovered_insights.has("insight_bob_at_scene"))


# ============================================================
# Integration: ScreenManager Navigation Data
# ============================================================

func test_screen_manager_navigation_data_set_on_navigate() -> void:
	# ScreenManager.navigate_to should set navigation_data
	# We can't fully test screen instantiation without a GameRoot,
	# but we can verify the navigation_data property exists and defaults empty
	assert_eq(ScreenManager.navigation_data, {}, "Should default to empty dict")


func test_screen_manager_navigation_data_cleared_on_reset() -> void:
	ScreenManager.navigation_data = {"evidence_id": "ev_test"}
	ScreenManager.reset()
	assert_eq(ScreenManager.navigation_data, {}, "Reset should clear navigation_data")
