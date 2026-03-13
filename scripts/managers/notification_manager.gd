## NotificationManager.gd
## Manages a queue of in-game notifications displayed in the investigation
## desk UI. Notifications persist until explicitly dismissed.
extends Node


# --- Signals --- #

## Emitted when a new notification is added to the queue.
signal notification_added(notification: Dictionary)

## Emitted when a notification is dismissed.
signal notification_dismissed(notification_id: String)

## Emitted when all notifications are cleared.
signal notifications_cleared


# --- Types --- #

## Notification categories for filtering and styling.
enum NotificationType {
	EVIDENCE,       ## New evidence discovered
	LAB_RESULT,     ## Lab analysis complete
	STATEMENT,      ## New statement unlocked
	SURVEILLANCE,   ## Surveillance update
	WARRANT,        ## Warrant approved/denied
	STORY,          ## Story event
	HINT,           ## Progressive hint
	SYSTEM,         ## System message
}


# --- State --- #

## Active notification queue.
var _notifications: Array[Dictionary] = []

## Counter for generating unique notification IDs.
var _next_id: int = 1


# --- Lifecycle --- #

func _ready() -> void:
	print("[NotificationManager] Initialized.")


# --- Public API --- #

## Adds a new notification to the queue.
## Returns the notification ID.
func notify(title: String, message: String, type: NotificationType = NotificationType.SYSTEM) -> String:
	var notif: Dictionary = {
		"id": "notif_%d" % _next_id,
		"title": title,
		"message": message,
		"type": type,
		"timestamp": Time.get_unix_time_from_system(),
		"read": false,
	}
	_next_id += 1
	_notifications.append(notif)
	notification_added.emit(notif)
	print("[NotificationManager] New: %s — %s" % [title, message])
	return notif.id


## Convenience methods for common notification types.
func notify_evidence(evidence_name: String) -> String:
	return notify("Evidence Found", evidence_name, NotificationType.EVIDENCE)


func notify_lab_result(result_name: String) -> String:
	return notify("Lab Result Ready", result_name, NotificationType.LAB_RESULT)


func notify_statement(person_name: String) -> String:
	return notify("New Statement", "From %s" % person_name, NotificationType.STATEMENT)


func notify_surveillance(update: String) -> String:
	return notify("Surveillance Update", update, NotificationType.SURVEILLANCE)


func notify_warrant(status: String) -> String:
	return notify("Warrant Update", status, NotificationType.WARRANT)


func notify_story(message: String) -> String:
	return notify("Investigation Update", message, NotificationType.STORY)


func notify_hint(hint: String) -> String:
	return notify("Hint", hint, NotificationType.HINT)


## Dismisses a notification by ID.
func dismiss(notification_id: String) -> bool:
	for i: int in range(_notifications.size()):
		if _notifications[i].get("id", "") == notification_id:
			_notifications.remove_at(i)
			notification_dismissed.emit(notification_id)
			return true
	return false


## Marks a notification as read (but keeps it in the queue).
func mark_read(notification_id: String) -> void:
	for notif: Dictionary in _notifications:
		if notif.get("id", "") == notification_id:
			notif.read = true
			return


## Clears all notifications.
func clear_all() -> void:
	_notifications.clear()
	notifications_cleared.emit()


## Returns all active notifications.
func get_all() -> Array[Dictionary]:
	return _notifications


## Returns all unread notifications.
func get_unread() -> Array[Dictionary]:
	var unread: Array[Dictionary] = []
	for notif: Dictionary in _notifications:
		if not notif.get("read", false):
			unread.append(notif)
	return unread


## Returns the count of unread notifications.
func get_unread_count() -> int:
	var count: int = 0
	for notif: Dictionary in _notifications:
		if not notif.get("read", false):
			count += 1
	return count


## Returns notifications filtered by type.
func get_by_type(type: NotificationType) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for notif: Dictionary in _notifications:
		if notif.get("type", -1) == type:
			filtered.append(notif)
	return filtered
