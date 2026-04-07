## GameRoot.gd
## Main application container. Manages top-level scene structure:
## global command bar with navigation, screen container, modal layer, and BGM.
## Phase 4A: Integrated with ScreenManager for all navigation.
## Phase 18: Title screen and case selection flow added.
## Phase 19: Redesigned premium command bar with icon-above-label nav items.
extends Control


## Scene paths for menu screens.
const TITLE_SCREEN_SCENE: String = "res://scenes/ui/title_screen.tscn"
const CASE_SELECTION_SCENE: String = "res://scenes/ui/case_selection_screen.tscn"

## Nav item definitions: [screen_id, icon_char, label_text]
const NAV_ITEMS: Array = [
	["desk_hub", "monitor", "Desk"],
	["evidence_archive", "mystery", "Evidence"],
	["detective_board", "pinboard", "Board"],
	["timeline_board", "calendar_clock", "Timeline"],
	["location_map", "map_search", "Map"],
	["suspect_list", "person_search", "Suspects"],
	["investigation_log", "docs", "Log"],
]

## Colors for the nav bar styling.
const NAV_ICON_INACTIVE: Color = Color(0.38, 0.37, 0.40)
const NAV_ICON_ACTIVE: Color = Color(0.95, 0.90, 0.82)
const NAV_ICON_HOVER: Color = Color(0.62, 0.60, 0.58)
const NAV_LABEL_INACTIVE: Color = Color(0.36, 0.35, 0.38)
const NAV_LABEL_ACTIVE: Color = Color(0.88, 0.85, 0.80)
const NAV_LABEL_HOVER: Color = Color(0.55, 0.53, 0.52)
const ACTIVE_UNDERLINE_COLOR: Color = Color(0.78, 0.62, 0.22, 0.65)
const ACTIVE_GLOW_COLOR: Color = Color(0.78, 0.62, 0.22, 0.18)
const GREEN_GLOW_COLOR: Color = Color(0.91, 0.93, 0.89, 0.65)
const BADGE_COLOR: Color = Color(0.9, 0.55, 0.15)
const END_DAY_BG: Color = Color(0.22, 0.22, 0.26, 0.9)
const END_DAY_BORDER: Color = Color(0.4, 0.38, 0.35, 0.5)
const END_DAY_HOVER_BG: Color = Color(0.28, 0.27, 0.32, 0.95)
const END_DAY_TEXT: Color = Color(0.85, 0.82, 0.78)


## Reference to the screen container where gameplay screens are loaded.
@onready var screen_container: Control = $ScreenContainer

## Reference to the modal layer for overlays (interrogation, briefings).
@onready var modal_layer: CanvasLayer = $ModalLayer

## Reference to the toast container for slide-in notifications.
@onready var toast_container: VBoxContainer = $ToastLayer/ToastAnchor/ToastContainer

## Reference to the global command bar at the top.
@onready var command_bar: PanelContainer = %CommandBar

## Day display label.
@onready var day_label: Label = %DayLabel

## Progress bar for case actions.
@onready var progress_bar: ColorRect = %ProgressBar

## Actions remaining display label.
@onready var actions_label: Label = %ActionsLabel

## Center zone container for nav items.
@onready var center_zone: HBoxContainer = $CommandBar/MainHBox/CenterZone

## Notification button (opens notification panel modal).
@onready var notification_button: Button = %NotificationButton

## End Day button (triggers night processing).
@onready var end_day_button: Button = %EndDayButton

## Phase icon label (sun/moon).
@onready var phase_icon: Label = $CommandBar/MainHBox/LeftZone/DaySection/PhaseIcon

## Tracks built nav item containers keyed by screen_id.
var _nav_items: Dictionary = {}


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

	# Build nav items programmatically
	_build_nav_items()

	# Notification button opens the notification panel modal
	notification_button.pressed.connect(_on_notification_button_pressed)

	# Style the End Day button
	_style_end_day_button()

	# End Day button
	end_day_button.pressed.connect(_on_end_day_pressed)

	# Connect to DaySystem for night-to-morning transition
	DaySystem.night_processing_completed.connect(_on_night_processing_completed)

	# Connect to ScreenManager for nav button highlighting
	ScreenManager.screen_changed.connect(_on_screen_changed)

	# Style the command bar
	_style_command_bar()

	# Style the notification button
	_style_notification_button()

	# Style the left zone labels
	_style_left_zone()

	# Start at the title screen — hide command bar until investigation begins
	_show_title_screen()

	print("[GameRoot] Ready — Phase 19: Redesigned command bar.")


