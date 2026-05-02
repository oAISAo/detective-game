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
const NAV_HOVER_BG: Color = Color(0.50, 0.48, 0.44, 0.04)
const NAV_ACTIVE_BG: Color = Color(0.52, 0.49, 0.42, 0.07)
const NAV_ACTIVE_BORDER: Color = Color(0.82, 0.74, 0.58, 0.14)

const NAV_ICON_INACTIVE: Color = Color(0.46, 0.46, 0.50)
const NAV_ICON_ACTIVE: Color = Color(0.91, 0.88, 0.82)
const NAV_ICON_HOVER: Color = Color(0.67, 0.66, 0.63)
const NAV_ICON_GLOW: Color = Color(0.88, 0.85, 0.76, 0.18)

const NAV_LABEL_INACTIVE: Color = Color(0.40, 0.40, 0.44)
const NAV_LABEL_ACTIVE: Color = Color(0.82, 0.80, 0.75)
const NAV_LABEL_HOVER: Color = Color(0.58, 0.57, 0.55)
const NAV_LABEL_GLOW: Color = Color(0.82, 0.80, 0.72, 0.10)

const ACTIVE_GLOW_COLOR: Color = Color(0.80, 0.68, 0.36, 0.16)
const GREEN_GLOW_COLOR: Color = Color(0.63, 0.67, 0.48, 0.22)
const NAV_UNDERLINE_COLOR: Color = Color(0.86, 0.82, 0.72)
const NAV_UNDERLINE_GLOW: Color = Color(0.68, 0.72, 0.50, 0.18)
const BADGE_COLOR: Color = Color(0.18, 0.19, 0.22, 0.94)

const END_DAY_TEXT: Color = Color(0.84, 0.82, 0.78)


## Reference to the screen container where gameplay screens are loaded.
@onready var screen_container: Control = $ScreenContainer

## Radial gradient background ColorRect.
@onready var _background: ColorRect = $Background

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

## Material Symbols font with ligatures — shared across all functions.
var icon_font: FontVariation


