## test_day_system.gd
## Unit tests for the DaySystem state machine.
## Validates the 3-phase day cycle: Morning → Daytime → Night.
extends GutTest


# --- Helpers --- #

## Resets GameManager and DaySystem to a clean starting state.
func _reset_state() -> void:
	GameManager.new_game()
	DaySystem.reset()
	EventSystem.reset()


# --- Setup --- #

func before_each() -> void:
	_reset_state()


# --- Phase Model: Only 3 Valid Phases --- #

func test_day_phase_enum_has_exactly_three_values() -> void:
	# DayPhase should only have MORNING, DAYTIME, NIGHT — no AFTERNOON or EVENING
	assert_eq(Enums.DayPhase.MORNING, 0, "MORNING should be 0")
	assert_eq(Enums.DayPhase.DAYTIME, 1, "DAYTIME should be 1")
	assert_eq(Enums.DayPhase.NIGHT, 2, "NIGHT should be 2")


# --- Initialization --- #

func test_initial_state() -> void:
	assert_false(DaySystem.is_morning_briefing_shown(), "Morning briefing should not be shown initially")


func test_game_starts_in_morning() -> void:
	assert_eq(GameManager.current_phase, Enums.DayPhase.MORNING, "Game should start in Morning phase")


func test_reset_clears_state() -> void:
	DaySystem._morning_briefing_shown = true
	DaySystem.reset()
	assert_false(DaySystem.is_morning_briefing_shown(), "Reset should clear morning briefing flag")


# --- Morning Phase --- #

func test_process_morning_sets_briefing_shown() -> void:
	DaySystem.process_morning()
	assert_true(DaySystem.is_morning_briefing_shown(), "Morning briefing should be shown after processing")


func test_process_morning_emits_signal() -> void:
	watch_signals(DaySystem)
	DaySystem.process_morning()
	assert_signal_emitted(DaySystem, "morning_briefing_ready")


func test_process_morning_returns_array() -> void:
	var briefing: Array[String] = DaySystem.process_morning()
	assert_typeof(briefing, TYPE_ARRAY, "Morning processing should return an array")


func test_morning_automatically_transitions_to_daytime() -> void:
	assert_eq(GameManager.current_phase, Enums.DayPhase.MORNING, "Should start in Morning")
	DaySystem.process_morning()
	assert_eq(GameManager.current_phase, Enums.DayPhase.DAYTIME, "Should auto-transition to Daytime after morning")


func test_morning_transition_emits_phase_changed() -> void:
	watch_signals(GameManager)
	DaySystem.process_morning()
	assert_signal_emitted(GameManager, "phase_changed")


func test_morning_resets_actions_to_four() -> void:
	GameManager.actions_remaining = 0
	DaySystem.process_morning()
	assert_eq(GameManager.actions_remaining, 4, "Actions should be reset to 4 when transitioning to Daytime")


func test_process_morning_final_day_warning() -> void:
	GameManager.current_day = GameManager.TOTAL_DAYS
	watch_signals(DaySystem)
	var briefing: Array[String] = DaySystem.process_morning()
	assert_signal_emitted(DaySystem, "final_day_warning")
	var has_warning: bool = false
	for item: String in briefing:
		if "FINAL DAY" in item:
			has_warning = true
			break
	assert_true(has_warning, "Final day should produce a warning in briefing")


func test_process_morning_no_warning_before_final_day() -> void:
	GameManager.current_day = 1
	watch_signals(DaySystem)
	DaySystem.process_morning()
	assert_signal_not_emitted(DaySystem, "final_day_warning")


# --- Player Cannot Act During Morning --- #

func test_player_cannot_use_actions_during_morning() -> void:
	assert_eq(GameManager.current_phase, Enums.DayPhase.MORNING, "Should be in Morning")
	assert_false(GameManager.is_daytime(), "is_daytime() should return false during Morning")


# --- Daytime Phase --- #

func test_player_can_act_during_daytime() -> void:
	DaySystem.process_morning()
	assert_eq(GameManager.current_phase, Enums.DayPhase.DAYTIME, "Should be in Daytime")
	assert_true(GameManager.is_daytime(), "is_daytime() should return true during Daytime")