## Builds all navigation item containers in the center zone.
func _build_nav_items() -> void:
	# Add breathing room between nav items
	center_zone.set("theme_override_constants/separation", 4)

	# Load Material Symbols font with ligatures enabled
	var base_font := load("res://assets/fonts/MaterialSymbolsOutlined.ttf") as FontFile
	var icon_font := FontVariation.new()
	icon_font.base_font = base_font
	icon_font.opentype_features = {"liga": 1, "calt": 1}

	for item_def: Array in NAV_ITEMS:
		var screen_id: String = item_def[0]
		var icon_char: String = item_def[1]
		var label_text: String = item_def[2]

		# Create the clickable container
		var btn := Button.new()
		btn.flat = true
		btn.custom_minimum_size = Vector2(74, 0)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		# Normal — fully transparent
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0, 0, 0, 0)
		normal_style.corner_radius_top_left = 8
		normal_style.corner_radius_top_right = 8
		normal_style.corner_radius_bottom_left = 8
		normal_style.corner_radius_bottom_right = 8
		normal_style.content_margin_left = 8.0
		normal_style.content_margin_right = 8.0
		normal_style.content_margin_top = 8.0
		normal_style.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("pressed", normal_style)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		# Hover — very subtle background lift
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.50, 0.48, 0.44, 0.07)
		hover_style.corner_radius_top_left = 8
		hover_style.corner_radius_top_right = 8
		hover_style.corner_radius_bottom_left = 8
		hover_style.corner_radius_bottom_right = 8
		hover_style.content_margin_left = 8.0
		hover_style.content_margin_right = 8.0
		hover_style.content_margin_top = 8.0
		hover_style.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("hover", hover_style)

		# Disabled (active tab) — subtle illuminated plate
		var active_style := StyleBoxFlat.new()
		active_style.bg_color = Color(0.55, 0.48, 0.32, 0.09)
		active_style.corner_radius_top_left = 8
		active_style.corner_radius_top_right = 8
		active_style.corner_radius_bottom_left = 8
		active_style.corner_radius_bottom_right = 8
		active_style.content_margin_left = 8.0
		active_style.content_margin_right = 8.0
		active_style.content_margin_top = 8.0
		active_style.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("disabled", active_style)

		# VBox inside the button for icon + label + underline
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.set("theme_override_constants/separation", 1)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.add_child(vbox)

		# Icon label — Material Symbol, larger for clarity
		var icon_label := Label.new()
		icon_label.text = icon_char
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_override("font", icon_font)
		icon_label.add_theme_font_size_override("font_size", 40)
		icon_label.add_theme_color_override("font_color", NAV_ICON_INACTIVE)
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon_label)

		# Text label — compact, understated
		var text_label := Label.new()
		text_label.text = label_text
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.add_theme_font_size_override("font_size", 14)
		text_label.add_theme_color_override("font_color", NAV_LABEL_INACTIVE)
		text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(text_label)

		# Underline indicator — styled panel with soft green glow shadow
		var underline_panel := PanelContainer.new()
		underline_panel.custom_minimum_size = Vector2(30, 2)
		underline_panel.visible = false
		underline_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		underline_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var underline_style := StyleBoxFlat.new()
		underline_style.bg_color = ACTIVE_GLOW_COLOR
		underline_style.corner_radius_top_left = 1
		underline_style.corner_radius_top_right = 1
		underline_style.corner_radius_bottom_left = 1
		underline_style.corner_radius_bottom_right = 1
		underline_style.shadow_color = GREEN_GLOW_COLOR
		underline_style.shadow_size = 4
		underline_style.shadow_offset = Vector2(0, 0)
		underline_panel.add_theme_stylebox_override("panel", underline_style)

		# Center the underline with a centering container
		var underline_center := CenterContainer.new()
		underline_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		underline_center.add_child(underline_panel)
		vbox.add_child(underline_center)

		# Connect press
		btn.pressed.connect(func() -> void: ScreenManager.navigate_to(screen_id))

		# Connect hover signals for highlight
		btn.mouse_entered.connect(func() -> void: _on_nav_hover(screen_id, true))
		btn.mouse_exited.connect(func() -> void: _on_nav_hover(screen_id, false))

		center_zone.add_child(btn)

		# Store references (including color state for tween interpolation)
		_nav_items[screen_id] = {
			"button": btn,
			"icon": icon_label,
			"label": text_label,
			"underline": underline_panel,
			"_icon_color": NAV_ICON_INACTIVE,
			"_label_color": NAV_LABEL_INACTIVE,
			"_tween": null,
		}


## Handles nav item hover state with smooth transitions.
func _on_nav_hover(screen_id: String, hovered: bool) -> void:
	if not _nav_items.has(screen_id):
		return
	var item: Dictionary = _nav_items[screen_id]
	# Don't change active item on hover
	if ScreenManager.current_screen == screen_id:
		return
	if hovered:
		_tween_nav_colors(screen_id, NAV_ICON_HOVER, NAV_LABEL_HOVER, 0.15)
	else:
		_tween_nav_colors(screen_id, NAV_ICON_INACTIVE, NAV_LABEL_INACTIVE, 0.2)


