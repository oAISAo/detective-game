## LocationCard.gd
## Cinematic photo-card for investigation locations.
## Image with status overlay, title/description footer, evidence count, and visit button.
class_name LocationCard
extends Panel


signal card_pressed(location_id: String)

var _location_id: String = ""
var _is_hovered: bool = false
var _base_style: StyleBoxFlat
var _hover_style: StyleBoxFlat
var _hover_tween: Tween
var _image_mask_material: ShaderMaterial

# New 3-state status system
const STATUS_NEW := "New"
const STATUS_OPEN := "Open"
const STATUS_EXHAUSTED := "Exhausted"

const STATUS_COLORS: Dictionary = {
	STATUS_NEW: UIColors.ACCENT_EXAMINED,
	STATUS_OPEN: UIColors.ACCENT_CLUE,
	STATUS_EXHAUSTED: UIColors.TEXT_MUTED,
}

# Card design constants
const CARD_CORNER_RADIUS: int = 14
const CARD_BORDER_WIDTH: int = 2
const CARD_BORDER_COLOR: Color = UIColors.LOCATION_CARD_BORDER
const CARD_BG: Color = UIColors.LOCATION_CARD_BG
const MEDIA_CORNER_RADIUS: int = 14
const CARD_SHADOW_SIZE: int = 8
const CARD_SHADOW_COLOR: Color = UIColors.LOCATION_CARD_SHADOW

# Hover constants
const HOVER_SHADOW_SIZE: int = 8
const HOVER_SHADOW_COLOR: Color = UIColors.LOCATION_CARD_HOVER_SHADOW
const HOVER_BORDER_COLOR: Color = UIColors.LOCATION_CARD_HOVER_BORDER
const HOVER_SCALE := Vector2(1.008, 1.008)
const HOVER_MODULATE: Color = UIColors.LOCATION_CARD_HOVER_MODULATE

const TEXT_COLOR_PRIMARY: Color = UIColors.TEXT_PRIMARY
const TEXT_COLOR_MUTED: Color = UIColors.TEXT_MUTED
const FONT_SIZE_TITLE: int = UIFonts.SIZE_TITLE
const FONT_SIZE_BODY: int = UIFonts.SIZE_BODY
const FONT_SIZE_META: int = UIFonts.SIZE_METADATA
const MEDIA_MASK_SHADER: Shader = preload("res://assets/shaders/rounded_media_mask.gdshader")

@onready var _media_frame: PanelContainer = %MediaFrame
@onready var _image_rect: TextureRect = %ImageRect
@onready var _image_placeholder: PanelContainer = %ImagePlaceholder
@onready var _placeholder_initial: Label = %PlaceholderInitial
@onready var _image_area: Control = $"VBox/ImageArea"
@onready var _overlay_margin: MarginContainer = $"VBox/ImageArea/MediaFrame/OverlayMargin"
@onready var _badge_row: HBoxContainer = $"VBox/ImageArea/MediaFrame/OverlayMargin/BadgeRow"
@onready var _name_label: Label = %NameLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _evidence_prefix_label: Label = %EvidencePrefixLabel
@onready var _evidence_label: Label = %EvidenceLabel
@onready var _status_badge: PanelContainer = %StatusBadge
@onready var _status_label: Label = %StatusLabel
@onready var _inspect_button: Button = %InspectButton
@onready var _footer: VBoxContainer = %Footer


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_PASS

	_apply_card_style()
	_apply_media_frame_style()
	_apply_image_mask()
	_apply_footer_style()
	_apply_inspect_button_style()
	_apply_placeholder_style()

	# Canonical activation path: inspect button press only.
	_inspect_button.pressed.connect(_on_pressed)
	_inspect_button.focus_mode = Control.FOCUS_ALL
	_inspect_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_configure_hover_event_routing()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Keep the rounded image mask in sync with the visible media frame.
	_media_frame.resized.connect(_update_media_mask_size)
	_image_rect.resized.connect(_update_media_mask_size)
	call_deferred("_update_media_mask_size")


