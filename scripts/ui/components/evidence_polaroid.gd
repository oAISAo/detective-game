## EvidencePolaroid.gd
## Polaroid-style card for displaying a piece of discovered evidence.
## Shows evidence image (or placeholder) with a handwriting-style name label.
## Emits card_pressed(evidence_id) when the player clicks the card.
class_name EvidencePolaroid
extends PanelContainer


signal card_pressed(evidence_id: String)

const _CORNER_RADIUS: int = 6
const _PADDING: int = 10
const _BOTTOM_PADDING: int = 6
const _IMAGE_MIN_HEIGHT: int = 120
const _SHADOW_SIZE: int = 8
const _HOVER_DIMNESS: float = 0.88
const _SELECTED_BORDER_WIDTH: int = 2
const _PIN_ICON_LIGATURE: String = "keep"
const _PIN_ICON_FONT_SIZE: int = 44

# Pin marker tuning:
# - _PIN_CAP_CUTOFF controls where the red cap stops and the silver body starts.
#   Lower values show less red. Higher values show more red.
#   0.0 = almost no red cap, 1.0 = the whole pin becomes red.
# - _PIN_ICON_ROTATION_DEGREES tilts the full composed pin.
#   Negative = tilt left, positive = tilt right.
# - _PIN_BODY_COLOR is the silver body tint.
# - _PIN_ICON_OUTLINE_SIZE makes the dark outline thinner or thicker.
const _PIN_ICON_OUTLINE_SIZE: int = 3
const _PIN_ICON_ROTATION_DEGREES: float = -15.0
const _PIN_CAP_CUTOFF: float = 0.64
const _PIN_BODY_COLOR: Color = Color(0.82, 0.84, 0.88)

@onready var _image_area: Control = $VBox/ImageArea
@onready var _image_clip: Control = %ImageClip
@onready var _image_rect: TextureRect = %ImageRect
@onready var _image_placeholder: ColorRect = %ImagePlaceholder
@onready var _badge_row: HBoxContainer = %BadgeRow
@onready var _pin_marker_row: Control = %PinMarkerRow
@onready var _pin_marker_chip: Control = %PinMarkerChip
@onready var _pin_marker: Label = %PinMarker
@onready var _pin_marker_cap_mask: ColorRect = %PinMarkerCapMask
@onready var _pin_marker_top: Label = %PinMarkerTop
@onready var _name_label: Label = %NameLabel

var _evidence_id: String = ""
var _base_modulate: Color = Color.WHITE
var _selected: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_card_style()
	_apply_pin_marker_style()
	_pin_marker_row.resized.connect(_refresh_pin_marker_visuals)
	_pin_marker.resized.connect(_refresh_pin_marker_visuals)
	_pin_marker_top.resized.connect(_refresh_pin_marker_visuals)
	resized.connect(_enforce_square_image)
	_configure_mouse_filter_routing()


## Populates the polaroid with evidence data. Call after adding to the scene tree.
func setup(ev: EvidenceData, handwriting_font: Font = null) -> void:
	_evidence_id = ev.id
	if not ev.image.is_empty() and ResourceLoader.exists(ev.image):
		_image_rect.texture = load(ev.image)
		_image_clip.visible = true
		_image_placeholder.visible = false
	else:
		_image_clip.visible = false
		_image_placeholder.visible = true
		_image_placeholder.color = UIColors.POLAROID_IMAGE_PLACEHOLDER_BG

	_name_label.text = ev.name
	_name_label.add_theme_color_override("font_color", UIColors.POLAROID_TEXT_TITLE)
	_name_label.add_theme_font_size_override("font_size", UIFonts.SIZE_TITLE)
	if handwriting_font:
		_name_label.add_theme_font_override("font", handwriting_font)
		
	# Force label to exactly two lines of height so 1-line vs 2-line names don't change polaroid size
	var font: Font = _name_label.get_theme_font("font")
	var line_height: float = font.get_height(UIFonts.SIZE_TITLE) if font else 20.0
	var line_spacing: int = _name_label.get_theme_constant("line_spacing")
	_name_label.custom_minimum_size.y = (line_height * 2) + line_spacing
	_name_label.lines_skipped = 0
	_name_label.max_lines_visible = 2

	_update_badges()


## Refreshes the badge row and centered pin marker to reflect current state.
## Call externally after state changes (e.g. after pinning/unpinning).
func refresh_badges() -> void:
	_update_badges()


## Sets the visual selected state. Called by the parent grid when this card
## becomes the active evidence or is deselected.
func set_selected(is_selected: bool) -> void:
	if _selected == is_selected:
		return
	_selected = is_selected
	_apply_card_style()


## Builds badge pills reflecting the current evidence state.
func _update_badges() -> void:
	UIHelper.clear_children(_badge_row)

	if _evidence_id.is_empty():
		_badge_row.visible = false
		_pin_marker_row.visible = false
		return

	var ev: EvidenceData = CaseManager.get_evidence(_evidence_id)

	if not EvidenceManager.is_reviewed(_evidence_id):
		_badge_row.add_child(_make_badge_pill("NEW", UIColors.BLUE))

	if ev != null and ev.lab_status == Enums.LabStatus.PROCESSING:
		_badge_row.add_child(_make_badge_pill("LAB", UIColors.AMBER))

	_badge_row.visible = _badge_row.get_child_count() > 0
	_pin_marker_row.visible = EvidenceManager.is_pinned(_evidence_id)

	# Dim the card when this evidence has been superseded by a discovered lab result.
	_base_modulate = Color(1.0, 1.0, 1.0, 0.5) if EvidenceManager.is_superseded(_evidence_id) else Color.WHITE
	modulate = _base_modulate


