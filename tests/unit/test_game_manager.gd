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
	assert_eq(GameManager.current_phase, Enums.DayPhase.MORNING, "Game should start in the morning")
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


# --- Day Phase --- #

func test_phase_display_morning() -> void:
	GameManager.current_phase = Enums.DayPhase.MORNING
	assert_eq(GameManager.get_phase_display(), "Morning")


func test_phase_display_daytime() -> void:
	GameManager.current_phase = Enums.DayPhase.DAYTIME
	assert_eq(GameManager.get_phase_display(), "Daytime")


func test_phase_display_night() -> void:
	GameManager.current_phase = Enums.DayPhase.NIGHT
	assert_eq(GameManager.get_phase_display(), "Night")


func test_is_daytime_returns_true_during_daytime() -> void:
	GameManager.current_phase = Enums.DayPhase.DAYTIME
	assert_true(GameManager.is_daytime(), "is_daytime() should return true during Daytime")


func test_is_daytime_returns_false_during_morning() -> void:
	GameManager.current_phase = Enums.DayPhase.MORNING
	assert_false(GameManager.is_daytime(), "is_daytime() should return false during Morning")


func test_is_daytime_returns_false_during_night() -> void:
	GameManager.current_phase = Enums.DayPhase.NIGHT
	assert_false(GameManager.is_daytime(), "is_daytime() should return false during Night")


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
	DaySystem.process_morning()
	DaySystem.try_end_day()
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
	var action_log: Array[Dictionary] = GameManager.get_investigation_log()
	assert_gt(action_log.size(), 0, "Log should have entries after actions")


func test_log_entries_have_correct_structure() -> void:
	GameManager.discover_evidence("ev_test")
	var action_log: Array[Dictionary] = GameManager.get_investigation_log()
	var entry: Dictionary = action_log[action_log.size() - 1]
	assert_has(entry, "day")
	assert_has(entry, "phase")
	assert_has(entry, "description")
	assert_has(entry, "timestamp")


# --- Serialization --- #

func test_serialize_produces_valid_dictionary() -> void:
	GameManager.discover_evidence("ev_test")
	GameManager.visit_location("loc_apartment")
	var data: Dictionary = GameManager.serialize()
	assert_has(data, "current_day")
	assert_has(data, "current_phase")
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


# --- Investigation Log --- #

func test_log_entry_phase_is_enum_not_string() -> void:
	GameManager.current_phase = Enums.DayPhase.MORNING
	GameManager.log_action("Test action")
	var log: Array[Dictionary] = GameManager.get_investigation_log()
	assert_false(log.is_empty(), "Log should have entries")
	var entry: Dictionary = log[log.size() - 1]
	assert_eq(entry["phase"], Enums.DayPhase.MORNING,
		"phase should be the enum value, not a string")


func test_log_entry_exists_for_all_phases() -> void:
	for phase: int in [Enums.DayPhase.MORNING, Enums.DayPhase.DAYTIME,
						Enums.DayPhase.NIGHT]:
		GameManager.current_phase = phase as Enums.DayPhase
		GameManager.log_action("Action at phase %d" % phase)
	var log: Array[Dictionary] = GameManager.get_investigation_log()
	assert_eq(log.size(), 3, "Should have 3 entries (one per phase)")


func test_evidence_log_shows_name_not_id() -> void:
	CaseManager.load_case_folder("riverside_apartment")
	GameManager.new_game()
	GameManager.discover_evidence("ev_knife")
	var log: Array[Dictionary] = GameManager.get_investigation_log()
	var last_entry: Dictionary = log[log.size() - 1]
	var desc: String = last_entry.get("description", "")
	assert_false(desc.contains("ev_knife"),
		"Log should not contain raw evidence ID")
	assert_true(desc.contains("Kitchen Knife") or desc.contains("Murder Weapon"),
		"Log should contain the evidence name")
	CaseManager.unload_case()


func test_location_log_shows_name_not_id() -> void:
	CaseManager.load_case_folder("riverside_apartment")
	GameManager.new_game()
	GameManager.visit_location("loc_victim_apartment")
	var log: Array[Dictionary] = GameManager.get_investigation_log()
	var last_entry: Dictionary = log[log.size() - 1]
	var desc: String = last_entry.get("description", "")
	assert_false(desc.contains("loc_victim_apartment"),
		"Log should not contain raw location ID")
	assert_true(desc.contains("Victim's Apartment"),
		"Log should contain the location name")
	CaseManager.unload_case()


# --- Day Range --- #

func test_timeline_day_range_day1() -> void:
	GameManager.current_day = 1
	var max_day: int = GameManager.current_day
	assert_eq(max_day, 1, "On day 1, max selectable day should be 1")


func test_timeline_day_range_day3() -> void:
	GameManager.current_day = 3
	var max_day: int = GameManager.current_day
	assert_eq(max_day, 3, "On day 3, max selectable day should be 3")


func test_timeline_day_range_never_exceeds_current() -> void:
	GameManager.current_day = 2
	var case_end_day: int = 4
	var max_day: int = GameManager.current_day
	assert_true(max_day <= case_end_day, "max_day should not exceed case end day")
	assert_eq(max_day, 2, "max_day should match current_day, not case end_day")


# --- Game Reset --- #

func test_game_reset_emits_signal() -> void:
	watch_signals(GameManager)
	GameManager.new_game()
	assert_signal_emitted(GameManager, "game_reset",
		"new_game should emit game_reset")


# --- Location Unlock Tracking --- #

func test_unlock_location_adds_to_unlocked_list() -> void:
	GameManager.unlock_location("loc_test")
	assert_true(GameManager.is_location_unlocked("loc_test"),
		"unlock_location should add to unlocked_locations")


func test_unlock_location_does_not_mark_visited() -> void:
	GameManager.unlock_location("loc_test")
	assert_false(GameManager.has_visited_location("loc_test"),
		"unlock_location should NOT mark location as visited")


func test_visit_location_also_unlocks() -> void:
	GameManager.visit_location("loc_test")
	assert_true(GameManager.is_location_unlocked("loc_test"),
		"visit_location should also add to unlocked_locations")
	assert_true(GameManager.has_visited_location("loc_test"),
		"visit_location should mark as visited")


func test_unlocked_locations_cleared_on_new_game() -> void:
	GameManager.unlock_location("loc_test")
	GameManager.new_game()
	assert_false(GameManager.is_location_unlocked("loc_test"),
		"new_game should clear unlocked_locations")


func test_unlocked_locations_serialized() -> void:
	GameManager.unlock_location("loc_a")
	GameManager.unlock_location("loc_b")
	var data: Dictionary = GameManager.serialize()
	assert_true(data.has("unlocked_locations"),
		"Serialized data should include unlocked_locations")
	assert_has(data["unlocked_locations"], "loc_a")
	assert_has(data["unlocked_locations"], "loc_b")


func test_unlocked_locations_deserialized() -> void:
	var data: Dictionary = GameManager.serialize()
	data["unlocked_locations"] = ["loc_x", "loc_y"]
	GameManager.deserialize(data)
	assert_true(GameManager.is_location_unlocked("loc_x"))
	assert_true(GameManager.is_location_unlocked("loc_y"))