## Smoothly transitions a nav item's icon and label colors via tween.
func _tween_nav_colors(screen_id: String, icon_color: Color, label_color: Color, duration: float = 0.15) -> void:
	var item: Dictionary = _nav_items[screen_id]
	if item.get("_tween") is Tween and item["_tween"].is_valid():
		item["_tween"].kill()

	var icon_lbl: Label = item["icon"]
	var text_lbl: Label = item["label"]
	var from_icon: Color = item.get("_icon_color", NAV_ICON_INACTIVE)
	var from_label: Color = item.get("_label_color", NAV_LABEL_INACTIVE)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(c: Color) -> void: icon_lbl.add_theme_color_override("font_color", c), from_icon, icon_color, duration)
	tw.tween_method(func(c: Color) -> void: text_lbl.add_theme_color_override("font_color", c), from_label, label_color, duration)

	item["_icon_color"] = icon_color
	item["_label_color"] = label_color
	item["_tween"] = tw


## Styles the command bar panel — premium dark command strip with depth.
func _style_command_bar() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.11, 0.14, 0.97)
	# Subtle top highlight for surface sheen
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.28, 0.26, 0.24, 0.30)
	# Slightly brighter top edge for depth
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.content_margin_left = 20.0
	style.content_margin_top = 6.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 4.0
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	# Anti-aliased corners
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.0
	command_bar.add_theme_stylebox_override("panel", style)


## Styles the End Day button with a premium dark look.
func _style_end_day_button() -> void:
	# Normal
	var normal := StyleBoxFlat.new()
	normal.bg_color = END_DAY_BG
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = END_DAY_BORDER
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_right = 8
	normal.corner_radius_bottom_left = 8
	normal.content_margin_left = 16.0
	normal.content_margin_top = 6.0
	normal.content_margin_right = 16.0
	normal.content_margin_bottom = 6.0
	end_day_button.add_theme_stylebox_override("normal", normal)

	# Hover
	var hover := StyleBoxFlat.new()
	hover.bg_color = END_DAY_HOVER_BG
	hover.border_width_left = 1
	hover.border_width_top = 1
	hover.border_width_right = 1
	hover.border_width_bottom = 1
	hover.border_color = Color(0.5, 0.48, 0.42, 0.6)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_right = 8
	hover.corner_radius_bottom_left = 8
	hover.content_margin_left = 16.0
	hover.content_margin_top = 6.0
	hover.content_margin_right = 16.0
	hover.content_margin_bottom = 6.0
	end_day_button.add_theme_stylebox_override("hover", hover)

	# Pressed
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.18, 0.18, 0.21, 0.95)
	pressed.border_width_left = 1
	pressed.border_width_top = 1
	pressed.border_width_right = 1
	pressed.border_width_bottom = 1
	pressed.border_color = Color(0.9, 0.7, 0.2, 0.5)
	pressed.corner_radius_top_left = 8
	pressed.corner_radius_top_right = 8
	pressed.corner_radius_bottom_right = 8
	pressed.corner_radius_bottom_left = 8
	pressed.content_margin_left = 16.0
	pressed.content_margin_top = 6.0
	pressed.content_margin_right = 16.0
	pressed.content_margin_bottom = 6.0
	end_day_button.add_theme_stylebox_override("pressed", pressed)

	# Focus
	end_day_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# Font
	end_day_button.add_theme_color_override("font_color", END_DAY_TEXT)
	end_day_button.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.88))
	end_day_button.add_theme_color_override("font_pressed_color", Color(0.7, 0.65, 0.6))
	end_day_button.add_theme_font_size_override("font_size", 14)


## Styles the notification button to be minimal and flat.
func _style_notification_button() -> void:
	var empty := StyleBoxFlat.new()
	empty.bg_color = Color(0, 0, 0, 0)
	empty.set_content_margin_all(0)
	notification_button.add_theme_stylebox_override("normal", empty)
	notification_button.add_theme_stylebox_override("pressed", empty)
	notification_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.25, 0.24, 0.28, 0.3)
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_right = 6
	hover.corner_radius_bottom_left = 6
	hover.set_content_margin_all(0)
	notification_button.add_theme_stylebox_override("hover", hover)

	notification_button.add_theme_font_size_override("font_size", 16)
	notification_button.add_theme_color_override("font_color", Color(0.42, 0.40, 0.42))
	notification_button.add_theme_color_override("font_hover_color", Color(0.60, 0.58, 0.56))


