## LocationCard.gd
## Reusable card component for displaying investigation locations.
## Features thumbnail/placeholder, status badge, clue count, and suspect tags.
## Used by the Case Map screen (Phase D7).
class_name LocationCard
extends PanelContainer


signal card_pressed(location_id: String)

var _location_id: String = ""

@onready var _image_rect: TextureRect = %ImageRect
@onready var _image_placeholder: PanelContainer = %ImagePlaceholder
@onready var _placeholder_initial: Label = %PlaceholderInitial
@onready var _name_label: Label = %NameLabel
@onready var _status_badge: Label = %StatusBadge
@onready var _description_label: Label = %DescriptionLabel
@onready var _meta_row: HBoxContainer = %MetaRow

const BADGE_COLORS: Dictionary = {
	"Not Visited": UIColors.STATUS_UNKNOWN,
	"Active Leads": UIColors.ACCENT_EXAMINED,
	"Scene Processed": UIColors.ACCENT_PROCESSED,
	"Lab Pending": UIColors.STATUS_PENDING,
}


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_card_style()
	_apply_placeholder_style()

	# Click overlay
	var overlay: Button = Button.new()
	overlay.flat = true
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	overlay.pressed.connect(_on_pressed)
	add_child(overlay)


## Populates the card with location data. Call after adding to the scene tree.
func setup(location: LocationData) -> void:
	_location_id = location.id
	_name_label.text = location.name

	# Image or placeholder
	if not location.image.is_empty() and ResourceLoader.exists(location.image):
		_image_rect.texture = load(location.image)
		_image_rect.visible = true
		_image_placeholder.visible = false
	else:
		_image_rect.visible = false
		_image_placeholder.visible = true
		_placeholder_initial.text = location.name.substr(0, 1).to_upper()

	# Status badge
	var status_text: String = LocationInvestigationManager.get_location_status(location.id)
	_status_badge.text = status_text
	_status_badge.add_theme_color_override(
		"font_color", BADGE_COLORS.get(status_text, UIColors.TEXT_MUTED)
	)

	# Description
	_description_label.text = _get_short_description(location)
	_description_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	_description_label.add_theme_font_size_override("font_size", 13)

	# Meta row: clue count + suspect tags
	_populate_meta(location)


func get_location_id() -> String:
	return _location_id


func _apply_card_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIColors.BG_BASE
	style.border_color = UIColors.BORDER_SUBTLE
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)
	custom_minimum_size.y = 120


func _apply_placeholder_style() -> void:
	var ph_style: StyleBoxFlat = StyleBoxFlat.new()
	ph_style.bg_color = UIColors.BG_PANEL
	ph_style.corner_radius_top_left = 4
	ph_style.corner_radius_top_right = 4
	ph_style.corner_radius_bottom_left = 4
	ph_style.corner_radius_bottom_right = 4
	_image_placeholder.add_theme_stylebox_override("panel", ph_style)
	_placeholder_initial.add_theme_font_size_override("font_size", 32)
	_placeholder_initial.add_theme_color_override("font_color", UIColors.TEXT_MUTED)


func _populate_meta(location: LocationData) -> void:
	for child: Node in _meta_row.get_children():
		_meta_row.remove_child(child)
		child.queue_free()

	var visited: bool = GameManager.has_visited_location(location.id)
	if visited:
		var completion: Dictionary = LocationInvestigationManager.get_location_completion(location.id)
		var clue_label: Label = Label.new()
		clue_label.text = "%d/%d clues found" % [completion["found"], completion["total"]]
		clue_label.theme_type_variation = &"MetadataLabel"
		clue_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
		_meta_row.add_child(clue_label)

	var tags: Array[String] = LocationInvestigationManager.get_suspect_relevance_tags(location.id)
	for tag_name: String in tags:
		var tag: Label = Label.new()
		tag.text = tag_name
		tag.theme_type_variation = &"MetadataLabel"
		tag.add_theme_color_override("font_color", UIColors.ACCENT_EXAMINED)
		tag.add_theme_font_size_override("font_size", 11)
		_meta_row.add_child(tag)


static func _get_short_description(loc: LocationData) -> String:
	if loc.description.is_empty():
		return ""
	var dot_idx: int = loc.description.find(".")
	if dot_idx >= 0 and dot_idx < 80:
		return loc.description.substr(0, dot_idx + 1)
	if loc.description.length() > 80:
		return loc.description.substr(0, 77) + "..."
	return loc.description


func _on_pressed() -> void:
	card_pressed.emit(_location_id)