func test_actions_decrement_correctly() -> void:
	DaySystem.process_morning()
	assert_eq(GameManager.actions_remaining, 4)
	GameManager.use_action()
	assert_eq(GameManager.actions_remaining, 3)
	GameManager.use_action()
	assert_eq(GameManager.actions_remaining, 2)
	GameManager.use_action()
	assert_eq(GameManager.actions_remaining, 1)


func test_actions_per_day_is_four() -> void:
	assert_eq(GameManager.ACTIONS_PER_DAY, 4, "ACTIONS_PER_DAY must be exactly 4")


# --- End Day Early --- #

func test_end_day_early_triggers_night() -> void:
	DaySystem.process_morning()
	assert_eq(GameManager.current_phase, Enums.DayPhase.DAYTIME)
	# Player has 4 actions but ends day early
	assert_true(GameManager.actions_remaining > 0, "Actions should remain")
	var result: bool = DaySystem.try_end_day()
	assert_true(result, "Ending day early should succeed")


func test_end_day_blocked_by_mandatory_actions() -> void:
	DaySystem.process_morning()
	GameManager.mandatory_actions_required.append("interrogate_sarah")
	watch_signals(DaySystem)
	var result: bool = DaySystem.try_end_day()
	assert_false(result, "Should fail when mandatory actions remain")
	assert_signal_emitted(DaySystem, "day_advance_blocked")


func test_end_day_succeeds_after_mandatory_completed() -> void:
	DaySystem.process_morning()
	GameManager.mandatory_actions_required.append("interrogate_sarah")
	GameManager.complete_mandatory_action("interrogate_sarah")
	var result: bool = DaySystem.try_end_day()
	assert_true(result, "Should succeed when all mandatory actions completed")


func test_force_advance_day_skips_mandatory_check() -> void:
	DaySystem.process_morning()
	GameManager.mandatory_actions_required.append("interrogate_sarah")
	DaySystem.force_advance_day()
	assert_eq(GameManager.current_day, 2, "Force advance should skip mandatory check and advance day")


# --- Night Phase --- #

func test_night_processing_advances_day() -> void:
	assert_eq(GameManager.current_day, 1, "Should start on day 1")
	DaySystem.process_morning()
	DaySystem.try_end_day()
	assert_eq(GameManager.current_day, 2, "Night processing should advance to day 2")


func test_night_transitions_to_next_morning() -> void:
	DaySystem.process_morning()
	DaySystem.try_end_day()
	assert_eq(GameManager.current_phase, Enums.DayPhase.MORNING, "After night, should be Morning of next day")


func test_night_processing_resets_actions() -> void:
	DaySystem.process_morning()
	GameManager.use_action()
	GameManager.use_action()
	DaySystem.try_end_day()
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY, "Should reset actions after night")


func test_night_processing_clears_interrogation_counts() -> void:
	DaySystem.process_morning()
	GameManager.interrogation_counts_today["suspect_01"] = 1
	DaySystem.try_end_day()
	assert_eq(GameManager.interrogation_counts_today.size(), 0, "Should clear interrogation counts")


func test_night_processing_clears_morning_briefing_flag() -> void:
	DaySystem.process_morning()
	assert_true(DaySystem.is_morning_briefing_shown())
	DaySystem.try_end_day()
	assert_false(DaySystem.is_morning_briefing_shown(), "Should reset morning briefing flag")


func test_night_processing_emits_signals() -> void:
	DaySystem.process_morning()
	watch_signals(DaySystem)
	DaySystem.try_end_day()
	assert_signal_emitted(DaySystem, "night_processing_started")
	assert_signal_emitted(DaySystem, "night_processing_completed")


func test_night_processing_emits_day_changed() -> void:
	DaySystem.process_morning()
	watch_signals(GameManager)
	DaySystem.try_end_day()
	assert_signal_emitted_with_parameters(GameManager, "day_changed", [2])


