## SuspectList.gd
## Screen showing all unlocked suspects with their interrogation status.
## Allows the player to start interrogation sessions from here.
extends Control


@onready var back_button: Button = %BackButton
@onready var suspect_list_container: VBoxContainer = %SuspectListContainer


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_suspects()


## Populates the suspect list with unlocked suspects.
func _populate_suspects() -> void:
	for child: Node in suspect_list_container.get_children():
		suspect_list_container.remove_child(child)
		child.queue_free()

	var unlocked_ids: Array[String] = GameManager.unlocked_interrogations
	if unlocked_ids.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No suspects available for questioning yet."
		empty_label.add_theme_color_override("font_color", UIColors.MUTED)
		suspect_list_container.add_child(empty_label)
		return

	for person_id: String in unlocked_ids:
		var person: PersonData = CaseManager.get_person(person_id)
		if person == null:
			continue

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		# Suspect name and role
		var info_label: Label = Label.new()
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var role_text: String = EnumHelper.enum_to_string(Enums.PersonRole, person.role)
		info_label.text = "%s (%s)" % [person.name, role_text.to_lower()]
		hbox.add_child(info_label)

		# Status indicator
		var status_label: Label = Label.new()
		status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var has_broken: bool = InterrogationManager.has_break_moment(person_id)
		var can_today: bool = GameManager.can_interrogate_today(person_id)

		if has_broken:
			status_label.text = "✓ Broken"
			status_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		elif not can_today:
			status_label.text = "Questioned today"
			status_label.add_theme_color_override("font_color", UIColors.SECONDARY)
		else:
			status_label.text = "Available"
			status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		hbox.add_child(status_label)

		# Interrogate button
		var btn: Button = Button.new()
		btn.text = "Interrogate"
		btn.pressed.connect(_on_interrogate_pressed.bind(person_id))

		if not GameManager.is_daytime():
			btn.disabled = true
			btn.tooltip_text = "Interrogations can only be performed during Daytime."
		elif not GameManager.has_actions_remaining():
			btn.disabled = true
			btn.tooltip_text = "No actions remaining today."
		elif not can_today:
			btn.disabled = true
			btn.tooltip_text = "Already interrogated this suspect today."
		elif has_broken:
			btn.disabled = true
			btn.tooltip_text = "This suspect has already broken."

		hbox.add_child(btn)
		suspect_list_container.add_child(hbox)


## Handles the interrogate button press for a suspect.
func _on_interrogate_pressed(person_id: String) -> void:
	if not GameManager.is_daytime():
		NotificationManager.notify("Not Available", "Interrogations can only be performed during Daytime.")
		return
	if not GameManager.has_actions_remaining():
		NotificationManager.notify("No Actions", "You have no actions remaining today.")
		return
	if not GameManager.can_interrogate_today(person_id):
		NotificationManager.notify("Limit Reached", "Already interrogated this suspect today.")
		return

	# Consume one action point (interrogation tracking is handled by InterrogationManager)
	GameManager.use_action()
	GameManager.log_action("Interrogation started with suspect")

	ScreenManager.navigate_to("interrogation", {"person_id": person_id})


## Navigates back to the previous screen.
func _on_back_pressed() -> void:
	ScreenManager.navigate_back()
