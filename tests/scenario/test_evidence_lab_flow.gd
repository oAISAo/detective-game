## test_evidence_lab_flow.gd
## Scenario tests for the evidence → lab → result gameplay loop.
## Validates: lab request lookup, raw evidence submission, day transition delivery,
## evidence state progression, and full hallway → lab → interrogation chain.
extends GutTest


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case_folder("riverside_apartment")
	LabManager.reset()
	LocationInvestigationManager.reset()
	GameManager.unlock_location("loc_hallway")


func after_each() -> void:
	LocationInvestigationManager.leave_location()
	if InterrogationManager.is_active():
		InterrogationManager.end_interrogation()
	CaseManager.unload_case()


# =========================================================================
# Test 1: CaseManager lab request lookup by evidence ID
# =========================================================================

func test_lab_request_lookup_by_evidence() -> void:
	var req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	assert_not_null(req, "Should find lab request for ev_shoe_print_raw")
	assert_eq(req.input_evidence_id, "ev_shoe_print_raw")
	assert_eq(req.output_evidence_id, "ev_shoe_print")
	assert_eq(req.analysis_type, "footwear_analysis")


func test_lab_request_lookup_returns_null_for_unknown() -> void:
	var req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_knife")
	assert_null(req, "Should return null for evidence without lab request")


func test_lab_request_lookup_wine_glasses() -> void:
	var req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_wine_glasses")
	assert_not_null(req, "Should find lab request for ev_wine_glasses")
	assert_eq(req.output_evidence_id, "ev_julia_fingerprint_glass")


func test_get_all_lab_requests() -> void:
	var all_reqs: Array[LabRequestData] = CaseManager.get_all_lab_requests()
	assert_eq(all_reqs.size(), 3, "Riverside apartment should have 3 lab requests")


# =========================================================================
# Test 2: Raw shoe print can be submitted to lab
# =========================================================================

func test_shoe_print_raw_can_be_submitted_to_lab() -> void:
	GameManager.discover_evidence("ev_shoe_print_raw")

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	assert_not_null(lab_req)

	var result: Dictionary = LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	assert_false(result.is_empty(), "Submission should succeed")
	assert_eq(result["input_evidence_id"], "ev_shoe_print_raw")
	assert_eq(result["output_evidence_id"], "ev_shoe_print")
	assert_eq(result["status"], "pending")


func test_shoe_print_raw_submission_tracks_in_lab_manager() -> void:
	GameManager.discover_evidence("ev_shoe_print_raw")

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	assert_true(LabManager.is_evidence_submitted("ev_shoe_print_raw"),
		"Evidence should be marked as submitted")
	assert_eq(LabManager.get_pending_count(), 1)


# =========================================================================
# Test 3: Lab result arrives next morning via DaySystem
# =========================================================================

func test_lab_result_arrives_next_morning() -> void:
	GameManager.discover_evidence("ev_shoe_print_raw")

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	assert_false(GameManager.has_evidence("ev_shoe_print"),
		"Output evidence should NOT be available yet")

	# Advance to next day — night processing then morning
	DaySystem.force_advance_day()

	# Process morning of next day
	DaySystem.process_morning()

	assert_true(GameManager.has_evidence("ev_shoe_print"),
		"Output evidence should be discovered after morning processing")


func test_lab_result_clears_from_active_requests() -> void:
	GameManager.discover_evidence("ev_shoe_print_raw")

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	assert_eq(GameManager.active_lab_requests.size(), 1,
		"Should have 1 active lab request before day advance")

	DaySystem.force_advance_day()
	DaySystem.process_morning()

	assert_eq(GameManager.active_lab_requests.size(), 0,
		"Active lab requests should be cleared after completion")


# =========================================================================
# Test 4: Evidence lab_status progression
# =========================================================================

func test_evidence_lab_status_not_submitted_initially() -> void:
	var ev: EvidenceData = CaseManager.get_evidence("ev_shoe_print_raw")
	assert_not_null(ev)
	assert_eq(ev.lab_status, Enums.LabStatus.NOT_SUBMITTED,
		"Should start as NOT_SUBMITTED")


func test_evidence_lab_status_processing_after_submit() -> void:
	GameManager.discover_evidence("ev_shoe_print_raw")

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	var ev: EvidenceData = CaseManager.get_evidence("ev_shoe_print_raw")
	assert_eq(ev.lab_status, Enums.LabStatus.PROCESSING,
		"Should be PROCESSING after submission")


func test_evidence_lab_status_completed_after_result() -> void:
	GameManager.discover_evidence("ev_shoe_print_raw")

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	DaySystem.force_advance_day()
	DaySystem.process_morning()

	var ev: EvidenceData = CaseManager.get_evidence("ev_shoe_print_raw")
	assert_eq(ev.lab_status, Enums.LabStatus.COMPLETED,
		"Should be COMPLETED after lab result arrives")


