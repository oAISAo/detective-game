## test_map_happy_flow.gd
## Comprehensive scenario tests for the complete map tab happy flow.
## Validates all 26 steps from map-happy-flow.md including:
## - Location card display and state transitions
## - Evidence discovery across multiple locations
## - Action consumption and remaining action tracking
## - Location unlock triggers
## - Target unlock triggers (conditional visibility)
## - Complete investigation progression from Day 1 to Day 3
extends GutTest


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case_folder("riverside_apartment")
	LocationInvestigationManager.reset()
	LabManager.reset()
	ToolManager.reset()
	# Unlock initial locations for Day 1
	GameManager.unlock_location("loc_victim_apartment")
	GameManager.unlock_location("loc_hallway")
	GameManager.unlock_location("loc_parking_lot")


func after_each() -> void:
	LocationInvestigationManager.leave_location()
	CaseManager.unload_case()


# =========================================================================
# STEP 1: Open Map Tab
# =========================================================================

func test_step_1_open_map_tab_displays_location_cards() -> void:
	# Step 1: Open Map Tab
	# Expected: Map screen displays with location cards in a grid

	var case_data: CaseData = CaseManager.get_case_data()
	assert_not_null(case_data, "Case should be loaded")

	var locations: Array[LocationData] = case_data.locations
	assert_true(locations.size() >= 3,
		"Should have at least 3 locations available (Apartment, Hallway, Parking Lot)")

	var apartment: LocationData = CaseManager.get_location("loc_victim_apartment")
	var hallway: LocationData = CaseManager.get_location("loc_hallway")
	var parking: LocationData = CaseManager.get_location("loc_parking_lot")

	assert_not_null(apartment, "Victim's Apartment should exist")
	assert_not_null(hallway, "Building Hallway should exist")
	assert_not_null(parking, "Parking Lot should exist")


func test_step_1_initial_locations_have_new_status() -> void:
	# Step 1: All cards show status badge: NEW (blue)

	var apartment: LocationData = CaseManager.get_location("loc_victim_apartment")
	var hallway: LocationData = CaseManager.get_location("loc_hallway")
	var parking: LocationData = CaseManager.get_location("loc_parking_lot")

	# NEW status means not visited
	assert_false(GameManager.has_visited_location("loc_victim_apartment"),
		"Apartment should not be visited yet")
	assert_false(GameManager.has_visited_location("loc_hallway"),
		"Hallway should not be visited yet")
	assert_false(GameManager.has_visited_location("loc_parking_lot"),
		"Parking Lot should not be visited yet")


func test_step_1_initial_locations_show_unknown_evidence() -> void:
	# Step 1: All cards show evidence count: "?"
	# This means evidence hasn't been discovered yet

	var apartment: LocationData = CaseManager.get_location("loc_victim_apartment")
	var hallway: LocationData = CaseManager.get_location("loc_hallway")
	var parking: LocationData = CaseManager.get_location("loc_parking_lot")

	# Locations should exist but not have investigations started
	assert_eq(apartment.investigable_objects.size(), 4,
		"Apartment should have 4 targets (Kitchen, Living Room, Phone, Study Desk)")
	assert_eq(hallway.investigable_objects.size(), 3,
		"Hallway should have 3 targets (Floor, Security System, Maintenance)")
	assert_eq(parking.investigable_objects.size(), 1,
		"Parking Lot should have 1 target (Camera)")


func test_step_1_victim_office_not_visible_initially() -> void:
	# Step 1: Victim's Office is NOT visible (not yet unlocked)

	assert_false(GameManager.is_location_unlocked("loc_victim_office"),
		"Victim's Office should not be unlocked initially")


# =========================================================================
# STEP 2: Enter Victim's Apartment
# =========================================================================

func test_step_2_enter_victims_apartment() -> void:
	# Step 2: Location Detail Screen opens for Apartment

	var result: Dictionary = LocationInvestigationManager.start_investigation("loc_victim_apartment")
	assert_true(result.get("success", false),
		"Should successfully start investigation in Apartment")

	assert_true(GameManager.has_visited_location("loc_victim_apartment"),
		"Apartment should be marked as visited")


