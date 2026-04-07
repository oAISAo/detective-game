## SuspectCard.gd
## Reusable card component for displaying suspect information.
## Used by the Suspect List screen in a grid layout (Phase D7).
class_name SuspectCard
extends PanelContainer


signal interrogate_pressed(person_id: String)

var _person_id: String = ""

@onready var _name_label: Label = %NameLabel
@onready var _role_badge: Label = %RoleBadge
@onready var _status_label: Label = %StatusLabel
@onready var _interrogate_button: Button = %InterrogateButton


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_interrogate_button.pressed.connect(_on_interrogate_pressed)


## Populates the card with suspect data. Call after adding to the scene tree.
func setup(person: PersonData, person_id: String) -> void:
	_person_id = person_id
	_name_label.text = person.name
	var role_text: String = EnumHelper.enum_to_string(Enums.PersonRole, person.role)
	_role_badge.text = role_text.to_lower()
	_role_badge.add_theme_color_override("font_color", _get_role_color(person.role))
	_apply_status()
	_configure_button()


func get_person_id() -> String:
	return _person_id


func _apply_status() -> void:
	var has_broken: bool = InterrogationManager.has_break_moment(_person_id)
	var can_today: bool = GameManager.can_interrogate_today(_person_id)

	if has_broken:
		_status_label.text = "Broken"
		_status_label.add_theme_color_override("font_color", UIColors.ACCENT_PROCESSED)
	elif not can_today:
		_status_label.text = "Questioned today"
		_status_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	else:
		_status_label.text = "Available"
		_status_label.add_theme_color_override("font_color", UIColors.STATUS_AVAILABLE)


func _configure_button() -> void:
	var has_broken: bool = InterrogationManager.has_break_moment(_person_id)
	var can_today: bool = GameManager.can_interrogate_today(_person_id)

	if not GameManager.is_daytime():
		_interrogate_button.disabled = true
		_interrogate_button.tooltip_text = "Interrogations can only be performed during Daytime."
	elif not GameManager.has_actions_remaining():
		_interrogate_button.disabled = true
		_interrogate_button.tooltip_text = "No actions remaining today."
	elif not can_today:
		_interrogate_button.disabled = true
		_interrogate_button.tooltip_text = "Already interrogated this suspect today."
	elif has_broken:
		_interrogate_button.disabled = true
		_interrogate_button.tooltip_text = "This suspect has already broken."


func _get_role_color(role: Enums.PersonRole) -> Color:
	match role:
		Enums.PersonRole.SUSPECT: return UIColors.ACCENT_CRITICAL
		Enums.PersonRole.WITNESS: return UIColors.ACCENT_EXAMINED
		Enums.PersonRole.VICTIM: return UIColors.TEXT_MUTED
		Enums.PersonRole.INVESTIGATOR: return UIColors.ACCENT_PROCESSED
		Enums.PersonRole.TECHNICIAN: return UIColors.ACCENT_PROCESSED
	return UIColors.TEXT_MUTED


func _on_interrogate_pressed() -> void:
	interrogate_pressed.emit(_person_id)
