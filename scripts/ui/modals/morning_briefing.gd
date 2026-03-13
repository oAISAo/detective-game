## MorningBriefing.gd
## Modal overlay for the daily morning briefing — summarizes new evidence,
## events, and objectives for the day.
## Phase 4A: Integrates with DialogueSystem for structured briefing content.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var briefing_text: RichTextLabel = %BriefingText
@onready var continue_button: Button = %ContinueButton
@onready var close_button: Button = %CloseButton
@onready var dimmer: ColorRect = %Dimmer


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	close_button.pressed.connect(_on_close_pressed)

	# Connect to DialogueSystem for briefing content
	DialogueSystem.dialogue_line_displayed.connect(_on_dialogue_line_displayed)
	DialogueSystem.dialogue_ended.connect(_on_dialogue_ended)

	_start_briefing()


## Starts the morning briefing flow.
func _start_briefing() -> void:
	title_label.text = "Morning Briefing — Day %d" % GameManager.current_day
	continue_button.visible = false
	close_button.visible = false

	# Check if there's pending briefing dialogue
	if DialogueSystem.is_active():
		_show_current_line()
	else:
		briefing_text.text = "[b]Good morning, Detective.[/b]\n\nNo new briefing information available today.\nCheck your evidence archive and investigation log."
		close_button.visible = true


## Displays the current dialogue line in the briefing.
func _show_current_line() -> void:
	var line: Dictionary = DialogueSystem.get_current_line()
	if line.is_empty():
		briefing_text.text = "Briefing complete."
		close_button.visible = true
		continue_button.visible = false
		return

	var speaker: String = line.get("speaker", "")
	var text: String = line.get("text", "")
	if speaker.is_empty():
		briefing_text.text = text
	else:
		briefing_text.text = "[b]%s:[/b]\n%s" % [speaker, text]
	continue_button.visible = true


## Advances the dialogue when Continue is pressed.
func _on_continue_pressed() -> void:
	DialogueSystem.advance()


## Handles new dialogue lines.
func _on_dialogue_line_displayed(_speaker: String, _text: String, _portrait: String) -> void:
	_show_current_line()


## Handles dialogue completion.
func _on_dialogue_ended(_dialogue_id: String) -> void:
	briefing_text.text = "[b]Briefing complete.[/b]\n\nGood luck with today's investigation, Detective."
	continue_button.visible = false
	close_button.visible = true


## Closes the modal.
func _on_close_pressed() -> void:
	ScreenManager.close_modal("morning_briefing")
