## LabQueueScreen.gd
## UI screen for managing lab analysis requests.
## Shows pending and completed requests, allows submitting new ones.
extends Control


@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var pending_count_label: Label = %PendingCountLabel
@onready var request_list: VBoxContainer = %RequestListContainer
@onready var no_requests_label: Label = %NoRequestsLabel
@onready var submit_section: VBoxContainer = %SubmitSection


func _ready() -> void:
	UIHelper.apply_back_button_icon(back_button, "Back")
	back_button.pressed.connect(func() -> void: ScreenManager.navigate_back())
	_refresh()


func _refresh() -> void:
	_clear_request_list()
	_build_submit_section()

	var pending: Array[Dictionary] = LabManager.get_pending_requests()
	var completed: Array[Dictionary] = LabManager.get_completed_requests()
	var total: int = pending.size() + completed.size()

	pending_count_label.text = "%d pending" % pending.size()
	no_requests_label.visible = total == 0

	# Show pending requests
	if not pending.is_empty():
		UIHelper.add_section_header("Pending Requests", request_list)
		for req: Dictionary in pending:
			_add_request_card(req, true)

	# Show completed requests
	if not completed.is_empty():
		UIHelper.add_section_header("Completed Results", request_list)
		for req: Dictionary in completed:
			_add_request_card(req, false)


func _clear_request_list() -> void:
	for child: Node in request_list.get_children():
		request_list.remove_child(child)
		child.queue_free()


func _add_request_card(req: Dictionary, is_pending: bool) -> void:
	var card := PanelContainer.new()
	UIHelper.apply_surface_style(card)
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Analysis type and evidence
	var header := Label.new()
	header.text = "%s — %s" % [
		req.get("analysis_type", "Unknown"),
		req.get("input_evidence_id", "?"),
	]
	header.add_theme_font_size_override("font_size", UIFonts.SIZE_BODY)
	vbox.add_child(header)

	# Status line
	var status := Label.new()
	if is_pending:
		var completion_day: int = req.get("completion_day", 0)
		if completion_day <= GameManager.current_day:
			status.text = "Result: Available now"
			status.add_theme_color_override("font_color", UIColors.GREEN)
		else:
			status.text = "Result: Day %d morning" % completion_day
			status.add_theme_color_override("font_color", UIColors.AMBER)
	else:
		status.text = "Completed — Output: %s" % req.get("output_evidence_id", "?")
		status.add_theme_color_override("font_color", UIColors.GREEN)
	status.theme_type_variation = &"MetadataLabel"
	vbox.add_child(status)
	# Cancel button for pending
	if is_pending:
		var cancel_btn := Button.new()
		cancel_btn.text = "Cancel"
		cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		var req_id: String = req.get("id", "")
		cancel_btn.pressed.connect(func() -> void:
			LabManager.cancel_request(req_id)
			_refresh()
		)
		vbox.add_child(cancel_btn)

	request_list.add_child(card)


# --- Submit Section --- #

func _build_submit_section() -> void:
	for child: Node in submit_section.get_children():
		submit_section.remove_child(child)
		child.queue_free()

	var header := Label.new()
	header.text = "SUBMIT NEW ANALYSIS"
	header.theme_type_variation = &"SectionHeader"
	submit_section.add_child(header)

	# Evidence dropdown
	var ev_label := Label.new()
	ev_label.text = "Evidence:"
	ev_label.theme_type_variation = &"MetadataLabel"
	submit_section.add_child(ev_label)

	var evidence_dropdown := OptionButton.new()
	evidence_dropdown.name = "EvidenceDropdown"
	var discovered: Array[EvidenceData] = _get_submittable_evidence()
	if discovered.is_empty():
		evidence_dropdown.add_item("No evidence available")
		evidence_dropdown.disabled = true
	else:
		for ev: EvidenceData in discovered:
			evidence_dropdown.add_item(ev.name if not ev.name.is_empty() else ev.id)
			evidence_dropdown.set_item_metadata(evidence_dropdown.item_count - 1, ev.id)
	submit_section.add_child(evidence_dropdown)

	# Analysis type dropdown
	var type_label := Label.new()
	type_label.text = "Analysis Type:"
	type_label.theme_type_variation = &"MetadataLabel"
	submit_section.add_child(type_label)

	var type_dropdown := OptionButton.new()
	type_dropdown.name = "TypeDropdown"
	type_dropdown.disabled = discovered.is_empty()
	submit_section.add_child(type_dropdown)

	if discovered.is_empty():
		type_dropdown.add_item("No analyses available")
	else:
		evidence_dropdown.item_selected.connect(func(index: int) -> void:
			var selected_evidence_id: String = evidence_dropdown.get_item_metadata(index)
			_populate_template_dropdown(type_dropdown, selected_evidence_id)
		)
		var initial_evidence_id: String = evidence_dropdown.get_item_metadata(0)
		_populate_template_dropdown(type_dropdown, initial_evidence_id)

	# Submit button
	var submit_btn := Button.new()
	submit_btn.text = "Submit to Lab"
	submit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	submit_btn.pressed.connect(_on_submit_to_lab)
	submit_section.add_child(submit_btn)