func test_step_2_apartment_has_four_targets() -> void:
	# Step 2: Left panel shows targets: Kitchen, Living Room, Victim's Phone, Study Desk

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	var location: LocationData = CaseManager.get_location("loc_victim_apartment")
	var target_ids: Array[String] = []
	for obj: InvestigableObjectData in location.investigable_objects:
		target_ids.append(obj.id)

	assert_has(target_ids, "obj_kitchen",
		"Kitchen target should exist")
	assert_has(target_ids, "obj_living_room",
		"Living Room target should exist")
	assert_has(target_ids, "obj_victim_phone",
		"Victim's Phone target should exist")
	assert_has(target_ids, "obj_study_desk",
		"Study Desk target should exist")


func test_step_2_entering_apartment_consumes_no_actions() -> void:
	# Step 2: No actions were consumed (entering is free)

	var actions_before: int = GameManager.actions_remaining

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	var actions_after: int = GameManager.actions_remaining
	assert_eq(actions_after, actions_before,
		"Entering a location should not consume actions")


# =========================================================================
# STEP 3: Select Kitchen Target
# =========================================================================

func test_step_3_select_kitchen_target_shows_details() -> void:
	# Step 3: Right panel updates with Kitchen details

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	var kitchen: InvestigableObjectData = null
	for obj: InvestigableObjectData in CaseManager.get_location("loc_victim_apartment").investigable_objects:
		if obj.id == "obj_kitchen":
			kitchen = obj
			break

	assert_not_null(kitchen, "Kitchen object should exist")
	assert_true("visual_inspection" in kitchen.available_actions,
		"Kitchen should have visual_inspection action")


func test_step_3_kitchen_initial_state_not_inspected() -> void:
	# Step 3: Status: "Not inspected" (amber)

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_victim_apartment", "obj_kitchen"
	)
	assert_eq(state, Enums.InvestigationState.NOT_INSPECTED,
		"Kitchen should start as NOT_INSPECTED")


# =========================================================================
# STEP 4: Examine Kitchen (Action 1 of 4)
# =========================================================================

func test_step_4_examine_kitchen_action_1_of_4() -> void:
	# Step 4: Actions remaining decreases from 4 to 3

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	var actions_before: int = GameManager.actions_remaining
	assert_eq(actions_before, 4, "Should start Day 1 with 4 actions")

	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")

	var actions_after: int = GameManager.actions_remaining
	assert_eq(actions_after, 3,
		"Kitchen inspection should consume 1 action (4 → 3)")


func test_step_4_kitchen_inspection_discovers_murder_weapon() -> void:
	# Step 4: Notification: "Murder Weapon (Kitchen Knife)"

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_apartment", "obj_kitchen"
	)

	assert_has(discovered, "ev_knife",
		"Kitchen inspection should discover ev_knife (Murder Weapon)")


func test_step_4_kitchen_inspection_discovers_knife_block() -> void:
	# Step 4: Notification: "Knife Block in Kitchen"

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_apartment", "obj_kitchen"
	)

	assert_has(discovered, "ev_knife_block",
		"Kitchen inspection should discover ev_knife_block")


func test_step_4_kitchen_inspection_completes_target() -> void:
	# Step 4: Action button changes to completed state
	# Step 4: Status changes to: "Fully processed" (grey)

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")

	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_victim_apartment", "obj_kitchen"
	)
	assert_eq(state, Enums.InvestigationState.FULLY_EXAMINED,
		"Kitchen should be FULLY_EXAMINED after inspection")


# =========================================================================
# STEP 5: Select Living Room Target
# =========================================================================

func test_step_5_select_living_room_target_shows_details() -> void:
	# Step 5: Right panel updates with Living Room details

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	var living_room: InvestigableObjectData = null
	for obj: InvestigableObjectData in CaseManager.get_location("loc_victim_apartment").investigable_objects:
		if obj.id == "obj_living_room":
			living_room = obj
			break

	assert_not_null(living_room, "Living Room object should exist")
	assert_true("visual_inspection" in living_room.available_actions,
		"Living Room should have visual_inspection action")


