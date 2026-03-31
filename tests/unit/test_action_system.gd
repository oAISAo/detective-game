## test_action_system.gd
## Unit tests for the ActionSystem singleton.
## Phase 2: Verify action availability, requirement checking, execution,
## result processing, and serialization.
extends GutTest


## Test case data with various action types for comprehensive testing.
const TEST_CASE_FILE: String = "test_action_case.json"

var _test_case_data: Dictionary = {
	"id": "case_action_test",
	"title": "Action Test Case",
	"description": "Test case for action system testing.",
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
			"id": "ev_required",
			"name": "Required Evidence",
			"description": "Evidence needed for some actions.",
			"type": "FORENSIC",
			"location_found": "loc_scene",
			"related_persons": [],
			"weight": 0.5,
			"importance_level": "CRITICAL",
		},
		{
			"id": "ev_result",
			"name": "Result Evidence",
			"description": "Evidence produced by an action.",
			"type": "DOCUMENT",
			"location_found": "",
			"related_persons": [],
			"weight": 0.3,
			"importance_level": "SUPPORTING",
		},
	],
	"statements": [],
	"events": [],
	"locations": [
		{
			"id": "loc_scene",
			"name": "Crime Scene",
			"searchable": true,
			"evidence_pool": ["ev_required"],
		},
		{
			"id": "loc_office",
			"name": "Office",
			"searchable": true,
			"evidence_pool": [],
		},
	],
	"event_triggers": [],
	"interrogation_topics": [],
	"actions": [
		{
			"id": "act_visit_scene",
			"name": "Visit Crime Scene",
			"type": "VISIT_LOCATION",
			"time_cost": 1,
			"target": "loc_scene",
			"requirements": [],
			"results": ["location:loc_scene"],
		},
		{
			"id": "act_interrogate",
			"name": "Interrogate Suspect",
			"type": "INTERROGATION",
			"time_cost": 1,
			"target": "p_suspect",
			"requirements": ["evidence:ev_required"],
			"results": ["insight:insight_confession"],
		},
		{
			"id": "act_search",
			"name": "Search Office",
			"type": "SEARCH_LOCATION",
			"time_cost": 1,
			"target": "loc_office",
			"requirements": ["warrant:w_office"],
			"results": ["evidence:ev_result"],
		},
		{
			"id": "act_passive_review",
			"name": "Review Evidence",
			"type": "ANALYZE_EVIDENCE",
			"time_cost": 0,
			"target": "",
			"requirements": [],
			"results": [],
		},
		{
			"id": "act_requires_action",
			"name": "Follow Up",
			"type": "VISIT_LOCATION",
			"time_cost": 1,
			"target": "loc_office",
			"requirements": ["action_completed:act_visit_scene"],
			"results": [],
		},
		{
			"id": "act_requires_day",
			"name": "Day 2 Only",
			"type": "VISIT_LOCATION",
			"time_cost": 1,
			"target": "loc_office",
			"requirements": ["day:2"],
			"results": [],
		},
		{
			"id": "act_lab_submit",
			"name": "Submit to Lab",
			"type": "ANALYZE_EVIDENCE",
			"time_cost": 1,
			"target": "ev_required",
			"requirements": ["evidence:ev_required"],
			"results": ["lab_request:ev_required"],
		},
		{
			"id": "act_start_surveillance",
			"name": "Start Surveillance",
			"type": "ANALYZE_EVIDENCE",
			"time_cost": 1,
			"target": "p_suspect",
			"requirements": [],
			"results": ["surveillance:p_suspect"],
		},
		{
			"id": "act_multi_result",
			"name": "Big Discovery",
			"type": "SEARCH_LOCATION",
			"time_cost": 1,
			"target": "loc_scene",
			"requirements": [],
			"results": ["evidence:ev_result", "mandatory:mandatory_01"],
		},
	],
	"insights": [
		{
			"id": "insight_confession",
			"description": "Suspect confessed",
			"source_evidence": [],
			"unlocks_topic": "",
		},
	],
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
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	DirAccess.remove_absolute(path)


func before_each() -> void:
	GameManager.new_game()
	ActionSystem.reset()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)
	# Set phase to DAYTIME so major actions are allowed
	GameManager.current_phase = Enums.DayPhase.DAYTIME


# --- Initialization --- #

