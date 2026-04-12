## SuspectList.gd
## Screen showing all unlocked suspects with card components.
## Allows the player to start interrogation sessions.
## Phase D7: Uses SuspectCard grid instead of row-based layout.
extends Control


const SuspectCardScene: PackedScene = preload("res://scenes/ui/components/suspect_card.tscn")

@onready var back_button: Button = %BackButton
@onready var suspect_grid: GridContainer = %SuspectGrid


func _ready() -> void:
	UIHelper.apply_back_button_icon(back_button, "Back")
	back_button.pressed.connect(_on_back_pressed)
	_populate_suspects()


## Populates the suspect grid with card components.
func _populate_suspects() -> void:
	for child: Node in suspect_grid.get_children():
		suspect_grid.remove_child(child)
		child.queue_free()

	var unlocked_ids: Array[String] = GameManager.unlocked_interrogations
	if unlocked_ids.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No suspects available for questioning yet."
		empty_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		suspect_grid.add_child(empty_label)
		return

	for person_id: String in unlocked_ids:
		var person: PersonData = CaseManager.get_person(person_id)
		if person == null:
			continue

		var card: SuspectCard = SuspectCardScene.instantiate()
		suspect_grid.add_child(card)
		card.setup(person, person_id)
		card.interrogate_pressed.connect(_on_interrogate_pressed)


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