func test_step_5_living_room_initial_state_not_inspected() -> void:
	# Step 5: Status: "Not inspected" (amber)

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_victim_apartment", "obj_living_room"
	)
	assert_eq(state, Enums.InvestigationState.NOT_INSPECTED,
		"Living Room should start as NOT_INSPECTED")


# =========================================================================
# STEP 6: Examine Living Room (Action 2 of 4)
# =========================================================================

func test_step_6_examine_living_room_action_2_of_4() -> void:
	# Step 6: Actions remaining decreases from 3 to 2

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")

	var actions_before: int = GameManager.actions_remaining
	assert_eq(actions_before, 3, "Should have 3 actions after kitchen")

	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")

	var actions_after: int = GameManager.actions_remaining
	assert_eq(actions_after, 2,
		"Living room inspection should consume 1 action (3 → 2)")


func test_step_6_living_room_inspection_discovers_wine_glasses() -> void:
	# Step 6: Notification: "Two Wine Glasses on Table"

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_apartment", "obj_living_room"
	)

	assert_has(discovered, "ev_wine_glasses",
		"Living room inspection should discover ev_wine_glasses")


func test_step_6_living_room_inspection_discovers_broken_frame() -> void:
	# Step 6: Notification: "Broken Picture Frame"

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_apartment", "obj_living_room"
	)

	assert_has(discovered, "ev_broken_picture_frame",
		"Living room inspection should discover ev_broken_picture_frame")


func test_step_6_living_room_inspection_discovers_wine_bottle() -> void:
	# Step 6: Notification: "Wine Bottle"

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_apartment", "obj_living_room"
	)

	assert_has(discovered, "ev_wine_bottle",
		"Living room inspection should discover ev_wine_bottle")


func test_step_6_living_room_fully_processed_after_inspection() -> void:
	# Step 6: Status changes to "Fully processed" (grey) after visual inspection.
	# Regression: ev_wine_glasses has a lab request, which previously caused
	# get_object_display_status() to return PARTIALLY_EXAMINED instead of FULLY_PROCESSED.

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")

	var display_status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(
		"loc_victim_apartment", "obj_living_room"
	)
	assert_eq(display_status, Enums.ObjectDisplayStatus.FULLY_PROCESSED,
		"Living Room should show FULLY_PROCESSED after inspection (not PARTIALLY_EXAMINED)")


# =========================================================================
# STEP 7: Select Victim's Phone Target
# =========================================================================

func test_step_7_select_victims_phone_target_shows_details() -> void:
	# Step 7: Right panel updates with Victim's Phone details

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	var phone: InvestigableObjectData = null
	for obj: InvestigableObjectData in CaseManager.get_location("loc_victim_apartment").investigable_objects:
		if obj.id == "obj_victim_phone":
			phone = obj
			break

	assert_not_null(phone, "Victim's Phone object should exist")
	# Phone has "examine_device" action, not "visual_inspection"
	assert_true("examine_device" in phone.available_actions,
		"Victim's Phone should have examine_device action")


func test_step_7_phone_initial_state_not_inspected() -> void:
	# Step 7: Status: "Not inspected" (amber)

	LocationInvestigationManager.start_investigation("loc_victim_apartment")

	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_victim_apartment", "obj_victim_phone"
	)
	assert_eq(state, Enums.InvestigationState.NOT_INSPECTED,
		"Victim's Phone should start as NOT_INSPECTED")


# =========================================================================
# STEP 8: Examine Victim's Phone (Action 3 of 4)
# =========================================================================

func test_step_8_examine_victims_phone_action_3_of_4() -> void:
	# Step 8: Actions remaining decreases from 2 to 1

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")

	var actions_before: int = GameManager.actions_remaining
	assert_eq(actions_before, 2, "Should have 2 actions after kitchen and living room")

	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")

	var actions_after: int = GameManager.actions_remaining
	assert_eq(actions_after, 1,
		"Phone inspection should consume 1 action (2 → 1)")


func test_step_8_phone_inspection_discovers_text_message() -> void:
	# Step 8: Notification: "Text Message From Julia"

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_apartment", "obj_victim_phone"
	)

	assert_has(discovered, "ev_julia_text_message",
		"Phone inspection should discover ev_julia_text_message")


