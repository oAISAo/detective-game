## test_hallway_investigation.gd
## Scenario tests for the Building Hallway location investigation flow.
## Validates: first-open behavior, visual inspection discovers evidence,
## security system state transitions, shoe print clue path, and state persistence.
extends GutTest


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case_folder("riverside_apartment")
	LocationInvestigationManager.reset()
	# Unlock the hallway so investigation can start
	GameManager.unlock_location("loc_hallway")


func after_each() -> void:
	LocationInvestigationManager.leave_location()
	CaseManager.unload_case()


# =========================================================================
# Test 1: First visit starts full investigation
# =========================================================================

func test_first_visit_starts_full_investigation() -> void:
	assert_false(GameManager.has_visited_location("loc_hallway"),
		"Hallway should not be visited initially")

	var result: Dictionary = LocationInvestigationManager.start_investigation("loc_hallway")
	assert_true(result.get("success", false), "Should be able to start investigation on first visit")

	assert_true(GameManager.has_visited_location("loc_hallway"),
		"Hallway should be marked as visited after starting investigation")


# =========================================================================
# Test 2: Hallway Floor has visual inspection action
# =========================================================================

func test_hallway_floor_has_visual_inspection_action() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	var location: LocationData = CaseManager.get_location("loc_hallway")
	assert_not_null(location, "Hallway location should exist")

	var floor_obj: InvestigableObjectData = null
	for obj: InvestigableObjectData in location.investigable_objects:
		if obj.id == "obj_hallway_floor":
			floor_obj = obj
			break

	assert_not_null(floor_obj, "Hallway Floor object should exist")
	assert_true("visual_inspection" in floor_obj.available_actions,
		"Hallway Floor should have visual_inspection action")


# =========================================================================
# Test 3: Hallway Floor visual inspection discovers shoe print raw
# =========================================================================

func test_hallway_floor_inspection_discovers_shoe_print_raw() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_hallway_floor"
	)

	assert_true(discovered.size() > 0,
		"Visual inspection of Hallway Floor should discover evidence")
	assert_has(discovered, "ev_shoe_print_raw",
		"Should discover ev_shoe_print_raw (unanalyzed shoe print)")
	assert_true(GameManager.has_evidence("ev_shoe_print_raw"),
		"ev_shoe_print_raw should be in discovered evidence")


# =========================================================================
# Test 4: Hallway Floor visual inspection is not a dead end
# =========================================================================

func test_hallway_floor_inspection_not_dead_end() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_hallway_floor"
	)

	# Must produce at least one piece of evidence
	assert_true(discovered.size() >= 1,
		"Visual inspection must discover at least one evidence item")


# =========================================================================
# Test 6: Security System examination discovers camera evidence
# =========================================================================

func test_security_system_examination_discovers_camera() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_security_system"
	)

	assert_true(discovered.size() > 0,
		"Security system examination should discover evidence")
	assert_has(discovered, "ev_hallway_camera",
		"Should discover ev_hallway_camera")
	assert_true(GameManager.has_evidence("ev_hallway_camera"),
		"ev_hallway_camera should be in discovered evidence")


# =========================================================================
# Test 7: Security System examination discovers elevator logs
# =========================================================================

func test_security_system_examination_discovers_elevator_logs() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_security_system"
	)

	assert_has(discovered, "ev_elevator_logs",
		"Should discover ev_elevator_logs")
	assert_true(GameManager.has_evidence("ev_elevator_logs"),
		"ev_elevator_logs should be in discovered evidence")


# =========================================================================
# Test 8: Security System state updates after examination
# =========================================================================

func test_security_system_state_updates_after_examination() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	var state_before: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_hallway", "obj_security_system"
	)
	assert_eq(state_before, Enums.InvestigationState.NOT_INSPECTED,
		"Should start as NOT_INSPECTED")

	LocationInvestigationManager.inspect_object("loc_hallway", "obj_security_system")

	var state_after: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_hallway", "obj_security_system"
	)
	# Security system has no tool_requirements, so examination completes it
	assert_eq(state_after, Enums.InvestigationState.FULLY_EXAMINED,
		"Security system should be FULLY_EXAMINED after examination (no tool actions)")