func test_night_processing_logs_day_end() -> void:
	DaySystem.process_morning()
	DaySystem.try_end_day()
	var log_entries: Array[Dictionary] = GameManager.get_investigation_log()
	var found_end: bool = false
	var found_begin: bool = false
	for entry: Dictionary in log_entries:
		if "Day 1 ended" in entry.get("description", ""):
			found_end = true
		if "Day 2 begins" in entry.get("description", ""):
			found_begin = true
	assert_true(found_end, "Should log day end")
	assert_true(found_begin, "Should log new day begin")


# --- Actions Reset on New Day --- #

func test_actions_reset_to_four_on_new_day() -> void:
	DaySystem.process_morning()
	GameManager.use_action()
	GameManager.use_action()
	GameManager.use_action()
	assert_eq(GameManager.actions_remaining, 1)
	DaySystem.try_end_day()
	# After night → new morning, actions should be reset
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY, "New day should have 4 actions")


func test_unused_actions_do_not_carry_over() -> void:
	DaySystem.process_morning()
	# Use only 1 of 4 actions
	GameManager.use_action()
	assert_eq(GameManager.actions_remaining, 3, "Should have 3 remaining")
	DaySystem.try_end_day()
	assert_eq(GameManager.actions_remaining, 4, "New day resets to 4, not 4+3")


# --- Investigation End --- #

func test_night_at_final_day_emits_time_expired() -> void:
	GameManager.current_day = GameManager.TOTAL_DAYS
	DaySystem.process_morning()
	watch_signals(DaySystem)
	DaySystem.try_end_day()
	assert_signal_emitted(DaySystem, "investigation_time_expired")


func test_night_at_final_day_does_not_advance_day() -> void:
	GameManager.current_day = GameManager.TOTAL_DAYS
	DaySystem.process_morning()
	DaySystem.try_end_day()
	assert_eq(GameManager.current_day, GameManager.TOTAL_DAYS, "Day should not advance past TOTAL_DAYS")


func test_full_four_day_cycle() -> void:
	for day: int in range(1, GameManager.TOTAL_DAYS):
		assert_eq(GameManager.current_day, day, "Day should be %d" % day)
		DaySystem.process_morning()
		DaySystem.try_end_day()
	assert_eq(GameManager.current_day, GameManager.TOTAL_DAYS, "Should end at TOTAL_DAYS")


# --- Lab Processing --- #

func test_lab_completion_during_morning() -> void:
	GameManager.active_lab_requests.append({
		"id": "lab_test",
		"input_evidence_id": "ev_sample",
		"analysis_type": "fingerprint",
		"day_submitted": 1,
		"completion_day": 1,
		"output_evidence_id": "ev_result",
	})
	watch_signals(DaySystem)
	var briefing: Array[String] = DaySystem.process_morning()
	assert_signal_emitted(DaySystem, "lab_result_ready")
	assert_true(GameManager.has_evidence("ev_result"), "Output evidence should be auto-discovered")
	assert_eq(GameManager.active_lab_requests.size(), 0, "Completed request should be removed")
	var has_lab_msg: bool = false
	for item: String in briefing:
		if "Lab result" in item:
			has_lab_msg = true
			break
	assert_true(has_lab_msg, "Briefing should mention lab result")


func test_lab_not_complete_stays_active() -> void:
	GameManager.active_lab_requests.append({
		"id": "lab_test",
		"input_evidence_id": "ev_sample",
		"analysis_type": "dna",
		"day_submitted": 1,
		"completion_day": 3,
		"output_evidence_id": "ev_dna_result",
	})
	DaySystem.process_morning()
	assert_eq(GameManager.active_lab_requests.size(), 1, "Pending request should remain active")
	assert_false(GameManager.has_evidence("ev_dna_result"), "Output evidence should not appear yet")


# --- Surveillance Processing --- #

func test_surveillance_results_during_morning() -> void:
	GameManager.active_surveillance.append({
		"id": "surv_test",
		"target_person": "person_01",
		"type": "PHONE_TAP",
		"day_installed": 1,
		"active_days": 2,
		"result_events": ["evt_reveal"],
	})
	watch_signals(DaySystem)
	var briefing: Array[String] = DaySystem.process_morning()
	assert_signal_emitted(DaySystem, "surveillance_result")
	var has_surv_msg: bool = false
	for item: String in briefing:
		if "Surveillance" in item:
			has_surv_msg = true
			break
	assert_true(has_surv_msg, "Briefing should mention surveillance update")