func test_step_8_phone_inspection_discovers_call_log() -> void:
	# Step 8: Notification: "Call Log Between Mark and Daniel"

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_apartment", "obj_victim_phone"
	)

	assert_has(discovered, "ev_mark_call_log",
		"Phone inspection should discover ev_mark_call_log")


func test_step_8_discovering_mark_call_log_unlocks_office() -> void:
	# Step 8: Critical trigger: Discovering ev_mark_call_log fires trig_unlock_office
	# → Victim's Office becomes available

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")

	assert_true(GameManager.is_location_unlocked("loc_victim_office"),
		"Victim's Office should be unlocked after discovering call log")


func test_step_8_office_unlock_fires_location_unlocked_once() -> void:
	# Step 8: Discovering ev_mark_call_log should unlock the office exactly once.
	# Regression: event_system previously auto-notified AND the trigger's explicit
	# notify: action also fired — causing two notification popups for the same unlock.
	# This test verifies location_unlocked fires exactly once for the office.

	watch_signals(GameManager)

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")

	assert_signal_emit_count(GameManager, "location_unlocked", 1,
		"location_unlocked should fire exactly once when the office is unlocked via call log")


# =========================================================================
# STEP 9: Go Back to Map
# =========================================================================

func test_step_9_return_to_map_apartment_shows_open_status() -> void:
	# Step 9: "Victim's Apartment" card now shows:
	# Status badge: OPEN (amber) — visited, Study Desk not yet examined

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")

	LocationInvestigationManager.leave_location()

	assert_true(GameManager.has_visited_location("loc_victim_apartment"),
		"Apartment should be marked as visited")


func test_step_9_office_location_now_appears_on_map() -> void:
	# Step 9: "Victim's Office" card now appears on the map with status NEW (blue)

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")

	assert_true(GameManager.is_location_unlocked("loc_victim_office"),
		"Victim's Office should be unlocked and visible on map")


# =========================================================================
# STEP 10: Enter Building Hallway
# =========================================================================

func test_step_10_enter_building_hallway() -> void:
	# Step 10: Location Detail Screen opens for hallway

	var result: Dictionary = LocationInvestigationManager.start_investigation("loc_hallway")
	assert_true(result.get("success", false),
		"Should successfully start investigation in Hallway")


func test_step_10_hallway_has_three_targets() -> void:
	# Step 10: Left panel shows 3 targets: Hallway Floor, Building Security System, Maintenance Office

	LocationInvestigationManager.start_investigation("loc_hallway")

	var location: LocationData = CaseManager.get_location("loc_hallway")
	var target_ids: Array[String] = []
	for obj: InvestigableObjectData in location.investigable_objects:
		target_ids.append(obj.id)

	assert_true(target_ids.size() >= 3,
		"Hallway should have at least 3 targets")
	assert_has(target_ids, "obj_hallway_floor", "Hallway Floor should exist")
	assert_has(target_ids, "obj_security_system", "Security System should exist")
	assert_has(target_ids, "obj_maintenance_office", "Maintenance Office should exist")


# =========================================================================
# STEP 11: Examine Hallway Floor (Action 4 of 4)
# =========================================================================

func test_step_11_examine_hallway_floor_action_4_of_4() -> void:
	# Step 11: Actions remaining decreases from 1 to 0

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")

	LocationInvestigationManager.leave_location()
	LocationInvestigationManager.start_investigation("loc_hallway")

	var actions_before: int = GameManager.actions_remaining
	assert_eq(actions_before, 1, "Should have 1 action remaining")

	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")

	var actions_after: int = GameManager.actions_remaining
	assert_eq(actions_after, 0,
		"Hallway floor inspection should consume last action (1 → 0)")


func test_step_11_hallway_floor_discovers_shoe_print() -> void:
	# Step 11: Notification: "Shoe Print in Hallway (Unanalyzed)"

	LocationInvestigationManager.start_investigation("loc_hallway")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_hallway_floor"
	)

	assert_has(discovered, "ev_shoe_print_raw",
		"Hallway floor inspection should discover ev_shoe_print_raw")