## Ensures all interactive regions participate in one card-level hover state.
func _configure_hover_event_routing() -> void:
	# Non-interactive visual controls should not consume hover hit-testing.
	_image_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_media_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placeholder_initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# The inspect button is interactive, so bridge its hover lifecycle to the card.
	_inspect_button.mouse_entered.connect(_on_hover_source_entered)
	_inspect_button.mouse_exited.connect(_on_hover_source_exited)


## Populates the card with location data. Call after adding to the scene tree.
func setup(location: LocationData) -> void:
	if location == null:
		_apply_invalid_setup_state("null location data")
		return

	var normalized_location_id: String = location.id.strip_edges()
	if normalized_location_id.is_empty():
		_apply_invalid_setup_state("missing location id")
		return

	_location_id = normalized_location_id
	_inspect_button.disabled = false

	var display_name: String = location.name.strip_edges()
	if display_name.is_empty():
		display_name = _location_id

	# Title — strongest text, near-white
	_name_label.text = display_name
	_name_label.uppercase = true
	_name_label.theme_type_variation = &"SectionHeader"
	_name_label.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	_name_label.add_theme_color_override("font_color", TEXT_COLOR_PRIMARY)

	_set_location_image(location.image, display_name)

	# Description — readable primary body copy on the dark card footer.
	_description_label.text = _get_short_description(location)
	_description_label.add_theme_color_override("font_color", TEXT_COLOR_PRIMARY)
	_description_label.add_theme_font_size_override("font_size", FONT_SIZE_BODY)

	# Evidence count
	_evidence_prefix_label.text = "Evidence:"
	_evidence_prefix_label.theme_type_variation = &"SectionHeader"
	_evidence_prefix_label.add_theme_font_size_override("font_size", FONT_SIZE_BODY)
	var visited: bool = GameManager.has_visited_location(_location_id)
	if visited:
		var completion: Dictionary = LocationInvestigationManager.get_location_completion(_location_id)
		_evidence_label.text = "%d / %d" % [completion["found"], completion["total"]]
		_evidence_prefix_label.add_theme_color_override("font_color", TEXT_COLOR_PRIMARY)
		_evidence_label.add_theme_color_override("font_color", TEXT_COLOR_PRIMARY)
	else:
		_evidence_label.text = "?"
		_evidence_prefix_label.add_theme_color_override("font_color", TEXT_COLOR_MUTED)
		_evidence_label.add_theme_color_override("font_color", TEXT_COLOR_MUTED)
	_evidence_label.add_theme_font_size_override("font_size", FONT_SIZE_BODY)

	# Status badge (overlaid on image, top-right)
	var status: String = _resolve_status(_location_id)
	_status_label.text = status.to_upper()
	_status_label.add_theme_font_size_override("font_size", FONT_SIZE_META)
	var status_color: Color = STATUS_COLORS.get(status, UIColors.TEXT_MUTED)
	_status_label.add_theme_color_override("font_color", status_color)
	_apply_badge_style(status_color)


## Sets location image when valid; otherwise falls back to a placeholder.
func _set_location_image(image_path: String, location_name: String) -> void:
	var normalized_path: String = image_path.strip_edges()
	if normalized_path.is_empty():
		_show_image_placeholder(location_name)
		return

	if not ResourceLoader.exists(normalized_path):
		push_warning("[LocationCard] Image path not found for location '%s': %s" % [_location_id, normalized_path])
		_show_image_placeholder(location_name)
		return

	var image_resource: Resource = load(normalized_path)
	if image_resource is Texture2D:
		_image_rect.texture = image_resource as Texture2D
		_image_rect.visible = true
		_image_placeholder.visible = false
		return

	push_warning(
		"[LocationCard] Image resource is not a Texture2D for location '%s': %s"
		% [_location_id, normalized_path]
	)
	_show_image_placeholder(location_name)


## Shows a placeholder image token when no valid texture can be used.
func _show_image_placeholder(location_name: String) -> void:
	_image_rect.texture = null
	_image_rect.visible = false
	_image_placeholder.visible = true

	var placeholder_text: String = location_name.strip_edges()
	if placeholder_text.is_empty():
		placeholder_text = "?"
	_placeholder_initial.text = placeholder_text.to_upper()
	_placeholder_initial.autowrap_mode = TextServer.AUTOWRAP_WORD
	_placeholder_initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholder_initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


