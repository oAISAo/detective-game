## GameRoot.gd
## Main application container. Manages top-level scene structure:
## global command bar, screen container, modal layer, and background music.
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

## Notification count label.
@onready var notification_label: Label = $CommandBar/HBoxContainer/NotificationLabel


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

	_update_command_bar()
	print("[GameRoot] Ready.")


## Updates all command bar labels with current state.
func _update_command_bar() -> void:
	day_label.text = "Day %d — %s" % [
		GameManager.current_day,
		GameManager.get_time_slot_display()
	]
	actions_label.text = "Actions left: %d" % GameManager.actions_remaining
	notification_label.text = _get_notification_text()


func _get_notification_text() -> String:
	var count: int = NotificationManager.get_unread_count()
	if count == 0:
		return ""
	return "🔔 %d" % count


# --- Signal Handlers --- #

func _on_day_changed(_new_day: int) -> void:
	_update_command_bar()


func _on_time_slot_changed(_new_slot: Enums.TimeSlot) -> void:
	_update_command_bar()


func _on_actions_changed(_remaining: int) -> void:
	_update_command_bar()


func _on_game_reset() -> void:
	_update_command_bar()
	# Clear screen container
	for child: Node in screen_container.get_children():
		child.queue_free()


func _on_notification_added(_notification: Dictionary) -> void:
	_update_command_bar()


func _on_notification_dismissed(_notification_id: String) -> void:
	_update_command_bar()


func _on_notifications_cleared() -> void:
	_update_command_bar()


# --- Screen Management --- #

## Loads a scene into the screen container, removing any existing screen.
func load_screen(scene_path: String) -> void:
	# Clear current screen
	for child: Node in screen_container.get_children():
		child.queue_free()

	# Load and instance new screen
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("[GameRoot] Failed to load screen: %s" % scene_path)
		return

	var instance: Node = scene.instantiate()
	screen_container.add_child(instance)
	print("[GameRoot] Screen loaded: %s" % scene_path)


## Shows a modal overlay on top of everything.
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
