## DeskHub.gd
## The main investigation desk screen — the player's home base.
## Shows day/time, actions remaining, notification area, and quick-access navigation.
## Phase 4A: Core navigation hub.
extends Control


@onready var day_info_label: Label = %DayInfoLabel
@onready var actions_info_label: Label = %ActionsInfoLabel
@onready var notification_list: VBoxContainer = %NotificationList
@onready var nav_evidence_button: Button = %NavEvidenceButton
@onready var nav_board_button: Button = %NavBoardButton
@onready var nav_timeline_button: Button = %NavTimelineButton
@onready var nav_map_button: Button = %NavMapButton
@onready var nav_log_button: Button = %NavLogButton


func _ready() -> void:
	# Connect navigation buttons
	nav_evidence_button.pressed.connect(func() -> void: ScreenManager.navigate_to("evidence_archive"))
	nav_board_button.pressed.connect(func() -> void: ScreenManager.navigate_to("detective_board"))
	nav_timeline_button.pressed.connect(func() -> void: ScreenManager.navigate_to("timeline_board"))
	nav_map_button.pressed.connect(func() -> void: ScreenManager.navigate_to("location_map"))
	nav_log_button.pressed.connect(func() -> void: ScreenManager.navigate_to("investigation_log"))

	# Connect signals for live updates
	GameManager.day_changed.connect(func(_d: int) -> void: _refresh())
	GameManager.time_slot_changed.connect(func(_s: Enums.TimeSlot) -> void: _refresh())
	GameManager.actions_remaining_changed.connect(func(_r: int) -> void: _refresh())
	NotificationManager.notification_added.connect(func(_n: Dictionary) -> void: _refresh_notifications())
	NotificationManager.notification_dismissed.connect(func(_id: String) -> void: _refresh_notifications())
	NotificationManager.notifications_cleared.connect(_refresh_notifications)

	_refresh()
	_refresh_notifications()


## Updates the desk hub info display.
func _refresh() -> void:
	day_info_label.text = "Day %d — %s" % [GameManager.current_day, GameManager.get_time_slot_display()]
	actions_info_label.text = "Actions Remaining: %d / %d" % [GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY]


## Refreshes the notification list area.
func _refresh_notifications() -> void:
	for child: Node in notification_list.get_children():
		child.queue_free()

	var unread: Array[Dictionary] = NotificationManager.get_unread()
	if unread.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No new notifications."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		notification_list.add_child(empty_label)
		return

	for notif: Dictionary in unread:
		var notif_label: Label = Label.new()
		notif_label.text = "• %s — %s" % [notif.get("title", ""), notif.get("message", "")]
		notif_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notification_list.add_child(notif_label)
