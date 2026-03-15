## ProsecutorReviewScreen.gd
## UI screen showing the prosecutor's evaluation: confidence score, dialogue, and player choice.
extends Control


@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var dialogue_label: Label = %DialogueLabel
@onready var charge_button: Button = %ChargeButton
@onready var investigate_button: Button = %InvestigateButton
@onready var review_button: Button = %ReviewButton


func _ready() -> void:
	back_button.pressed.connect(func() -> void: ScreenManager.navigate_back())
	charge_button.pressed.connect(func() -> void: _on_choice("charge"))
	investigate_button.pressed.connect(func() -> void: _on_choice("investigate"))
	review_button.pressed.connect(func() -> void: _on_choice("review"))
	_refresh()


func _refresh() -> void:
	title_label.text = "Prosecutor Review"
	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	if concl_mgr == null:
		score_label.text = "System not available."
		dialogue_label.text = ""
		return

	if not concl_mgr.is_evaluated():
		score_label.text = "No report evaluated yet."
		dialogue_label.text = ""
		return

	score_label.text = "Confidence: %.0f%%" % (concl_mgr.get_confidence_score() * 100.0)
	dialogue_label.text = concl_mgr.get_prosecutor_dialogue()


func _on_choice(choice: String) -> void:
	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	if concl_mgr == null:
		return

	concl_mgr.make_choice(choice)

	match choice:
		"charge":
			ScreenManager.navigate_to("case_outcome")
		"investigate":
			ScreenManager.navigate_to("desk_hub")
		"review":
			ScreenManager.navigate_back()
