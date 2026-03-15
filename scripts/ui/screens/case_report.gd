## CaseReportScreen.gd
## UI screen for the player to submit their final case report.
## Shows the 5 report sections and lets the player review before submitting.
extends Control


@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var submit_button: Button = %SubmitButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	back_button.pressed.connect(func() -> void: ScreenManager.navigate_back())
	submit_button.pressed.connect(_on_submit_pressed)
	_refresh()


func _refresh() -> void:
	title_label.text = "Case Report"
	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	if concl_mgr == null:
		status_label.text = "Conclusion system not available."
		submit_button.disabled = true
		return

	if concl_mgr.has_report():
		status_label.text = "Report already submitted."
		submit_button.disabled = true
	else:
		status_label.text = "Ready to submit."
		submit_button.disabled = false


func _on_submit_pressed() -> void:
	var th_mgr: Node = get_node_or_null("/root/TheoryManager")
	if th_mgr == null:
		status_label.text = "TheoryManager not available."
		return

	var theories: Array[Dictionary] = th_mgr.get_all_theories()
	if theories.is_empty():
		status_label.text = "No theories available."
		return

	# Use first complete theory, else first theory
	var theory: Dictionary = theories[0]
	for t: Dictionary in theories:
		if th_mgr.is_complete(t["id"]):
			theory = t
			break

	var report: Dictionary = {
		"suspect": {"answer": theory.get("suspect_id", ""), "evidence": []},
		"motive": {"answer": theory.get("motive", ""), "evidence": []},
		"weapon": {"answer": theory.get("method", ""), "evidence": []},
		"time": {"answer": "%d %d" % [theory.get("time_minutes", 0), theory.get("time_day", 1)], "evidence": []},
		"access": {"answer": theory.get("access", "Unknown"), "evidence": []},
	}

	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	if concl_mgr and concl_mgr.submit_report(report):
		ScreenManager.navigate_to("prosecutor_review")
	else:
		status_label.text = "Failed to submit report."
