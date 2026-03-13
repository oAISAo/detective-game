## test_day_cycle_integration.gd
## Integration tests for the full day cycle: Morning → Afternoon → Evening → Night.
## Tests DaySystem + ActionSystem + GameManager working together.
## Phase 2: Verify complete investigation flow across multiple days.
extends GutTest


## Test case file with actions, triggers, and delayed actions.
const TEST_CASE_FILE: String = "test_day_cycle_case.json"

var _test_case_data: Dictionary = {
	"id": "case_day_cycle",
	"title": "Day Cycle Test Case",
	"description": "Integration test case for day cycle.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{
			"id": "p_suspect",
			"name": "Test Suspect",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 5,
		},
	],
	"evidence": [
		{
			"id": "ev_initial",
			"name": "Initial Evidence",
			"description": "Evidence available from the start.",
			"type": "FORENSIC",
			"location_found": "loc_scene",
			"related_persons": [],
			"weight": 0.5,
			"importance_level": "CRITICAL",
		},
		{
			"id": "ev_lab_output",
			"name": "Lab Analysis Result",
			"description": "Evidence produced by lab.",
			"type": "FORENSIC",
			"location_found": "",
			"related_persons": [],
			"weight": 0.7,
			"importance_level": "CRITICAL",
		},
	],
	"statements": [],
	"events": [],
	"locations": [
		{
			"id": "loc_scene",
			"name": "Crime Scene",
			"searchable": true,
			"evidence_pool": ["ev_initial"],
		},
	],
	"event_triggers": [
		{
			"id": "trigger_day2_event",
			"trigger_type": "DAY_START",
			"trigger_day": 2,
			"conditions": [],
			"actions": ["Day 2 briefing event"],
			"result_events": [],
		},
		{
			"id": "trigger_conditional",
			"trigger_type": "DAY_START",
			"trigger_day": -1,
			"conditions": ["evidence_discovered:ev_initial"],
			"actions": ["Evidence-based event triggered"],
			"result_events": [],
		},
	],
	"interrogation_topics": [],
	"actions": [
		{
			"id": "act_visit",
			"name": "Visit Scene",
			"type": "VISIT_LOCATION",
			"time_cost": 1,
			"target": "loc_scene",
			"requirements": [],
			"results": ["evidence:ev_initial", "location:loc_scene"],
		},
		{
			"id": "act_interrogate",
			"name": "Interrogate Suspect",
			"type": "INTERROGATION",
			"time_cost": 1,
			"target": "p_suspect",
			"requirements": ["evidence:ev_initial"],
			"results": [],
		},
		{
			"id": "act_free",
			"name": "Review Notes",
			"type": "ANALYZE_EVIDENCE",
			"time_cost": 0,
			"target": "",
			"requirements": [],
			"results": [],
		},
	],
	"insights": [],
}


# --- Setup / Teardown --- #

func before_all() -> void:
	var dir: DirAccess = DirAccess.open("res://data/cases")
	if dir == null:
		DirAccess.make_dir_recursive_absolute("res://data/cases")
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_test_case_data, "\t"))
	file.close()


func after_all() -> void:
	CaseManager.unload_case()
	DirAccess.remove_absolute("res://data/cases/%s" % TEST_CASE_FILE)


func before_each() -> void:
	GameManager.new_game()
	DaySystem.reset()
	ActionSystem.reset()
	EventSystem.reset()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)


# --- Full Day Cycle --- #

func test_morning_afternoon_evening_night_cycle() -> void:
	# Morning — briefing
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.MORNING)
	var briefing: Array[String] = DaySystem.process_morning()
	assert_true(DaySystem.is_morning_briefing_shown())

	# Player moves to afternoon
	GameManager.advance_time_slot()
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.AFTERNOON)

	# Afternoon — execute major action
	var result: bool = ActionSystem.execute_action("act_visit")
	assert_true(result, "Should execute visit action")
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY - 1)
	assert_true(GameManager.has_evidence("ev_initial"))
	# Action auto-advances to evening
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.EVENING)

	# Evening — execute second action (now has evidence for interrogation)
	result = ActionSystem.execute_action("act_interrogate")
	assert_true(result, "Should execute interrogation with evidence")
	assert_eq(GameManager.actions_remaining, 0)
	# Action auto-advances to night
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.NIGHT)

	# Night — end day
	var advanced: bool = DaySystem.try_end_day()
	assert_true(advanced, "Should advance to next day")
	assert_eq(GameManager.current_day, 2)
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.MORNING)
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY)


func test_day_2_morning_briefing_includes_trigger() -> void:
	# Advance to Day 2
	DaySystem.try_end_day()
	assert_eq(GameManager.current_day, 2)

	# Process morning briefing
	var briefing: Array[String] = DaySystem.process_morning()
	var has_day2_event: bool = false
	for item: String in briefing:
		if "Day 2 briefing event" in item:
			has_day2_event = true
			break
	assert_true(has_day2_event, "Day 2 morning should include the day-start trigger event")


func test_conditional_trigger_fires_when_evidence_discovered() -> void:
	# Discover evidence first
	GameManager.discover_evidence("ev_initial")
	# Process morning — conditional trigger should fire
	var briefing: Array[String] = DaySystem.process_morning()
	var has_conditional: bool = false
	for item: String in briefing:
		if "Evidence-based event" in item:
			has_conditional = true
			break
	assert_true(has_conditional, "Conditional trigger should fire when evidence is discovered")


func test_conditional_trigger_does_not_fire_without_evidence() -> void:
	var briefing: Array[String] = DaySystem.process_morning()
	var has_conditional: bool = false
	for item: String in briefing:
		if "Evidence-based event" in item:
			has_conditional = true
			break
	assert_false(has_conditional, "Conditional trigger should NOT fire without evidence")