func _on_submit_to_lab() -> void:
	if not GameManager.has_actions_remaining():
		NotificationManager.notify("No Actions", "You have no actions remaining today.")
		return

	var evidence_dropdown: OptionButton = submit_section.get_node_or_null("EvidenceDropdown")
	var type_dropdown: OptionButton = submit_section.get_node_or_null("TypeDropdown")
	if evidence_dropdown == null or type_dropdown == null:
		return

	if evidence_dropdown.disabled or evidence_dropdown.selected < 0:
		NotificationManager.notify("Error", "No evidence selected.")
		return
	if type_dropdown.disabled or type_dropdown.selected < 0:
		NotificationManager.notify("Error", "No analysis selected.")
		return

	var evidence_id: String = evidence_dropdown.get_item_metadata(evidence_dropdown.selected)
	var template_id: String = type_dropdown.get_item_metadata(type_dropdown.selected)
	var analysis_type: String = type_dropdown.get_item_text(type_dropdown.selected)
	var result: Dictionary = LabManager.submit_template_request(template_id, 1)
	if result.is_empty():
		NotificationManager.notify("Submission Failed", "Could not submit lab request. Check if the max concurrent limit is reached.")
		return

	GameManager.use_action()
	NotificationManager.notify("Lab Request Submitted", "%s submitted for %s." % [analysis_type, evidence_id])
	UIHelper.stamp_flash(submit_section)
	_refresh()


func _get_submittable_evidence() -> Array[EvidenceData]:
	var result: Array[EvidenceData] = []
	for ev: EvidenceData in EvidenceManager.get_discovered_evidence_data():
		if CaseManager.get_lab_requests_for_evidence(ev.id).is_empty():
			continue
		result.append(ev)
	return result


func _populate_template_dropdown(type_dropdown: OptionButton, evidence_id: String) -> void:
	type_dropdown.clear()
	var available_count: int = 0
	for lab_req: LabRequestData in CaseManager.get_lab_requests_for_evidence(evidence_id):
		if GameManager.has_evidence(lab_req.output_evidence_id):
			continue
		var output_ev: EvidenceData = CaseManager.get_evidence(lab_req.output_evidence_id)
		var output_name: String = output_ev.name if output_ev != null else lab_req.output_evidence_id
		type_dropdown.add_item(
			"%s -> %s" % [_format_analysis_type(lab_req.analysis_type), output_name]
		)
		type_dropdown.set_item_metadata(type_dropdown.item_count - 1, lab_req.id)
		available_count += 1

	if available_count == 0:
		type_dropdown.add_item("No analyses available")
		type_dropdown.disabled = true
		return

	type_dropdown.disabled = false


func _format_analysis_type(analysis_type: String) -> String:
	var words: PackedStringArray = analysis_type.replace("_", " ").split(" ", false)
	var formatted_words: Array[String] = []
	for word: String in words:
		formatted_words.append(word.to_upper() if word.length() <= 3 else word.capitalize())
	return " ".join(formatted_words)