## Applies a safe fallback state when setup receives invalid location input.
func _apply_invalid_setup_state(reason: String) -> void:
	push_error("[LocationCard] setup rejected: %s" % reason)
	_location_id = ""
	_inspect_button.disabled = true

	_name_label.text = "UNKNOWN LOCATION"
	_name_label.uppercase = true
	_name_label.theme_type_variation = &"SectionHeader"
	_name_label.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	_name_label.add_theme_color_override("font_color", TEXT_COLOR_PRIMARY)

	_description_label.text = "Location data is invalid."
	_description_label.add_theme_color_override("font_color", TEXT_COLOR_PRIMARY)
	_description_label.add_theme_font_size_override("font_size", FONT_SIZE_BODY)

	_evidence_prefix_label.text = "Evidence:"
	_evidence_prefix_label.theme_type_variation = &"SectionHeader"
	_evidence_prefix_label.add_theme_font_size_override("font_size", FONT_SIZE_BODY)
	_evidence_prefix_label.add_theme_color_override("font_color", TEXT_COLOR_MUTED)
	_evidence_label.text = "?"
	_evidence_label.add_theme_font_size_override("font_size", FONT_SIZE_BODY)
	_evidence_label.add_theme_color_override("font_color", TEXT_COLOR_MUTED)

	var status_color: Color = STATUS_COLORS.get(STATUS_NEW, UIColors.TEXT_MUTED)
	_status_label.text = STATUS_NEW.to_upper()
	_status_label.add_theme_font_size_override("font_size", FONT_SIZE_META)
	_status_label.add_theme_color_override("font_color", status_color)
	_apply_badge_style(status_color)

	_show_image_placeholder("INVALID")


func get_location_id() -> String:
	return _location_id


## Maps manager status buckets to the card's 3-state UI labels.
func _resolve_status(location_id: String) -> String:
	var map_status: int = LocationInvestigationManager.get_location_card_status(location_id)
	match map_status:
		LocationInvestigationManager.MapCardStatus.NEW:
			return STATUS_NEW
		LocationInvestigationManager.MapCardStatus.OPEN:
			return STATUS_OPEN
		LocationInvestigationManager.MapCardStatus.EXHAUSTED:
			return STATUS_EXHAUSTED
		_:
			push_warning("[LocationCard] Unknown map card status '%s' for location '%s'." % [str(map_status), location_id])
			return STATUS_NEW


# --- Styling ---

func _apply_card_style() -> void:
	_base_style = StyleBoxFlat.new()
	_base_style.bg_color = CARD_BG
	_base_style.border_color = CARD_BORDER_COLOR
	_base_style.set_border_width_all(CARD_BORDER_WIDTH)
	_base_style.set_corner_radius_all(CARD_CORNER_RADIUS)
	_base_style.shadow_color = CARD_SHADOW_COLOR
	_base_style.shadow_size = CARD_SHADOW_SIZE
	add_theme_stylebox_override("panel", _base_style)

	# Pre-build hover style
	_hover_style = _base_style.duplicate() as StyleBoxFlat
	_hover_style.border_color = HOVER_BORDER_COLOR
	_hover_style.set_border_width_all(CARD_BORDER_WIDTH)
	_hover_style.shadow_color = HOVER_SHADOW_COLOR
	_hover_style.shadow_size = HOVER_SHADOW_SIZE


func _apply_image_mask() -> void:
	_image_mask_material = ShaderMaterial.new()
	_image_mask_material.shader = MEDIA_MASK_SHADER
	_image_mask_material.set_shader_parameter("corner_radius", float(MEDIA_CORNER_RADIUS))
	_image_rect.material = _image_mask_material


func _update_media_mask_size() -> void:
	if not _image_mask_material:
		return
	var media_size: Vector2 = _media_frame.size
	if media_size.x <= 0.0 or media_size.y <= 0.0:
		return
	_image_mask_material.set_shader_parameter("rect_size", media_size)