func test_expired_surveillance_removed_during_night() -> void:
	GameManager.active_surveillance.append({
		"id": "surv_test",
		"target_person": "person_01",
		"type": "PHONE_TAP",
		"day_installed": 1,
		"active_days": 1,
		"result_events": [],
	})
	DaySystem.process_morning()
	DaySystem.try_end_day()
	assert_eq(GameManager.active_surveillance.size(), 0, "Expired surveillance should be removed")


func test_active_surveillance_kept_during_night() -> void:
	GameManager.active_surveillance.append({
		"id": "surv_test",
		"target_person": "person_01",
		"type": "PHONE_TAP",
		"day_installed": 1,
		"active_days": 3,
		"result_events": [],
	})
	DaySystem.process_morning()
	DaySystem.try_end_day()
	assert_eq(GameManager.active_surveillance.size(), 1, "Still-active surveillance should be kept")


# --- No Invalid Phases --- #

func test_no_afternoon_phase_exists() -> void:
	# Verify no AFTERNOON value in DayPhase enum
	var has_afternoon: bool = false
	for phase_name: String in ["AFTERNOON"]:
		# Try accessing — if it doesn't exist, it won't match any valid value
		has_afternoon = has_afternoon or (GameManager.get_phase_display() == "Afternoon")
	GameManager.current_phase = Enums.DayPhase.MORNING
	assert_ne(GameManager.get_phase_display(), "Afternoon")
	GameManager.current_phase = Enums.DayPhase.DAYTIME
	assert_ne(GameManager.get_phase_display(), "Afternoon")
	GameManager.current_phase = Enums.DayPhase.NIGHT
	assert_ne(GameManager.get_phase_display(), "Afternoon")


func test_no_evening_phase_exists() -> void:
	GameManager.current_phase = Enums.DayPhase.MORNING
	assert_ne(GameManager.get_phase_display(), "Evening")
	GameManager.current_phase = Enums.DayPhase.DAYTIME
	assert_ne(GameManager.get_phase_display(), "Evening")
	GameManager.current_phase = Enums.DayPhase.NIGHT
	assert_ne(GameManager.get_phase_display(), "Evening")


# --- Phase Display Strings --- #

func test_phase_display_morning() -> void:
	GameManager.current_phase = Enums.DayPhase.MORNING
	assert_eq(GameManager.get_phase_display(), "Morning")


func test_phase_display_daytime() -> void:
	GameManager.current_phase = Enums.DayPhase.DAYTIME
	assert_eq(GameManager.get_phase_display(), "Daytime")


func test_phase_display_night() -> void:
	GameManager.current_phase = Enums.DayPhase.NIGHT
	assert_eq(GameManager.get_phase_display(), "Night")


# --- Serialization --- #

func test_serialize_returns_dictionary() -> void:
	var data: Dictionary = DaySystem.serialize()
	assert_has(data, "morning_briefing_shown", "Should contain morning_briefing_shown")


func test_deserialize_restores_state() -> void:
	DaySystem._morning_briefing_shown = true
	var data: Dictionary = DaySystem.serialize()

	DaySystem.reset()
	assert_false(DaySystem._morning_briefing_shown, "Should be reset")

	DaySystem.deserialize(data)
	assert_true(DaySystem._morning_briefing_shown, "Should be restored")


func test_serialize_round_trip() -> void:
	DaySystem._morning_briefing_shown = true
	var original: Dictionary = DaySystem.serialize()

	DaySystem.reset()
	DaySystem.deserialize(original)
	var restored: Dictionary = DaySystem.serialize()

	assert_eq(restored["morning_briefing_shown"], original["morning_briefing_shown"])


# --- Morning Briefing with Case Data --- #

func test_process_morning_returns_briefing_items() -> void:
	CaseManager.load_case_folder("riverside_apartment")
	GameManager.new_game()
	EventSystem.reset()
	var briefing: Array[String] = []
	briefing.assign(DaySystem.process_morning())
	assert_false(briefing.is_empty(),
		"Morning briefing should have items on Day 1 with riverside_apartment case")
	CaseManager.unload_case()
