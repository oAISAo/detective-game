## EvidenceCard.gd
## Reusable card component for displaying evidence items in a grid.
## Used by the Evidence Archive screen (Phase D6).
class_name EvidenceCard
extends PanelContainer


signal card_pressed(evidence_id: String)

var _evidence_id: String = ""

@onready var _name_label: Label = %NameLabel
@onready var _type_badge: Label = %TypeBadge
@onready var _description_label: Label = %DescriptionLabel
@onready var _state_label: Label = %StateLabel


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Click overlay — flat button covering the card for pointer cursor + click
	var overlay: Button = Button.new()
	overlay.flat = true
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	overlay.pressed.connect(_on_pressed)
	add_child(overlay)


## Populates the card with evidence data. Call after adding to the scene tree.
func setup(evidence: EvidenceData) -> void:
	_evidence_id = evidence.id
	_name_label.text = evidence.name
	_type_badge.text = UIHelper.get_evidence_type_label(evidence.type)
	_type_badge.add_theme_color_override("font_color", _get_type_color(evidence.type))
	_description_label.text = _truncate(evidence.description, 100)
	_description_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
	_apply_state(evidence)


func get_evidence_id() -> String:
	return _evidence_id


func _apply_state(evidence: EvidenceData) -> void:
	match evidence.lab_status:
		Enums.LabStatus.COMPLETED:
			_state_label.text = "Processed"
			_state_label.add_theme_color_override("font_color", UIColors.GREEN)
		Enums.LabStatus.PROCESSING:
			_state_label.text = "In Lab"
			_state_label.add_theme_color_override("font_color", UIColors.BLUE)
		_:
			if evidence.requires_lab_analysis:
				_state_label.text = "Awaiting Analysis"
				_state_label.add_theme_color_override("font_color", UIColors.AMBER)
			else:
				_state_label.text = "Collected"
				_state_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)


func _get_type_color(type: Enums.EvidenceType) -> Color:
	match type:
		Enums.EvidenceType.FORENSIC: return UIColors.BLUE
		Enums.EvidenceType.DOCUMENT: return UIColors.TEXT_SECONDARY
		Enums.EvidenceType.PHOTO: return UIColors.AMBER
		Enums.EvidenceType.RECORDING: return UIColors.RED
		Enums.EvidenceType.FINANCIAL: return UIColors.AMBER
		Enums.EvidenceType.DIGITAL: return UIColors.BLUE
		Enums.EvidenceType.OBJECT: return UIColors.TEXT_SECONDARY
	return UIColors.TEXT_GREY


static func _truncate(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return text.substr(0, max_length - 3) + "..."


func _on_pressed() -> void:
	card_pressed.emit(_evidence_id)
	UIHelper.selection_pulse(self)
