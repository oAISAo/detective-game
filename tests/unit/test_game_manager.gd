## test_game_manager.gd
## Unit tests for the GameManager autoload singleton.
## Phase 0: Verify initialization, evidence tracking, action economy,
## day progression, mandatory actions, interrogation limits, and serialization.
extends GutTest


# --- Setup --- #

func before_each() -> void:
	GameManager.new_game()


# --- Initialization --- #

func test_initial_state() -> void:
	assert_eq(GameManager.current_day, 1, "Game should start on day 1")
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.MORNING, "Game should start in the morning")
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY, "Should have full actions")
	assert_eq(GameManager.discovered_evidence.size(), 0, "No evidence discovered at start")
	assert_eq(GameManager.discovered_insights.size(), 0, "No insights at start")
	assert_eq(GameManager.visited_locations.size(), 0, "No locations visited at start")
	assert_eq(GameManager.hints_used, 0, "No hints used at start")
	assert_true(GameManager.game_active, "Game should be active after new_game")


# --- Evidence Discovery --- #

func test_discover_evidence_returns_true_for_new() -> void:
	var result: bool = GameManager.discover_evidence("ev_test_01")
	assert_true(result, "Should return true for new evidence")


func test_discover_evidence_returns_false_for_duplicate() -> void:
	GameManager.discover_evidence("ev_test_01")
	var result: bool = GameManager.discover_evidence("ev_test_01")
	assert_false(result, "Should return false for already-discovered evidence")


func test_has_evidence() -> void:
	assert_false(GameManager.has_evidence("ev_test_01"), "Should not have undiscovered evidence")
	GameManager.discover_evidence("ev_test_01")
	assert_true(GameManager.has_evidence("ev_test_01"), "Should have discovered evidence")


func test_discover_evidence_emits_signal() -> void:
	watch_signals(GameManager)
	GameManager.discover_evidence("ev_test_01")
	assert_signal_emitted_with_parameters(GameManager, "evidence_discovered", ["ev_test_01"])


# --- Insight Discovery --- #

func test_discover_insight_returns_true_for_new() -> void:
	var result: bool = GameManager.discover_insight("insight_01")
	assert_true(result, "Should return true for new insight")


func test_discover_insight_returns_false_for_duplicate() -> void:
	GameManager.discover_insight("insight_01")
	var result: bool = GameManager.discover_insight("insight_01")
	assert_false(result, "Should return false for duplicate insight")


# --- Location Visits --- #

func test_visit_location_first_time() -> void:
	var result: bool = GameManager.visit_location("loc_apartment")
	assert_true(result, "First visit should return true")
	assert_true(GameManager.has_visited_location("loc_apartment"))


func test_visit_location_second_time() -> void:
	GameManager.visit_location("loc_apartment")
	var result: bool = GameManager.visit_location("loc_apartment")
	assert_false(result, "Second visit should return false")


# --- Action Economy --- #

func test_use_action_deducts_correctly() -> void:
	var initial: int = GameManager.actions_remaining
	GameManager.use_action()
	assert_eq(GameManager.actions_remaining, initial - 1, "Action should be deducted")


func test_use_action_returns_false_when_none_remaining() -> void:
	# Use all actions
	for i: int in range(GameManager.ACTIONS_PER_DAY):
		GameManager.use_action()
	var result: bool = GameManager.use_action()
	assert_false(result, "Should return false when no actions remain")


func test_has_actions_remaining() -> void:
	assert_true(GameManager.has_actions_remaining(), "Should have actions at start")
	for i: int in range(GameManager.ACTIONS_PER_DAY):
		GameManager.use_action()
	assert_false(GameManager.has_actions_remaining(), "Should have no actions after using all")


func test_actions_remaining_signal() -> void:
	watch_signals(GameManager)
	GameManager.use_action()
	assert_signal_emitted(GameManager, "actions_remaining_changed")


# --- Mandatory Actions --- #

