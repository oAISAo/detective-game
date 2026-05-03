## test_evidence_manager.gd
## Unit tests for the EvidenceManager autoload singleton.
## Phase 5: Verify filtering, search, pinning, comparison, contradictions, hints, serialization.
extends GutTest


## Path to the test case JSON file.
const TEST_CASE_FILE: String = "test_evidence.json"

## Comprehensive test case data for Phase 5 evidence system testing.
var _test_case_data: Dictionary = {
	"id": "case_evidence_test",
	"title": "Evidence System Test Case",
	"description": "Test case for Phase 5 evidence system.",
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
			"description": "A partial fingerprint found on a wine glass at the crime scene.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": ["p_julia"],
			"tags": ["fingerprint", "kitchen", "forensic"],
			"weight": 0.8,
			"importance_level": "CRITICAL",
			"hint_text": "Did you check the wine glasses in the kitchen?",
			"legal_categories": ["PRESENCE"],
			"linked_statements": ["s_julia_01"],
		},
		{
			"id": "ev_camera",
			"name": "Parking Camera Footage",
			"description": "Security camera footage from the parking lot showing vehicle movements.",
			"type": "RECORDING",
			"location_found": "loc_parking",
			"related_persons": ["p_mark"],
			"tags": ["camera", "parking", "video"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_document",
			"name": "Financial Records",
			"description": "Records showing irregular transactions between Mark and the victim.",
			"type": "FINANCIAL",
			"location_found": "loc_office",
			"related_persons": ["p_mark", "p_victim"],
			"tags": ["financial", "money", "records"],
			"weight": 0.7,
			"importance_level": "CRITICAL",
			"hint_text": "Look at the victim's financial records more closely.",
			"legal_categories": ["MOTIVE"],
		},
		{
			"id": "ev_photo",
			"name": "Crime Scene Photo",
			"description": "A photograph of the crime scene showing the position of the body.",
			"type": "PHOTO",
			"location_found": "loc_apartment",
			"related_persons": ["p_victim"],
			"tags": ["photo", "crime scene"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_phone",
			"name": "Victim's Phone Records",
			"description": "Call logs showing frequent calls between the victim and Julia.",
			"type": "DIGITAL",
			"location_found": "loc_office",
			"related_persons": ["p_julia", "p_victim"],
			"tags": ["phone", "digital", "calls"],
			"weight": 0.4,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_knife",
			"name": "Kitchen Knife",
			"description": "A knife found hidden in the kitchen drawer with traces of blood.",
			"type": "OBJECT",
			"location_found": "loc_apartment",
			"related_persons": [],
			"tags": ["weapon", "kitchen", "blood"],
			"weight": 0.9,
			"importance_level": "CRITICAL",
			"requires_lab_analysis": true,
			"hint_text": "The technician says there might be something hidden in the kitchen drawers.",
			"legal_categories": ["OPPORTUNITY"],
		},
		{
			"id": "ev_letter",
			"name": "Threatening Letter",
			"description": "A handwritten letter threatening the victim.",
			"type": "DOCUMENT",
			"location_found": "loc_apartment",
			"related_persons": ["p_victim"],
			"tags": ["letter", "threat", "handwritten"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_knife_result",
			"name": "Blood DNA Analysis",
			"description": "DNA extracted from blood traces on the kitchen knife.",
			"type": "FORENSIC",
			"location_found": "",
			"related_persons": [],
			"tags": ["forensic", "dna"],
			"weight": 0.95,
			"importance_level": "CRITICAL",
		},
	],
	"statements": [
		{
			"id": "s_julia_01",
			"person_id": "p_julia",
			"text": "I was home all evening. I never left the apartment.",
			"day_given": 1,
			"related_evidence": ["ev_fingerprint"],
			"contradicting_evidence": ["ev_camera"],
		},
		{
			"id": "s_mark_01",
			"person_id": "p_mark",
			"text": "I left the office at 19:30 and went straight home.",
			"day_given": 1,
			"related_evidence": ["ev_camera"],
			"contradicting_evidence": ["ev_camera"],
		},
		{
			"id": "s_julia_02",
			"person_id": "p_julia",
			"text": "I never entered the kitchen that night.",
			"day_given": 2,
			"related_evidence": ["ev_knife"],
			"contradicting_evidence": ["ev_fingerprint"],
		},
		{
			"id": "s_mark_02",
			"person_id": "p_mark",
			"text": "I had no financial dealings with Daniel.",
			"day_given": 3,
			"related_evidence": ["ev_document"],
			"contradicting_evidence": ["ev_document"],
		},
	],
	"events": [],
	"locations": [
		{
			"id": "loc_apartment",
			"name": "Victim's Apartment",
			"searchable": true,
			"evidence_pool": ["ev_fingerprint", "ev_photo", "ev_knife", "ev_letter"],
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
			"evidence_pool": ["ev_document", "ev_phone"],
		},
	],
	"event_triggers": [],
	"interrogation_topics": [],
	"actions": [],
	"insights": [
		{
			"id": "insight_alibi_lie",
			"description": "Julia lied about being home — the parking camera shows her car leaving.",
			"source_evidence": ["ev_camera", "ev_fingerprint"],
			"strengthens_theory": "theory_julia",
		},
		{
			"id": "insight_financial_motive",
			"description": "Mark had a motive — irregular financial transactions suggest embezzlement.",
			"source_evidence": ["ev_document", "ev_phone"],
			"strengthens_theory": "theory_mark",
		},
	],
	"lab_requests": [
		{
			"id": "lab_knife_dna",
			"input_evidence_id": "ev_knife",
			"output_evidence_id": "ev_knife_result",
			"analysis_type": "dna",
			"day_submitted": 1,
			"completion_day": 2,
			"lab_transform": "derive",
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
# §5.1 — Discovered Evidence Data
# ============================================================

func test_get_discovered_evidence_data_empty_initially() -> void:
	var data: Array[EvidenceData] = EvidenceManager.get_discovered_evidence_data()
	assert_eq(data.size(), 0, "Should return empty array when no evidence discovered")


func test_get_discovered_evidence_data_returns_discovered() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_evidence("ev_camera")
	var data: Array[EvidenceData] = EvidenceManager.get_discovered_evidence_data()
	assert_eq(data.size(), 2, "Should return 2 discovered evidence items")
	var ids: Array[String] = []
	for ev: EvidenceData in data:
		ids.append(ev.id)
	assert_has(ids, "ev_fingerprint")
	assert_has(ids, "ev_camera")


func test_get_discovered_evidence_data_ignores_unknown_ids() -> void:
	GameManager.discover_evidence("ev_nonexistent")
	var data: Array[EvidenceData] = EvidenceManager.get_discovered_evidence_data()
	assert_eq(data.size(), 0, "Should ignore evidence IDs not found in CaseManager")


# ============================================================
# §5.1 — Filtering by Type
# ============================================================

func test_filter_by_type_forensic() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_evidence("ev_camera")
	GameManager.discover_evidence("ev_photo")
	var result: Array[EvidenceData] = EvidenceManager.filter_by_type(Enums.EvidenceType.FORENSIC)
	assert_eq(result.size(), 1, "Should find 1 forensic evidence")
	assert_eq(result[0].id, "ev_fingerprint")


func test_filter_by_type_returns_empty_for_no_match() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	var result: Array[EvidenceData] = EvidenceManager.filter_by_type(Enums.EvidenceType.FINANCIAL)
	assert_eq(result.size(), 0, "Should return empty when no match")


func test_filter_by_type_document() -> void:
	GameManager.discover_evidence("ev_letter")
	GameManager.discover_evidence("ev_document")
	var result: Array[EvidenceData] = EvidenceManager.filter_by_type(Enums.EvidenceType.DOCUMENT)
	assert_eq(result.size(), 1, "Should find 1 document evidence")
	assert_eq(result[0].id, "ev_letter")


func test_filter_by_type_multiple_results() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_evidence("ev_photo")
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_letter")
	# ev_fingerprint, ev_photo, ev_knife, ev_letter are at loc_apartment
	# Filter by PHOTO should find ev_photo only
	var result: Array[EvidenceData] = EvidenceManager.filter_by_type(Enums.EvidenceType.PHOTO)
	assert_eq(result.size(), 1)
	assert_eq(result[0].id, "ev_photo")


# ============================================================
# §5.1 — Search
# ============================================================

func test_search_by_name() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_evidence("ev_camera")
	var result: Array[EvidenceData] = EvidenceManager.search_evidence("fingerprint")
	assert_eq(result.size(), 1, "Should find by name")
	assert_eq(result[0].id, "ev_fingerprint")


func test_search_by_description() -> void:
	GameManager.discover_evidence("ev_document")
	var result: Array[EvidenceData] = EvidenceManager.search_evidence("irregular transactions")
	assert_eq(result.size(), 1, "Should find by description")
	assert_eq(result[0].id, "ev_document")


func test_search_does_not_match_tag_only_query() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_camera")
	var result: Array[EvidenceData] = EvidenceManager.search_evidence("weapon")
	assert_eq(result.size(), 0, "Search should no longer match tag-only queries")


func test_search_empty_query_returns_all() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_evidence("ev_camera")
	var result: Array[EvidenceData] = EvidenceManager.search_evidence("")
	assert_eq(result.size(), 2, "Empty query should return all discovered")


func test_search_no_match_returns_empty() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	var result: Array[EvidenceData] = EvidenceManager.search_evidence("zzz_nonexistent")
	assert_eq(result.size(), 0, "Should return empty for no match")


func test_search_case_insensitive() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	var result: Array[EvidenceData] = EvidenceManager.search_evidence("FINGERPRINT")
	assert_eq(result.size(), 1, "Search should be case-insensitive")
	assert_eq(result[0].id, "ev_fingerprint")


# ============================================================
# §5.3 — Pinning
# ============================================================

func test_pin_evidence_succeeds() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	var result: bool = EvidenceManager.pin_evidence("ev_fingerprint")
	assert_true(result, "Pinning discovered evidence should succeed")
	assert_true(EvidenceManager.is_pinned("ev_fingerprint"))


func test_pin_evidence_already_pinned_returns_false() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_fingerprint")
	var result: bool = EvidenceManager.pin_evidence("ev_fingerprint")
	assert_false(result, "Double pin should return false")


func test_pin_evidence_max_reached() -> void:
	for ev_id: String in ["ev_fingerprint", "ev_camera", "ev_document", "ev_photo", "ev_phone"]:
		GameManager.discover_evidence(ev_id)
		EvidenceManager.pin_evidence(ev_id)
	assert_eq(EvidenceManager.get_pinned_evidence().size(), 5, "Should have 5 pinned")
	GameManager.discover_evidence("ev_knife")
	var result: bool = EvidenceManager.pin_evidence("ev_knife")
	assert_false(result, "Should fail when max pinned reached")
	assert_push_warning("[EvidenceManager] Cannot pin — maximum 5 items reached.")


func test_pin_undiscovered_evidence_fails() -> void:
	var result: bool = EvidenceManager.pin_evidence("ev_fingerprint")
	assert_false(result, "Should fail for undiscovered evidence")
	assert_push_error("[EvidenceManager] Cannot pin undiscovered evidence: ev_fingerprint")


func test_unpin_evidence_succeeds() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_fingerprint")
	var result: bool = EvidenceManager.unpin_evidence("ev_fingerprint")
	assert_true(result, "Unpinning should succeed")
	assert_false(EvidenceManager.is_pinned("ev_fingerprint"))


func test_unpin_not_pinned_returns_false() -> void:
	var result: bool = EvidenceManager.unpin_evidence("ev_fingerprint")
	assert_false(result, "Unpinning non-pinned should return false")


func test_is_pinned() -> void:
	assert_false(EvidenceManager.is_pinned("ev_fingerprint"))
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_fingerprint")
	assert_true(EvidenceManager.is_pinned("ev_fingerprint"))
	assert_false(EvidenceManager.is_pinned("ev_camera"))


func test_get_pinned_evidence_returns_duplicate() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_fingerprint")
	var pinned: Array[String] = EvidenceManager.get_pinned_evidence()
	pinned.append("fake_id")
	assert_eq(EvidenceManager.get_pinned_evidence().size(), 1, "Should not affect internal state")


func test_get_pinned_evidence_data() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_evidence("ev_camera")
	EvidenceManager.pin_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_camera")
	var data: Array[EvidenceData] = EvidenceManager.get_pinned_evidence_data()
	assert_eq(data.size(), 2, "Should return 2 pinned evidence data items")


func test_pin_emits_signal() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	watch_signals(EvidenceManager)
	EvidenceManager.pin_evidence("ev_fingerprint")
	assert_signal_emitted_with_parameters(EvidenceManager, "evidence_pinned", ["ev_fingerprint"])


func test_unpin_emits_signal() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_fingerprint")
	watch_signals(EvidenceManager)
	EvidenceManager.unpin_evidence("ev_fingerprint")
	assert_signal_emitted_with_parameters(EvidenceManager, "evidence_unpinned", ["ev_fingerprint"])


# ============================================================
# §5.4 — Comparison
# ============================================================

func test_compare_evidence_valid_pair_returns_insight() -> void:
	GameManager.discover_evidence("ev_camera")
	GameManager.discover_evidence("ev_fingerprint")
	var insight: InsightData = EvidenceManager.compare_evidence("ev_camera", "ev_fingerprint")
	assert_not_null(insight, "Should return an InsightData for a valid pair")
	assert_eq(insight.id, "insight_alibi_lie")


func test_compare_evidence_invalid_pair_returns_null() -> void:
	GameManager.discover_evidence("ev_camera")
	GameManager.discover_evidence("ev_knife")
	var insight: InsightData = EvidenceManager.compare_evidence("ev_camera", "ev_knife")
	assert_null(insight, "Should return null for a pair with no matching insight")


func test_compare_evidence_already_discovered_returns_null() -> void:
	GameManager.discover_evidence("ev_camera")
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_insight("insight_alibi_lie")
	var insight: InsightData = EvidenceManager.compare_evidence("ev_camera", "ev_fingerprint")
	assert_null(insight, "Should return null if insight already discovered")


func test_compare_evidence_emits_signal() -> void:
	GameManager.discover_evidence("ev_camera")
	GameManager.discover_evidence("ev_fingerprint")
	watch_signals(EvidenceManager)
	EvidenceManager.compare_evidence("ev_camera", "ev_fingerprint")
	assert_signal_emitted_with_parameters(EvidenceManager, "insight_generated", ["insight_alibi_lie"])


func test_compare_evidence_discovers_insight_in_game_state() -> void:
	GameManager.discover_evidence("ev_camera")
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.compare_evidence("ev_camera", "ev_fingerprint")
	assert_true(GameManager.discovered_insights.has("insight_alibi_lie"),
		"Insight should be added to GameManager.discovered_insights")


func test_compare_evidence_second_pair() -> void:
	GameManager.discover_evidence("ev_document")
	GameManager.discover_evidence("ev_phone")
	var insight: InsightData = EvidenceManager.compare_evidence("ev_document", "ev_phone")
	assert_not_null(insight)
	assert_eq(insight.id, "insight_financial_motive")


func test_get_valid_comparisons_for() -> void:
	GameManager.discover_evidence("ev_camera")
	GameManager.discover_evidence("ev_fingerprint")
	var targets: Array[String] = EvidenceManager.get_valid_comparisons_for("ev_camera")
	assert_eq(targets.size(), 1, "Should find 1 valid comparison target")
	assert_eq(targets[0], "ev_fingerprint")


func test_get_valid_comparisons_excludes_already_discovered() -> void:
	GameManager.discover_evidence("ev_camera")
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_insight("insight_alibi_lie")
	var targets: Array[String] = EvidenceManager.get_valid_comparisons_for("ev_camera")
	assert_eq(targets.size(), 0, "Should exclude already-discovered insight targets")


func test_get_valid_comparisons_excludes_undiscovered_evidence() -> void:
	GameManager.discover_evidence("ev_camera")
	# ev_fingerprint not discovered yet
	var targets: Array[String] = EvidenceManager.get_valid_comparisons_for("ev_camera")
	assert_eq(targets.size(), 0, "Should exclude undiscovered evidence from targets")


# ============================================================
# §5.5 — Testimony
# ============================================================

func test_get_testimony_returns_current_day_statements() -> void:
	# Day 1 — should see s_julia_01 and s_mark_01
	var testimony: Array[StatementData] = EvidenceManager.get_testimony()
	assert_eq(testimony.size(), 2, "Should return 2 day-1 statements on day 1")


func test_get_testimony_excludes_future_statements() -> void:
	# Day 1 — s_julia_02 is day 2, s_mark_02 is day 3
	var testimony: Array[StatementData] = EvidenceManager.get_testimony()
	var ids: Array[String] = []
	for stmt: StatementData in testimony:
		ids.append(stmt.id)
	assert_does_not_have(ids, "s_julia_02")
	assert_does_not_have(ids, "s_mark_02")


func test_get_testimony_includes_past_days() -> void:
	# Advance to day 2
	GameManager.current_day = 2
	var testimony: Array[StatementData] = EvidenceManager.get_testimony()
	assert_eq(testimony.size(), 3, "Day 2 should include day-1 and day-2 statements")


func test_get_testimony_all_days() -> void:
	GameManager.current_day = 3
	var testimony: Array[StatementData] = EvidenceManager.get_testimony()
	assert_eq(testimony.size(), 4, "Day 3 should include all 4 statements")


# ============================================================
# §5.5 — Contradictions
# ============================================================

func test_check_contradictions_finds_matches() -> void:
	GameManager.discover_evidence("ev_camera")
	var result: Array[Dictionary] = EvidenceManager.check_contradictions()
	# s_julia_01 contradicted by ev_camera, s_mark_01 contradicted by ev_camera
	assert_eq(result.size(), 2, "Should find 2 contradictions for ev_camera")


func test_check_contradictions_empty_when_no_evidence() -> void:
	var result: Array[Dictionary] = EvidenceManager.check_contradictions()
	assert_eq(result.size(), 0, "Should find no contradictions without evidence")


func test_check_contradictions_specific_evidence() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	var result: Array[Dictionary] = EvidenceManager.check_contradictions()
	# Only s_julia_02 has ev_fingerprint in contradicting_evidence
	assert_eq(result.size(), 1, "ev_fingerprint should contradict 1 statement")
	assert_eq(result[0].get("statement_id", ""), "s_julia_02")


func test_has_contradiction_true() -> void:
	GameManager.discover_evidence("ev_camera")
	EvidenceManager.check_contradictions()
	assert_true(EvidenceManager.has_contradiction("s_julia_01"))
	assert_true(EvidenceManager.has_contradiction("s_mark_01"))


func test_has_contradiction_false() -> void:
	GameManager.discover_evidence("ev_camera")
	EvidenceManager.check_contradictions()
	assert_false(EvidenceManager.has_contradiction("s_julia_02"))


func test_get_contradictions_for_statement() -> void:
	GameManager.discover_evidence("ev_camera")
	EvidenceManager.check_contradictions()
	var contradictions: Array[Dictionary] = EvidenceManager.get_contradictions_for_statement("s_julia_01")
	assert_eq(contradictions.size(), 1, "Should have 1 contradiction for s_julia_01")
	assert_eq(contradictions[0].get("evidence_id", ""), "ev_camera")


func test_contradiction_detected_on_evidence_discovery() -> void:
	# The auto-detection should fire when evidence is discovered
	watch_signals(EvidenceManager)
	GameManager.discover_evidence("ev_camera")
	# Allow signal propagation (since _on_evidence_discovered connects to evidence_discovered)
	assert_signal_emitted(EvidenceManager, "contradiction_detected")


func test_contradiction_respects_day_scope() -> void:
	# s_julia_02 is day 2 — but contradicting_evidence is ev_fingerprint
	# s_julia_02's contradicting_evidence contains ev_fingerprint
	# check_contradictions scans ALL statements, not just testimony
	GameManager.discover_evidence("ev_fingerprint")
	var result: Array[Dictionary] = EvidenceManager.check_contradictions()
	# s_julia_02 has contradicting_evidence: ["ev_fingerprint"] — scanned even if day_given=2
	assert_eq(result.size(), 1)
	assert_eq(result[0].get("statement_id", ""), "s_julia_02")


# ============================================================
# §5.6 — Progressive Discovery Hints
# ============================================================

func test_request_hint_succeeds() -> void:
	# Need: day >= 2, location visited, critical evidence missing
	GameManager.current_day = 2
	GameManager.visit_location("loc_apartment")
	# ev_fingerprint is CRITICAL, at loc_apartment, not yet discovered
	var hint: Dictionary = EvidenceManager.request_hint()
	assert_false(hint.is_empty(), "Should return a valid hint")
	assert_eq(hint.get("text", ""), "Did you check the wine glasses in the kitchen?")
	assert_eq(hint.get("source", ""), "Technician")
	assert_eq(hint.get("target_evidence", ""), "ev_fingerprint")


func test_request_hint_budget_exceeded() -> void:
	GameManager.current_day = 2
	GameManager.visit_location("loc_apartment")
	# Use all 3 hints
	GameManager.hints_used = GameManager.MAX_HINTS_PER_CASE
	var hint: Dictionary = EvidenceManager.request_hint()
	assert_true(hint.is_empty(), "Should return empty when budget exceeded")


func test_request_hint_no_critical_missing() -> void:
	GameManager.current_day = 2
	GameManager.visit_location("loc_apartment")
	GameManager.visit_location("loc_office")
	# Discover all critical evidence
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_evidence("ev_document")
	GameManager.discover_evidence("ev_knife")
	var hint: Dictionary = EvidenceManager.request_hint()
	assert_true(hint.is_empty(), "Should return empty when no critical evidence missing")


func test_request_hint_day_too_early() -> void:
	# Day 1 — hints require day >= 2
	GameManager.visit_location("loc_apartment")
	var hint: Dictionary = EvidenceManager.request_hint()
	assert_true(hint.is_empty(), "Should return empty on day 1")
	# Hint budget should NOT have been consumed (refunded)
	assert_eq(GameManager.hints_used, 0, "Hint should be refunded when no hint available")


func test_request_hint_location_not_visited() -> void:
	GameManager.current_day = 2
	# Don't visit loc_apartment — ev_fingerprint is there
	var hint: Dictionary = EvidenceManager.request_hint()
	assert_true(hint.is_empty(), "Should return empty when location not visited")


func test_request_hint_emits_signal() -> void:
	GameManager.current_day = 2
	GameManager.visit_location("loc_apartment")
	watch_signals(EvidenceManager)
	EvidenceManager.request_hint()
	assert_signal_emitted(EvidenceManager, "hint_delivered")


func test_request_hint_custom_text() -> void:
	GameManager.current_day = 2
	GameManager.visit_location("loc_apartment")
	# ev_fingerprint has custom hint_text
	var hint: Dictionary = EvidenceManager.request_hint()
	assert_string_contains(hint.get("text", ""), "wine glasses")


func test_request_hint_generic_text_when_no_custom() -> void:
	GameManager.current_day = 2
	# Discover ev_fingerprint and ev_knife (both critical at loc_apartment)
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_evidence("ev_knife")
	GameManager.visit_location("loc_office")
	# ev_document is CRITICAL at loc_office with hint_text set
	var hint: Dictionary = EvidenceManager.request_hint()
	assert_false(hint.is_empty())
	assert_eq(hint.get("target_evidence", ""), "ev_document")


# ============================================================
# §5.1 — Evidence Weight Validation
# ============================================================

func test_evidence_weight_within_valid_range() -> void:
	var all_ev: Array[EvidenceData] = CaseManager.get_all_evidence()
	for ev: EvidenceData in all_ev:
		assert_true(ev.weight >= 0.0 and ev.weight <= 1.0,
			"Evidence '%s' weight %.2f should be 0.0-1.0" % [ev.id, ev.weight])


# ============================================================
# §5.7 — Data Model Fields
# ============================================================

func test_evidence_data_has_hint_text() -> void:
	var ev: EvidenceData = CaseManager.get_evidence("ev_fingerprint")
	assert_not_null(ev)
	assert_eq(ev.hint_text, "Did you check the wine glasses in the kitchen?")


func test_evidence_data_hint_text_defaults_empty() -> void:
	var ev: EvidenceData = CaseManager.get_evidence("ev_camera")
	assert_not_null(ev)
	assert_eq(ev.hint_text, "", "Hint text should default to empty string")


func test_statement_data_has_contradicting_evidence() -> void:
	var stmt: StatementData = CaseManager.get_statement("s_julia_01")
	assert_not_null(stmt)
	assert_eq(stmt.contradicting_evidence.size(), 1)
	assert_eq(stmt.contradicting_evidence[0], "ev_camera")


func test_statement_data_contradicting_evidence_defaults_empty() -> void:
	# Create a minimal statement without contradicting_evidence
	var data: Dictionary = {
		"id": "s_test",
		"person_id": "p_test",
		"text": "Test statement.",
		"day_given": 1,
		"related_evidence": [],
	}
	var stmt: StatementData = StatementData.from_dict(data)
	assert_eq(stmt.contradicting_evidence.size(), 0)


func test_evidence_data_to_dict_includes_hint_text() -> void:
	var ev: EvidenceData = CaseManager.get_evidence("ev_fingerprint")
	var d: Dictionary = ev.to_dict()
	assert_true(d.has("hint_text"))
	assert_eq(d["hint_text"], "Did you check the wine glasses in the kitchen?")


func test_statement_data_to_dict_includes_contradicting_evidence() -> void:
	var stmt: StatementData = CaseManager.get_statement("s_julia_01")
	var d: Dictionary = stmt.to_dict()
	assert_true(d.has("contradicting_evidence"))
	assert_eq(d["contradicting_evidence"].size(), 1)


# ============================================================
# Serialization & Reset
# ============================================================

func test_serialize_returns_dictionary() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_fingerprint")
	var data: Dictionary = EvidenceManager.serialize()
	assert_true(data.has("pinned_evidence"))
	assert_true(data.has("detected_contradictions"))
	assert_false(data.has("player_tags"))


func test_deserialize_restores_state() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_fingerprint")
	var data: Dictionary = EvidenceManager.serialize()
	EvidenceManager.reset()
	assert_false(EvidenceManager.is_pinned("ev_fingerprint"))
	EvidenceManager.deserialize(data)
	assert_true(EvidenceManager.is_pinned("ev_fingerprint"))


func test_serialize_round_trip() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_evidence("ev_camera")
	EvidenceManager.pin_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_camera")
	EvidenceManager.check_contradictions()

	var data: Dictionary = EvidenceManager.serialize()
	EvidenceManager.reset()
	EvidenceManager.deserialize(data)

	assert_eq(EvidenceManager.get_pinned_evidence().size(), 2)
	assert_true(EvidenceManager.is_pinned("ev_fingerprint"))
	assert_true(EvidenceManager.is_pinned("ev_camera"))


func test_deserialize_ignores_legacy_player_tags_key() -> void:
	var legacy_state: Dictionary = {
		"player_tags": {
			"ev_fingerprint": ["legacy_tag"],
		}
	}
	EvidenceManager.deserialize(legacy_state)
	var serialized: Dictionary = EvidenceManager.serialize()
	assert_false(serialized.has("player_tags"), "Legacy player_tags data should be ignored on load.")


func test_reset_clears_all_state() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_fingerprint")
	EvidenceManager.check_contradictions()
	EvidenceManager.reset()
	assert_eq(EvidenceManager.get_pinned_evidence().size(), 0)
	assert_eq(EvidenceManager.detected_contradictions.size(), 0)


func test_game_manager_new_game_resets_evidence_manager() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_fingerprint")
	GameManager.new_game()
	assert_eq(EvidenceManager.get_pinned_evidence().size(), 0, "new_game should reset EvidenceManager")


func test_game_manager_serialize_includes_evidence_manager() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_fingerprint")
	var data: Dictionary = GameManager.serialize()
	assert_true(data.has("evidence_manager"), "GameManager serialize should include evidence_manager")
	assert_true(data["evidence_manager"].has("pinned_evidence"))


func test_game_manager_deserialize_restores_evidence_manager() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.pin_evidence("ev_fingerprint")
	var data: Dictionary = GameManager.serialize()
	GameManager.new_game()
	assert_false(EvidenceManager.is_pinned("ev_fingerprint"))
	GameManager.deserialize(data)
	assert_true(EvidenceManager.is_pinned("ev_fingerprint"))


# ============================================================
# Reviewed State
# ============================================================

func test_is_reviewed_false_by_default() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	assert_false(EvidenceManager.is_reviewed("ev_fingerprint"),
		"Evidence should not be reviewed until mark_reviewed is called.")


func test_mark_reviewed_marks_and_emits_signal() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	watch_signals(EvidenceManager)
	EvidenceManager.mark_reviewed("ev_fingerprint")
	assert_true(EvidenceManager.is_reviewed("ev_fingerprint"),
		"Evidence should be marked reviewed after mark_reviewed.")
	assert_signal_emitted(EvidenceManager, "evidence_reviewed")
	assert_signal_emitted_with_parameters(EvidenceManager, "evidence_reviewed", ["ev_fingerprint"])


func test_mark_reviewed_again_is_no_op() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.mark_reviewed("ev_fingerprint")
	watch_signals(EvidenceManager)
	EvidenceManager.mark_reviewed("ev_fingerprint")
	assert_signal_emit_count(EvidenceManager, "evidence_reviewed", 0,
		"Second mark_reviewed call must not re-emit the signal.")


func test_reviewed_state_serializes_and_restores() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.mark_reviewed("ev_fingerprint")
	var data: Dictionary = EvidenceManager.serialize()
	EvidenceManager.reset()
	assert_false(EvidenceManager.is_reviewed("ev_fingerprint"),
		"is_reviewed should be false after reset.")
	EvidenceManager.deserialize(data)
	assert_true(EvidenceManager.is_reviewed("ev_fingerprint"),
		"is_reviewed should be restored after deserialize.")


func test_reset_clears_reviewed_state() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	EvidenceManager.mark_reviewed("ev_fingerprint")
	EvidenceManager.reset()
	assert_false(EvidenceManager.is_reviewed("ev_fingerprint"),
		"reset() must clear the reviewed state.")


# ============================================================
# §7 — Player Notes
# ============================================================

func test_player_notes_empty_by_default() -> void:
	assert_eq(EvidenceManager.get_player_notes("ev_fingerprint"), "",
		"get_player_notes should return empty string when no note has been set.")


func test_set_and_get_player_notes() -> void:
	EvidenceManager.set_player_notes("ev_fingerprint", "Suspicious residue visible.")
	assert_eq(EvidenceManager.get_player_notes("ev_fingerprint"), "Suspicious residue visible.",
		"get_player_notes should return the exact text passed to set_player_notes.")


func test_set_empty_notes_removes_entry() -> void:
	EvidenceManager.set_player_notes("ev_fingerprint", "Some note.")
	EvidenceManager.set_player_notes("ev_fingerprint", "")
	assert_eq(EvidenceManager.get_player_notes("ev_fingerprint"), "",
		"Setting empty notes should clear the entry — get_player_notes must return ''.")


func test_set_player_notes_emits_signal() -> void:
	watch_signals(EvidenceManager)
	EvidenceManager.set_player_notes("ev_fingerprint", "Check this again.")
	assert_signal_emitted(EvidenceManager, "player_notes_changed")
	assert_signal_emitted_with_parameters(EvidenceManager, "player_notes_changed",
		["ev_fingerprint"])


func test_player_notes_serializes_and_restores() -> void:
	EvidenceManager.set_player_notes("ev_fingerprint", "My key note.")
	var data: Dictionary = EvidenceManager.serialize()
	EvidenceManager.reset()
	assert_eq(EvidenceManager.get_player_notes("ev_fingerprint"), "",
		"Notes should be absent after reset.")
	EvidenceManager.deserialize(data)
	assert_eq(EvidenceManager.get_player_notes("ev_fingerprint"), "My key note.",
		"Notes should be restored after deserialize.")


# ============================================================
# §9 — Sent to Board & Superseded State
# ============================================================

func test_is_sent_to_board_false_by_default() -> void:
	assert_false(EvidenceManager.is_sent_to_board("ev_fingerprint"),
		"Evidence should not be marked sent-to-board by default.")


func test_mark_sent_to_board_sets_state() -> void:
	EvidenceManager.mark_sent_to_board("ev_fingerprint")
	assert_true(EvidenceManager.is_sent_to_board("ev_fingerprint"),
		"Evidence should be marked sent-to-board after mark_sent_to_board.")


func test_mark_sent_to_board_emits_signal() -> void:
	watch_signals(EvidenceManager)
	EvidenceManager.mark_sent_to_board("ev_fingerprint")
	assert_signal_emitted_with_parameters(EvidenceManager, "evidence_sent_to_board",
		["ev_fingerprint"])


func test_mark_sent_to_board_is_idempotent() -> void:
	EvidenceManager.mark_sent_to_board("ev_fingerprint")
	watch_signals(EvidenceManager)
	EvidenceManager.mark_sent_to_board("ev_fingerprint")
	assert_signal_emit_count(EvidenceManager, "evidence_sent_to_board", 0,
		"Second mark_sent_to_board call must not re-emit the signal.")


func test_sent_to_board_serializes_and_restores() -> void:
	EvidenceManager.mark_sent_to_board("ev_fingerprint")
	var data: Dictionary = EvidenceManager.serialize()
	EvidenceManager.reset()
	assert_false(EvidenceManager.is_sent_to_board("ev_fingerprint"),
		"is_sent_to_board should be false after reset.")
	EvidenceManager.deserialize(data)
	assert_true(EvidenceManager.is_sent_to_board("ev_fingerprint"),
		"is_sent_to_board should be restored after deserialize.")


func test_reset_clears_sent_to_board() -> void:
	EvidenceManager.mark_sent_to_board("ev_fingerprint")
	EvidenceManager.reset()
	assert_false(EvidenceManager.is_sent_to_board("ev_fingerprint"),
		"reset() must clear sent-to-board state.")


func test_is_superseded_false_without_lab_request() -> void:
	GameManager.discover_evidence("ev_fingerprint")
	assert_false(EvidenceManager.is_superseded("ev_fingerprint"),
		"Evidence without a lab request should never be superseded.")


func test_is_superseded_false_before_output_discovered() -> void:
	GameManager.discover_evidence("ev_knife")
	assert_false(EvidenceManager.is_superseded("ev_knife"),
		"Evidence with an undiscovered lab result should not be superseded.")


func test_is_superseded_true_when_output_discovered() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_knife_result")
	assert_true(EvidenceManager.is_superseded("ev_knife"),
		"Evidence should be superseded when its lab result has been discovered.")
