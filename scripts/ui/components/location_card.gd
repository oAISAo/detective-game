## LocationCard.gd
## Cinematic photo-card for investigation locations.
## Image with status overlay, title/description footer, evidence count, and visit button.
class_name LocationCard
extends PanelContainer


signal card_pressed(location_id: String)

var _location_id: String = ""
var _is_hovered: bool = false
var _base_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _hover_tween: Tween

# New 3-state status system
const STATUS_NEW := "New"
const STATUS_OPEN := "Open"
const STATUS_EXHAUSTED := "Exhausted"

const STATUS_COLORS: Dictionary = {
	STATUS_NEW: Color(0.55, 0.65, 0.8),
	STATUS_OPEN: UIColors.ACCENT_CLUE,
	STATUS_EXHAUSTED: UIColors.TEXT_MUTED,
}

# Card design constants
const CARD_CORNER_RADIUS: int = 14
const CARD_BORDER_COLOR := Color(0.40, 0.40, 0.43, 1.0)
const CARD_BG := Color(0.10, 0.10, 0.13)
const FOOTER_COLOR := Color(0.11, 0.11, 0.14)
const FOOTER_PADDING_H: int = 18
const FOOTER_PADDING_V: int = 14
const GRADIENT_COLOR := Color(0.06, 0.06, 0.08)
const IMAGE_PADDING: int = 16
const CARD_SHADOW_SIZE: int = 6
const CARD_SHADOW_OFFSET := Vector2(0, 4)
const CARD_SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.55)

# Hover constants
const HOVER_SHADOW_SIZE: int = 10
const HOVER_SHADOW_OFFSET := Vector2(0, 4)
const HOVER_SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.55)
const HOVER_BORDER_COLOR := Color(0.9, 0.75, 0.3, 0.35)

@onready var _image_rect: TextureRect = %ImageRect
@onready var _image_placeholder: PanelContainer = %ImagePlaceholder
@onready var _placeholder_initial: Label = %PlaceholderInitial
@onready var _name_label: Label = %NameLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _evidence_label: Label = %EvidenceLabel
@onready var _status_badge: PanelContainer = %StatusBadge
@onready var _status_label: Label = %StatusLabel
@onready var _inspect_button: Button = %InspectButton
@onready var _gradient_overlay: ColorRect = %GradientOverlay
@onready var _footer: VBoxContainer = %Footer


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_apply_card_style()
	_apply_gradient_overlay()
	_apply_footer_style()
	_apply_inspect_button_style()
	_apply_placeholder_style()

	_inspect_button.pressed.connect(_on_pressed)
	_inspect_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Populates the card with location data. Call after adding to the scene tree.
func setup(location: LocationData) -> void:
	_location_id = location.id

	# Title — strongest text, near-white
	_name_label.text = location.name
	_name_label.uppercase = true
	_name_label.add_theme_font_size_override("font_size", 19)
	_name_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90))

	# Image or placeholder
	if not location.image.is_empty() and ResourceLoader.exists(location.image):
		_image_rect.texture = load(location.image)
		_image_rect.visible = true
		_image_placeholder.visible = false
	else:
		_image_rect.visible = false
		_image_placeholder.visible = true
		_placeholder_initial.text = location.name.to_upper()
		_placeholder_initial.autowrap_mode = TextServer.AUTOWRAP_WORD
		_placeholder_initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_placeholder_initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Description — neutral gray, not warm amber
	_description_label.text = _get_short_description(location)
	_description_label.add_theme_color_override("font_color", Color(0.72, 0.70, 0.68))
	_description_label.add_theme_font_size_override("font_size", 13)

	# Evidence count
	var visited: bool = GameManager.has_visited_location(location.id)
	if visited:
		var completion: Dictionary = LocationInvestigationManager.get_location_completion(location.id)
		_evidence_label.text = "Evidence: %d / %d" % [completion["found"], completion["total"]]
		var found_color: Color = Color(0.72, 0.70, 0.68)
		if completion["found"] > 0:
			found_color = UIColors.ACCENT_CLUE
		_evidence_label.add_theme_color_override("font_color", found_color)
	else:
		_evidence_label.text = "Evidence: 0 / ?"
		_evidence_label.add_theme_color_override("font_color", Color(0.55, 0.53, 0.51))
	_evidence_label.add_theme_font_size_override("font_size", 13)

	# Status badge (overlaid on image, top-right)
	var status: String = _resolve_status(location.id)
	_status_label.text = status.to_upper()
	_status_label.add_theme_font_size_override("font_size", 12)
	var status_color: Color = STATUS_COLORS.get(status, UIColors.TEXT_MUTED)
	_status_label.add_theme_color_override("font_color", status_color)
	_apply_badge_style(status_color)


