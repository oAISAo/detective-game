## ProsecutorReviewScreen.gd
## UI screen showing the prosecutor's evaluation: confidence score, dialogue, and player choice.
extends Control


@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var score_label: RichTextLabel = %ScoreLabel
@onready var dialogue_label: RichTextLabel = %DialogueLabel
@onready var strength_summary_label: RichTextLabel = %StrengthSummaryLabel
@onready var charge_button: Button = %ChargeButton
@onready var investigate_button: Button = %InvestigateButton
@onready var review_button: Button = %ReviewButton


func _ready() -> void:
	UIHelper.apply_back_button_icon(back_button, "Back")
	back_button.pressed.connect(func() -> void: ScreenManager.navigate_back())
	charge_button.pressed.connect(func() -> void: _on_choice("charge"))
	investigate_button.pressed.connect(func() -> void: _on_choice("investigate"))
	review_button.pressed.connect(func() -> void: _on_choice("review"))
	_refresh()


func _refresh() -> void:
	title_label.text = "Prosecutor Review"

	if not ConclusionManager.is_evaluated():
		score_label.text = "No report evaluated yet."
		dialogue_label.text = ""
		strength_summary_label.text = ""
		return

	var confidence: float = ConclusionManager.get_confidence_score()
	var confidence_pct: float = confidence * 100.0
	var color: String = _confidence_color(confidence)
	score_label.text = "[b]Confidence:[/b] [color=%s]%.0f%%[/color]" % [color, confidence_pct]

	var prosecutor_text: String = ConclusionManager.get_prosecutor_dialogue()
	dialogue_label.text = "[i]\"%s\"[/i]" % prosecutor_text

	_populate_strength_summary()


func _populate_strength_summary() -> void:
	var lines: String = "[b]Evidence Strength Summary[/b]\n"

	var evidence_score: float = ConclusionManager.get_evidence_score() if ConclusionManager.has_method("get_evidence_score") else 0.0
	var timeline_score: float = ConclusionManager.get_timeline_score() if ConclusionManager.has_method("get_timeline_score") else 0.0
	var motive_score: float = ConclusionManager.get_motive_score() if ConclusionManager.has_method("get_motive_score") else 0.0
	var alternatives_score: float = ConclusionManager.get_alternatives_score() if ConclusionManager.has_method("get_alternatives_score") else 0.0
	var contradiction_penalty: float = ConclusionManager.get_contradiction_penalty() if ConclusionManager.has_method("get_contradiction_penalty") else 0.0
	var coverage_bonus: float = ConclusionManager.get_coverage_bonus() if ConclusionManager.has_method("get_coverage_bonus") else 0.0

	lines += "  Evidence Quality: [color=%s]%.0f%%[/color]\n" % [_score_color(evidence_score), evidence_score * 100.0]
	lines += "  Timeline Accuracy: [color=%s]%.0f%%[/color]\n" % [_score_color(timeline_score), timeline_score * 100.0]
	lines += "  Motive Proof: [color=%s]%.0f%%[/color]\n" % [_score_color(motive_score), motive_score * 100.0]
	lines += "  Alternatives Eliminated: [color=%s]%.0f%%[/color]\n" % [_score_color(alternatives_score), alternatives_score * 100.0]

	if contradiction_penalty > 0.0:
		lines += "  [color=red]Contradiction Penalty: -%.0f%%[/color]\n" % (contradiction_penalty * 100.0)
	if coverage_bonus > 0.0:
		lines += "  [color=green]Coverage Bonus: +%.0f%%[/color]" % (coverage_bonus * 100.0)

	strength_summary_label.text = lines


func _confidence_color(score: float) -> String:
	if score >= 0.90:
		return "green"
	elif score >= 0.70:
		return "cyan"
	elif score >= 0.40:
		return "yellow"
	return "red"


func _score_color(score: float) -> String:
	if score >= 0.8:
		return "green"
	elif score >= 0.5:
		return "yellow"
	return "red"


func _on_choice(choice: String) -> void:
	if choice == "charge":
		var dialog: ConfirmationDialog = ConfirmationDialog.new()
		dialog.dialog_text = "File charges against the suspect? This is irreversible and will end the investigation."
		dialog.confirmed.connect(func() -> void:
			ConclusionManager.make_choice("charge")
			ScreenManager.navigate_to("case_outcome")
			dialog.queue_free()
		)
		dialog.canceled.connect(func() -> void: dialog.queue_free())
		dialog.close_requested.connect(func() -> void: dialog.queue_free())
		add_child(dialog)
		dialog.popup_centered()
		return

	ConclusionManager.make_choice(choice)

	match choice:
		"investigate":
			ScreenManager.navigate_to("desk_hub")
		"review":
			ScreenManager.navigate_back()
