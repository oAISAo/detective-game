## NotificationPanel.gd
## Modal overlay for viewing all notifications.
## Phase 4A: Shows read/unread notifications with mark-read and dismiss.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var notification_scroll: ScrollContainer = %NotificationScroll
@onready var notification_list: VBoxContainer = %NotificationListContainer
@onready var close_button: Button = %CloseButton
@onready var clear_all_button: Button = %ClearAllButton
@onready var dimmer: ColorRect = %Dimmer


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	clear_all_button.pressed.connect(_on_clear_all_pressed)

	NotificationManager.notification_added.connect(func(_n: Dictionary) -> void: _refresh())
	NotificationManager.notification_dismissed.connect(func(_id: String) -> void: _refresh())
	NotificationManager.notifications_cleared.connect(_refresh)

	_refresh()


## Refreshes the notification list display.
func _refresh() -> void:
	for child: Node in notification_list.get_children():
		notification_list.remove_child(child)
		child.queue_free()

	var all_notifications: Array[Dictionary] = NotificationManager.get_all()
	if all_notifications.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No notifications."
		empty_label.add_theme_color_override("font_color", UIColors.MUTED)
		notification_list.add_child(empty_label)
		clear_all_button.visible = false
		return

	clear_all_button.visible = true

	for notif: Dictionary in all_notifications:
		var item: HBoxContainer = HBoxContainer.new()
		item.add_theme_constant_override("separation", 8)

		# Unread indicator
		var indicator: Label = Label.new()
		indicator.text = "●" if not notif.get("read", false) else "○"
		indicator.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3) if not notif.get("read", false) else Color(0.4, 0.4, 0.4))
		item.add_child(indicator)

		# Text
		var text_label: Label = Label.new()
		text_label.text = "%s — %s" % [notif.get("title", ""), notif.get("message", "")]
		text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.add_child(text_label)

		# Actions
		if not notif.get("read", false):
			var read_btn: Button = Button.new()
			read_btn.text = "Mark Read"
			read_btn.pressed.connect(_on_mark_read.bind(notif.get("id", "")))
			item.add_child(read_btn)

		var dismiss_btn: Button = Button.new()
		dismiss_btn.text = "Dismiss"
		dismiss_btn.pressed.connect(_on_dismiss.bind(notif.get("id", "")))
		item.add_child(dismiss_btn)

		notification_list.add_child(item)


## Marks a notification as read.
func _on_mark_read(notification_id: String) -> void:
	NotificationManager.mark_read(notification_id)
	_refresh()


## Dismisses a notification.
func _on_dismiss(notification_id: String) -> void:
	NotificationManager.dismiss(notification_id)


## Clears all notifications.
func _on_clear_all_pressed() -> void:
	NotificationManager.clear_all()


## Closes the panel.
func _on_close_pressed() -> void:
	ScreenManager.close_modal("notification_panel")