func _apply_pin_marker_style() -> void:
	var icon_font: FontVariation = _make_pin_icon_font()
	var label_settings: LabelSettings = _make_pin_label_settings(icon_font, _PIN_BODY_COLOR, _PIN_ICON_OUTLINE_SIZE)
	_pin_marker.text = _PIN_ICON_LIGATURE
	_pin_marker.label_settings = label_settings
	_pin_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pin_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_pin_marker_top.text = _PIN_ICON_LIGATURE
	_pin_marker_top.label_settings = _make_pin_label_settings(icon_font, UIColors.RED, 0)
	_pin_marker_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pin_marker_top.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_refresh_pin_marker_visuals()
	call_deferred("_refresh_pin_marker_visuals")


func _make_pin_icon_font() -> FontVariation:
	var icon_font := FontVariation.new()
	icon_font.base_font = load("res://assets/fonts/MaterialSymbolsOutlined.ttf") as FontFile
	icon_font.opentype_features = {"liga": 1, "calt": 1}
	var text_server: TextServer = TextServerManager.get_primary_interface()
	if text_server != null:
		icon_font.variation_opentype = {
			text_server.name_to_tag("FILL"): 1,
		}
	return icon_font


func _make_pin_label_settings(font: Font, color: Color, outline_size: int) -> LabelSettings:
	var label_settings := LabelSettings.new()
	label_settings.font = font
	label_settings.font_size = _PIN_ICON_FONT_SIZE
	label_settings.font_color = color
	label_settings.outline_color = UIColors.BG_PANEL
	label_settings.outline_size = outline_size
	return label_settings


func _refresh_pin_marker_visuals() -> void:
	var icon_size: Vector2 = _pin_marker.get_combined_minimum_size()
	if icon_size == Vector2.ZERO:
		return
	var pivot: Vector2 = icon_size / 2.0
	var row_size: Vector2 = _pin_marker_row.size
	_pin_marker_chip.custom_minimum_size = icon_size
	_pin_marker_chip.position = Vector2(max((row_size.x - icon_size.x - (icon_size.x * 0.25)) * 0.5, 0.0), 4.0)
	_pin_marker_chip.size = icon_size
	_pin_marker_chip.pivot_offset = pivot
	_pin_marker_chip.rotation_degrees = _PIN_ICON_ROTATION_DEGREES
	_pin_marker.position = Vector2.ZERO
	_pin_marker.size = icon_size
	_pin_marker.custom_minimum_size = icon_size
	_pin_marker.pivot_offset = Vector2.ZERO
	_pin_marker.rotation_degrees = 0.0
	# Only the top slice of the red overlay is shown through this mask.
	# Increase _PIN_CAP_CUTOFF for a taller red cap, decrease it for more silver body.
	var cap_size := Vector2(icon_size.x, icon_size.y * _PIN_CAP_CUTOFF)
	_pin_marker_cap_mask.position = Vector2.ZERO
	_pin_marker_cap_mask.size = cap_size
	_pin_marker_cap_mask.custom_minimum_size = cap_size
	_pin_marker_top.position = Vector2.ZERO
	_pin_marker_top.size = icon_size
	_pin_marker_top.custom_minimum_size = icon_size
	_pin_marker_top.pivot_offset = Vector2.ZERO
	_pin_marker_top.rotation_degrees = 0.0


## Creates a styled badge pill (PanelContainer + Label) matching the LocationCard overlay style.
func _make_badge_pill(text: String, color: Color) -> PanelContainer:
	var pill: PanelContainer = PanelContainer.new()
	pill.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.bg_color = UIColors.LOCATION_CARD_BADGE_BG
	var border_color: Color = color
	border_color.a = UIColors.LOCATION_CARD_BADGE_BORDER_ALPHA
	badge_style.border_color = border_color
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(4)
	badge_style.content_margin_left = 8
	badge_style.content_margin_right = 8
	badge_style.content_margin_top = 4
	badge_style.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", badge_style)

	var label: Label = Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(label)

	return pill


func _gui_input(event: InputEvent) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if _evidence_id.is_empty():
		return
	card_pressed.emit(_evidence_id)
	accept_event()


func _on_mouse_entered() -> void:
	modulate = Color(_HOVER_DIMNESS, _HOVER_DIMNESS, _HOVER_DIMNESS, _base_modulate.a)


func _on_mouse_exited() -> void:
	modulate = _base_modulate


func _apply_card_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.POLAROID_BG
	style.set_corner_radius_all(_CORNER_RADIUS)
	style.content_margin_left = _PADDING
	style.content_margin_top = _PADDING
	style.content_margin_right = _PADDING
	style.content_margin_bottom = _BOTTOM_PADDING
	style.shadow_color = UIColors.LOCATION_CARD_SHADOW
	style.shadow_size = _SHADOW_SIZE
	if _selected:
		style.shadow_color = UIColors.AMBER_SHADOW
		style.border_color = UIColors.AMBER
		style.set_border_width_all(_SELECTED_BORDER_WIDTH)
	add_theme_stylebox_override("panel", style)


## Keeps the image area square by setting min height to match inner width.
func _enforce_square_image() -> void:
	var inner_width: float = size.x - (_PADDING * 2)
	if inner_width > 0.0:
		_image_area.custom_minimum_size.y = inner_width


## Routes all mouse events through the card root so hover and click work uniformly
## regardless of which child node the cursor is over.
func _configure_mouse_filter_routing() -> void:
	var vbox: Node = get_node_or_null("VBox")
	if vbox:
		_set_control_tree_mouse_filter(vbox)


func _set_control_tree_mouse_filter(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_set_control_tree_mouse_filter(child)
