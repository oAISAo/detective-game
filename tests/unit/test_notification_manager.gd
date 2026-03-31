## test_notification_manager.gd
## Unit tests for the NotificationManager autoload singleton.
## Phase 0: Verify notification queue, dismissal, filtering, and signals.
extends GutTest


# --- Setup --- #

func before_each() -> void:
	NotificationManager.clear_all()


# --- Adding Notifications --- #

func test_notify_adds_to_queue() -> void:
	NotificationManager.notify("Test", "Test message")
	assert_eq(NotificationManager.get_all().size(), 1)


func test_notify_returns_unique_id() -> void:
	var id1: String = NotificationManager.notify("Test 1", "Message 1")
	var id2: String = NotificationManager.notify("Test 2", "Message 2")
	assert_ne(id1, id2, "IDs should be unique")


func test_notify_emits_signal() -> void:
	watch_signals(NotificationManager)
	NotificationManager.notify("Test", "Message")
	assert_signal_emitted(NotificationManager, "notification_added")


func test_notification_structure() -> void:
	NotificationManager.notify("Test Title", "Test Message", NotificationManager.NotificationType.EVIDENCE)
	var notifications: Array[Dictionary] = NotificationManager.get_all()
	var notif: Dictionary = notifications[0]
	assert_has(notif, "id")
	assert_has(notif, "title")
	assert_has(notif, "message")
	assert_has(notif, "type")
	assert_has(notif, "timestamp")
	assert_has(notif, "read")
	assert_eq(notif.title, "Test Title")
	assert_eq(notif.message, "Test Message")
	assert_eq(notif.type, NotificationManager.NotificationType.EVIDENCE)
	assert_false(notif.read)


# --- Convenience Methods --- #

func test_notify_evidence() -> void:
	NotificationManager.notify_evidence("Wine Glass")
	var notifications: Array[Dictionary] = NotificationManager.get_all()
	assert_eq(notifications[0].type, NotificationManager.NotificationType.EVIDENCE)


func test_notify_lab_result() -> void:
	NotificationManager.notify_lab_result("Fingerprint Match")
	var notifications: Array[Dictionary] = NotificationManager.get_all()
	assert_eq(notifications[0].type, NotificationManager.NotificationType.LAB_RESULT)


func test_notify_hint() -> void:
	NotificationManager.notify_hint("Check the kitchen")
	var notifications: Array[Dictionary] = NotificationManager.get_all()
	assert_eq(notifications[0].type, NotificationManager.NotificationType.HINT)


# --- Dismissal --- #

func test_dismiss_removes_notification() -> void:
	var id: String = NotificationManager.notify("Test", "Message")
	assert_eq(NotificationManager.get_all().size(), 1)
	NotificationManager.dismiss(id)
	assert_eq(NotificationManager.get_all().size(), 0)


func test_dismiss_returns_false_for_invalid_id() -> void:
	var result: bool = NotificationManager.dismiss("nonexistent_id")
	assert_false(result)


func test_dismiss_emits_signal() -> void:
	var id: String = NotificationManager.notify("Test", "Message")
	watch_signals(NotificationManager)
	NotificationManager.dismiss(id)
	assert_signal_emitted_with_parameters(NotificationManager, "notification_dismissed", [id])


# --- Read Status --- #

func test_mark_read() -> void:
	var id: String = NotificationManager.notify("Test", "Message")
	NotificationManager.mark_read(id)
	var notifications: Array[Dictionary] = NotificationManager.get_all()
	assert_true(notifications[0].read)


func test_get_unread() -> void:
	NotificationManager.notify("Unread 1", "Message")
	var id2: String = NotificationManager.notify("Read 1", "Message")
	NotificationManager.notify("Unread 2", "Message")
	NotificationManager.mark_read(id2)

	var unread: Array[Dictionary] = NotificationManager.get_unread()
	assert_eq(unread.size(), 2)


func test_get_unread_count() -> void:
	NotificationManager.notify("Test 1", "Message")
	NotificationManager.notify("Test 2", "Message")
	var id3: String = NotificationManager.notify("Test 3", "Message")
	NotificationManager.mark_read(id3)

	assert_eq(NotificationManager.get_unread_count(), 2)


# --- Filtering --- #

func test_get_by_type() -> void:
	NotificationManager.notify_evidence("Wine Glass")
	NotificationManager.notify_lab_result("Fingerprint")
	NotificationManager.notify_evidence("Camera Footage")

	var evidence_notifs: Array[Dictionary] = NotificationManager.get_by_type(
		NotificationManager.NotificationType.EVIDENCE
	)
	assert_eq(evidence_notifs.size(), 2)

	var lab_notifs: Array[Dictionary] = NotificationManager.get_by_type(
		NotificationManager.NotificationType.LAB_RESULT
	)
	assert_eq(lab_notifs.size(), 1)


# --- Clear All --- #

func test_clear_all() -> void:
	NotificationManager.notify("Test 1", "Message")
	NotificationManager.notify("Test 2", "Message")
	NotificationManager.notify("Test 3", "Message")
	assert_eq(NotificationManager.get_all().size(), 3)

	NotificationManager.clear_all()
	assert_eq(NotificationManager.get_all().size(), 0)


func test_clear_all_emits_signal() -> void:
	NotificationManager.notify("Test", "Message")
	watch_signals(NotificationManager)
	NotificationManager.clear_all()
	assert_signal_emitted(NotificationManager, "notifications_cleared")


# --- API Method Existence --- #

func test_has_notify_method() -> void:
	assert_true(NotificationManager.has_method("notify"),
		"NotificationManager should have 'notify' method")


func test_has_notify_evidence_method() -> void:
	assert_true(NotificationManager.has_method("notify_evidence"),
		"NotificationManager should have 'notify_evidence' method")


func test_no_send_notification_method() -> void:
	assert_false(NotificationManager.has_method("send_notification"),
		"NotificationManager should NOT have 'send_notification' method")