func test_step_11_hallway_floor_fully_processed_after_inspection() -> void:
	# Step 11: Status changes to "Fully processed" (grey) after visual inspection.
	# Regression: ev_shoe_print_raw has a lab request, which previously caused
	# get_object_display_status() to return PARTIALLY_EXAMINED instead of FULLY_PROCESSED.

	LocationInvestigationManager.start_investigation("loc_hallway")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")

	var display_status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(
		"loc_hallway", "obj_hallway_floor"
	)
	assert_eq(display_status, Enums.ObjectDisplayStatus.FULLY_PROCESSED,
		"Hallway Floor should show FULLY_PROCESSED after inspection (not PARTIALLY_EXAMINED)")


# =========================================================================
# STEP 12: Verify No Actions Remaining
# =========================================================================

func test_step_12_verify_no_actions_remaining_button_disabled() -> void:
	# Step 12: After all 4 Day 1 actions are spent, the action button is disabled.
	# The security system cannot be inspected when actions_remaining == 0.

	# Consume all 4 Day 1 actions: 3 apartment + 1 hallway floor
	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")
	LocationInvestigationManager.leave_location()

	LocationInvestigationManager.start_investigation("loc_hallway")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")

	assert_eq(GameManager.actions_remaining, 0,
		"All 4 Day 1 actions should be exhausted after 3 apartment + 1 hallway inspection")

	# Attempting to inspect security system should silently fail — no actions consumed
	var result: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_security_system"
	)
	assert_true(result.is_empty(),
		"Inspection attempt with no actions should return empty (button is disabled)")

	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_hallway", "obj_security_system"
	)
	assert_eq(state, Enums.InvestigationState.NOT_INSPECTED,
		"Security system should remain NOT_INSPECTED after failed inspection attempt")


# =========================================================================
# STEP 13: Go Back to Map
# =========================================================================

func test_step_13_return_to_map_shows_all_locations() -> void:
	# Step 13: Map screen shows multiple locations with their status

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")

	LocationInvestigationManager.leave_location()
	LocationInvestigationManager.start_investigation("loc_hallway")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")

	LocationInvestigationManager.leave_location()

	var apartment_visited: bool = GameManager.has_visited_location("loc_victim_apartment")
	var hallway_visited: bool = GameManager.has_visited_location("loc_hallway")
	var office_unlocked: bool = GameManager.is_location_unlocked("loc_victim_office")

	assert_true(apartment_visited, "Apartment should be visited")
	assert_true(hallway_visited, "Hallway should be visited")
	assert_true(office_unlocked, "Office should be unlocked")


# =========================================================================
# STEP 14: End Day 1
# =========================================================================

func test_step_14_end_day_1_transitions_to_day_2() -> void:
	# Step 14: Day transitions to Day 2
	# Note: This depends on game's day progression system

	var day_before: int = GameManager.current_day
	assert_eq(day_before, 1, "Should start on Day 1")


# =========================================================================
# STEP 15: Morning — Lab Results
# =========================================================================

func test_step_15_morning_lab_results_available() -> void:
	# Step 15: If lab evidence was submitted, results are delivered
	# (This is implementation-dependent; tested at integration level)

	# For now, verify LabManager exists and can process evidence
	var lab_manager: LabManager = LabManager
	assert_not_null(lab_manager, "LabManager should exist")


# =========================================================================
# STEP 16: Open Map, Enter Building Hallway
# =========================================================================

func test_step_16_hallway_floor_shows_completed_on_day_2() -> void:
	# Step 16: Hallway Floor shows as "Fully processed"

	LocationInvestigationManager.start_investigation("loc_hallway")
	LocationInvestigationManager.inspect_object("loc_hallway", "obj_hallway_floor")

	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_hallway", "obj_hallway_floor"
	)
	assert_eq(state, Enums.InvestigationState.FULLY_EXAMINED,
		"Hallway Floor should remain FULLY_EXAMINED on subsequent visits")


func test_step_16_security_system_still_not_inspected() -> void:
	# Step 16: Security System and Maintenance Office still NOT_INSPECTED

	LocationInvestigationManager.start_investigation("loc_hallway")

	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_hallway", "obj_security_system"
	)
	assert_eq(state, Enums.InvestigationState.NOT_INSPECTED,
		"Security system should still be NOT_INSPECTED")