func _ready() -> void:
	_setup_background()

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
	var base_font := load("res://assets/fonts/MaterialSymbolsOutlined.ttf") as FontFile
	icon_font = FontVariation.new()
	icon_font.base_font = base_font
	icon_font.opentype_features = {"liga": 1, "calt": 1}
	_build_nav_items()

	# Notification button opens the notification panel modal
	notification_button.pressed.connect(_on_notification_button_pressed)

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
	center_zone.set("theme_override_constants/separation", 6)

	for item_def: Array in NAV_ITEMS:
		var screen_id: String = item_def[0]
		var icon_char: String = item_def[1]
		var label_text: String = item_def[2]

		# -----------------------------
		# Button root
		# -----------------------------
		var btn := Button.new()
		btn.flat = true
		btn.custom_minimum_size = Vector2(88, 84)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		# -----------------------------
		# Button styles
		# -----------------------------
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0, 0, 0, 0)
		normal_style.corner_radius_top_left = 10
		normal_style.corner_radius_top_right = 10
		normal_style.corner_radius_bottom_left = 10
		normal_style.corner_radius_bottom_right = 10
		normal_style.content_margin_left = 8.0
		normal_style.content_margin_right = 8.0
		normal_style.content_margin_top = 8.0
		normal_style.content_margin_bottom = 0.0
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("pressed", normal_style)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = NAV_HOVER_BG
		hover_style.corner_radius_top_left = 10
		hover_style.corner_radius_top_right = 10
		hover_style.corner_radius_bottom_left = 10
		hover_style.corner_radius_bottom_right = 10
		hover_style.content_margin_left = 8.0
		hover_style.content_margin_right = 8.0
		hover_style.content_margin_top = 8.0
		hover_style.content_margin_bottom = 0.0
		btn.add_theme_stylebox_override("hover", hover_style)

		var active_style := StyleBoxFlat.new()
		active_style.bg_color = NAV_ACTIVE_BG
		active_style.corner_radius_top_left = 10
		active_style.corner_radius_top_right = 10
		active_style.corner_radius_bottom_left = 10
		active_style.corner_radius_bottom_right = 10
		active_style.content_margin_left = 8.0
		active_style.content_margin_right = 8.0
		active_style.content_margin_top = 8.0
		active_style.content_margin_bottom = 0.0
		active_style.border_width_left = 1
		active_style.border_width_top = 1
		active_style.border_width_right = 1
		active_style.border_width_bottom = 1
		active_style.border_color = NAV_ACTIVE_BORDER
		# We no longer apply active_style to "disabled" because we want the active tab to remain clickable when on a subscreen.
		# Styles are swapped dynamically in _update_nav_highlight().

		# -----------------------------
		# Content layer
		# -----------------------------
		var content_center := CenterContainer.new()
		content_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(content_center)

		var content_vbox := VBoxContainer.new()
		content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		content_vbox.set("theme_override_constants/separation", 2)
		content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content_center.add_child(content_vbox)

		# -----------------------------
		# Icon stack
		# -----------------------------
		var icon_stack := Control.new()
		icon_stack.custom_minimum_size = Vector2(58, 44)
		icon_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content_vbox.add_child(icon_stack)

		var icon_glow := Label.new()
		icon_glow.text = icon_char
		icon_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_glow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_glow.add_theme_font_override("font", icon_font)
		icon_glow.add_theme_font_size_override("font_size", UIFonts.SIZE_ICON_GLOW)
		var icon_glow_start: Color = NAV_ICON_GLOW
		icon_glow_start.a = 0.0
		icon_glow.add_theme_color_override("font_color", icon_glow_start)
		icon_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_glow.offset_top = 1
		icon_glow.offset_bottom = 1
		icon_stack.add_child(icon_glow)

		var icon_label := Label.new()
		icon_label.text = icon_char
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_override("font", icon_font)
		icon_label.add_theme_font_size_override("font_size", UIFonts.SIZE_ICON)
		icon_label.add_theme_color_override("font_color", NAV_ICON_INACTIVE)
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_stack.add_child(icon_label)

		# -----------------------------
		# Label stack
		# -----------------------------
		var text_stack := Control.new()
		text_stack.custom_minimum_size = Vector2(76, 18)
		text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content_vbox.add_child(text_stack)

		var text_glow := Label.new()
		text_glow.text = label_text
		text_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_glow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text_glow.add_theme_font_size_override("font_size", UIFonts.SIZE_NAV_LABEL_GLOW)
		var label_glow_start: Color = NAV_LABEL_GLOW
		label_glow_start.a = 0.0
		text_glow.add_theme_color_override("font_color", label_glow_start)
		text_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		text_glow.offset_top = 1
		text_glow.offset_bottom = 1
		text_stack.add_child(text_glow)

		var text_label := Label.new()
		text_label.text = label_text
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text_label.add_theme_font_size_override("font_size", UIFonts.SIZE_CALLOUT)
		text_label.add_theme_color_override("font_color", NAV_LABEL_INACTIVE)
		text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		text_stack.add_child(text_label)

		# -----------------------------
		# Underline layer
		# -----------------------------
		var underline_holder := Control.new()
		underline_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		underline_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.add_child(underline_holder)

		var underline_glow := Panel.new()
		underline_glow.visible = false
		underline_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		underline_glow.custom_minimum_size = Vector2(60, 4)

		var glow_style := StyleBoxFlat.new()
		glow_style.bg_color = NAV_UNDERLINE_GLOW
		glow_style.corner_radius_top_left = 1
		glow_style.corner_radius_top_right = 1
		glow_style.corner_radius_bottom_left = 0
		glow_style.corner_radius_bottom_right = 0
		underline_glow.add_theme_stylebox_override("panel", glow_style)
		underline_holder.add_child(underline_glow)

		var underline_panel := Panel.new()
		underline_panel.visible = false
		underline_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		underline_panel.custom_minimum_size = Vector2(56, 2)

		var underline_style := StyleBoxFlat.new()
		underline_style.bg_color = NAV_UNDERLINE_COLOR
		underline_style.corner_radius_top_left = 1
		underline_style.corner_radius_top_right = 1
		underline_style.corner_radius_bottom_left = 1
		underline_style.corner_radius_bottom_right = 1
		underline_panel.add_theme_stylebox_override("panel", underline_style)
		underline_holder.add_child(underline_panel)

		btn.resized.connect(func() -> void:
			underline_glow.position = Vector2(
				(btn.size.x - underline_glow.custom_minimum_size.x) * 0.5,
				btn.size.y - underline_glow.custom_minimum_size.y + 4
			)

			underline_panel.position = Vector2(
				(btn.size.x - underline_panel.custom_minimum_size.x) * 0.5,
				btn.size.y - underline_panel.custom_minimum_size.y + 4
			)
		)
		btn.resized.emit()

		# -----------------------------
		# Signals
		# -----------------------------
		btn.pressed.connect(func() -> void:
			ScreenManager.navigate_to(screen_id)
		)

		btn.mouse_entered.connect(func() -> void:
			_on_nav_hover(screen_id, true)
		)

		btn.mouse_exited.connect(func() -> void:
			_on_nav_hover(screen_id, false)
		)

		center_zone.add_child(btn)

		# -----------------------------
		# Store refs
		# -----------------------------
		_nav_items[screen_id] = {
			"button": btn,
			"normal_style": normal_style,
			"hover_style": hover_style,
			"active_style": active_style,
			"icon": icon_label,
			"icon_glow": icon_glow,
			"icon_stack": icon_stack,
			"label": text_label,
			"label_glow": text_glow,
			"text_stack": text_stack,
			"underline": underline_panel,
			"underline_glow": underline_glow,
			"_icon_color": NAV_ICON_INACTIVE,
			"_label_color": NAV_LABEL_INACTIVE,
			"_hovered": false,
			"_tween": null,
		}

	if not _nav_items.is_empty():
		_refresh_nav_items()