## Styles the left zone labels with appropriate sizes and colors.
func _style_left_zone() -> void:
	day_label.add_theme_font_size_override("font_size", 16)
	day_label.add_theme_color_override("font_color", Color(0.72, 0.69, 0.65))

	actions_label.add_theme_font_size_override("font_size", 16)
	actions_label.add_theme_color_override("font_color", Color(0.50, 0.48, 0.45))

	phase_icon.add_theme_font_size_override("font_size", 16)
	phase_icon.add_theme_color_override("font_color", Color(0.78, 0.62, 0.22, 0.75))


## Updates all command bar labels with current state.
func _update_command_bar() -> void:
	day_label.text = "Day %d – %s" % [
		GameManager.current_day,
		GameManager.get_phase_display()
	]

	# Update phase icon
	if GameManager.is_daytime():
		phase_icon.text = "☀"
	else:
		phase_icon.text = "🌙"

	# Show actions only during Daytime
	if GameManager.is_daytime():
		actions_label.text = "Actions: %d / %d" % [GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY]
		actions_label.visible = true
		# Update progress bar width proportionally
		var ratio: float = float(GameManager.actions_remaining) / float(GameManager.ACTIONS_PER_DAY) if GameManager.ACTIONS_PER_DAY > 0 else 0.0
		progress_bar.custom_minimum_size.x = 120.0 * ratio
		progress_bar.visible = true
	else:
		actions_label.visible = false
		progress_bar.visible = false

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
	for screen_id: String in _nav_items:
		var item: Dictionary = _nav_items[screen_id]
		var is_active: bool = (screen_id == current)
		var btn: Button = item["button"]
		btn.disabled = is_active
		btn.mouse_default_cursor_shape = Control.CURSOR_ARROW if is_active else Control.CURSOR_POINTING_HAND

		if is_active:
			_tween_nav_colors(screen_id, NAV_ICON_ACTIVE, NAV_LABEL_ACTIVE, 0.2)
			item["underline"].visible = true
		else:
			_tween_nav_colors(screen_id, NAV_ICON_INACTIVE, NAV_LABEL_INACTIVE, 0.25)
			item["underline"].visible = false


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
	if DaySystem.has_method("process_morning"):
		briefing_items.assign(DaySystem.call("process_morning"))

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
		screen_container.remove_child(child)
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

	# If the save was in MORNING phase, process morning to transition to DAYTIME
	if GameManager.current_phase == Enums.DayPhase.MORNING:
		if DaySystem.has_method("process_morning"):
			var briefing_items: Array[String] = []
			briefing_items.assign(DaySystem.call("process_morning"))
			_update_command_bar()
			ScreenManager.navigate_to("desk_hub")
			if not briefing_items.is_empty():
				DialogueSystem.queue_briefing(briefing_items, GameManager.current_day)
				ScreenManager.open_modal("morning_briefing")
		else:
			_update_command_bar()
			ScreenManager.navigate_to("desk_hub")
	else:
		_update_command_bar()
		ScreenManager.navigate_to("desk_hub")

	print("[GameRoot] Continued from save slot %d." % slot)


func _on_case_selected(case_folder: String) -> void:
	_start_investigation(case_folder)


func _on_case_selection_back() -> void:
	_show_title_screen()


func _on_notification_added(notification: Dictionary) -> void:
	_update_notification_button()
	_spawn_toast(notification)


func _on_notification_dismissed(_notification_id: String) -> void:
	_update_notification_button()


func _on_notifications_cleared() -> void:
	_update_notification_button()


func _on_screen_changed(_screen_id: String) -> void:
	_update_nav_highlight()


func _on_end_day_pressed() -> void:
	if DaySystem.has_method("try_end_day"):
		DaySystem.call("try_end_day")


func _on_night_processing_completed(new_day: int) -> void:
	# Process the new day's morning briefing
	var briefing_items: Array[String] = []
	if DaySystem.has_method("process_morning"):
		briefing_items.assign(DaySystem.call("process_morning"))

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


## Spawns a slide-in toast for a notification dictionary.
func _spawn_toast(notification: Dictionary) -> void:
	var toast: NotificationToast = NotificationToast.new()
	toast_container.add_child(toast)
	toast.setup(
		notification.get("title", ""),
		notification.get("message", ""),
		notification.get("type", NotificationManager.NotificationType.SYSTEM),
	)


# --- Legacy Screen Management (kept for backward compatibility) --- #

## Loads a scene into the screen container, removing any existing screen.
## Prefer ScreenManager.navigate_to() for new code.
func load_screen(scene_path: String) -> void:
	for child: Node in screen_container.get_children():
		screen_container.remove_child(child)
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
		modal_layer.remove_child(child)
		child.queue_free()
