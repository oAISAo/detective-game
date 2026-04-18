## EvidencePolaroid.gd
## Polaroid-style card for displaying a piece of discovered evidence.
## Shows evidence image (or placeholder) with a handwriting-style name label.
class_name EvidencePolaroid
extends PanelContainer


const _CORNER_RADIUS: int = 6
const _PADDING: int = 4
const _BOTTOM_PADDING: int = 10
const _IMAGE_MIN_HEIGHT: int = 120
const _VBOX_SEPARATION: int = 4

@onready var _image_clip: Control = %ImageClip
@onready var _image_rect: TextureRect = %ImageRect
@onready var _image_placeholder: ColorRect = %ImagePlaceholder
@onready var _name_label: Label = %NameLabel


func _ready() -> void:
	_apply_card_style()


## Populates the polaroid with evidence data. Call after adding to the scene tree.
func setup(ev: EvidenceData, handwriting_font: Font = null) -> void:
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
	_name_label.add_theme_font_size_override("font_size", UIFonts.SIZE_SECTION)
	if handwriting_font:
		_name_label.add_theme_font_override("font", handwriting_font)


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
	add_theme_stylebox_override("panel", style)