func test_initial_state() -> void:
	assert_eq(ActionSystem.executed_actions.size(), 0, "No actions should be executed initially")
	assert_eq(ActionSystem.actions_executed_today.size(), 0, "No daily actions initially")


func test_reset_clears_state() -> void:
	ActionSystem.executed_actions.append("test_action")
	ActionSystem.actions_executed_today.append("test_action")
	ActionSystem.reset()
	assert_eq(ActionSystem.executed_actions.size(), 0, "Reset should clear executed actions")
	assert_eq(ActionSystem.actions_executed_today.size(), 0, "Reset should clear daily actions")


# --- Action Availability --- #

func test_available_action_with_no_requirements() -> void:
	var reasons: Array[String] = ActionSystem.check_availability("act_visit_scene")
	assert_eq(reasons.size(), 0, "Action with no requirements should be available")


func test_unavailable_action_missing_evidence() -> void:
	var reasons: Array[String] = ActionSystem.check_availability("act_interrogate")
	assert_true(reasons.size() > 0, "Should have failure reasons")
	var has_evidence_reason: bool = false
	for reason: String in reasons:
		if "evidence" in reason.to_lower():
			has_evidence_reason = true
			break
	assert_true(has_evidence_reason, "Should mention missing evidence requirement")


func test_available_action_with_evidence_met() -> void:
	GameManager.discover_evidence("ev_required")
	var reasons: Array[String] = ActionSystem.check_availability("act_interrogate")
	assert_eq(reasons.size(), 0, "Should be available when evidence requirement is met")


func test_unavailable_action_missing_warrant() -> void:
	var reasons: Array[String] = ActionSystem.check_availability("act_search")
	assert_true(reasons.size() > 0, "Should fail without warrant")
	var has_warrant_reason: bool = false
	for reason: String in reasons:
		if "warrant" in reason.to_lower():
			has_warrant_reason = true
			break
	assert_true(has_warrant_reason, "Should mention missing warrant")


func test_available_action_with_warrant_met() -> void:
	GameManager.warrants_obtained.append("w_office")
	var reasons: Array[String] = ActionSystem.check_availability("act_search")
	assert_eq(reasons.size(), 0, "Should be available when warrant is obtained")


func test_unavailable_during_morning() -> void:
	GameManager.current_phase = Enums.DayPhase.MORNING
	var reasons: Array[String] = ActionSystem.check_availability("act_visit_scene")
	assert_true(reasons.size() > 0, "Major action should be unavailable during MORNING")


func test_unavailable_during_night() -> void:
	GameManager.current_phase = Enums.DayPhase.NIGHT
	var reasons: Array[String] = ActionSystem.check_availability("act_visit_scene")
	assert_true(reasons.size() > 0, "Major action should be unavailable during NIGHT")


func test_available_during_daytime() -> void:
	GameManager.current_phase = Enums.DayPhase.DAYTIME
	var reasons: Array[String] = ActionSystem.check_availability("act_visit_scene")
	assert_eq(reasons.size(), 0, "Major action should be available during DAYTIME")


func test_passive_action_no_slot_check() -> void:
	GameManager.current_phase = Enums.DayPhase.MORNING
	var reasons: Array[String] = ActionSystem.check_availability("act_passive_review")
	assert_eq(reasons.size(), 0, "Passive actions should be available any time")


func test_unavailable_when_no_actions_remaining() -> void:
	GameManager.actions_remaining = 0
	var reasons: Array[String] = ActionSystem.check_availability("act_visit_scene")
	assert_true(reasons.size() > 0, "Should fail when no action slots remain")


func test_passive_action_available_when_no_actions_remaining() -> void:
	GameManager.actions_remaining = 0
	var reasons: Array[String] = ActionSystem.check_availability("act_passive_review")
	assert_eq(reasons.size(), 0, "Passive action should work even with no slots")


func test_nonexistent_action() -> void:
	var reasons: Array[String] = ActionSystem.check_availability("act_nonexistent")
	assert_true(reasons.size() > 0, "Should fail for nonexistent action")


func test_action_completed_requirement() -> void:
	var reasons: Array[String] = ActionSystem.check_availability("act_requires_action")
	assert_true(reasons.size() > 0, "Should fail when prereq action not completed")
	ActionSystem.executed_actions.append("act_visit_scene")
	reasons = ActionSystem.check_availability("act_requires_action")
	assert_eq(reasons.size(), 0, "Should pass when prereq action completed")