func _apply_media_frame_style() -> void:
	var media_style: StyleBoxFlat = StyleBoxFlat.new()
	media_style.bg_color = UIColors.LOCATION_CARD_MEDIA_BG
	media_style.set_corner_radius_all(MEDIA_CORNER_RADIUS)
	_media_frame.add_theme_stylebox_override("panel", media_style)


func _apply_footer_style() -> void:
	_footer.add_theme_constant_override("separation", 6)


func _apply_inspect_button_style() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = UIColors.LOCATION_CARD_BUTTON_BG
	normal.border_color = UIColors.LOCATION_CARD_BUTTON_BORDER
	normal.set_border_width_all(0)
	normal.corner_radius_top_left = 20
	normal.corner_radius_top_right = 20
	normal.corner_radius_bottom_left = 20
	normal.corner_radius_bottom_right = 20
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	_inspect_button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = UIColors.LOCATION_CARD_BUTTON_BG_HOVER
	_inspect_button.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = UIColors.LOCATION_CARD_BUTTON_BG_PRESSED
	_inspect_button.add_theme_stylebox_override("pressed", pressed)

	_inspect_button.add_theme_color_override("font_color", UIColors.LOCATION_CARD_BUTTON_TEXT)
	_inspect_button.add_theme_color_override("font_hover_color", UIColors.LOCATION_CARD_BUTTON_TEXT_HOVER)
	_inspect_button.add_theme_color_override("font_pressed_color", UIColors.LOCATION_CARD_BUTTON_TEXT_PRESSED)
	_inspect_button.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)


func _apply_placeholder_style() -> void:
	var ph_style := StyleBoxFlat.new()
	ph_style.bg_color = UIColors.LOCATION_CARD_PLACEHOLDER_BG
	ph_style.set_corner_radius_all(MEDIA_CORNER_RADIUS)
	ph_style.content_margin_left = 32
	ph_style.content_margin_right = 32
	ph_style.content_margin_top = 32
	ph_style.content_margin_bottom = 32
	_image_placeholder.add_theme_stylebox_override("panel", ph_style)
	_placeholder_initial.add_theme_font_size_override("font_size", 32)
	_placeholder_initial.add_theme_color_override("font_color", UIColors.LOCATION_CARD_PLACEHOLDER_TEXT)


func _apply_badge_style(status_color: Color) -> void:
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = UIColors.LOCATION_CARD_BADGE_BG
	var status_border_color: Color = status_color
	status_border_color.a = UIColors.LOCATION_CARD_BADGE_BORDER_ALPHA
	badge_style.border_color = status_border_color
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


# --- Mouse / Hover ---


func _on_mouse_entered() -> void:
	_on_hover_source_entered()


func _on_mouse_exited() -> void:
	_on_hover_source_exited()


func _on_hover_source_entered() -> void:
	_set_hovered_state(true)


func _on_hover_source_exited() -> void:
	if _is_mouse_within_card_bounds():
		# Guard against stale mouse position timing when moving quickly between controls.
		call_deferred("_finalize_hover_exit_if_needed")
		return
	_set_hovered_state(false)


func _finalize_hover_exit_if_needed() -> void:
	if _is_mouse_within_card_bounds():
		return
	_set_hovered_state(false)


func _is_mouse_within_card_bounds() -> bool:
	if not is_inside_tree():
		return false
	return get_global_rect().has_point(get_global_mouse_position())


func _set_hovered_state(hovered: bool) -> void:
	if _is_hovered == hovered:
		return
	_is_hovered = hovered
	_animate_hover(hovered)


func _animate_hover(hovered: bool) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	if hovered:
		add_theme_stylebox_override("panel", _hover_style)
		_hover_tween.tween_property(self, "scale", HOVER_SCALE, 0.15)
		_hover_tween.parallel().tween_property(self, "modulate", HOVER_MODULATE, 0.15)
	else:
		add_theme_stylebox_override("panel", _base_style)
		_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.2)
		_hover_tween.parallel().tween_property(self, "modulate", UIColors.MODULATE_NEUTRAL, 0.2)


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
	if _location_id.is_empty():
		return
	card_pressed.emit(_location_id)