func test_trigger_fires_only_once() -> void:
	GameManager.discover_evidence("ev_initial")
	DaySystem.process_morning()
	# Process morning again — trigger should not re-fire
	DaySystem._morning_briefing_shown = false
	var briefing2: Array[String] = DaySystem.process_morning()
	var count: int = 0
	for item: String in briefing2:
		if "Evidence-based event" in item:
			count += 1
	assert_eq(count, 0, "Trigger should not fire a second time")


# --- Delayed Actions Across Days --- #

func test_lab_request_completes_on_correct_day() -> void:
	# Submit a lab request on Day 1 that completes Day 2
	GameManager.active_lab_requests.append({
		"id": "lab_test",
		"input_evidence_id": "ev_initial",
		"analysis_type": "fingerprint",
		"day_submitted": 1,
		"completion_day": 2,
		"output_evidence_id": "ev_lab_output",
	})

	# Day 1 morning — should NOT complete yet
	var briefing1: Array[String] = DaySystem.process_morning()
	assert_eq(GameManager.active_lab_requests.size(), 1, "Lab should still be pending on Day 1")

	# Advance to Day 2
	DaySystem.try_end_day()

	# Day 2 morning — should complete
	var briefing2: Array[String] = DaySystem.process_morning()
	assert_eq(GameManager.active_lab_requests.size(), 0, "Lab should be completed on Day 2")
	assert_true(GameManager.has_evidence("ev_lab_output"), "Lab output evidence should be discovered")


func test_surveillance_active_across_days() -> void:
	# Install surveillance on Day 1, active for 3 days
	GameManager.active_surveillance.append({
		"id": "surv_test",
		"target_person": "p_suspect",
		"type": "PHONE_TAP",
		"day_installed": 1,
		"active_days": 3,
		"result_events": ["evt_wiretap"],
	})

	# Day 1 — should be active
	var briefing1: Array[String] = DaySystem.process_morning()
	var has_surv: bool = false
	for item: String in briefing1:
		if "Surveillance" in item:
			has_surv = true
			break
	assert_true(has_surv, "Surveillance should report on Day 1")

	# Night processing Day 1 → Day 2
	DaySystem.try_end_day()
	assert_eq(GameManager.active_surveillance.size(), 1, "Surveillance should still be active on Day 2")

	# Night processing Day 2 → Day 3
	DaySystem.try_end_day()
	assert_eq(GameManager.active_surveillance.size(), 1, "Surveillance should still be active on Day 3")

	# Night processing Day 3 → Day 4
	DaySystem.try_end_day()
	assert_eq(GameManager.active_surveillance.size(), 0, "Surveillance should expire after Day 3")


# --- Mandatory Action Blocking --- #

func test_mandatory_blocks_day_advance() -> void:
	GameManager.mandatory_actions_required.append("must_do_this")
	watch_signals(DaySystem)
	var result: bool = DaySystem.try_end_day()
	assert_false(result, "Day advance should be blocked")
	assert_signal_emitted(DaySystem, "day_advance_blocked")
	assert_eq(GameManager.current_day, 1, "Day should not change")


func test_mandatory_allows_after_completion() -> void:
	GameManager.mandatory_actions_required.append("must_do_this")
	GameManager.complete_mandatory_action("must_do_this")
	var result: bool = DaySystem.try_end_day()
	assert_true(result, "Day advance should succeed after completing mandatory")
	assert_eq(GameManager.current_day, 2, "Day should advance")


# --- End of Investigation --- #

func test_full_investigation_four_days() -> void:
	watch_signals(DaySystem)
	# Advance through all 4 days
	for i: int in range(GameManager.TOTAL_DAYS - 1):
		DaySystem.try_end_day()
	# Now on Day 4
	assert_eq(GameManager.current_day, GameManager.TOTAL_DAYS)

	# Morning briefing on Day 4 should warn
	DaySystem.process_morning()
	assert_signal_emitted(DaySystem, "final_day_warning")

	# End Day 4
	DaySystem.try_end_day()
	assert_signal_emitted(DaySystem, "investigation_time_expired")
	# Day should NOT advance past TOTAL_DAYS
	assert_eq(GameManager.current_day, GameManager.TOTAL_DAYS)


# --- Passive Actions Don't Consume Slots --- #

func test_passive_actions_during_any_time() -> void:
	# Passive actions work during morning
	GameManager.current_time_slot = Enums.TimeSlot.MORNING
	var result: bool = ActionSystem.execute_action("act_free")
	assert_true(result, "Passive action should work during morning")
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY, "Should not consume slot")


# --- Action System + Day System Integration --- #

func test_action_system_daily_reset_via_day_advance() -> void:
	GameManager.current_time_slot = Enums.TimeSlot.AFTERNOON
	ActionSystem.execute_action("act_visit")
	assert_eq(ActionSystem.actions_executed_today.size(), 1, "Should have 1 daily action")

	# Manually trigger new day reset
	ActionSystem.on_new_day()
	assert_eq(ActionSystem.actions_executed_today.size(), 0, "Daily actions should reset")
	assert_eq(ActionSystem.executed_actions.size(), 1, "Total actions should persist")


# --- Investigation Log Records Correctly --- #

func test_investigation_log_records_day_transitions() -> void:
	DaySystem.try_end_day()
	DaySystem.try_end_day()
	var action_log: Array[Dictionary] = GameManager.get_investigation_log()
	var day_entries: int = 0
	for entry: Dictionary in action_log:
		var desc: String = entry.get("description", "")
		if "Day" in desc and ("begins" in desc or "ended" in desc):
			day_entries += 1
	assert_true(day_entries >= 4, "Log should contain day transition entries")