func test_mandatory_actions_block_when_incomplete() -> void:
	GameManager.mandatory_actions_required.append("action_01")
	assert_false(GameManager.all_mandatory_actions_completed(), "Should not be complete")


func test_mandatory_actions_pass_when_complete() -> void:
	GameManager.mandatory_actions_required.append("action_01")
	GameManager.complete_mandatory_action("action_01")
	assert_true(GameManager.all_mandatory_actions_completed(), "Should be complete")


func test_complete_mandatory_action_returns_false_for_non_required() -> void:
	var result: bool = GameManager.complete_mandatory_action("not_required")
	assert_false(result, "Should return false for non-required action")


func test_complete_mandatory_action_returns_false_for_already_completed() -> void:
	GameManager.mandatory_actions_required.append("action_01")
	GameManager.complete_mandatory_action("action_01")
	var result: bool = GameManager.complete_mandatory_action("action_01")
	assert_false(result, "Should return false for already-completed action")


func test_get_remaining_mandatory_actions() -> void:
	GameManager.mandatory_actions_required.append("action_01")
	GameManager.mandatory_actions_required.append("action_02")
	GameManager.complete_mandatory_action("action_01")
	var remaining: Array[String] = GameManager.get_remaining_mandatory_actions()
	assert_eq(remaining.size(), 1)
	assert_eq(remaining[0], "action_02")


# --- Day Progression --- #

func test_advance_time_slot_morning_to_afternoon() -> void:
	GameManager.current_time_slot = Enums.TimeSlot.MORNING
	var result: Enums.TimeSlot = GameManager.advance_time_slot()
	assert_eq(result, Enums.TimeSlot.AFTERNOON)


func test_advance_time_slot_afternoon_to_evening() -> void:
	GameManager.current_time_slot = Enums.TimeSlot.AFTERNOON
	var result: Enums.TimeSlot = GameManager.advance_time_slot()
	assert_eq(result, Enums.TimeSlot.EVENING)


func test_advance_time_slot_evening_to_night() -> void:
	GameManager.current_time_slot = Enums.TimeSlot.EVENING
	var result: Enums.TimeSlot = GameManager.advance_time_slot()
	assert_eq(result, Enums.TimeSlot.NIGHT)


func test_advance_time_slot_night_advances_day() -> void:
	GameManager.current_time_slot = Enums.TimeSlot.NIGHT
	GameManager.advance_time_slot()
	assert_eq(GameManager.current_day, 2, "Day should advance from night")
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.MORNING, "Should be morning after night")


func test_day_does_not_advance_past_total_days() -> void:
	GameManager.current_day = GameManager.TOTAL_DAYS
	GameManager.current_time_slot = Enums.TimeSlot.NIGHT
	GameManager.advance_time_slot()
	assert_eq(GameManager.current_day, GameManager.TOTAL_DAYS, "Day should not exceed total days")


func test_actions_reset_on_new_day() -> void:
	GameManager.use_action()
	GameManager.current_time_slot = Enums.TimeSlot.NIGHT
	GameManager.advance_time_slot()
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY, "Actions should reset on new day")


func test_time_slot_display_strings() -> void:
	GameManager.current_time_slot = Enums.TimeSlot.MORNING
	assert_eq(GameManager.get_time_slot_display(), "Morning")
	GameManager.current_time_slot = Enums.TimeSlot.AFTERNOON
	assert_eq(GameManager.get_time_slot_display(), "Afternoon")
	GameManager.current_time_slot = Enums.TimeSlot.EVENING
	assert_eq(GameManager.get_time_slot_display(), "Evening")
	GameManager.current_time_slot = Enums.TimeSlot.NIGHT
	assert_eq(GameManager.get_time_slot_display(), "Night")


# --- Interrogation Tracking --- #

func test_record_interrogation_allowed() -> void:
	var result: bool = GameManager.record_interrogation("p_julia")
	assert_true(result, "First interrogation should be allowed")


