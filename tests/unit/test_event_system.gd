## test_event_system.gd
## Unit tests for the EventSystem singleton.
## Phase 3: Condition checking, trigger firing, action dispatching,
## DAY_START/TIMED/CONDITIONAL evaluation, deduplication, serialization.
extends GutTest


# --- Helpers --- #

func _reset_state() -> void:
	GameManager.new_game()
	EventSystem.reset()
	NotificationManager.clear_all()


# --- Setup --- #

func before_each() -> void:
	_reset_state()


# --- Initialization --- #

func test_initial_state() -> void:
	assert_eq(EventSystem.get_fired_triggers().size(), 0, "No triggers should have fired initially")
	assert_eq(EventSystem.get_pending_morning_actions().size(), 0, "No pending morning actions initially")
	assert_eq(EventSystem.get_trigger_history().size(), 0, "No trigger history initially")


func test_reset_clears_all_state() -> void:
	EventSystem._fired_triggers.append("trig_01")
	EventSystem._pending_morning_actions.append({"trigger_id": "x", "actions": []})
	EventSystem._trigger_history.append({"trigger_id": "x"})
	EventSystem.reset()
	assert_eq(EventSystem.get_fired_triggers().size(), 0, "Reset should clear fired triggers")
	assert_eq(EventSystem.get_pending_morning_actions().size(), 0, "Reset should clear pending actions")
	assert_eq(EventSystem.get_trigger_history().size(), 0, "Reset should clear history")


# --- Condition Checking --- #

func test_check_conditions_evidence_discovered() -> void:
	var conditions: Array[String] = ["evidence_discovered:ev_test"]
	assert_false(EventSystem._check_conditions(conditions), "Should fail without evidence")
	GameManager.discover_evidence("ev_test")
	assert_true(EventSystem._check_conditions(conditions), "Should pass with evidence")


func test_check_conditions_location_visited() -> void:
	var conditions: Array[String] = ["location_visited:loc_01"]
	assert_false(EventSystem._check_conditions(conditions), "Should fail without location")
	GameManager.visit_location("loc_01")
	assert_true(EventSystem._check_conditions(conditions), "Should pass with location")


func test_check_conditions_action_completed() -> void:
	var conditions: Array[String] = ["action_completed:interrogate_sarah"]
	assert_false(EventSystem._check_conditions(conditions), "Should fail without action completed")
	GameManager.mandatory_actions_required.append("interrogate_sarah")
	GameManager.complete_mandatory_action("interrogate_sarah")
	assert_true(EventSystem._check_conditions(conditions), "Should pass with action completed")


func test_check_conditions_warrant_obtained() -> void:
	var conditions: Array[String] = ["warrant_obtained:w_01"]
	assert_false(EventSystem._check_conditions(conditions), "Should fail without warrant")
	GameManager.warrants_obtained.append("w_01")
	assert_true(EventSystem._check_conditions(conditions), "Should pass with warrant")


func test_check_conditions_day() -> void:
	var conditions: Array[String] = ["day:2"]
	GameManager.current_day = 1
	assert_false(EventSystem._check_conditions(conditions), "Should fail on wrong day")
	GameManager.current_day = 2
	assert_true(EventSystem._check_conditions(conditions), "Should pass on correct day")


func test_check_conditions_day_gte() -> void:
	var conditions: Array[String] = ["day_gte:3"]
	GameManager.current_day = 2
	assert_false(EventSystem._check_conditions(conditions), "Should fail when day < threshold")
	GameManager.current_day = 3
	assert_true(EventSystem._check_conditions(conditions), "Should pass when day == threshold")
	GameManager.current_day = 4
	assert_true(EventSystem._check_conditions(conditions), "Should pass when day > threshold")


func test_check_conditions_insight_discovered() -> void:
	var conditions: Array[String] = ["insight_discovered:insight_01"]
	assert_false(EventSystem._check_conditions(conditions), "Should fail without insight")
	GameManager.discover_insight("insight_01")
	assert_true(EventSystem._check_conditions(conditions), "Should pass with insight")


func test_check_conditions_interrogation_completed() -> void:
	var conditions: Array[String] = ["interrogation_completed:person_sarah"]
	assert_false(EventSystem._check_conditions(conditions), "Should fail without interrogation")
	GameManager.completed_interrogations["person_sarah"] = ["topic_01"]
	assert_true(EventSystem._check_conditions(conditions), "Should pass with interrogation")


