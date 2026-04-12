## UIHelper.gd
## Shared UI utility methods used across multiple screens.
## Eliminates duplication of common label/formatting/signal helpers.
## Phase D3: Adds ConfirmationFlash and SelectionPulse animation helpers.
class_name UIHelper

const _MAIN_THEME_PATH: String = "res://resources/themes/main_theme.tres"
const _MATERIAL_ICON_FONT_PATH: String = "res://assets/fonts/MaterialSymbolsOutlined.ttf"
const _BACK_ICON_LIGATURE: String = "arrow_back_ios"
const _BACK_CONTENT_NODE_NAME: String = "BackButtonContent"
const _BACK_CONTENT_MIN_WIDTH: float = 100.0
const _BACK_CONTENT_MIN_HEIGHT: float = 44.0
const _BACK_MIN_MARGIN_X: int = 24
const _BACK_MIN_MARGIN_Y: int = 10
const _BACK_CONTENT_SEPARATION: int = 6

static var _back_icon_font: FontVariation = null
static var _main_theme: Theme = null


## Returns a human-readable label for an evidence type.
static func get_evidence_type_label(type: Enums.EvidenceType) -> String:
	match type:
		Enums.EvidenceType.FORENSIC: return "Forensic"
		Enums.EvidenceType.DOCUMENT: return "Document"
		Enums.EvidenceType.PHOTO: return "Photo"
		Enums.EvidenceType.RECORDING: return "Recording"
		Enums.EvidenceType.FINANCIAL: return "Financial"
		Enums.EvidenceType.DIGITAL: return "Digital"
		Enums.EvidenceType.OBJECT: return "Object"
	return "Unknown"


## Returns the display name for a location, or the raw ID if not found.
static func get_location_name(location_id: String) -> String:
	if location_id.is_empty():
		return "Unknown"
	var loc: LocationData = CaseManager.get_location(location_id)
	return loc.name if loc else location_id


## Returns a human-readable label for a legal category.
static func get_legal_category_label(cat: int) -> String:
	match cat:
		Enums.LegalCategory.PRESENCE: return "Presence"
		Enums.LegalCategory.MOTIVE: return "Motive"
		Enums.LegalCategory.OPPORTUNITY: return "Opportunity"
		Enums.LegalCategory.CONNECTION: return "Connection"
	return "Unknown"


## Safely disconnects a signal callback if it is currently connected.
static func safe_disconnect(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)


## Creates and adds a styled section header label to a parent container.
## Uses the SectionHeader theme type variation and uppercases the text.
static func add_section_header(text: String, parent: Control) -> void:
	var label := Label.new()
	label.text = text.to_upper()
	label.theme_type_variation = &"SectionHeader"
	parent.add_child(label)