func get_location_id() -> String:
	return _location_id


## Maps the old 4-status system to the new 3-status system.
static func _resolve_status(location_id: String) -> String:
	var old_status: String = LocationInvestigationManager.get_location_status(location_id)
	match old_status:
		"Not Visited":
			return STATUS_NEW
		"Active Leads", "Lab Pending":
			return STATUS_OPEN
		"Scene Processed":
			return STATUS_EXHAUSTED
		_:
			return STATUS_NEW


# --- Styling ---

func _apply_card_style() -> void:
	# Base style: no shadow (shadow only on hover)
	_base_style = StyleBoxFlat.new()
	_base_style.bg_color = CARD_BG
	_base_style.border_color = CARD_BORDER_COLOR
	_base_style.set_border_width_all(2)
	_base_style.corner_radius_top_left = CARD_CORNER_RADIUS
	_base_style.corner_radius_top_right = CARD_CORNER_RADIUS
	_base_style.corner_radius_bottom_left = CARD_CORNER_RADIUS
	_base_style.corner_radius_bottom_right = CARD_CORNER_RADIUS
	_base_style.shadow_size = 0
	_base_style.content_margin_left = 20
	_base_style.content_margin_right = 20
	_base_style.content_margin_top = 20
	_base_style.content_margin_bottom = 20
	_base_style.shadow_color = CARD_SHADOW_COLOR
	_base_style.shadow_size = CARD_SHADOW_SIZE
	_base_style.shadow_offset = CARD_SHADOW_OFFSET
	add_theme_stylebox_override("panel", _base_style)

	# Pre-build hover style
	_hover_style = _base_style.duplicate()
	_hover_style.border_color = HOVER_BORDER_COLOR
	_hover_style.set_border_width_all(2)
	_hover_style.shadow_color = HOVER_SHADOW_COLOR
	_hover_style.shadow_size = HOVER_SHADOW_SIZE
	_hover_style.shadow_offset = HOVER_SHADOW_OFFSET


func _apply_gradient_overlay() -> void:
	_gradient_overlay.color = Color.TRANSPARENT
	_gradient_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_setup_gradient_texture")


func _setup_gradient_texture() -> void:
	var parent: Control = _gradient_overlay.get_parent()
	var idx: int = _gradient_overlay.get_index()
	_gradient_overlay.queue_free()

	var gradient_rect := TextureRect.new()
	# Use anchor mode (layout_mode = 1) to fill the Control parent
	gradient_rect.layout_mode = 1
	gradient_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	gradient_rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	gradient_rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	gradient_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gradient_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gradient_rect.stretch_mode = TextureRect.STRETCH_SCALE

	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0))
	gradient.set_color(1, Color(GRADIENT_COLOR.r, GRADIENT_COLOR.g, GRADIENT_COLOR.b, 0.9))
	gradient.set_offset(0, 0.35)
	gradient.set_offset(1, 1.0)

	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 4
	tex.height = 256

	gradient_rect.texture = tex
	parent.add_child(gradient_rect)
	parent.move_child(gradient_rect, idx)