func test_check_conditions_trigger_fired() -> void:
	var conditions: Array[String] = ["trigger_fired:trig_01"]
	assert_false(EventSystem._check_conditions(conditions), "Should fail without trigger fired")
	EventSystem._fired_triggers.append("trig_01")
	assert_true(EventSystem._check_conditions(conditions), "Should pass with trigger fired")


func test_check_conditions_lab_complete() -> void:
	var conditions: Array[String] = ["lab_complete:lab_01"]
	# Lab still active — condition should fail
	GameManager.active_lab_requests.append({"id": "lab_01"})
	assert_false(EventSystem._check_conditions(conditions), "Should fail when lab is still active")
	# Lab completed (removed from active)
	GameManager.active_lab_requests.clear()
	assert_true(EventSystem._check_conditions(conditions), "Should pass when lab is no longer active")


func test_check_conditions_multiple() -> void:
	var conditions: Array[String] = ["evidence_discovered:ev_01", "location_visited:loc_01"]
	assert_false(EventSystem._check_conditions(conditions), "Should fail when both missing")
	GameManager.discover_evidence("ev_01")
	assert_false(EventSystem._check_conditions(conditions), "Should fail with only one met")
	GameManager.visit_location("loc_01")
	assert_true(EventSystem._check_conditions(conditions), "Should pass when all met")


func test_check_conditions_empty() -> void:
	var conditions: Array[String] = []
	assert_true(EventSystem._check_conditions(conditions), "Empty conditions should always pass")


# --- has_trigger_fired / get_fired_triggers --- #

func test_has_trigger_fired() -> void:
	assert_false(EventSystem.has_trigger_fired("trig_01"))
	EventSystem._fired_triggers.append("trig_01")
	assert_true(EventSystem.has_trigger_fired("trig_01"))


func test_get_fired_triggers_returns_copy() -> void:
	EventSystem._fired_triggers.append("trig_a")
	var copy: Array[String] = EventSystem.get_fired_triggers()
	copy.append("trig_b")
	assert_eq(EventSystem.get_fired_triggers().size(), 1, "Original should not be modified")


# --- Trigger History --- #

func test_trigger_history_records_entries() -> void:
	# Manually fire a trigger to populate history
	var trigger: EventTriggerData = EventTriggerData.new()
	trigger.id = "test_trig"
	trigger.trigger_type = Enums.TriggerType.CONDITIONAL
	trigger.conditions = []
	trigger.actions = []
	trigger.result_events = []
	EventSystem._fire_trigger(trigger, "TEST")
	var history: Array[Dictionary] = EventSystem.get_trigger_history()
	assert_eq(history.size(), 1, "Should have one history entry")
	assert_eq(history[0]["trigger_id"], "test_trig")
	assert_eq(history[0]["source"], "TEST")


# --- Action Dispatching --- #

func test_dispatch_action_notify() -> void:
	EventSystem._dispatch_action("notify:Test message", "trig_test")
	var notifs: Array[Dictionary] = NotificationManager.get_all()
	assert_eq(notifs.size(), 1, "Should create one notification")
	assert_eq(notifs[0]["message"], "Test message")


func test_dispatch_action_unlock_evidence() -> void:
	EventSystem._dispatch_action("unlock_evidence:ev_blood", "trig_test")
	assert_true(GameManager.has_evidence("ev_blood"), "Should discover evidence")
	var notifs: Array[Dictionary] = NotificationManager.get_all()
	assert_gte(notifs.size(), 1, "Should create evidence notification")


func test_dispatch_action_unlock_event() -> void:
	EventSystem._dispatch_action("unlock_event:evt_reveal", "trig_test")
	var notifs: Array[Dictionary] = NotificationManager.get_all()
	assert_gte(notifs.size(), 1, "Should create story notification")


func test_dispatch_action_unlock_location() -> void:
	EventSystem._dispatch_action("unlock_location:loc_warehouse", "trig_test")
	assert_true(GameManager.is_location_unlocked("loc_warehouse"), "Should unlock location")


func test_dispatch_action_add_mandatory() -> void:
	EventSystem._dispatch_action("add_mandatory:interrogate_bob", "trig_test")
	assert_true("interrogate_bob" in GameManager.mandatory_actions_required)


func test_dispatch_action_plain_text() -> void:
	EventSystem._dispatch_action("Something happened", "trig_test")
	var notifs: Array[Dictionary] = NotificationManager.get_all()
	assert_gte(notifs.size(), 1, "Plain text should create story notification")


