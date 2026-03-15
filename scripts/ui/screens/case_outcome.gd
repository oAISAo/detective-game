## CaseOutcomeScreen.gd
## UI screen showing the final case outcome, epilogue, and discovered/missed evidence.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var outcome_label: Label = %OutcomeLabel
@onready var score_label: Label = %ScoreLabel
@onready var discovered_label: Label = %DiscoveredLabel
@onready var missed_label: Label = %MissedLabel


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	title_label.text = "Case Outcome"
	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	if concl_mgr == null:
		outcome_label.text = "System not available."
		return

	var epilogue: Dictionary = concl_mgr.get_epilogue()
	outcome_label.text = epilogue.get("outcome", "Unknown")
	score_label.text = "Final Score: %.0f%%" % (epilogue.get("score", 0.0) * 100.0)

	var disc: Array = epilogue.get("discovered", [])
	var miss: Array = epilogue.get("missed", [])

	var disc_text: String = "Evidence Discovered (%d):\n" % disc.size()
	for d: Dictionary in disc:
		disc_text += "  ✓ %s\n" % d.get("name", d.get("id", "?"))
	discovered_label.text = disc_text

	var miss_text: String = "Evidence Missed (%d):\n" % miss.size()
	for m: Dictionary in miss:
		miss_text += "  ✗ %s\n" % m.get("name", m.get("id", "?"))
	missed_label.text = miss_text