# =========================================================================
# Test 5: Full hallway → lab → interrogation chain
# =========================================================================

func test_full_hallway_to_lab_to_interrogation() -> void:
	# --- Step 1: Investigate hallway ---
	LocationInvestigationManager.start_investigation("loc_hallway", true)

	# Inspect security system → camera + elevator logs
	var sec_discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_security_system"
	)
	assert_has(sec_discovered, "ev_hallway_camera")
	assert_has(sec_discovered, "ev_elevator_logs")

	# Inspect hallway floor → shoe print raw
	var floor_discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_hallway_floor"
	)
	assert_has(floor_discovered, "ev_shoe_print_raw")

	# Inspect maintenance office → work log
	var office_discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_maintenance_office"
	)
	assert_has(office_discovered, "ev_lucas_work_log")

	# Verify 4/4 clues found
	var completion: Dictionary = LocationInvestigationManager.get_location_completion("loc_hallway")
	assert_eq(completion["found"], 4, "Should have found 4 clues")
	assert_eq(completion["total"], 4, "Total should be 4")

	LocationInvestigationManager.leave_location()

	# --- Step 2: Submit shoe print to lab ---
	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	assert_not_null(lab_req)

	var submit_result: Dictionary = LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)
	assert_false(submit_result.is_empty(), "Lab submission should succeed")

	# --- Step 3: Advance to next day and get lab results ---
	DaySystem.force_advance_day()
	DaySystem.process_morning()

	assert_true(GameManager.has_evidence("ev_shoe_print"),
		"Should have analyzed shoe print after morning processing")

	# --- Step 4: Use evidence in Sarah's interrogation ---
	assert_true(GameManager.has_evidence("ev_hallway_camera"),
		"Should have hallway camera for interrogation")
	assert_true(GameManager.has_evidence("ev_shoe_print"),
		"Should have analyzed shoe print for interrogation")

	InterrogationManager.start_interrogation("p_sarah")

	# Present hallway camera against initial statement
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	var r1: Dictionary = InterrogationManager.present_evidence("ev_hallway_camera")
	assert_true(r1.get("triggered", false), "Camera trigger should fire")
	assert_eq(InterrogationManager.get_current_pressure(), 1)

	# Present analyzed shoe print against confronted statement
	InterrogationManager.select_focus("statement", "stmt_sarah_confronted")
	var r2: Dictionary = InterrogationManager.present_evidence("ev_shoe_print")
	assert_true(r2.get("triggered", false), "Shoe print trigger should fire")
	assert_eq(InterrogationManager.get_current_pressure(), 2)

	# Apply pressure → break
	assert_true(InterrogationManager.can_apply_pressure())
	var break_result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(break_result.get("break_moment", false), "Should trigger break")

	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_sarah_saw_woman",
		"Break should produce saw-woman statement")

	InterrogationManager.end_interrogation()


# =========================================================================
# Test 6: Multiple lab requests can run concurrently
# =========================================================================

func test_multiple_lab_requests_concurrent() -> void:
	GameManager.discover_evidence("ev_shoe_print_raw")
	GameManager.discover_evidence("ev_wine_glasses")

	var req1: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	var req2: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_wine_glasses")

	LabManager.submit_request(
		"ev_shoe_print_raw", req1.analysis_type, req1.output_evidence_id, 1
	)
	LabManager.submit_request(
		"ev_wine_glasses", req2.analysis_type, req2.output_evidence_id, 1
	)

	assert_eq(LabManager.get_pending_count(), 2)

	DaySystem.force_advance_day()
	DaySystem.process_morning()

	assert_true(GameManager.has_evidence("ev_shoe_print"))
	assert_true(GameManager.has_evidence("ev_julia_fingerprint_glass"))


# =========================================================================
# Test 7: Hallway floor state is PARTIALLY_EXAMINED after inspection
# =========================================================================

func test_hallway_floor_partially_examined_with_unfulfilled_tool() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway", true)
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")

	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_hallway", "obj_hallway_floor"
	)
	assert_eq(state, Enums.InvestigationState.PARTIALLY_EXAMINED,
		"Hallway floor should be PARTIALLY_EXAMINED (forensic_kit tool not available)")

	# But evidence was still discovered
	assert_true(GameManager.has_evidence("ev_shoe_print_raw"),
		"Shoe print raw should be discovered despite partial state")


# =========================================================================
# Test 8: Completion persists after leaving and returning
# =========================================================================

