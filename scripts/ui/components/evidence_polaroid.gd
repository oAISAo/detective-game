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

@onready var _image_clip: Control = %ImageClip
@onready var _image_rect: TextureRect = %ImageRect
@onready var _image_placeholder: ColorRect = %ImagePlaceholder
@onready var _name_label: Label = %NameLabel

var _evidence_id: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_card_style()
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
	var line_height: float = _name_label.get_theme_font("font").get_height(UIFonts.SIZE_TITLE)
	var line_spacing: int = _name_label.get_theme_constant("line_spacing")
	_name_label.custom_minimum_size.y = (line_height * 2) + line_spacing
	_name_label.lines_skipped = 0
	_name_label.max_lines_visible = 2


func _gui_input(event: InputEvent) -> void:
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if _evidence_id.is_empty():
		return
	card_pressed.emit(_evidence_id)
	accept_event()


func _on_mouse_entered() -> void:
	modulate = Color(_HOVER_DIMNESS, _HOVER_DIMNESS, _HOVER_DIMNESS)


func _on_mouse_exited() -> void:
	modulate = Color.WHITE


func _apply_card_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.POLAROID_BG
	style.corner_radius_top_left = _CORNER_RADIUS
	style.corner_radius_top_right = _CORNER_RADIUS
	style.corner_radius_bottom_left = _CORNER_RADIUS
	style.corner_radius_bottom_right = _CORNER_RADIUS
	style.content_margin_left = _PADDING
	style.content_margin_top = _PADDING
	style.content_margin_right = _PADDING
	style.content_margin_bottom = _BOTTOM_PADDING
	style.shadow_color = UIColors.LOCATION_CARD_SHADOW
	style.shadow_size = _SHADOW_SIZE
	add_theme_stylebox_override("panel", style)


## Keeps the image area square by setting min height to match inner width.
func _enforce_square_image() -> void:
	var inner_width: float = size.x - (_PADDING * 2)
	if inner_width > 0.0:
		_image_clip.custom_minimum_size.y = inner_width
		_image_placeholder.custom_minimum_size.y = inner_width


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
