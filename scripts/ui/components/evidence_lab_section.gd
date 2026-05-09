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

	var lab_requests: Array[LabRequestData] = CaseManager.get_lab_requests_for_evidence(_evidence_id)
	if lab_requests.is_empty():
		return

	add_theme_constant_override("separation", 8)

	var header := Label.new()
	header.text = "Forensic Analysis"
	header.theme_type_variation = &"SectionHeader"
	add_child(header)

	var completed_requests: Array[LabRequestData] = _get_completed_requests(lab_requests)
	var available_requests: Array[LabRequestData] = _get_available_requests(lab_requests)
	var already_submitted: bool = LabManager.is_evidence_submitted(_evidence_id)

	if not completed_requests.is_empty():
		_build_completed_state(completed_requests)
	if already_submitted:
		_build_pending_state()
		return
	if not available_requests.is_empty():
		_build_submit_state(available_requests)


func clear() -> void:
	_evidence_id = ""
	UIHelper.clear_children(self)


func _build_completed_state(completed_requests: Array[LabRequestData]) -> void:
	if completed_requests.size() == 1:
		_add_completed_request(completed_requests[0])
		return

	var status_label := Label.new()
	status_label.text = "Completed analyses"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status_label)

	for lab_req: LabRequestData in completed_requests:
		_add_output_link(lab_req)


func _add_completed_request(lab_req: LabRequestData) -> void:
	var output_ev: EvidenceData = CaseManager.get_evidence(lab_req.output_evidence_id)
	if output_ev == null:
		return

	var status_label := Label.new()
	status_label.text = _get_completed_status_text(lab_req, output_ev)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status_label)

	_add_output_link(lab_req)


func _add_output_link(lab_req: LabRequestData) -> void:
	var output_ev: EvidenceData = CaseManager.get_evidence(lab_req.output_evidence_id)
	if output_ev == null:
		return

	var view_btn := LinkButton.new()
	view_btn.text = "\u2192 %s" % output_ev.name
	view_btn.underline = LinkButton.UNDERLINE_MODE_NEVER
	view_btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var out_id: String = lab_req.output_evidence_id
	view_btn.pressed.connect(func() -> void: output_evidence_requested.emit(out_id))
	add_child(view_btn)


func _get_completed_status_text(lab_req: LabRequestData, output_ev: EvidenceData) -> String:
	if not lab_req.completed_status_text.is_empty():
		return lab_req.completed_status_text
	if not output_ev.lab_result_text.is_empty():
		return output_ev.lab_result_text

	push_warning("[EvidenceLabSection] Missing completed_status_text for lab request: %s" % lab_req.id)
	return "Analysis complete. Result ready for review."


func _build_pending_state() -> void:
	var status_label := Label.new()
	status_label.text = "Submitted to Lab \u2014 Results pending."
	status_label.add_theme_color_override("font_color", UIColors.AMBER)
	add_child(status_label)


func _build_submit_state(available_requests: Array[LabRequestData]) -> void:
	var desc_label := Label.new()
	desc_label.text = "Possible forensic analyses available."
	desc_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(desc_label)

	for lab_req: LabRequestData in available_requests:
		_add_submit_option(lab_req)


func _add_submit_option(lab_req: LabRequestData) -> void:
	var output_ev: EvidenceData = CaseManager.get_evidence(lab_req.output_evidence_id)
	if output_ev != null:
		var expected_label := Label.new()
		expected_label.text = "Expected result: %s" % output_ev.name
		expected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		expected_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
		add_child(expected_label)

	var submit_btn := Button.new()
	submit_btn.text = "Submit to Lab \u2014 %s" % _format_analysis_type(lab_req.analysis_type)
	submit_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	submit_btn.pressed.connect(_on_submit_pressed.bind(lab_req.id))
	add_child(submit_btn)


func _format_analysis_type(analysis_type: String) -> String:
	var words: PackedStringArray = analysis_type.replace("_", " ").split(" ", false)
	var formatted_words: Array[String] = []
	for word: String in words:
		formatted_words.append(word.to_upper() if word.length() <= 3 else word.capitalize())
	return " ".join(formatted_words)


func _get_completed_requests(lab_requests: Array[LabRequestData]) -> Array[LabRequestData]:
	var result: Array[LabRequestData] = []
	for lab_req: LabRequestData in lab_requests:
		if GameManager.has_evidence(lab_req.output_evidence_id):
			result.append(lab_req)
	return result


func _get_available_requests(lab_requests: Array[LabRequestData]) -> Array[LabRequestData]:
	var result: Array[LabRequestData] = []
	for lab_req: LabRequestData in lab_requests:
		if GameManager.has_evidence(lab_req.output_evidence_id):
			continue
		result.append(lab_req)
	return result


func _on_submit_pressed(template_id: String) -> void:
	if _evidence_id.is_empty() or template_id.is_empty():
		return
	var success: bool = EvidenceManager.submit_to_lab_request(template_id)
	if not success:
		NotificationManager.notify("Submission Failed", "Could not submit lab request.")
		return
	UIHelper.confirmation_flash("Submitted to Lab", self)
	lab_submitted.emit()
