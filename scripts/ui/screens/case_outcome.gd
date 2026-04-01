## CaseOutcomeScreen.gd
## UI screen showing the final case outcome, epilogue, and discovered/missed evidence.
extends Control


@onready var title_label: RichTextLabel = %TitleLabel
@onready var outcome_label: RichTextLabel = %OutcomeLabel
@onready var score_label: RichTextLabel = %ScoreLabel
@onready var discovered_label: RichTextLabel = %DiscoveredLabel
@onready var missed_label: RichTextLabel = %MissedLabel
@onready var return_to_title_button: Button = %ReturnToTitleButton


func _ready() -> void:
	return_to_title_button.pressed.connect(_on_return_to_title)
	_refresh()


func _refresh() -> void:
	title_label.text = "[b][font_size=24]Case Outcome[/font_size][/b]"

	var epilogue: Dictionary = ConclusionManager.get_epilogue()

	# Outcome
	var outcome_text: String = epilogue.get("outcome", "Unknown")
	var outcome_color: String = _outcome_color(outcome_text)
	outcome_label.text = "[b]Verdict:[/b] [color=%s]%s[/color]" % [outcome_color, outcome_text]

	# Score
	var score: float = epilogue.get("score", 0.0)
	var score_pct: float = score * 100.0
	var score_color: String = _score_color(score)
	score_label.text = "[b]Final Score:[/b] [color=%s]%.0f%%[/color]" % [score_color, score_pct]

	# Discovered evidence
	var disc: Array = epilogue.get("discovered", [])
	var disc_text: String = "[b][color=green]Evidence Discovered (%d)[/color][/b]\n" % disc.size()
	if disc.is_empty():
		disc_text += "  [i]None[/i]"
	else:
		for d: Dictionary in disc:
			var ev_name: String = d.get("name", d.get("id", "?"))
			disc_text += "  [color=green]-[/color] %s\n" % ev_name
	discovered_label.text = disc_text

	# Missed evidence
	var miss: Array = epilogue.get("missed", [])
	var miss_text: String = "[b][color=red]Evidence Missed (%d)[/color][/b]\n" % miss.size()
	if miss.is_empty():
		miss_text += "  [i]None — you found everything![/i]"
	else:
		for m: Dictionary in miss:
			var ev_name: String = m.get("name", m.get("id", "?"))
			miss_text += "  [color=red]-[/color] %s\n" % ev_name
	missed_label.text = miss_text


func _outcome_color(outcome: String) -> String:
	match outcome:
		"Perfect Solution":
			return "green"
		"Correct But Incomplete":
			return "cyan"
		"Wrong Suspect, Plausible Theory":
			return "yellow"
		_:
			return "red"


func _score_color(score: float) -> String:
	if score >= 0.90:
		return "green"
	elif score >= 0.70:
		return "cyan"
	elif score >= 0.40:
		return "yellow"
	return "red"


func _on_return_to_title() -> void:
	var game_root: Node = get_tree().current_scene
	if game_root.has_method("return_to_title"):
		game_root.return_to_title()
	else:
		push_error("[CaseOutcome] GameRoot.return_to_title() not found.")