func test_day_requirement() -> void:
	GameManager.current_day = 1
	var reasons: Array[String] = ActionSystem.check_availability("act_requires_day")
	assert_true(reasons.size() > 0, "Should fail on day 1 when day 2 required")
	GameManager.current_day = 2
	reasons = ActionSystem.check_availability("act_requires_day")
	assert_eq(reasons.size(), 0, "Should pass on day 2")


func test_interrogation_limit_check() -> void:
	GameManager.discover_evidence("ev_required")
	var reasons: Array[String] = ActionSystem.check_availability("act_interrogate")
	assert_eq(reasons.size(), 0, "Should be available first time")

	GameManager.record_interrogation("p_suspect")
	reasons = ActionSystem.check_availability("act_interrogate")
	assert_true(reasons.size() > 0, "Should be blocked after daily interrogation limit")


# --- get_available_actions --- #

func test_get_available_actions_filters_correctly() -> void:
	var available: Array[ActionData] = ActionSystem.get_available_actions()
	# At start, during DAYTIME with full actions: act_visit_scene, act_passive_review,
	# act_start_surveillance, act_multi_result should be available
	var available_ids: Array[String] = []
	for a: ActionData in available:
		available_ids.append(a.id)
	assert_has(available_ids, "act_visit_scene", "Visit scene should be available")
	assert_has(available_ids, "act_passive_review", "Passive review should be available")
	assert_does_not_have(available_ids, "act_interrogate", "Interrogate should need evidence")
	assert_does_not_have(available_ids, "act_search", "Search should need warrant")


func test_get_passive_actions() -> void:
	var passive: Array[ActionData] = ActionSystem.get_passive_actions()
	assert_eq(passive.size(), 1, "Should have 1 passive action")
	assert_eq(passive[0].id, "act_passive_review", "Should be the review action")


# --- Action Execution --- #

func test_execute_major_action_succeeds() -> void:
	var result: bool = ActionSystem.execute_action("act_visit_scene")
	assert_true(result, "Should execute successfully")
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY - 1, "Should consume action slot")


func test_execute_action_tracks_execution() -> void:
	ActionSystem.execute_action("act_visit_scene")
	assert_has(ActionSystem.executed_actions, "act_visit_scene", "Should track in executed_actions")
	assert_has(ActionSystem.actions_executed_today, "act_visit_scene", "Should track in daily list")


func test_execute_action_emits_signal() -> void:
	watch_signals(ActionSystem)
	ActionSystem.execute_action("act_visit_scene")
	assert_signal_emitted(ActionSystem, "action_executed")


func test_execute_action_fails_when_unavailable() -> void:
	watch_signals(ActionSystem)
	var result: bool = ActionSystem.execute_action("act_interrogate")
	assert_false(result, "Should fail when requirements not met")
	assert_signal_emitted(ActionSystem, "action_unavailable")


func test_execute_passive_action_no_slot_cost() -> void:
	var before: int = GameManager.actions_remaining
	ActionSystem.execute_action("act_passive_review")
	assert_eq(GameManager.actions_remaining, before, "Passive action should not consume slot")


func test_execute_major_action_already_completed() -> void:
	ActionSystem.execute_action("act_visit_scene")
	var result: bool = ActionSystem.execute_action("act_visit_scene")
	assert_false(result, "Should not allow re-executing major action")


func test_execute_action_does_not_change_phase() -> void:
	GameManager.current_phase = Enums.DayPhase.DAYTIME
	ActionSystem.execute_action("act_visit_scene")
	assert_eq(GameManager.current_phase, Enums.DayPhase.DAYTIME, "Action should not change phase")


func test_execute_action_records_interrogation() -> void:
	GameManager.discover_evidence("ev_required")
	ActionSystem.execute_action("act_interrogate")
	assert_false(GameManager.can_interrogate_today("p_suspect"), "Should record interrogation")


func test_execute_action_visits_location() -> void:
	ActionSystem.execute_action("act_visit_scene")
	assert_true(GameManager.has_visited_location("loc_scene"), "Should track location visit")


func test_execute_action_logs_to_investigation_log() -> void:
	ActionSystem.execute_action("act_visit_scene")
	var action_log: Array[Dictionary] = GameManager.get_investigation_log()
	var found: bool = false
	for entry: Dictionary in action_log:
		if "Visit Crime Scene" in entry.get("description", ""):
			found = true
			break
	assert_true(found, "Action should be logged in investigation log")