## Handles nav item hover state.
func _on_nav_hover(screen_id: String, hovered: bool) -> void:
	if not _nav_items.has(screen_id):
		return

	var item: Dictionary = _nav_items[screen_id]
	var active_tab := _get_active_nav_tab(ScreenManager.current_screen)
	var is_active := (active_tab == screen_id)

	# Active item should not track hover state visually (glows, text bumps, etc.)
	item["_hovered"] = hovered and not is_active

	_apply_nav_item_state(screen_id, item["_hovered"], is_active)


## Applies full visual state to a nav item with tweened transitions.
func _apply_nav_item_state(screen_id: String, hovered: bool, active: bool) -> void:
	if not _nav_items.has(screen_id):
		return

	var item: Dictionary = _nav_items[screen_id]

	var icon_lbl: Label = item["icon"]
	var icon_glow: Label = item["icon_glow"]
	var icon_stack: Control = item["icon_stack"]
	var text_stack: Control = item["text_stack"]
	var text_lbl: Label = item["label"]
	var text_glow: Label = item["label_glow"]
	var underline: Control = item["underline"]
	var underline_glow: Control = item["underline_glow"]

	if item.get("_tween") is Tween and item["_tween"].is_valid():
		item["_tween"].kill()

	var target_icon_color := NAV_ICON_INACTIVE
	var target_label_color := NAV_LABEL_INACTIVE
	var target_icon_glow_alpha := 0.0
	var target_label_glow_alpha := 0.0
	var target_icon_scale := Vector2.ONE
	var target_text_scale := Vector2.ONE

	if active:
		target_icon_color = NAV_ICON_ACTIVE
		target_label_color = NAV_LABEL_ACTIVE
		target_icon_glow_alpha = 0.14
		target_label_glow_alpha = 0.08
		target_icon_scale = Vector2(1.025, 1.025)
		target_text_scale = Vector2(1.01, 1.01)
	elif hovered:
		target_icon_color = NAV_ICON_HOVER
		target_label_color = NAV_LABEL_HOVER
		target_icon_glow_alpha = 0.10
		target_label_glow_alpha = 0.04
		target_icon_scale = Vector2(1.01, 1.01)
		target_text_scale = Vector2(1.005, 1.005)

	underline.visible = active
	underline_glow.visible = active

	var from_icon: Color = item.get("_icon_color", NAV_ICON_INACTIVE)
	var from_label: Color = item.get("_label_color", NAV_LABEL_INACTIVE)
	var from_icon_glow: Color = icon_glow.get_theme_color("font_color")
	var from_label_glow: Color = text_glow.get_theme_color("font_color")

	var to_icon_glow := Color(
		NAV_ICON_GLOW.r,
		NAV_ICON_GLOW.g,
		NAV_ICON_GLOW.b,
		target_icon_glow_alpha
	)

	var to_label_glow := Color(
		NAV_LABEL_GLOW.r,
		NAV_LABEL_GLOW.g,
		NAV_LABEL_GLOW.b,
		target_label_glow_alpha
	)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)

	tw.tween_method(
		func(c: Color) -> void:
			icon_lbl.add_theme_color_override("font_color", c),
		from_icon,
		target_icon_color,
		0.18
	)

	tw.tween_method(
		func(c: Color) -> void:
			text_lbl.add_theme_color_override("font_color", c),
		from_label,
		target_label_color,
		0.18
	)

	tw.tween_method(
		func(c: Color) -> void:
			icon_glow.add_theme_color_override("font_color", c),
		from_icon_glow,
		to_icon_glow,
		0.18
	)

	tw.tween_method(
		func(c: Color) -> void:
			text_glow.add_theme_color_override("font_color", c),
		from_label_glow,
		to_label_glow,
		0.18
	)

	tw.tween_property(icon_stack, "scale", target_icon_scale, 0.18)
	tw.tween_property(text_stack, "scale", target_text_scale, 0.18)

	item["_icon_color"] = target_icon_color
	item["_label_color"] = target_label_color
	item["_tween"] = tw