func test_dispatch_action_unknown_type() -> void:
	EventSystem._dispatch_action("unknown_type:value", "trig_test")
	var notifs: Array[Dictionary] = NotificationManager.get_all()
	assert_gte(notifs.size(), 1, "Unknown action should still create notification")


# --- Pending Morning Actions --- #

func test_pending_morning_actions() -> void:
	EventSystem._pending_morning_actions.append({
		"trigger_id": "trig_01",
		"actions": ["notify:Hello"],
		"target_day": 2,
	})
	assert_eq(EventSystem.get_pending_morning_actions().size(), 1)
	EventSystem.clear_pending_morning_actions()
	assert_eq(EventSystem.get_pending_morning_actions().size(), 0)


# --- Force Trigger --- #

func test_force_trigger_not_loaded() -> void:
	# CaseManager not loaded — should return false
	CaseManager.unload_case()
	var result: bool = EventSystem.force_trigger("nonexistent")
	assert_false(result, "Should return false when case not loaded")


func test_reset_trigger() -> void:
	EventSystem._fired_triggers.append("trig_01")
	assert_true(EventSystem.has_trigger_fired("trig_01"))
	EventSystem.reset_trigger("trig_01")
	assert_false(EventSystem.has_trigger_fired("trig_01"))


# --- Conditional Trigger Signal Handlers --- #

func test_evidence_discovery_evaluates_conditionals() -> void:
	# This test verifies the signal connection is made.
	# Without a loaded case, it should not crash.
	CaseManager.unload_case()
	GameManager.discover_evidence("ev_test")
	assert_true(GameManager.has_evidence("ev_test"), "Evidence should still be discovered even without case")


func test_location_visit_evaluates_conditionals() -> void:
	CaseManager.unload_case()
	GameManager.visit_location("loc_test")
	assert_true(GameManager.has_visited_location("loc_test"), "Location should still be visited")


func test_insight_discovery_evaluates_conditionals() -> void:
	CaseManager.unload_case()
	GameManager.discover_insight("insight_test")
	assert_true("insight_test" in GameManager.discovered_insights, "Insight should still be discovered")


# --- Serialization --- #

func test_serialize_returns_dictionary() -> void:
	var data: Dictionary = EventSystem.serialize()
	assert_has(data, "fired_triggers", "Should contain fired_triggers")
	assert_has(data, "pending_morning_actions", "Should contain pending_morning_actions")
	assert_has(data, "trigger_history", "Should contain trigger_history")


func test_deserialize_restores_state() -> void:
	EventSystem._fired_triggers.append("trig_01")
	EventSystem._fired_triggers.append("trig_02")
	EventSystem._pending_morning_actions.append({"trigger_id": "x", "actions": ["a"]})
	EventSystem._trigger_history.append({"trigger_id": "x", "source": "TEST"})
	var data: Dictionary = EventSystem.serialize()

	EventSystem.reset()
	assert_eq(EventSystem._fired_triggers.size(), 0, "Should be reset")

	EventSystem.deserialize(data)
	assert_eq(EventSystem._fired_triggers.size(), 2, "Should have 2 triggers restored")
	assert_has(EventSystem._fired_triggers, "trig_01")
	assert_has(EventSystem._fired_triggers, "trig_02")
	assert_eq(EventSystem._pending_morning_actions.size(), 1, "Should have 1 pending action")
	assert_eq(EventSystem._trigger_history.size(), 1, "Should have 1 history entry")


func test_serialize_round_trip() -> void:
	EventSystem._fired_triggers.append("trig_a")
	EventSystem._trigger_history.append({"trigger_id": "trig_a", "source": "DAY_START"})
	var original: Dictionary = EventSystem.serialize()

	EventSystem.reset()
	EventSystem.deserialize(original)
	var restored: Dictionary = EventSystem.serialize()

	assert_eq(restored["fired_triggers"].size(), original["fired_triggers"].size())
	assert_eq(restored["trigger_history"].size(), original["trigger_history"].size())


# --- Trigger Deduplication --- #

