## CaseReportScreen.gd
## UI screen for the player to submit their final case report.
## Shows the 5 report sections and lets the player review before submitting.
extends Control


@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var submit_button: Button = %SubmitButton
@onready var status_label: RichTextLabel = %StatusLabel

# Section answer labels
@onready var suspect_answer: RichTextLabel = %SuspectAnswer
@onready var motive_answer: RichTextLabel = %MotiveAnswer
@onready var weapon_answer: RichTextLabel = %WeaponAnswer
@onready var time_answer: RichTextLabel = %TimeAnswer
@onready var access_answer: RichTextLabel = %AccessAnswer

# Section evidence lists
@onready var suspect_evidence_list: VBoxContainer = %SuspectEvidenceList
@onready var motive_evidence_list: VBoxContainer = %MotiveEvidenceList
@onready var weapon_evidence_list: VBoxContainer = %WeaponEvidenceList
@onready var time_evidence_list: VBoxContainer = %TimeEvidenceList
@onready var access_evidence_list: VBoxContainer = %AccessEvidenceList


func _ready() -> void:
	back_button.pressed.connect(func() -> void: ScreenManager.navigate_back())
	submit_button.pressed.connect(_on_submit_pressed)
	_refresh()


func _refresh() -> void:
	title_label.text = "Case Report"

	if ConclusionManager.has_report():
		status_label.text = "Report already submitted."
		submit_button.disabled = true
	else:
		status_label.text = "Ready to submit."
		submit_button.disabled = false

	_populate_sections()


func _populate_sections() -> void:
	var theories: Array[Dictionary] = TheoryManager.get_all_theories()
	if theories.is_empty():
		_set_section(suspect_answer, suspect_evidence_list, "[i]No theories created yet.[/i]", [])
		_set_section(motive_answer, motive_evidence_list, "[i]No theories created yet.[/i]", [])
		_set_section(weapon_answer, weapon_evidence_list, "[i]No theories created yet.[/i]", [])
		_set_section(time_answer, time_evidence_list, "[i]No theories created yet.[/i]", [])
		_set_section(access_answer, access_evidence_list, "[i]No theories created yet.[/i]", [])
		return

	# Use first complete theory, else first theory
	var theory: Dictionary = theories[0]
	for t: Dictionary in theories:
		if TheoryManager.is_complete(t["id"]):
			theory = t
			break

	var theory_id: String = theory.get("id", "")

	# Suspect section
	var suspect_id: String = theory.get("suspect_id", "")
	var suspect_name: String = _get_person_name(suspect_id) if not suspect_id.is_empty() else ""
	var suspect_text: String = "[b]%s[/b]" % suspect_name if not suspect_name.is_empty() else "[i]Not selected[/i]"
	_set_section(suspect_answer, suspect_evidence_list, suspect_text, TheoryManager.get_step_evidence(theory_id, "suspect"))

	# Motive section
	var motive_text: String = theory.get("motive", "")
	if motive_text.is_empty():
		motive_text = "[i]Not specified[/i]"
	_set_section(motive_answer, motive_evidence_list, motive_text, TheoryManager.get_step_evidence(theory_id, "motive"))

	# Weapon/method section
	var method_text: String = theory.get("method", "")
	if method_text.is_empty():
		method_text = "[i]Not specified[/i]"
	_set_section(weapon_answer, weapon_evidence_list, method_text, TheoryManager.get_step_evidence(theory_id, "method"))

	# Time section
	var time_minutes: int = theory.get("time_minutes", -1)
	var time_day: int = theory.get("time_day", -1)
	var time_text: String = "[i]Not specified[/i]"
	if time_minutes >= 0 and time_day >= 0:
		var hours: int = time_minutes / 60
		var mins: int = time_minutes % 60
		time_text = "Day %d, %02d:%02d" % [time_day, hours, mins]
	_set_section(time_answer, time_evidence_list, time_text, TheoryManager.get_step_evidence(theory_id, "time"))

	# Access section (no direct theory field, show timeline links as proxy)
	var timeline_ids: Array = theory.get("timeline_entry_ids", [])
	var access_text: String = "[i]Not specified[/i]"
	if not timeline_ids.is_empty():
		access_text = "%d timeline entries linked" % timeline_ids.size()
	_set_section(access_answer, access_evidence_list, access_text, [])


func _set_section(answer_label: RichTextLabel, evidence_container: VBoxContainer, answer_bbcode: String, evidence_ids: Array) -> void:
	answer_label.text = answer_bbcode

	# Clear existing evidence children
	for child: Node in evidence_container.get_children():
		child.queue_free()

	if evidence_ids.is_empty():
		var none_label := Label.new()
		none_label.text = "  (none attached)"
		evidence_container.add_child(none_label)
		return

	for ev_id in evidence_ids:
		var ev_name: String = _get_evidence_name(str(ev_id))
		var ev_label := Label.new()
		ev_label.text = "  - %s" % ev_name
		evidence_container.add_child(ev_label)


func _get_evidence_name(evidence_id: String) -> String:
	var ev: EvidenceData = CaseManager.get_evidence(evidence_id)
	if ev != null and not ev.name.is_empty():
		return ev.name
	return evidence_id


func _get_person_name(person_id: String) -> String:
	var person: PersonData = CaseManager.get_person(person_id)
	if person != null and not person.name.is_empty():
		return person.name
	return person_id


func _on_submit_pressed() -> void:
	var theories: Array[Dictionary] = TheoryManager.get_all_theories()
	if theories.is_empty():
		status_label.text = "No theories available."
		return

	# Use first complete theory, else first theory
	var theory: Dictionary = theories[0]
	for t: Dictionary in theories:
		if TheoryManager.is_complete(t["id"]):
			theory = t
			break

	var theory_id: String = theory.get("id", "")

	var report: Dictionary = {
		"suspect": {"answer": theory.get("suspect_id", ""), "evidence": TheoryManager.get_step_evidence(theory_id, "suspect")},
		"motive": {"answer": theory.get("motive", ""), "evidence": TheoryManager.get_step_evidence(theory_id, "motive")},
		"weapon": {"answer": theory.get("method", ""), "evidence": TheoryManager.get_step_evidence(theory_id, "method")},
		"time": {"answer": "%d %d" % [theory.get("time_minutes", 0), theory.get("time_day", 1)], "evidence": TheoryManager.get_step_evidence(theory_id, "time")},
		"access": {"answer": "", "evidence": []},
	}

	if ConclusionManager.submit_report(report):
		ScreenManager.navigate_to("prosecutor_review")
	else:
		status_label.text = "Failed to submit report."