func test_hallway_completion_persists_after_revisit() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway", true)

	LocationInvestigationManager.inspect_object("loc_hallway", "obj_security_system")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_maintenance_office")

	var before: Dictionary = LocationInvestigationManager.get_location_completion("loc_hallway")
	assert_eq(before["found"], 4)

	LocationInvestigationManager.leave_location()
	LocationInvestigationManager.start_investigation("loc_hallway", true)

	var after: Dictionary = LocationInvestigationManager.get_location_completion("loc_hallway")
	assert_eq(after["found"], 4,
		"Clue count should persist after leaving and returning")


# =========================================================================
# Test 9: Evidence upgrade replaces raw with analyzed
# =========================================================================

func test_evidence_upgrade_replaces_raw_with_analyzed() -> void:
	GameManager.discover_evidence("ev_shoe_print_raw")
	assert_true(GameManager.has_evidence("ev_shoe_print_raw"))
	assert_false(GameManager.has_evidence("ev_shoe_print"))

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	DaySystem.force_advance_day()
	DaySystem.process_morning()

	# After lab completion: raw evidence should be gone, analyzed should be present
	assert_false(GameManager.has_evidence("ev_shoe_print_raw"),
		"Raw evidence should be removed after upgrade")
	assert_true(GameManager.has_evidence("ev_shoe_print"),
		"Analyzed evidence should be present after upgrade")


func test_evidence_upgrade_no_duplicate_in_archive() -> void:
	GameManager.discover_evidence("ev_shoe_print_raw")

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	DaySystem.force_advance_day()
	DaySystem.process_morning()

	# Verify no duplicates — only analyzed version should exist
	var count: int = 0
	for ev_id: String in GameManager.discovered_evidence:
		if ev_id == "ev_shoe_print_raw" or ev_id == "ev_shoe_print":
			count += 1
	assert_eq(count, 1, "Should have exactly 1 version of shoe print evidence (analyzed only)")
	assert_true(GameManager.has_evidence("ev_shoe_print"))


func test_evidence_upgrade_preserves_position_in_array() -> void:
	# Discover some evidence before and after raw shoe print
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print_raw")
	GameManager.discover_evidence("ev_elevator_logs")

	var idx_before: int = GameManager.discovered_evidence.find("ev_shoe_print_raw")
	assert_true(idx_before >= 0)

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	DaySystem.force_advance_day()
	DaySystem.process_morning()

	var idx_after: int = GameManager.discovered_evidence.find("ev_shoe_print")
	assert_eq(idx_after, idx_before,
		"Upgraded evidence should be at the same position as the raw version")


# =========================================================================
# Test 12: Analyzed evidence with lab results should not show lab status
# =========================================================================

func test_analyzed_evidence_hides_lab_status_when_results_exist() -> void:
	# The analyzed shoe print has requires_lab_analysis=true AND lab_result_text populated.
	# After our fix, when lab_result_text is non-empty, only "Lab Result" should show,
	# not "Lab Status: Not Submitted".
	var ev: EvidenceData = CaseManager.get_evidence("ev_shoe_print")
	assert_not_null(ev, "Analyzed shoe print evidence should exist")
	assert_true(ev.requires_lab_analysis,
		"Analyzed shoe print should have requires_lab_analysis=true")
	assert_false(ev.lab_result_text.is_empty(),
		"Analyzed shoe print should have lab_result_text populated")

	# The UI logic: if requires_lab_analysis AND lab_result_text non-empty → show result only
	# If requires_lab_analysis AND lab_result_text empty → show status
	# This test validates the data conditions that drive the correct UI behavior
	var should_show_result: bool = ev.requires_lab_analysis and not ev.lab_result_text.is_empty()
	var should_show_status: bool = ev.requires_lab_analysis and ev.lab_result_text.is_empty()
	assert_true(should_show_result,
		"Should show lab result (not status) for analyzed evidence with results")
	assert_false(should_show_status,
		"Should NOT show lab status for analyzed evidence with results")


# =========================================================================
# Test 13: Raw evidence without results should still show lab status
# =========================================================================

func test_raw_evidence_shows_lab_status_without_results() -> void:
	var ev: EvidenceData = CaseManager.get_evidence("ev_shoe_print_raw")
	assert_not_null(ev, "Raw shoe print evidence should exist")

	# Raw evidence does not have requires_lab_analysis set, but a lab request exists for it
	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	assert_not_null(lab_req, "Lab request should exist for raw shoe print")

	# When requires_lab_analysis is false but lab request exists, the UI shows lab status
	var should_show_status: bool = not ev.requires_lab_analysis and lab_req != null
	assert_true(should_show_status,
		"Raw evidence with lab request should show lab status row")