## Maps sub-screens to their parent navigation tabs to keep the navbar highlighted.
func _get_active_nav_tab(screen_id: String) -> String:
	var tab_mapping: Dictionary = {
		"location_investigation": "location_map",
		"interrogation": "suspect_list",
		"theory_builder": "detective_board",
	}
	if tab_mapping.has(screen_id):
		return tab_mapping[screen_id]
	return screen_id


## Refreshes all nav item visual states.
func _refresh_nav_items() -> void:
	var active_tab: String = _get_active_nav_tab(ScreenManager.current_screen)
	for screen_id: String in _nav_items.keys():
		var item: Dictionary = _nav_items[screen_id]
		var hovered: bool = item.get("_hovered", false)
		var active: bool = (active_tab == screen_id)
		_apply_nav_item_state(screen_id, hovered, active)


## Builds a radial gradient background — lighter at the top-center, darker at edges/bottom.
## Center: #1A1C23, Edges: #0F1014
func _setup_background() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

void fragment() {
	// Slightly above center to emphasize top UI
	// vec2 center = vec2(0.5, 0.28);
	vec2 center = vec2(0.5, 0.32);

	// Mild aspect correction (prevents horizontal stretching)
	vec2 diff = (UV - center) * vec2(1.4, 1.0);
	float dist = length(diff);

	// Gradient falloff (compressed for stronger contrast)
	float t = clamp(dist / 0.65, 0.0, 1.0);

	// Sharper curve for better visual separation
	t = pow(t, 1.8);

	// Base colors (slightly exaggerated for visibility)
	vec3 center_color = vec3(0.13, 0.14, 0.18);
	vec3 edge_color   = vec3(0.04, 0.045, 0.055);

	vec3 color = mix(center_color, edge_color, t);

	// --- Subtle highlight boost ---
	// Creates a soft "light spot" around the center
	// float glow = 1.0 - smoothstep(0.0, 0.45, dist);
	// float glow = 1.0 - smoothstep(0.0, 0.6, dist);
	float glow = 1.0 - smoothstep(0.0, 0.8, dist);

	// Keep this LOW — it's easy to overdo
	color += glow * 0.035;

	COLOR = vec4(color, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_background.material = mat


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
	notification_button.add_theme_font_override("font", icon_font)
	notification_button.add_theme_font_size_override("font_size", UIFonts.SIZE_ICON_GLOW)
	notification_button.add_theme_color_override("font_color", UIColors.TEXT_PRIMARY)
	notification_button.add_theme_color_override("font_hover_color", UIColors.TEXT_HOVER)
	notification_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	notification_button.clip_contents = false

	# Badge label for unread count — circle/pill anchored to button's top-right
	var badge := Label.new()
	badge.name = "NotifBadge"
	badge.visible = false
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(16, 16)
	badge.add_theme_font_size_override("font_size", UIFonts.SIZE_CALLOUT)
	badge.add_theme_color_override("font_color", END_DAY_TEXT)
	var badge_box := StyleBoxFlat.new()
	badge_box.bg_color = BADGE_COLOR
	badge_box.corner_radius_top_left = 12
	badge_box.corner_radius_top_right = 12
	badge_box.corner_radius_bottom_left = 12
	badge_box.corner_radius_bottom_right = 12
	badge_box.content_margin_left = 10.0
	badge_box.content_margin_right = 10.0
	badge_box.content_margin_top = 4.0
	badge_box.content_margin_bottom = 4.0

	badge_box.border_width_left = 4
	badge_box.border_width_top = 4
	badge_box.border_width_right = 4
	badge_box.border_width_bottom = 4
	badge_box.border_color = Color(0.11, 0.11, 0.14, 0.97)

	badge.add_theme_stylebox_override("normal", badge_box)
	notification_button.add_child(badge)
	# Set anchors directly to avoid PRESET_MODE_KEEP_SIZE stretching the badge
	badge.anchor_left = 1.0
	badge.anchor_top = 0.0
	badge.anchor_right = 1.0
	badge.anchor_bottom = 0.0
	badge.offset_left = 0.0
	badge.offset_top = -4.0
	badge.offset_right = 4.0
	badge.offset_bottom = 0.0
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	badge.grow_vertical = Control.GROW_DIRECTION_END


## Styles the left zone labels with appropriate sizes and colors.
func _style_left_zone() -> void:
	day_label.add_theme_font_size_override("font_size", UIFonts.SIZE_SECTION)
	day_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)

	actions_label.add_theme_font_size_override("font_size", UIFonts.SIZE_TITLE)
	actions_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)

	phase_icon.add_theme_font_override("font", icon_font)
	phase_icon.add_theme_font_size_override("font_size", UIFonts.SIZE_ICON_GLOW)
	var phase_icon_color: Color = UIColors.AMBER
	phase_icon_color.a = 0.75
	phase_icon.add_theme_color_override("font_color", phase_icon_color)