func test_record_interrogation_blocked_after_limit() -> void:
	GameManager.record_interrogation("p_julia")
	var result: bool = GameManager.record_interrogation("p_julia")
	assert_false(result, "Second interrogation same day should be blocked")


func test_can_interrogate_today() -> void:
	assert_true(GameManager.can_interrogate_today("p_julia"))
	GameManager.record_interrogation("p_julia")
	assert_false(GameManager.can_interrogate_today("p_julia"))


func test_interrogation_counts_reset_on_new_day() -> void:
	GameManager.record_interrogation("p_julia")
	GameManager.current_time_slot = Enums.TimeSlot.NIGHT
	GameManager.advance_time_slot()
	assert_true(GameManager.can_interrogate_today("p_julia"), "Interrogation should be available on new day")


# --- Hints --- #

func test_use_hint_returns_true_when_available() -> void:
	var result: bool = GameManager.use_hint()
	assert_true(result, "Should return true when hints remain")


func test_use_hint_returns_false_when_exhausted() -> void:
	for i: int in range(GameManager.MAX_HINTS_PER_CASE):
		GameManager.use_hint()
	var result: bool = GameManager.use_hint()
	assert_false(result, "Should return false when hints exhausted")


func test_get_hints_remaining() -> void:
	assert_eq(GameManager.get_hints_remaining(), GameManager.MAX_HINTS_PER_CASE)
	GameManager.use_hint()
	assert_eq(GameManager.get_hints_remaining(), GameManager.MAX_HINTS_PER_CASE - 1)


# --- Investigation Log --- #

func test_log_records_actions() -> void:
	GameManager.discover_evidence("ev_test")
	var log: Array[Dictionary] = GameManager.get_investigation_log()
	assert_gt(log.size(), 0, "Log should have entries after actions")


func test_log_entries_have_correct_structure() -> void:
	GameManager.discover_evidence("ev_test")
	var log: Array[Dictionary] = GameManager.get_investigation_log()
	var entry: Dictionary = log[log.size() - 1]
	assert_has(entry, "day")
	assert_has(entry, "time_slot")
	assert_has(entry, "description")
	assert_has(entry, "timestamp")


# --- Serialization --- #

func test_serialize_produces_valid_dictionary() -> void:
	GameManager.discover_evidence("ev_test")
	GameManager.visit_location("loc_apartment")
	var data: Dictionary = GameManager.serialize()
	assert_has(data, "current_day")
	assert_has(data, "current_time_slot")
	assert_has(data, "actions_remaining")
	assert_has(data, "discovered_evidence")
	assert_has(data, "visited_locations")
	assert_has(data, "hints_used")
	assert_has(data, "game_active")


func test_deserialize_restores_state() -> void:
	GameManager.discover_evidence("ev_test_01")
	GameManager.discover_evidence("ev_test_02")
	GameManager.visit_location("loc_apartment")
	GameManager.use_action()
	GameManager.use_hint()
	var saved: Dictionary = GameManager.serialize()

	# Reset and restore
	GameManager.new_game()
	assert_eq(GameManager.discovered_evidence.size(), 0, "Should be reset")

	GameManager.deserialize(saved)
	assert_eq(GameManager.discovered_evidence.size(), 2, "Should have 2 evidence items after restore")
	assert_true(GameManager.has_evidence("ev_test_01"))
	assert_true(GameManager.has_evidence("ev_test_02"))
	assert_true(GameManager.has_visited_location("loc_apartment"))
	assert_eq(GameManager.hints_used, 1)
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY - 1)


func test_new_game_resets_all_state() -> void:
	GameManager.discover_evidence("ev_test")
	GameManager.visit_location("loc_apartment")
	GameManager.use_action()
	GameManager.use_hint()
	GameManager.new_game()

	assert_eq(GameManager.current_day, 1)
	assert_eq(GameManager.discovered_evidence.size(), 0)
	assert_eq(GameManager.visited_locations.size(), 0)
	assert_eq(GameManager.hints_used, 0)
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY)