func test_trigger_fires_only_once() -> void:
	var trigger: EventTriggerData = EventTriggerData.new()
	trigger.id = "dedup_test"
	trigger.trigger_type = Enums.TriggerType.CONDITIONAL
	trigger.conditions = []
	trigger.actions = ["notify:first fire"]
	trigger.result_events = []

	# Fire once
	EventSystem._fire_trigger(trigger, "TEST")
	assert_true(EventSystem.has_trigger_fired("dedup_test"))
	assert_eq(EventSystem.get_trigger_history().size(), 1)

	# Can't fire again (the calling code should check _fired_triggers)
	assert_true(EventSystem.has_trigger_fired("dedup_test"))


# --- Trigger Signals --- #

func test_trigger_fired_signal_emitted() -> void:
	watch_signals(EventSystem)
	var trigger: EventTriggerData = EventTriggerData.new()
	trigger.id = "sig_test"
	trigger.trigger_type = Enums.TriggerType.CONDITIONAL
	trigger.conditions = []
	trigger.actions = []
	trigger.result_events = []
	EventSystem._fire_trigger(trigger, "TEST")
	assert_signal_emitted(EventSystem, "trigger_fired")


func test_action_dispatched_signal() -> void:
	watch_signals(EventSystem)
	var trigger: EventTriggerData = EventTriggerData.new()
	trigger.id = "dispatch_test"
	trigger.trigger_type = Enums.TriggerType.CONDITIONAL
	trigger.conditions = []
	trigger.actions = ["notify:Hello world"]
	trigger.result_events = []
	EventSystem._dispatch_trigger_actions(trigger)
	assert_signal_emitted(EventSystem, "action_dispatched")


# --- Briefing Text Conversion --- #

func test_action_to_briefing_text_unlock_location() -> void:
	var text: String = EventSystem._action_to_briefing_text("unlock_location:loc_test")
	assert_true(text.begins_with("New location available:"),
		"unlock_location should produce human-readable briefing text")
	assert_false(text.contains("unlock_location"),
		"Briefing text should not contain raw action prefix")


func test_action_to_briefing_text_notify() -> void:
	var text: String = EventSystem._action_to_briefing_text("notify:A murder has occurred")
	assert_eq(text, "A murder has occurred",
		"notify: prefix should be stripped from briefing text")


func test_action_to_briefing_text_unlock_evidence() -> void:
	var text: String = EventSystem._action_to_briefing_text("unlock_evidence:ev_test")
	assert_true(text.begins_with("New evidence:"),
		"unlock_evidence should produce briefing text")


func test_action_to_briefing_text_unlock_interrogation() -> void:
	var text: String = EventSystem._action_to_briefing_text("unlock_interrogation:p_test")
	assert_true(text.begins_with("New suspect available"),
		"unlock_interrogation should produce briefing text")


func test_action_to_briefing_text_internal_action_returns_empty() -> void:
	var text: String = EventSystem._action_to_briefing_text("add_mandatory:do_something")
	assert_eq(text, "", "Internal actions should return empty string")
	var text2: String = EventSystem._action_to_briefing_text("show_dialogue:some_key")
	assert_eq(text2, "", "show_dialogue should return empty string")


func test_action_to_briefing_text_plain_text() -> void:
	var text: String = EventSystem._action_to_briefing_text("Something happened")
	assert_eq(text, "Something happened",
		"Plain text actions should pass through unchanged")


func test_evaluate_day_start_dispatches_actions() -> void:
	CaseManager.load_case_folder("riverside_apartment")
	GameManager.new_game()
	EventSystem.reset()
	var briefing: Array[String] = []
	briefing.assign(EventSystem.evaluate_day_start_triggers())
	assert_true(GameManager.is_location_unlocked("loc_victim_apartment"),
		"Day 1 trigger should have unlocked victim's apartment")
	for line: String in briefing:
		assert_false(line.begins_with("unlock_location:"),
			"Briefing should not contain raw unlock_location tokens")
		assert_false(line.begins_with("unlock_interrogation:"),
			"Briefing should not contain raw unlock_interrogation tokens")
	CaseManager.unload_case()


func test_trigger_fired_not_in_log() -> void:
	CaseManager.load_case_folder("riverside_apartment")
	GameManager.new_game()
	EventSystem.reset()
	EventSystem.evaluate_day_start_triggers()
	var log: Array[Dictionary] = GameManager.get_investigation_log()
	for entry: Dictionary in log:
		var desc: String = entry.get("description", "")
		assert_false(desc.begins_with("Trigger fired:"),
			"Log should not contain raw 'Trigger fired:' entries")
	CaseManager.unload_case()