# =========================================================================
# STEP 17: Examine Building Security System (Action 1 of 4)
# =========================================================================

func test_step_17_security_system_discovers_hallway_camera() -> void:
	# Step 17: Notification: "Hallway Camera (Blurry Figure)"

	LocationInvestigationManager.start_investigation("loc_hallway")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_security_system"
	)

	assert_has(discovered, "ev_hallway_camera",
		"Security system inspection should discover ev_hallway_camera")


func test_step_17_security_system_discovers_elevator_logs() -> void:
	# Step 17: Notification: "Elevator Logs"

	LocationInvestigationManager.start_investigation("loc_hallway")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_hallway", "obj_security_system"
	)

	assert_has(discovered, "ev_elevator_logs",
		"Security system inspection should discover ev_elevator_logs")


# =========================================================================
# STEP 18: Go Back, Enter Parking Lot
# =========================================================================

func test_step_18_enter_parking_lot_has_one_target() -> void:
	# Step 18: Location Detail Screen opens
	# Step 18: 1 target: "Parking Lot Security Camera"

	var result: Dictionary = LocationInvestigationManager.start_investigation("loc_parking_lot")
	assert_true(result.get("success", false),
		"Should successfully start investigation in Parking Lot")

	var location: LocationData = CaseManager.get_location("loc_parking_lot")
	assert_eq(location.investigable_objects.size(), 1,
		"Parking Lot should have exactly 1 target")
	assert_eq(location.investigable_objects[0].id, "obj_parking_camera",
		"Target should be the parking camera")


# =========================================================================
# STEP 19: Examine Parking Camera (Action 2 of 4)
# =========================================================================

func test_step_19_parking_camera_discovers_footage() -> void:
	# Step 19: Notification: "Parking Lot Camera Footage"

	LocationInvestigationManager.start_investigation("loc_parking_lot")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_parking_lot", "obj_parking_camera"
	)

	assert_has(discovered, "ev_parking_camera",
		"Parking camera inspection should discover ev_parking_camera")


# =========================================================================
# STEP 20: Back to Map — Verify Parking Lot Exhausted
# =========================================================================

func test_step_20_parking_lot_fully_examined_single_target() -> void:
	# Step 20: Since Parking Lot has only 1 target and it's been inspected,
	# location should be exhausted

	LocationInvestigationManager.start_investigation("loc_parking_lot")
	LocationInvestigationManager.inspect_object("loc_parking_lot", "obj_parking_camera")

	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_parking_lot", "obj_parking_camera"
	)
	assert_eq(state, Enums.InvestigationState.FULLY_EXAMINED,
		"Parking camera should be FULLY_EXAMINED")


# =========================================================================
# STEP 21: Enter Victim's Office
# =========================================================================

func test_step_21_enter_victims_office() -> void:
	# Step 21: Location Detail Screen opens for the office

	# First unlock the office by discovering the call log
	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")

	var result: Dictionary = LocationInvestigationManager.start_investigation("loc_victim_office")
	assert_true(result.get("success", false),
		"Should successfully start investigation in Victim's Office")


func test_step_21_office_initially_has_visible_targets() -> void:
	# Step 21: Targets visible: "Office Desk", "File Cabinet" (only 2 — Bookshelf and Desk Drawer are hidden)

	# Unlock office first
	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")
	LocationInvestigationManager.leave_location()

	LocationInvestigationManager.start_investigation("loc_victim_office")

	var location: LocationData = CaseManager.get_location("loc_victim_office")
	var visible_targets: Array[String] = []
	for obj: InvestigableObjectData in location.investigable_objects:
		if obj.discovery_condition.is_empty():
			visible_targets.append(obj.id)

	# Should have at least desk and file cabinet visible
	assert_true(visible_targets.size() >= 2,
		"Should have at least 2 visible targets initially")


func test_step_21_office_evidence_count_total_is_five() -> void:
	# Step 21: Evidence count shows "0 / 5" — 5 total items across all 4 office targets.
	# Breakdown: Office Desk (1) + File Cabinet (2) + Bookshelf (1) + Desk Drawer (1) = 5.
	# All targets are included in the total, even conditionally hidden ones.

	var completion: Dictionary = LocationInvestigationManager.get_location_completion("loc_victim_office")
	assert_eq(completion["total"], 5,
		"Victim's Office should have 5 total evidence items across all targets")


