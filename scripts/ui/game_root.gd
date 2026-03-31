## GameRoot.gd
## Main application container. Manages top-level scene structure:
## global command bar with navigation, screen container, modal layer, and BGM.
## Phase 4A: Integrated with ScreenManager for all navigation.
## Phase 18: Title screen and case selection flow added.
extends Control


## Scene paths for menu screens.
const TITLE_SCREEN_SCENE: String = "res://scenes/ui/title_screen.tscn"
const CASE_SELECTION_SCENE: String = "res://scenes/ui/case_selection_screen.tscn"


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
@onready var nav_suspects_button: Button = $CommandBar/HBoxContainer/NavSuspectsButton
@onready var nav_log_button: Button = $CommandBar/HBoxContainer/NavLogButton

## Notification button (opens notification panel modal).
@onready var notification_button: Button = $CommandBar/HBoxContainer/NotificationButton

## End Day button (triggers night processing).
@onready var end_day_button: Button = $CommandBar/HBoxContainer/EndDayButton


func _ready() -> void:
	# Connect to GameManager signals for UI updates
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.phase_changed.connect(_on_phase_changed)
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
	nav_suspects_button.pressed.connect(func() -> void: ScreenManager.navigate_to("suspect_list"))
	nav_log_button.pressed.connect(func() -> void: ScreenManager.navigate_to("investigation_log"))

	# Notification button opens the notification panel modal
	notification_button.pressed.connect(_on_notification_button_pressed)

	# End Day button
	end_day_button.pressed.connect(_on_end_day_pressed)

	# Connect to DaySystem for night-to-morning transition
	var day_sys: Node = get_node_or_null("/root/DaySystem")
	if day_sys:
		day_sys.night_processing_completed.connect(_on_night_processing_completed)

	# Connect to ScreenManager for nav button highlighting
	ScreenManager.screen_changed.connect(_on_screen_changed)

	# Start at the title screen — hide command bar until investigation begins
	_show_title_screen()

	print("[GameRoot] Ready — Phase 18: Title screen.")


## Updates all command bar labels with current state.
func _update_command_bar() -> void:
	day_label.text = "Day %d — %s" % [
		GameManager.current_day,
		GameManager.get_phase_display()
	]
	# Show actions only during Daytime
	if GameManager.is_daytime():
		actions_label.text = "Actions: %d / %d" % [GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY]
		actions_label.visible = true
	else:
		actions_label.visible = false
	# End Day button only visible during Daytime
	end_day_button.visible = GameManager.is_daytime()
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
	nav_suspects_button.disabled = (current == "suspect_list")
	nav_log_button.disabled = (current == "investigation_log")


# --- Signal Handlers --- #

func _on_day_changed(_new_day: int) -> void:
	_update_command_bar()


func _on_phase_changed(_new_phase: Enums.DayPhase) -> void:
	_update_command_bar()


func _on_actions_changed(_remaining: int) -> void:
	_update_command_bar()


func _on_game_reset() -> void:
	_update_command_bar()


# --- Title Screen & Case Selection Flow --- #

## Shows the title screen, hiding the command bar and clearing the screen container.
func _show_title_screen() -> void:
	command_bar.visible = false
	_clear_screen_container()
	ScreenManager.reset()

	var scene: PackedScene = load(TITLE_SCREEN_SCENE) as PackedScene
	if scene == null:
		push_error("[GameRoot] Failed to load title screen.")
		return

	var title_screen: Control = scene.instantiate() as Control
	title_screen.new_game_requested.connect(_on_title_new_game)
	title_screen.continue_requested.connect(_on_title_continue)
	title_screen.debug_game_requested.connect(_on_title_debug_game)
	screen_container.add_child(title_screen)