func _apply_footer_style() -> void:
	_footer.add_theme_constant_override("separation", 6)

	var vbox := _footer.get_parent()
	var footer_idx := _footer.get_index()

	var footer_panel := PanelContainer.new()
	var footer_style := StyleBoxFlat.new()
	# footer_style.bg_color = Color(0.07, 0.07, 0.09, 1.0)
	footer_style.bg_color = Color(0.07, 0.07, 0.09, 0.6)
	# footer_style.bg_color = Color.TRANSPARENT
	footer_style.corner_radius_bottom_left = CARD_CORNER_RADIUS
	footer_style.corner_radius_bottom_right = CARD_CORNER_RADIUS
	footer_style.content_margin_left = FOOTER_PADDING_H
	footer_style.content_margin_right = FOOTER_PADDING_H
	footer_style.content_margin_top = FOOTER_PADDING_V
	footer_style.content_margin_bottom = FOOTER_PADDING_V
	footer_panel.clip_contents = true
	footer_panel.add_theme_stylebox_override("panel", footer_style)
	footer_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	_footer.get_parent().add_child(footer_panel)
	_footer.get_parent().move_child(footer_panel, footer_idx)
	_footer.reparent(footer_panel)
	_footer.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _apply_inspect_button_style() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.76, 0.74, 0.70)
	normal.border_color = Color(0.60, 0.58, 0.54, 0.4)
	normal.set_border_width_all(0)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	_inspect_button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.85, 0.83, 0.78)
	_inspect_button.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.65, 0.63, 0.60)
	_inspect_button.add_theme_stylebox_override("pressed", pressed)

	_inspect_button.add_theme_color_override("font_color", Color(0.12, 0.11, 0.10))
	_inspect_button.add_theme_color_override("font_hover_color", Color(0.08, 0.07, 0.06))
	_inspect_button.add_theme_color_override("font_pressed_color", Color(0.20, 0.18, 0.16))
	_inspect_button.add_theme_font_size_override("font_size", 14)


func _apply_placeholder_style() -> void:
	var ph_style := StyleBoxFlat.new()
	ph_style.bg_color = Color(0.10, 0.12, 0.18)
	ph_style.set_corner_radius_all(8)
	ph_style.content_margin_left = 32
	ph_style.content_margin_right = 32
	ph_style.content_margin_top = 32
	ph_style.content_margin_bottom = 32
	_image_placeholder.add_theme_stylebox_override("panel", ph_style)
	_placeholder_initial.add_theme_font_size_override("font_size", 32)
	_placeholder_initial.add_theme_color_override("font_color", Color(0.88, 0.86, 0.82))


func _apply_badge_style(status_color: Color) -> void:
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	badge_style.border_color = Color(status_color.r, status_color.g, status_color.b, 0.4)
	badge_style.set_border_width_all(1)
	badge_style.corner_radius_top_left = 4
	badge_style.corner_radius_top_right = 4
	badge_style.corner_radius_bottom_left = 4
	badge_style.corner_radius_bottom_right = 4
	badge_style.content_margin_left = 12
	badge_style.content_margin_right = 12
	badge_style.content_margin_top = 6
	badge_style.content_margin_bottom = 6
	_status_badge.add_theme_stylebox_override("panel", badge_style)


# --- Hover / Focus States ---

func _on_mouse_entered() -> void:
	_is_hovered = true
	_animate_hover(true)


func _on_mouse_exited() -> void:
	_is_hovered = false
	_animate_hover(false)


func _animate_hover(hovered: bool) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	if hovered:
		add_theme_stylebox_override("panel", _hover_style)
		_hover_tween.tween_property(self, "scale", Vector2(1.015, 1.015), 0.15)
		_hover_tween.parallel().tween_property(self, "modulate", Color(1.06, 1.06, 1.06), 0.15)
	else:
		add_theme_stylebox_override("panel", _base_style)
		_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
		_hover_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.2)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_on_pressed()


# --- Helpers ---

static func _get_short_description(loc: LocationData) -> String:
	if loc.description.is_empty():
		return ""
	var dot_idx: int = loc.description.find(".")
	if dot_idx >= 0 and dot_idx < 120:
		return loc.description.substr(0, dot_idx + 1)
	if loc.description.length() > 120:
		return loc.description.substr(0, 117) + "..."
	return loc.description


func _on_pressed() -> void:
	card_pressed.emit(_location_id)
