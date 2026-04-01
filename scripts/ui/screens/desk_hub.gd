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
@onready var nav_suspects_button: Button = %NavSuspectsButton
@onready var nav_log_button: Button = %NavLogButton

# Stored callables for signal disconnection on exit
var _on_day_changed: Callable
var _on_phase_changed: Callable
var _on_actions_changed: Callable
var _on_notif_added: Callable
var _on_notif_dismissed: Callable
var _on_notif_cleared: Callable


func _ready() -> void:
	# Connect navigation buttons
	nav_evidence_button.pressed.connect(func() -> void: ScreenManager.navigate_to("evidence_archive"))
	nav_board_button.pressed.connect(func() -> void: ScreenManager.navigate_to("detective_board"))
	nav_timeline_button.pressed.connect(func() -> void: ScreenManager.navigate_to("timeline_board"))
	nav_map_button.pressed.connect(func() -> void: ScreenManager.navigate_to("location_map"))
	nav_suspects_button.pressed.connect(func() -> void: ScreenManager.navigate_to("suspect_list"))
	nav_log_button.pressed.connect(func() -> void: ScreenManager.navigate_to("investigation_log"))

	# Store callables so we can disconnect them in _exit_tree
	_on_day_changed = func(_d: int) -> void: _refresh()
	_on_phase_changed = func(_s: Enums.DayPhase) -> void: _refresh()
	_on_actions_changed = func(_r: int) -> void: _refresh()
	_on_notif_added = func(_n: Dictionary) -> void: _refresh_notifications()
	_on_notif_dismissed = func(_id: String) -> void: _refresh_notifications()
	_on_notif_cleared = _refresh_notifications

	# Connect signals for live updates
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.actions_remaining_changed.connect(_on_actions_changed)
	NotificationManager.notification_added.connect(_on_notif_added)
	NotificationManager.notification_dismissed.connect(_on_notif_dismissed)
	NotificationManager.notifications_cleared.connect(_on_notif_cleared)

	_refresh()
	_refresh_notifications()


func _exit_tree() -> void:
	GameManager.day_changed.disconnect(_on_day_changed)
	GameManager.phase_changed.disconnect(_on_phase_changed)
	GameManager.actions_remaining_changed.disconnect(_on_actions_changed)
	NotificationManager.notification_added.disconnect(_on_notif_added)
	NotificationManager.notification_dismissed.disconnect(_on_notif_dismissed)
	NotificationManager.notifications_cleared.disconnect(_on_notif_cleared)


## Updates the desk hub info display.
func _refresh() -> void:
	day_info_label.text = "Day %d — %s" % [GameManager.current_day, GameManager.get_phase_display()]
	if GameManager.is_daytime():
		actions_info_label.text = "Actions Remaining: %d / %d" % [GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY]
		actions_info_label.visible = true
	else:
		actions_info_label.visible = false


## Refreshes the notification list area.
func _refresh_notifications() -> void:
	for child: Node in notification_list.get_children():
		notification_list.remove_child(child)
		child.queue_free()

	var unread: Array[Dictionary] = NotificationManager.get_unread()
	if unread.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No new notifications."
		empty_label.add_theme_color_override("font_color", UIColors.MUTED)
		notification_list.add_child(empty_label)
		return

	for notif: Dictionary in unread:
		var notif_label: Label = Label.new()
		notif_label.text = "• %s — %s" % [notif.get("title", ""), notif.get("message", "")]
		notif_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		notification_list.add_child(notif_label)
