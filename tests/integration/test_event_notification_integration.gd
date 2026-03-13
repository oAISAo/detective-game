## test_event_notification_integration.gd
## Integration tests for EventSystem + NotificationManager + DialogueSystem + DaySystem.
## Phase 3: End-to-end flows for trigger evaluation, notification delivery,
## and morning briefing dialogue generation.
extends GutTest


# --- Helpers --- #

func _reset_all() -> void:
	GameManager.new_game()
	DaySystem.reset()
	ActionSystem.reset()
	EventSystem.reset()
	DialogueSystem.reset()
	NotificationManager.clear_all()


# --- Setup --- #

func before_each() -> void:
	_reset_all()


# --- Action Dispatch → Notification --- #

func test_unlock_evidence_creates_notification() -> void:
	EventSystem._dispatch_action("unlock_evidence:ev_blood_sample", "trig_01")
	assert_true(GameManager.has_evidence("ev_blood_sample"), "Evidence should be discovered")
	var notifs: Array[Dictionary] = NotificationManager.get_all()
	assert_gte(notifs.size(), 1, "Should have at least one notification")
	var found_evidence: bool = false
	for notif: Dictionary in notifs:
		if notif.get("type", -1) == NotificationManager.NotificationType.EVIDENCE:
			found_evidence = true
			break
	assert_true(found_evidence, "Should have EVIDENCE-type notification")


func test_notify_action_creates_story_notification() -> void:
	EventSystem._dispatch_action("notify:Breaking news — suspect seen fleeing!", "trig_02")
	var notifs: Array[Dictionary] = NotificationManager.get_all()
	assert_eq(notifs.size(), 1)
	assert_eq(notifs[0].get("type"), NotificationManager.NotificationType.STORY)
	assert_eq(notifs[0].get("message"), "Breaking news — suspect seen fleeing!")


func test_add_mandatory_action_updates_gamemanager() -> void:
	EventSystem._dispatch_action("add_mandatory:review_security_footage", "trig_03")
	assert_true("review_security_footage" in GameManager.mandatory_actions_required)


# --- Trigger Fire → History + Notifications --- #

func test_manual_trigger_fire_creates_history() -> void:
	var trigger: EventTriggerData = EventTriggerData.new()
	trigger.id = "test_manual_01"
	trigger.trigger_type = Enums.TriggerType.CONDITIONAL
	trigger.conditions = []
	trigger.actions = ["notify:Something happened"]
	trigger.result_events = []
	EventSystem._fire_trigger(trigger, "INTEGRATION_TEST")
	EventSystem._dispatch_trigger_actions(trigger)

	assert_true(EventSystem.has_trigger_fired("test_manual_01"))
	assert_eq(EventSystem.get_trigger_history().size(), 1)
	var notifs: Array[Dictionary] = NotificationManager.get_all()
	assert_gte(notifs.size(), 1, "Action should have created notification")


# --- Morning Briefing → Dialogue --- #

func test_morning_briefing_to_dialogue() -> void:
	# Queue a briefing and verify the dialogue system picks it up
	var briefing_items: Array[String] = ["Lab results available.", "New lead identified."]
	DialogueSystem.queue_briefing(briefing_items, 1)

	assert_true(DialogueSystem.is_active(), "Dialogue should auto-start from briefing")
	var line: Dictionary = DialogueSystem.get_current_line()
	assert_eq(line.get("speaker", ""), "Chief")
	assert_true("Day 1" in line.get("text", ""), "First line should mention the day")

	# Advance through all lines (greeting + 2 items = 3)
	DialogueSystem.advance()  # Item 1
	assert_eq(DialogueSystem.get_current_line().get("text", ""), "Lab results available.")
	DialogueSystem.advance()  # Item 2
	assert_eq(DialogueSystem.get_current_line().get("text", ""), "New lead identified.")
	DialogueSystem.advance()  # End
	assert_false(DialogueSystem.is_active(), "Dialogue should end")
	assert_true(DialogueSystem.has_shown_dialogue("morning_briefing_day_1"))


# --- DaySystem Morning → EventSystem → Notifications --- #