# =========================================================================
# Test 9: Maintenance Office visual inspection discovers work log
# =========================================================================

func test_maintenance_office_inspection_discovers_work_log() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_maintenance_office"
	)

	assert_true(discovered.size() > 0,
		"Maintenance office inspection should discover evidence")
	assert_has(discovered, "ev_lucas_work_log",
		"Should discover ev_lucas_work_log")


# =========================================================================
# Test 10: Maintenance Office reaches FULLY_EXAMINED (no tool requirements)
# =========================================================================

func test_maintenance_office_state_fully_examined() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	LocationInvestigationManager.inspect_object("loc_hallway", "obj_maintenance_office")

	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_hallway", "obj_maintenance_office"
	)
	assert_eq(state, Enums.InvestigationState.FULLY_EXAMINED,
		"Maintenance office should be FULLY_EXAMINED (no tool actions remain)")


# =========================================================================
# Test 11: All hallway objects start NOT_INSPECTED
# =========================================================================

func test_all_hallway_objects_start_not_inspected() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	for obj_id: String in ["obj_hallway_floor", "obj_security_system", "obj_maintenance_office"]:
		var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
			"loc_hallway", obj_id
		)
		assert_eq(state, Enums.InvestigationState.NOT_INSPECTED,
			"%s should start as NOT_INSPECTED" % obj_id)


# =========================================================================
# Test 12: Location completion counts update after inspections
# =========================================================================

func test_completion_counts_update_after_inspections() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	var before: Dictionary = LocationInvestigationManager.get_location_completion("loc_hallway")
	assert_eq(before["found"], 0, "No evidence found initially")
	assert_true(before["total"] > 0, "Total should be > 0")

	# Inspect security system (discovers camera + elevator logs)
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_security_system")

	var after: Dictionary = LocationInvestigationManager.get_location_completion("loc_hallway")
	assert_true(after["found"] > before["found"],
		"Found clue count should increase after discovering evidence")


# =========================================================================
# Test 13: Repeated inspection does not re-discover evidence
# =========================================================================

func test_repeated_inspection_no_re_discovery() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	var first: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_hallway_floor"
	)
	assert_true(first.size() > 0, "First inspection should discover evidence")

	var second: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_hallway_floor"
	)
	assert_eq(second.size(), 0, "Second inspection should discover nothing (already done)")


# =========================================================================
# Test 14: Object states persist after leaving and returning
# =========================================================================

func test_object_states_persist_after_revisit() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_security_system")

	var state_before_leave: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_hallway", "obj_security_system"
	)

	# Leave and return
	LocationInvestigationManager.leave_location()
	LocationInvestigationManager.start_investigation("loc_hallway")

	var state_after_return: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_hallway", "obj_security_system"
	)
	assert_eq(state_after_return, state_before_leave,
		"Object state should persist after leaving and returning")


# =========================================================================
# Test 15: Full hallway evidence chain from clean new game
# =========================================================================

func test_full_hallway_evidence_chain() -> void:
	LocationInvestigationManager.start_investigation("loc_hallway")

	# Step 1: Inspect security system → camera + elevator logs
	var sec_discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_security_system"
	)
	assert_has(sec_discovered, "ev_hallway_camera", "Should get camera from security system")
	assert_has(sec_discovered, "ev_elevator_logs", "Should get elevator logs from security system")

	# Step 2: Inspect hallway floor → shoe print raw
	var floor_discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_hallway_floor"
	)
	assert_has(floor_discovered, "ev_shoe_print_raw", "Should get raw shoe print from floor")

	# Step 3: Inspect maintenance office → work log
	var office_discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_maintenance_office"
	)
	assert_has(office_discovered, "ev_lucas_work_log", "Should get work log from office")

	# Verify all evidence is in game state
	assert_true(GameManager.has_evidence("ev_hallway_camera"))
	assert_true(GameManager.has_evidence("ev_elevator_logs"))
	assert_true(GameManager.has_evidence("ev_shoe_print_raw"))
	assert_true(GameManager.has_evidence("ev_lucas_work_log"))