# --- Result Processing --- #

func test_result_evidence_discovery() -> void:
	GameManager.warrants_obtained.append("w_office")
	ActionSystem.execute_action("act_search")
	assert_true(GameManager.has_evidence("ev_result"), "Should discover evidence from result")


func test_result_insight_discovery() -> void:
	GameManager.discover_evidence("ev_required")
	ActionSystem.execute_action("act_interrogate")
	assert_true("insight_confession" in GameManager.discovered_insights, "Should discover insight from result")


func test_result_mandatory_completion() -> void:
	GameManager.mandatory_actions_required.append("mandatory_01")
	ActionSystem.execute_action("act_multi_result")
	assert_true("mandatory_01" in GameManager.mandatory_actions_completed, "Should complete mandatory action")


func test_result_warrant_grant() -> void:
	# We'll test the _apply_single_result directly for warrant
	ActionSystem._apply_single_result("warrant", "w_test")
	assert_has(GameManager.warrants_obtained, "w_test", "Should grant warrant")


func test_result_emits_signal() -> void:
	watch_signals(ActionSystem)
	ActionSystem.execute_action("act_visit_scene")
	assert_signal_emitted(ActionSystem, "action_result_applied")


# --- Delayed Actions --- #

func test_lab_request_creation() -> void:
	GameManager.discover_evidence("ev_required")
	watch_signals(ActionSystem)
	ActionSystem.execute_action("act_lab_submit")
	assert_eq(GameManager.active_lab_requests.size(), 1, "Should create lab request")
	assert_signal_emitted(ActionSystem, "delayed_action_submitted")
	var req: Dictionary = GameManager.active_lab_requests[0]
	assert_eq(req["input_evidence_id"], "ev_required", "Should reference correct evidence")
	assert_eq(req["completion_day"], GameManager.current_day + 1, "Should complete next day")


func test_surveillance_creation() -> void:
	watch_signals(ActionSystem)
	ActionSystem.execute_action("act_start_surveillance")
	assert_eq(GameManager.active_surveillance.size(), 1, "Should create surveillance")
	assert_signal_emitted(ActionSystem, "delayed_action_submitted")
	var surv: Dictionary = GameManager.active_surveillance[0]
	assert_eq(surv["target_person"], "p_suspect", "Should target correct person")
	assert_eq(surv["active_days"], 2, "Should be active for 2 days")


# --- Daily Reset --- #

func test_on_new_day_clears_daily_actions() -> void:
	ActionSystem.actions_executed_today.append("test_action")
	ActionSystem.on_new_day()
	assert_eq(ActionSystem.actions_executed_today.size(), 0, "on_new_day should clear daily list")


func test_on_new_day_preserves_total_executed() -> void:
	ActionSystem.executed_actions.append("test_action")
	ActionSystem.on_new_day()
	assert_eq(ActionSystem.executed_actions.size(), 1, "on_new_day should NOT clear total list")


# --- Serialization --- #

func test_serialize_returns_dictionary() -> void:
	var data: Dictionary = ActionSystem.serialize()
	assert_has(data, "executed_actions", "Should contain executed_actions")
	assert_has(data, "actions_executed_today", "Should contain actions_executed_today")


func test_deserialize_restores_state() -> void:
	ActionSystem.executed_actions.append("act_01")
	ActionSystem.executed_actions.append("act_02")
	ActionSystem.actions_executed_today.append("act_02")
	var data: Dictionary = ActionSystem.serialize()

	ActionSystem.reset()
	ActionSystem.deserialize(data)
	assert_eq(ActionSystem.executed_actions.size(), 2, "Should restore 2 executed actions")
	assert_eq(ActionSystem.actions_executed_today.size(), 1, "Should restore 1 daily action")
	assert_has(ActionSystem.executed_actions, "act_01")
	assert_has(ActionSystem.executed_actions, "act_02")


func test_serialize_round_trip() -> void:
	ActionSystem.executed_actions.append("act_a")
	ActionSystem.actions_executed_today.append("act_a")
	var original: Dictionary = ActionSystem.serialize()

	ActionSystem.reset()
	ActionSystem.deserialize(original)
	var restored: Dictionary = ActionSystem.serialize()

	assert_eq(restored["executed_actions"].size(), original["executed_actions"].size())
	assert_eq(restored["actions_executed_today"].size(), original["actions_executed_today"].size())
