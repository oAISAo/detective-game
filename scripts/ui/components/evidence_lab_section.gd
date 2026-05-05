## EvidenceLabSection
## Displays the forensic analysis block for an evidence item.
## Handles three states: completed, pending (submitted), and submittable.
class_name EvidenceLabSection
extends VBoxContainer


signal lab_submitted
signal output_evidence_requested(evidence_id: String)

var _evidence_id: String = ""


func populate(evidence_id: String) -> void:
	_evidence_id = evidence_id
	UIHelper.clear_children(self)

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(_evidence_id)
	if lab_req == null:
		return

	add_theme_constant_override("separation", 8)

	var header := Label.new()
	header.text = "Forensic Analysis"
	header.theme_type_variation = &"SectionHeader"
	add_child(header)

	var output_discovered: bool = GameManager.has_evidence(lab_req.output_evidence_id)
	var already_submitted: bool = LabManager.is_evidence_submitted(_evidence_id)

	if output_discovered:
		_build_completed_state(lab_req)
	elif already_submitted:
		_build_pending_state()
	else:
		_build_submit_state()


func clear() -> void:
	_evidence_id = ""
	UIHelper.clear_children(self)


func _build_completed_state(lab_req: LabRequestData) -> void:
	var status_label := Label.new()
	status_label.text = "Lab analysis complete."
	add_child(status_label)

	var output_ev: EvidenceData = CaseManager.get_evidence(lab_req.output_evidence_id)
	if output_ev == null:
		return

	var result_label := Label.new()
	result_label.text = "Result: %s" % output_ev.name
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(result_label)

	var view_btn := Button.new()
	view_btn.text = "\u2192 View: %s" % output_ev.name
	view_btn.flat = true
	view_btn.add_theme_color_override("font_color", UIColors.BLUE)
	view_btn.clip_text = true
	var out_id: String = lab_req.output_evidence_id
	view_btn.pressed.connect(
		func() -> void:
			output_evidence_requested.emit(out_id)
	)
	add_child(view_btn)


func _build_pending_state() -> void:
	var status_label := Label.new()
	status_label.text = "Submitted to Lab \u2014 Results pending."
	status_label.add_theme_color_override("font_color", UIColors.AMBER)
	add_child(status_label)


func _build_submit_state() -> void:
	var desc_label := Label.new()
	desc_label.text = "This evidence can be submitted for forensic analysis."
	desc_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(desc_label)

	var submit_btn := Button.new()
	submit_btn.text = "Submit to Lab"
	submit_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	submit_btn.pressed.connect(_on_submit_pressed)
	add_child(submit_btn)


func _on_submit_pressed() -> void:
	if _evidence_id.is_empty():
		return
	var success: bool = EvidenceManager.submit_to_lab(_evidence_id)
	if not success:
		NotificationManager.notify("Submission Failed", "Could not submit lab request.")
		return
	UIHelper.confirmation_flash("Submitted to Lab", self)
	lab_submitted.emit()