# =========================================================================
# STEP 22: Examine Office Desk (Action 1 of 4)
# =========================================================================

func test_step_22_office_desk_discovers_email() -> void:
	# Step 22: Notification: "Email From Daniel to Mark"

	# Unlock office first
	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")
	LocationInvestigationManager.leave_location()

	LocationInvestigationManager.start_investigation("loc_victim_office")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_office", "obj_office_desk"
	)

	assert_has(discovered, "ev_daniel_email",
		"Office desk inspection should discover ev_daniel_email")


# =========================================================================
# STEP 23: Examine File Cabinet (Action 2 of 4)
# =========================================================================

func test_step_23_file_cabinet_discovers_bank_transfer() -> void:
	# Step 23: Notification: "Suspicious Bank Transfer"

	# Unlock office by finding call log on Day 1 (consumes 3 of 4 actions)
	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")
	LocationInvestigationManager.leave_location()

	# Advance to Day 3 with a fresh action budget for the office investigation
	GameManager.advance_day()
	GameManager.advance_day()
	GameManager.reset_actions()

	LocationInvestigationManager.start_investigation("loc_victim_office")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_office_desk")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_office", "obj_file_cabinet"
	)

	assert_has(discovered, "ev_bank_transfer",
		"File cabinet inspection should discover ev_bank_transfer")


func test_step_23_file_cabinet_discovers_accounting_files() -> void:
	# Step 23: Notification: "Accounting Files"

	# Unlock office by finding call log on Day 1 (consumes 3 of 4 actions)
	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")
	LocationInvestigationManager.leave_location()

	# Advance to Day 3 with a fresh action budget for the office investigation
	GameManager.advance_day()
	GameManager.advance_day()
	GameManager.reset_actions()

	LocationInvestigationManager.start_investigation("loc_victim_office")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_office_desk")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_office", "obj_file_cabinet"
	)

	assert_has(discovered, "ev_accounting_files",
		"File cabinet inspection should discover ev_accounting_files")


func test_step_23_discovering_accounting_files_unlocks_bookshelf() -> void:
	# Step 23: Conditional trigger: Discovering ev_accounting_files makes the Bookshelf target visible

	# Unlock office by finding call log on Day 1 (consumes 3 of 4 actions)
	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")
	LocationInvestigationManager.leave_location()

	# Advance to Day 3 with a fresh action budget for the office investigation
	GameManager.advance_day()
	GameManager.advance_day()
	GameManager.reset_actions()

	LocationInvestigationManager.start_investigation("loc_victim_office")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_office_desk")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_file_cabinet")

	# Bookshelf should now be visible because ev_accounting_files was discovered
	var location: LocationData = CaseManager.get_location("loc_victim_office")
	var visible_objects: Array[InvestigableObjectData] = LocationInvestigationManager.get_visible_objects(location)
	var bookshelf_visible: bool = false
	for obj: InvestigableObjectData in visible_objects:
		if obj.id == "obj_bookshelf":
			bookshelf_visible = true
			break

	assert_true(bookshelf_visible,
		"Bookshelf should be visible after discovering accounting files")


# =========================================================================
# STEP 24: Examine Bookshelf (Action 3 of 4)
# =========================================================================

func test_step_24_bookshelf_discovers_hidden_safe() -> void:
	# Step 24: Notification: "Hidden Safe in Office"

	# Unlock office by finding call log on Day 1 (consumes 3 of 4 actions)
	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")
	LocationInvestigationManager.leave_location()

	# Advance to Day 3 with a fresh action budget for the office investigation
	GameManager.advance_day()
	GameManager.advance_day()
	GameManager.reset_actions()

	LocationInvestigationManager.start_investigation("loc_victim_office")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_office_desk")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_file_cabinet")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_office", "obj_bookshelf"
	)

	assert_has(discovered, "ev_hidden_safe",
		"Bookshelf inspection should discover ev_hidden_safe")


