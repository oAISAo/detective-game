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
const _SHADOW_OFFSET: Vector2 = Vector2(2, 2)
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
	style.shadow_offset = _SHADOW_OFFSET
	add_theme_stylebox_override("panel", style)


## Keeps the image area square by setting min height to match inner width.
func _enforce_square_image() -> void:
	var inner_width: float = size.x - (_PADDING * 2)
	if inner_width > 0.0:
		_image_clip.custom_minimum_size.y = inner_width
		_image_placeholder.custom_minimum_size.y = inner_width