## Shows a brief inline confirmation flash on a parent control.
## The label scales slightly, then fades out over 0.6s.
## Use after evidence submission, theory filing, lab queuing, etc.
static func confirmation_flash(text: String, parent: Control, color: Color = UIColors.GREEN) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", UIFonts.SIZE_BODY)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)

	# Scale up slightly, then fade out
	label.pivot_offset = label.size / 2.0
	var tween: Tween = parent.create_tween()
	tween.tween_property(label, "scale", Vector2(1.05, 1.05), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.tween_callback(label.queue_free)


## Shows a "SUBMITTED" stamp overlay on a control element.
## Used for lab queue submissions to give a "case file stamped" feel.
static func stamp_flash(parent: Control) -> void:
	var stamp := Label.new()
	stamp.text = "SUBMITTED"
	stamp.add_theme_color_override("font_color", UIColors.GREEN)
	stamp.add_theme_font_size_override("font_size", UIFonts.SIZE_STAMP)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp.modulate.a = 0.0

	# Fill the entire parent so text alignment centers properly
	stamp.set_anchors_preset(Control.PRESET_FULL_RECT)
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(stamp)

	# Slam in with scale, then fade out
	stamp.scale = Vector2(1.4, 1.4)
	stamp.pivot_offset = parent.size / 2.0
	var tween: Tween = parent.create_tween()
	tween.tween_property(stamp, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(stamp, "scale", Vector2(1.0, 1.0), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(0.4)
	tween.tween_property(stamp, "modulate:a", 0.0, 0.35)
	tween.tween_callback(stamp.queue_free)


## Briefly pulses a control's modulate to highlight selection.
## Flashes the accent color alpha, then returns to normal.
static func selection_pulse(control: Control) -> void:
	var tween: Tween = control.create_tween()
	tween.tween_property(control, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)


## Applies the shared ListButton variation and selection contract.
## Normal state uses a single bottom border; selected uses full border.
static func apply_list_button_style(
	button: Button,
	is_selected: bool = false,
	horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER
) -> void:
	if button == null:
		return

	button.theme_type_variation = &"ListButton"
	button.toggle_mode = true
	button.button_pressed = is_selected
	button.alignment = horizontal_alignment


## Updates selection state for a ListButton without changing other properties.
static func set_list_button_selected(button: Button, is_selected: bool) -> void:
	if button == null:
		return

	button.toggle_mode = true
	button.button_pressed = is_selected


## Applies a shared icon + text treatment for back buttons while keeping
## the default button style, dimensions, and theme spacing.
static func apply_back_button_icon(button: Button, label_text: String = "Back") -> void:
	if button == null:
		return
	_apply_end_day_button_theme(button)

	var old_content: Node = button.get_node_or_null(_BACK_CONTENT_NODE_NAME)
	if old_content:
		button.remove_child(old_content)
		old_content.free()

	button.text = ""
	button.clip_contents = true

	var margin_left: int = _BACK_MIN_MARGIN_X
	var margin_top: int = _BACK_MIN_MARGIN_Y
	var margin_right: int = _BACK_MIN_MARGIN_X
	var margin_bottom: int = _BACK_MIN_MARGIN_Y
	var normal_style: StyleBox = button.get_theme_stylebox("normal")
	if normal_style != null:
		margin_left = maxi(_BACK_MIN_MARGIN_X, int(normal_style.get_content_margin(SIDE_LEFT)))
		margin_top = maxi(_BACK_MIN_MARGIN_Y, int(normal_style.get_content_margin(SIDE_TOP)))
		margin_right = maxi(_BACK_MIN_MARGIN_X, int(normal_style.get_content_margin(SIDE_RIGHT)))
		margin_bottom = maxi(_BACK_MIN_MARGIN_Y, int(normal_style.get_content_margin(SIDE_BOTTOM)))

	var margin: MarginContainer = MarginContainer.new()
	margin.name = _BACK_CONTENT_NODE_NAME
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", margin_left)
	margin.add_theme_constant_override("margin_top", margin_top)
	margin.add_theme_constant_override("margin_right", margin_right)
	margin.add_theme_constant_override("margin_bottom", margin_bottom)
	button.add_child(margin)

	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", _BACK_CONTENT_SEPARATION)
	margin.add_child(row)

	var icon_label: Label = Label.new()
	icon_label.text = _BACK_ICON_LIGATURE
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_material_icon_font(icon_label)
	row.add_child(icon_label)

	var text_label: Label = Label.new()
	text_label.text = label_text
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var button_font: Font = button.get_theme_font("font")
	if button_font != null:
		text_label.add_theme_font_override("font", button_font)

	var button_font_size: int = button.get_theme_font_size("font_size")
	if button_font_size > 0:
		text_label.add_theme_font_size_override("font_size", button_font_size)
		icon_label.add_theme_font_size_override("font_size", button_font_size)
	else:
		button_font_size = UIFonts.SIZE_SECTION
		text_label.add_theme_font_size_override("font_size", button_font_size)
		icon_label.add_theme_font_size_override("font_size", button_font_size)

	var button_font_color: Color = button.get_theme_color("font_color")
	text_label.add_theme_color_override("font_color", button_font_color)
	icon_label.add_theme_color_override("font_color", button_font_color)
	row.add_child(text_label)

	var text_width: float = _measure_text_width(button_font, label_text, button_font_size)
	var icon_width: float = _measure_text_width(_back_icon_font, _BACK_ICON_LIGATURE, button_font_size)
	var desired_min_width: float = margin_left + icon_width + _BACK_CONTENT_SEPARATION + text_width + margin_right
	button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, maxf(_BACK_CONTENT_MIN_WIDTH, desired_min_width))
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, _BACK_CONTENT_MIN_HEIGHT)


static func _apply_end_day_button_theme(button: Button) -> void:
	var theme: Theme = _get_main_theme()
	if theme == null:
		return

	_copy_theme_stylebox(button, theme, "normal")
	_copy_theme_stylebox(button, theme, "hover")
	_copy_theme_stylebox(button, theme, "pressed")
	_copy_theme_stylebox(button, theme, "disabled")
	_copy_theme_stylebox(button, theme, "focus")

	button.add_theme_font_override("font", theme.get_font("font", "Button"))
	button.add_theme_font_size_override("font_size", theme.get_font_size("font_size", "Button"))
	button.add_theme_color_override("font_color", theme.get_color("font_color", "Button"))
	button.add_theme_color_override("font_hover_color", theme.get_color("font_hover_color", "Button"))
	button.add_theme_color_override("font_pressed_color", theme.get_color("font_pressed_color", "Button"))
	button.add_theme_color_override("font_disabled_color", theme.get_color("font_disabled_color", "Button"))


static func _copy_theme_stylebox(button: Button, theme: Theme, style_name: StringName) -> void:
	var style: StyleBox = theme.get_stylebox(style_name, "Button")
	if style == null:
		return
	button.add_theme_stylebox_override(style_name, style.duplicate(true))


static func _get_main_theme() -> Theme:
	if _main_theme != null:
		return _main_theme

	_main_theme = load(_MAIN_THEME_PATH) as Theme
	if _main_theme == null:
		push_error("[UIHelper] Failed to load theme resource: %s" % _MAIN_THEME_PATH)
	return _main_theme


static func _measure_text_width(font: Font, text: String, font_size: int) -> float:
	if font == null:
		return 0.0
	if text.is_empty():
		return 0.0
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


static func _apply_material_icon_font(icon_label: Label) -> void:
	if _back_icon_font == null:
		var base_font: FontFile = load(_MATERIAL_ICON_FONT_PATH) as FontFile
		if base_font == null:
			push_error("[UIHelper] Failed to load icon font: %s" % _MATERIAL_ICON_FONT_PATH)
			return

		_back_icon_font = FontVariation.new()
		_back_icon_font.base_font = base_font
		_back_icon_font.opentype_features = {"liga": 1, "calt": 1}

	icon_label.add_theme_font_override("font", _back_icon_font)


## Applies the SurfacePanel theme type variation to a PanelContainer.
## Use this on programmatically created PanelContainers that sit inside
## a screen (which already uses BG_PANEL), so they get the lighter
## BG_SURFACE background and subtler border defined in main_theme.tres.
static func apply_surface_style(panel: PanelContainer) -> void:
	panel.theme_type_variation = &"SurfacePanel"