## Updates all command bar labels with current state.
func _update_command_bar() -> void:
	day_label.text = "Day %d – %s" % [
		GameManager.current_day,
		GameManager.get_phase_display()
	]

	# Update phase icon
	if GameManager.is_daytime():
		phase_icon.text = "wb_sunny"
	else:
		phase_icon.text = "bedtime"

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


## Updates the notification button icon and badge count.
func _update_notification_button() -> void:
	notification_button.text = "notifications"
	var count: int = NotificationManager.get_unread_count()
	var badge: Label = notification_button.get_node_or_null("NotifBadge")
	if badge:
		badge.visible = count > 0
		if count > 0:
			badge.text = str(min(count, 99))


## Highlights the active nav button based on current screen.
func _update_nav_highlight() -> void:
	var current: String = ScreenManager.current_screen
	var active_tab: String = _get_active_nav_tab(current)

	for screen_id: String in _nav_items.keys():
		var item: Dictionary = _nav_items[screen_id]
		var is_active_tab: bool = (screen_id == active_tab)
		var is_exact_screen: bool = (screen_id == current)
		var btn: Button = item["button"]

		# Swap the normal and hover styles to simulate an active visual state without disabling input.
		if is_active_tab:
			btn.add_theme_stylebox_override("normal", item["active_style"])
			btn.add_theme_stylebox_override("hover", item["active_style"])
		else:
			btn.add_theme_stylebox_override("normal", item["normal_style"])
			btn.add_theme_stylebox_override("hover", item["hover_style"])

		# Never disable the button so that clicking an active tab works (e.g. to escape a sub-screen)
		btn.disabled = false
		btn.mouse_default_cursor_shape = Control.CURSOR_ARROW if is_exact_screen else Control.CURSOR_POINTING_HAND

		# Active item should never retain hover state, even if it's clickable
		if is_active_tab:
			item["_hovered"] = false


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
	_refresh_nav_items()


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
	toast.setup(notification)


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
