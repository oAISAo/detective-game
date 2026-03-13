## GameRoot.gd
## Main application container. Manages top-level scene structure:
## global command bar with navigation, screen container, modal layer, and BGM.
## Phase 4A: Integrated with ScreenManager for all navigation.
extends Control


## Reference to the screen container where gameplay screens are loaded.
@onready var screen_container: Control = $ScreenContainer

## Reference to the modal layer for overlays (interrogation, briefings).
@onready var modal_layer: CanvasLayer = $ModalLayer

## Reference to the global command bar at the top.
@onready var command_bar: PanelContainer = $CommandBar

## Day display label.
@onready var day_label: Label = $CommandBar/HBoxContainer/DayLabel

## Actions remaining display label.
@onready var actions_label: Label = $CommandBar/HBoxContainer/ActionsLabel

## Navigation buttons.
@onready var nav_desk_button: Button = $CommandBar/HBoxContainer/NavDeskButton
@onready var nav_evidence_button: Button = $CommandBar/HBoxContainer/NavEvidenceButton
@onready var nav_board_button: Button = $CommandBar/HBoxContainer/NavBoardButton
@onready var nav_timeline_button: Button = $CommandBar/HBoxContainer/NavTimelineButton
@onready var nav_map_button: Button = $CommandBar/HBoxContainer/NavMapButton
@onready var nav_log_button: Button = $CommandBar/HBoxContainer/NavLogButton

## Notification button (opens notification panel modal).
@onready var notification_button: Button = $CommandBar/HBoxContainer/NotificationButton


func _ready() -> void:
	# Connect to GameManager signals for UI updates
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.time_slot_changed.connect(_on_time_slot_changed)
	GameManager.actions_remaining_changed.connect(_on_actions_changed)
	GameManager.game_reset.connect(_on_game_reset)

	# Connect to NotificationManager
	NotificationManager.notification_added.connect(_on_notification_added)
	NotificationManager.notification_dismissed.connect(_on_notification_dismissed)
	NotificationManager.notifications_cleared.connect(_on_notifications_cleared)

	# Connect navigation buttons
	nav_desk_button.pressed.connect(func() -> void: ScreenManager.navigate_to("desk_hub"))
	nav_evidence_button.pressed.connect(func() -> void: ScreenManager.navigate_to("evidence_archive"))
	nav_board_button.pressed.connect(func() -> void: ScreenManager.navigate_to("detective_board"))
	nav_timeline_button.pressed.connect(func() -> void: ScreenManager.navigate_to("timeline_board"))
	nav_map_button.pressed.connect(func() -> void: ScreenManager.navigate_to("location_map"))
	nav_log_button.pressed.connect(func() -> void: ScreenManager.navigate_to("investigation_log"))

	# Notification button opens the notification panel modal
	notification_button.pressed.connect(_on_notification_button_pressed)

	# Connect to ScreenManager for nav button highlighting
	ScreenManager.screen_changed.connect(_on_screen_changed)

	_update_command_bar()

	# Navigate to desk hub as the default screen
	ScreenManager.navigate_to("desk_hub")

	print("[GameRoot] Ready — Phase 4A.")


## Updates all command bar labels with current state.
func _update_command_bar() -> void:
	day_label.text = "Day %d — %s" % [
		GameManager.current_day,
		GameManager.get_time_slot_display()
	]
	actions_label.text = "Actions: %d" % GameManager.actions_remaining
	_update_notification_button()


## Updates the notification button text with unread count.
func _update_notification_button() -> void:
	var count: int = NotificationManager.get_unread_count()
	if count == 0:
		notification_button.text = "🔔"
	else:
		notification_button.text = "🔔 %d" % count


## Highlights the active nav button based on current screen.
func _update_nav_highlight() -> void:
	var current: String = ScreenManager.current_screen
	nav_desk_button.disabled = (current == "desk_hub")
	nav_evidence_button.disabled = (current == "evidence_archive")
	nav_board_button.disabled = (current == "detective_board")
	nav_timeline_button.disabled = (current == "timeline_board")
	nav_map_button.disabled = (current == "location_map")
	nav_log_button.disabled = (current == "investigation_log")


# --- Signal Handlers --- #

func _on_day_changed(_new_day: int) -> void:
	_update_command_bar()


func _on_time_slot_changed(_new_slot: Enums.TimeSlot) -> void:
	_update_command_bar()


func _on_actions_changed(_remaining: int) -> void:
	_update_command_bar()


func _on_game_reset() -> void:
	_update_command_bar()
	ScreenManager.reset()
	ScreenManager.navigate_to("desk_hub")


func _on_notification_added(_notification: Dictionary) -> void:
	_update_notification_button()


func _on_notification_dismissed(_notification_id: String) -> void:
	_update_notification_button()


func _on_notifications_cleared() -> void:
	_update_notification_button()


func _on_screen_changed(_screen_id: String) -> void:
	_update_nav_highlight()


func _on_notification_button_pressed() -> void:
	if ScreenManager.is_modal_open("notification_panel"):
		ScreenManager.close_modal("notification_panel")
	else:
		ScreenManager.open_modal("notification_panel")


# --- Legacy Screen Management (kept for backward compatibility) --- #

## Loads a scene into the screen container, removing any existing screen.
## Prefer ScreenManager.navigate_to() for new code.
func load_screen(scene_path: String) -> void:
	for child: Node in screen_container.get_children():
		child.queue_free()

	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("[GameRoot] Failed to load screen: %s" % scene_path)
		return

	var instance: Node = scene.instantiate()
	screen_container.add_child(instance)
	print("[GameRoot] Screen loaded: %s" % scene_path)


## Shows a modal overlay on top of everything.
## Prefer ScreenManager.open_modal() for new code.
func show_modal(scene_path: String) -> Node:
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("[GameRoot] Failed to load modal: %s" % scene_path)
		return null

	var instance: Node = scene.instantiate()
	modal_layer.add_child(instance)
	print("[GameRoot] Modal shown: %s" % scene_path)
	return instance


## Closes and removes a specific modal.
func close_modal(modal_node: Node) -> void:
	if modal_node and modal_node.get_parent() == modal_layer:
		modal_node.queue_free()


## Closes all modals.
func close_all_modals() -> void:
	for child: Node in modal_layer.get_children():
		child.queue_free()