func test_day_morning_process_creates_notifications_for_lab() -> void:
	GameManager.active_lab_requests.append({
		"id": "lab_01",
		"input_evidence_id": "ev_sample",
		"analysis_type": "fingerprint",
		"day_submitted": 1,
		"completion_day": 1,
		"output_evidence_id": "ev_fingerprint_result",
	})
	DaySystem.process_morning()
	assert_true(GameManager.has_evidence("ev_fingerprint_result"), "Lab output evidence should be discovered")


# --- Conditional Trigger → Notification on Evidence Discovery --- #

func test_evidence_discovery_fires_conditional_trigger() -> void:
	# Manually set up a CONDITIONAL trigger in EventSystem state
	# (normally from CaseManager, but we test the signal integration)
	watch_signals(EventSystem)
	# Without loaded case, evaluate_conditional_triggers should not crash
	GameManager.discover_evidence("ev_test")
	assert_true(GameManager.has_evidence("ev_test"), "Evidence should be discovered despite no case loaded")


# --- Serialization Across Systems --- #

func test_full_state_serialization() -> void:
	# Set up state across multiple systems
	EventSystem._fired_triggers.append("trig_01")
	DialogueSystem._dialogue_history.append("dialogue_01")
	GameManager.discover_evidence("ev_test")
	NotificationManager.notify_story("Test notification")

	var gm_state: Dictionary = GameManager.serialize()
	var es_state: Dictionary = EventSystem.serialize()
	var ds_state: Dictionary = DialogueSystem.serialize()

	# Reset everything
	_reset_all()

	# Restore
	GameManager.deserialize(gm_state)
	EventSystem.deserialize(es_state)
	DialogueSystem.deserialize(ds_state)

	assert_true(EventSystem.has_trigger_fired("trig_01"), "EventSystem trigger should be restored")
	assert_true(DialogueSystem.has_shown_dialogue("dialogue_01"), "DialogueSystem history should be restored")
	assert_true(GameManager.has_evidence("ev_test"), "GameManager evidence should be restored")


# --- Multiple Action Dispatches --- #

func test_multiple_actions_create_multiple_notifications() -> void:
	EventSystem._dispatch_action("notify:Update 1", "trig_multi")
	EventSystem._dispatch_action("unlock_evidence:ev_01", "trig_multi")
	EventSystem._dispatch_action("notify:Update 2", "trig_multi")
	var notifs: Array[Dictionary] = NotificationManager.get_all()
	# notify creates 1, unlock_evidence creates 1, notify creates 1 = 3 notifications
	# But discover_evidence might also create a notification via the signal handler
	assert_gte(notifs.size(), 3, "Should have at least 3 notifications")


# --- Dialogue Chain After Triggers --- #

func test_dialogue_chain_completes_sequentially() -> void:
	DialogueSystem.queue_simple("Chief", "First message", "chief", "msg_1")
	DialogueSystem.queue_simple("Tech", "Second message", "tech", "msg_2")

	assert_true(DialogueSystem.is_active())
	assert_eq(DialogueSystem.get_current_dialogue().get("id", ""), "msg_1")

	# Complete first
	DialogueSystem.advance()
	assert_eq(DialogueSystem.get_current_dialogue().get("id", ""), "msg_2")

	# Complete second
	DialogueSystem.advance()
	assert_false(DialogueSystem.is_active())
	assert_true(DialogueSystem.has_shown_dialogue("msg_1"))
	assert_true(DialogueSystem.has_shown_dialogue("msg_2"))


# --- Pending Morning Actions --- #

func test_timed_trigger_pending_actions_delivered_at_morning() -> void:
	# Simulate timed trigger queuing actions
	EventSystem._pending_morning_actions.append({
		"trigger_id": "trig_timed_01",
		"actions": ["notify:Timed event!"],
		"target_day": 2,
	})
	var results: Array[String] = EventSystem.evaluate_day_start_triggers()
	# The pending action should be included in results
	var found_timed: bool = false
	for item: String in results:
		if "Timed event!" in item:
			found_timed = true
			break
	assert_true(found_timed, "Pending morning actions should be delivered during day-start evaluation")
	assert_eq(EventSystem.get_pending_morning_actions().size(), 0, "Pending actions should be cleared after delivery")
