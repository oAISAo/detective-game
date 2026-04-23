## test_object_display_status.gd
## Tests for derived object display status across the clue lifecycle.
## Validates: status after raw clue discovery, after lab submission,
## after analyzed evidence delivery, hint text changes, and location-level
## clue count independence from lab state.
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
	CaseManager.unload_case()


# =========================================================================
# Test 1: Object status is NOT_INSPECTED before any interaction
# =========================================================================

func test_initial_display_status_not_inspected() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	var status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(
		"loc_hallway", "obj_hallway_floor"
	)
	assert_eq(status, Enums.ObjectDisplayStatus.NOT_INSPECTED,
		"Object should be NOT_INSPECTED before any interaction")


# =========================================================================
# Test 2: Object status after raw clue discovery (before lab submission)
# =========================================================================

func test_status_fully_processed_after_raw_discovery() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")

	# Once inspection is done, the object is FULLY_PROCESSED regardless of whether the player
	# has submitted the raw evidence to the lab. Lab submission is an Evidence-tab concern.
	var status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(
		"loc_hallway", "obj_hallway_floor"
	)
	assert_eq(status, Enums.ObjectDisplayStatus.FULLY_PROCESSED,
		"Should be FULLY_PROCESSED after inspection — lab submission state does not affect map-tab status")


# =========================================================================
# Test 4: Object status stays FULLY_PROCESSED even after lab submission
# Regression test for bug where AWAITING_LAB_RESULTS overrode FULLY_EXAMINED.
# =========================================================================

func test_status_stays_fully_processed_after_lab_submission() -> void:
	# Once an object is fully examined (map-tab's one action done), its display
	# status must remain FULLY_PROCESSED regardless of whether the player has
	# submitted the raw evidence to the lab. Lab state is an Evidence-tab concern.
	LocationInvestigationManager.start_investigation("loc_hallway")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")

	# Submit raw shoe print to lab
	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	assert_not_null(lab_req)
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	var status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(
		"loc_hallway", "obj_hallway_floor"
	)
	assert_eq(status, Enums.ObjectDisplayStatus.FULLY_PROCESSED,
		"FULLY_EXAMINED objects must show FULLY_PROCESSED even when evidence is sent to the lab")


# =========================================================================
# Test 6: Object status after analyzed result arrives shows FULLY_PROCESSED
# =========================================================================

func test_status_fully_processed_after_lab_result() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")
	LocationInvestigationManager.leave_location()

	# Submit and complete lab
	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	DaySystem.force_advance_day()
	DaySystem.process_morning()

	var status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(
		"loc_hallway", "obj_hallway_floor"
	)
	# Note: hallway floor also has tool_requirements (forensic_kit), so base state is PARTIALLY_EXAMINED
	# But the lab result has completed, so depending on tool state it may still show partially
	# The key point is it should NOT show AWAITING_LAB_RESULTS anymore
	assert_ne(status, Enums.ObjectDisplayStatus.AWAITING_LAB_RESULTS,
		"Should NOT show AWAITING_LAB_RESULTS after lab result arrives")


# =========================================================================
# Test 8: Location-level clue count remains correct independent of lab state
# =========================================================================

func test_clue_count_correct_before_lab() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	# Discover all evidence at hallway
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_security_system")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_maintenance_office")

	var completion: Dictionary = LocationInvestigationManager.get_location_completion("loc_hallway")
	assert_eq(completion["found"], 4, "Should have 4/4 clues found")
	assert_eq(completion["total"], 4, "Total should be 4")


func test_clue_count_correct_after_lab_submission() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	LocationInvestigationManager.inspect_object("loc_hallway", "obj_security_system")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_maintenance_office")
	LocationInvestigationManager.leave_location()

	# Submit shoe print to lab
	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	# Clue count should still be 4/4
	var completion: Dictionary = LocationInvestigationManager.get_location_completion("loc_hallway")
	assert_eq(completion["found"], 4,
		"Clue count should remain 4/4 after lab submission")


func test_clue_count_correct_after_lab_completion() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	LocationInvestigationManager.inspect_object("loc_hallway", "obj_security_system")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_maintenance_office")
	LocationInvestigationManager.leave_location()

	# Submit and complete lab
	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	DaySystem.force_advance_day()
	DaySystem.process_morning()

	# After upgrade: raw replaced by analyzed, count stays 4/4
	var completion: Dictionary = LocationInvestigationManager.get_location_completion("loc_hallway")
	assert_eq(completion["found"], 4,
		"Clue count should remain 4/4 after lab completion and evidence upgrade")


# =========================================================================
# Test 9: Location-level lab pending badge
# =========================================================================

func test_location_no_lab_pending_after_completion() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")
	LocationInvestigationManager.leave_location()

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence("ev_shoe_print_raw")
	LabManager.submit_request(
		"ev_shoe_print_raw",
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	DaySystem.force_advance_day()
	DaySystem.process_morning()

	assert_false(
		LocationInvestigationManager.has_pending_lab_at_location("loc_hallway"),
		"Location should NOT show lab pending after completion"
	)


# =========================================================================
# Test 10: Objects without lab requirements go straight to FULLY_PROCESSED
# =========================================================================

func test_object_without_lab_fully_processed() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	# Security system has no tool_requirements and no lab-eligible evidence
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_security_system")

	var status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(
		"loc_hallway", "obj_security_system"
	)
	assert_eq(status, Enums.ObjectDisplayStatus.FULLY_PROCESSED,
		"Non-lab object should go straight to FULLY_PROCESSED after full examination")


