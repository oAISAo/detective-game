## WaitButton.gd
## Reusable cinematic lab-action button with amber split background.
## Supports three visual states:
##   - Normal: amber border, hover effects, clickable
##   - Submitted: amber accent, hourglass icon + "Pending", not clickable
##   - Disabled: dimmed amber border, not clickable
class_name WaitButton
extends PanelContainer


signal pressed

const MATERIAL_ICON_FONT_PATH: String = "res://assets/fonts/MaterialSymbolsOutlined.ttf"
const HOURGLASS_ICON_LIGATURE: String = "hourglass"
const READY_LABEL_TEXT: String = "1 Day"
const SUBMITTED_LABEL_TEXT: String = "Pending"
const CORNER_RADIUS: int = 10
const BORDER_WIDTH: int = 2
const SHADOW_SIZE: int = 6
const BASE_BG_ALPHA: float = 0.14
const NORMAL_GLOW_ALPHA: float = 0.26
const HOVER_GLOW_ALPHA: float = 0.42
const HOVER_BRIGHTNESS: Color = Color(1.03, 1.03, 1.03)
const CONTENT_PADDING_X: int = 12
const CONTENT_PADDING_Y: int = 10
const SIDE_SHADOW_EXPAND_MARGIN: float = 6.0
const RIGHT_SECTION_EXTRA_WIDTH: float = 24.0
const RIGHT_SECTION_MIN_WIDTH: float = 76.0
const DISABLED_BORDER_AMBER_LERP: float = 0.55
const DISABLED_GLOW_ALPHA: float = 0.08

static var _icon_font: FontVariation = null

var _action_text: String = "Photo Analysis"
var _is_disabled: bool = false
var _is_submitted: bool = false
var _is_hovered: bool = false
var _hover_tween: Tween

@export var action_text: String = "Photo Analysis":
	set(value):
		_action_text = value.strip_edges()
		if _action_text.is_empty():
			_action_text = "Analysis"
		_refresh_labels()
	get:
		return _action_text

@export var disabled: bool = false:
	set(value):
		_is_disabled = value
		if _is_disabled:
			_is_hovered = false
		_update_visual_state()
	get:
		return _is_disabled

@export var submitted: bool = false:
	set(value):
		_is_submitted = value
		if _is_submitted:
			_is_hovered = false
		_refresh_labels()
		_update_visual_state()
	get:
		return _is_submitted

@onready var _background: ActionButtonBackground = %Background
@onready var _content_margin: MarginContainer = %ContentMargin
@onready var _action_label: Label = %LabelActionText
@onready var _right_content: HBoxContainer = %HBoxRight
@onready var _hourglass_icon: Label = %HourglassIcon
@onready var _meta_label: Label = %LabelMeta


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_apply_content_margins()
	_configure_fonts()
	_configure_background_palette()
	_refresh_labels()
	_update_visual_state()
	resized.connect(_on_resized)
	call_deferred("_update_background_split_width")

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_mouse_entered)
	focus_exited.connect(_on_mouse_exited)


func _gui_input(event: InputEvent) -> void:
	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button == null:
		return
	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not mouse_button.pressed:
		return

	if _is_submitted:
		accept_event()
		return

	if _is_disabled:
		accept_event()
		return

	pressed.emit()
	accept_event()


func _on_mouse_entered() -> void:
	if _is_disabled or _is_submitted:
		return
	_is_hovered = true
	_update_visual_state()


func _on_mouse_exited() -> void:
	_is_hovered = false
	_update_visual_state()


func _refresh_labels() -> void:
	if _action_label == null or _meta_label == null or _hourglass_icon == null:
		return

	_action_label.text = _action_text
	_hourglass_icon.text = HOURGLASS_ICON_LIGATURE
	_meta_label.text = SUBMITTED_LABEL_TEXT if _is_submitted else READY_LABEL_TEXT

	_update_background_split_width()