## Shows the case selection screen.
func _show_case_selection() -> void:
	_clear_screen_container()

	var scene: PackedScene = load(CASE_SELECTION_SCENE) as PackedScene
	if scene == null:
		push_error("[GameRoot] Failed to load case selection screen.")
		return

	var case_screen: Control = scene.instantiate() as Control
	case_screen.case_selected.connect(_on_case_selected)
	case_screen.back_requested.connect(_on_case_selection_back)
	screen_container.add_child(case_screen)


## Starts the investigation after loading a case.
func _start_investigation(case_folder: String) -> void:
	# Load the case data
	var loaded: bool = CaseManager.load_case_folder(case_folder)
	if not loaded:
		push_error("[GameRoot] Failed to load case: %s" % case_folder)
		return

	# Initialize all game systems for a new game
	GameManager.new_game()

	# Process the first morning (day-start events, briefing)
	var briefing_items: Array[String] = []
	var day_sys: Node = get_node_or_null("/root/DaySystem")
	if day_sys and day_sys.has_method("process_morning"):
		briefing_items.assign(day_sys.call("process_morning"))

	# Show the command bar and navigate to the desk hub
	command_bar.visible = true
	ScreenManager.reset()
	_update_command_bar()
	ScreenManager.navigate_to("desk_hub")

	# Show the morning briefing modal if there are briefing items
	if not briefing_items.is_empty():
		DialogueSystem.queue_briefing(briefing_items, GameManager.current_day)
		ScreenManager.open_modal("morning_briefing")

	print("[GameRoot] Investigation started: %s" % case_folder)


## Clears all children from the screen container.
func _clear_screen_container() -> void:
	for child: Node in screen_container.get_children():
		child.queue_free()


## Returns to the title screen (e.g. from main menu).
func return_to_title() -> void:
	GameManager.game_active = false
	_show_title_screen()


func _on_title_new_game() -> void:
	_show_case_selection()


func _on_title_debug_game(preset_filename: String) -> void:
	var loaded: bool = DebugStateLoader.load_debug_state(preset_filename)
	if not loaded:
		push_error("[GameRoot] Failed to load debug preset: %s" % preset_filename)
		return

	command_bar.visible = true
	ScreenManager.reset()
	_update_command_bar()
	ScreenManager.navigate_to("desk_hub")
	print("[GameRoot] Debug game started with preset: %s" % preset_filename)


func _on_title_continue(slot: int) -> void:
	var loaded: bool = SaveManager.load_game(slot)
	if not loaded:
		push_error("[GameRoot] Failed to load save slot %d." % slot)
		return

	command_bar.visible = true
	ScreenManager.reset()
	_update_command_bar()
	ScreenManager.navigate_to("desk_hub")
	print("[GameRoot] Continued from save slot %d." % slot)


func _on_case_selected(case_folder: String) -> void:
	_start_investigation(case_folder)


func _on_case_selection_back() -> void:
	_show_title_screen()


func _on_notification_added(_notification: Dictionary) -> void:
	_update_notification_button()


func _on_notification_dismissed(_notification_id: String) -> void:
	_update_notification_button()


func _on_notifications_cleared() -> void:
	_update_notification_button()


func _on_screen_changed(_screen_id: String) -> void:
	_update_nav_highlight()


func _on_end_day_pressed() -> void:
	var day_sys: Node = get_node_or_null("/root/DaySystem")
	if day_sys and day_sys.has_method("try_end_day"):
		day_sys.call("try_end_day")


func _on_night_processing_completed(new_day: int) -> void:
	# Process the new day's morning briefing
	var day_sys: Node = get_node_or_null("/root/DaySystem")
	var briefing_items: Array[String] = []
	if day_sys and day_sys.has_method("process_morning"):
		briefing_items.assign(day_sys.call("process_morning"))

	_update_command_bar()
	ScreenManager.navigate_to("desk_hub")

	if not briefing_items.is_empty():
		DialogueSystem.queue_briefing(briefing_items, new_day)
		ScreenManager.open_modal("morning_briefing")


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
