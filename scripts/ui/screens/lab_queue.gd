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


## Analysis type presets.
const ANALYSIS_TYPES: Array[String] = [
	"Fingerprint Analysis",
	"DNA Analysis",
	"Chemical Analysis",
	"Digital Forensics",
]


func _ready() -> void:
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
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Analysis type and evidence
	var header := Label.new()
	header.text = "%s — %s" % [
		req.get("analysis_type", "Unknown"),
		req.get("input_evidence_id", "?"),
	]
	header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(header)

	# Status line
	var status := Label.new()
	if is_pending:
		var completion_day: int = req.get("completion_day", 0)
		if completion_day <= GameManager.current_day:
			status.text = "Result: Available now"
			status.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		else:
			status.text = "Result: Day %d morning" % completion_day
			status.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	else:
		status.text = "Completed — Output: %s" % req.get("output_evidence_id", "?")
		status.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
	status.add_theme_font_size_override("font_size", 14)
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
	header.text = "Submit New Analysis"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", UIColors.HEADER)
	submit_section.add_child(header)

	# Evidence dropdown
	var ev_label := Label.new()
	ev_label.text = "Evidence:"
	ev_label.add_theme_font_size_override("font_size", 14)
	submit_section.add_child(ev_label)

	var evidence_dropdown := OptionButton.new()
	evidence_dropdown.name = "EvidenceDropdown"
	var discovered: Array[EvidenceData] = EvidenceManager.get_discovered_evidence_data()
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
	type_label.add_theme_font_size_override("font_size", 14)
	submit_section.add_child(type_label)

	var type_dropdown := OptionButton.new()
	type_dropdown.name = "TypeDropdown"
	for analysis_type: String in ANALYSIS_TYPES:
		type_dropdown.add_item(analysis_type)
	submit_section.add_child(type_dropdown)

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

	var evidence_id: String = evidence_dropdown.get_item_metadata(evidence_dropdown.selected)
	var analysis_type: String = type_dropdown.get_item_text(type_dropdown.selected)

	var result: Dictionary = LabManager.submit_request(evidence_id, analysis_type, "", 1)
	if result.is_empty():
		NotificationManager.notify("Submission Failed", "Could not submit lab request. Check if the max concurrent limit is reached.")
		return

	GameManager.use_action()
	NotificationManager.notify("Lab Request Submitted", "%s submitted for %s." % [analysis_type, evidence_id])
	_refresh()