func _update_visual_state() -> void:
	if _background == null or _action_label == null or _meta_label == null or _hourglass_icon == null:
		return

	var border_color: Color = UIColors.AMBER
	var glow_alpha: float = NORMAL_GLOW_ALPHA
	var action_text_color: Color = UIColors.TEXT_PRIMARY
	var meta_text_color: Color = UIColors.TEXT_SECONDARY
	var meta_icon_color: Color = UIColors.AMBER_SHADOW
	var target_modulate: Color = Color.WHITE

	if _is_submitted:
		border_color = UIColors.AMBER.lerp(UIColors.TEXT_GREY, 0.28)
		border_color.a = 0.75
		glow_alpha = 0.0
		action_text_color = UIColors.TEXT_SECONDARY
		meta_text_color = UIColors.AMBER.lerp(UIColors.TEXT_GREY, 0.50)
		meta_icon_color = UIColors.AMBER.lerp(UIColors.TEXT_GREY, 0.50)
	elif _is_disabled:
		border_color = UIColors.AMBER.lerp(UIColors.TEXT_GREY, DISABLED_BORDER_AMBER_LERP)
		border_color.a = 0.70
		glow_alpha = DISABLED_GLOW_ALPHA
		action_text_color = UIColors.TEXT_SECONDARY
		meta_text_color = UIColors.TEXT_GREY
		meta_icon_color = UIColors.TEXT_GREY
	else:
		if _is_hovered:
			border_color = UIColors.AMBER.lerp(UIColors.TEXT_HOVER, 0.18)
			glow_alpha = HOVER_GLOW_ALPHA
			action_text_color = UIColors.TEXT_HOVER
			meta_text_color = UIColors.TEXT_PRIMARY
			meta_icon_color = UIColors.AMBER
			target_modulate = HOVER_BRIGHTNESS

	add_theme_stylebox_override("panel", _build_panel_style(border_color, glow_alpha))

	_action_label.add_theme_color_override("font_color", action_text_color)
	_meta_label.add_theme_color_override("font_color", meta_text_color)
	_hourglass_icon.add_theme_color_override("font_color", meta_icon_color)

	var interactive: bool = not _is_disabled and not _is_submitted
	_background.set("hover_intensity", 1.0 if (_is_hovered and interactive) else 0.0)
	if _is_submitted:
		_background.set("color_mode", ActionButtonBackground.ColorMode.COMPLETED)
	elif _is_disabled:
		_background.set("color_mode", ActionButtonBackground.ColorMode.DISABLED)
	else:
		_background.set("color_mode", ActionButtonBackground.ColorMode.NORMAL)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
	_animate_modulate(target_modulate)


func _build_panel_style(border_color: Color, glow_alpha: float) -> StyleBoxFlat:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(UIColors.BG_BASE.r, UIColors.BG_BASE.g, UIColors.BG_BASE.b, BASE_BG_ALPHA)
	panel_style.set_border_width_all(BORDER_WIDTH)
	panel_style.border_color = border_color
	panel_style.set_corner_radius_all(CORNER_RADIUS)
	panel_style.content_margin_left = 0.0
	panel_style.content_margin_top = 0.0
	panel_style.content_margin_right = 0.0
	panel_style.content_margin_bottom = 0.0
	panel_style.expand_margin_left = SIDE_SHADOW_EXPAND_MARGIN
	panel_style.expand_margin_right = SIDE_SHADOW_EXPAND_MARGIN
	panel_style.expand_margin_top = SIDE_SHADOW_EXPAND_MARGIN
	panel_style.expand_margin_bottom = SIDE_SHADOW_EXPAND_MARGIN

	if glow_alpha > 0.0:
		var glow_color: Color = UIColors.AMBER_SHADOW
		glow_color.a = glow_alpha
		panel_style.shadow_color = glow_color
		panel_style.shadow_size = SHADOW_SIZE

	return panel_style


func _animate_modulate(target_modulate: Color) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "modulate", target_modulate, 0.10).set_ease(Tween.EASE_OUT)


func _configure_fonts() -> void:
	_action_label.theme_type_variation = &"ActionButtonLabel"
	_meta_label.theme_type_variation = &"ActionButtonMeta"

	var icon_font: FontVariation = _get_icon_font()
	if icon_font != null:
		_hourglass_icon.add_theme_font_override("font", icon_font)
		_hourglass_icon.add_theme_font_size_override("font_size", UIFonts.SIZE_ICON_BUTTON)


func _configure_background_palette() -> void:
	if _background == null:
		return

	_background.set("normal_accent_color", UIColors.AMBER)
	_background.set("completed_accent_color", UIColors.AMBER.lerp(UIColors.TEXT_GREY, 0.18))
	_background.set("disabled_accent_color", UIColors.AMBER.lerp(UIColors.TEXT_GREY, 0.42))


func _on_resized() -> void:
	_update_background_split_width()


func _apply_content_margins() -> void:
	if _content_margin == null:
		return

	_content_margin.add_theme_constant_override("margin_left", CONTENT_PADDING_X)
	_content_margin.add_theme_constant_override("margin_top", CONTENT_PADDING_Y)
	_content_margin.add_theme_constant_override("margin_right", CONTENT_PADDING_X)
	_content_margin.add_theme_constant_override("margin_bottom", CONTENT_PADDING_Y)


func _update_background_split_width() -> void:
	if _background == null or _right_content == null:
		return

	var right_width: float = _right_content.get_combined_minimum_size().x + RIGHT_SECTION_EXTRA_WIDTH
	_background.set("right_section_width", maxf(RIGHT_SECTION_MIN_WIDTH, right_width))


func _get_icon_font() -> FontVariation:
	if _icon_font != null:
		return _icon_font

	var base_font: FontFile = load(MATERIAL_ICON_FONT_PATH) as FontFile
	if base_font == null:
		push_error("[WaitButton] Failed to load icon font: %s" % MATERIAL_ICON_FONT_PATH)
		return null

	_icon_font = FontVariation.new()
	_icon_font.base_font = base_font
	_icon_font.opentype_features = {"liga": 1, "calt": 1}
	return _icon_font