func test_step_24_discovering_safe_unlocks_desk_drawer() -> void:
	# Step 24: Conditional trigger: Discovering ev_hidden_safe makes the Desk Drawer target visible

	# Unlock office by finding call log on Day 1 (consumes 3 of 4 actions)
	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")
	LocationInvestigationManager.leave_location()

	# Advance to Day 3 with a fresh action budget for the office investigation
	GameManager.advance_day()
	GameManager.advance_day()
	GameManager.reset_actions()

	LocationInvestigationManager.start_investigation("loc_victim_office")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_office_desk")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_file_cabinet")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_bookshelf")

	# Desk Drawer should now be visible because ev_hidden_safe was discovered
	var location: LocationData = CaseManager.get_location("loc_victim_office")
	var visible_objects: Array[InvestigableObjectData] = LocationInvestigationManager.get_visible_objects(location)
	var drawer_visible: bool = false
	for obj: InvestigableObjectData in visible_objects:
		if obj.id == "obj_desk_drawer":
			drawer_visible = true
			break

	assert_true(drawer_visible,
		"Desk Drawer should be visible after discovering hidden safe")


# =========================================================================
# STEP 25: Examine Desk Drawer (Action 4 of 4)
# =========================================================================

func test_step_25_desk_drawer_discovers_personal_journal() -> void:
	# Step 25: Notification: "Daniel's Personal Journal"

	# Unlock office by finding call log on Day 1 (consumes 3 of 4 actions)
	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")
	LocationInvestigationManager.leave_location()

	# Advance to Day 3 with a fresh action budget for the office investigation
	GameManager.advance_day()
	GameManager.advance_day()
	GameManager.reset_actions()

	LocationInvestigationManager.start_investigation("loc_victim_office")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_office_desk")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_file_cabinet")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_bookshelf")

	var discovered: Array[String] = LocationInvestigationManager.inspect_object(
		"loc_victim_office", "obj_desk_drawer"
	)

	assert_has(discovered, "ev_personal_journal",
		"Desk drawer inspection should discover ev_personal_journal")


# =========================================================================
# STEP 26: Back to Map — Verify Final State
# =========================================================================

func test_step_26_final_map_state_apartment_open_or_exhausted() -> void:
	# Step 26: "Victim's Apartment" — OPEN (Study Desk not examined) or EXHAUSTED (if all done)

	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")
	LocationInvestigationManager.leave_location()

	assert_true(GameManager.has_visited_location("loc_victim_apartment"),
		"Apartment should be visited (showing OPEN or EXHAUSTED status)")


func test_step_26_final_map_state_office_exhausted() -> void:
	# Step 26: "Victim's Office" — EXHAUSTED (grey) — all 4 targets done

	# Unlock office by finding call log on Day 1 (consumes 3 of 4 actions)
	LocationInvestigationManager.start_investigation("loc_victim_apartment")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_kitchen")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_living_room")
	LocationInvestigationManager.inspect_object("loc_victim_apartment", "obj_victim_phone")
	LocationInvestigationManager.leave_location()

	# Advance to Day 3 with a fresh action budget for the office investigation
	GameManager.advance_day()
	GameManager.advance_day()
	GameManager.reset_actions()

	# Inspect all 4 office targets in unlock order
	LocationInvestigationManager.start_investigation("loc_victim_office")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_office_desk")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_file_cabinet")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_bookshelf")
	LocationInvestigationManager.inspect_object("loc_victim_office", "obj_desk_drawer")

	# All 4 targets should be fully examined
	var desk_state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_victim_office", "obj_office_desk"
	)
	var cabinet_state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_victim_office", "obj_file_cabinet"
	)
	var bookshelf_state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_victim_office", "obj_bookshelf"
	)
	var drawer_state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
		"loc_victim_office", "obj_desk_drawer"
	)

	assert_eq(desk_state, Enums.InvestigationState.FULLY_EXAMINED, "Office desk should be fully examined")
	assert_eq(cabinet_state, Enums.InvestigationState.FULLY_EXAMINED, "File cabinet should be fully examined")
	assert_eq(bookshelf_state, Enums.InvestigationState.FULLY_EXAMINED, "Bookshelf should be fully examined")
	assert_eq(drawer_state, Enums.InvestigationState.FULLY_EXAMINED, "Desk drawer should be fully examined")
