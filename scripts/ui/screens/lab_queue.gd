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
	back_button.pressed.connect(func() -> void: ScreenManager.navigate_back())
	_refresh()


func _refresh() -> void:
	_clear_request_list()

	var lab_mgr: Node = get_node_or_null("/root/LabManager")
	if lab_mgr == null:
		no_requests_label.visible = true
		no_requests_label.text = "Lab system not available."
		return

	var pending: Array[Dictionary] = lab_mgr.get_pending_requests()
	var completed: Array[Dictionary] = lab_mgr.get_completed_requests()
	var total: int = pending.size() + completed.size()

	pending_count_label.text = "%d pending" % pending.size()
	no_requests_label.visible = total == 0

	# Show pending requests
	if not pending.is_empty():
		_add_section_header("Pending Requests")
		for req: Dictionary in pending:
			_add_request_card(req, true)

	# Show completed requests
	if not completed.is_empty():
		_add_section_header("Completed Results")
		for req: Dictionary in completed:
			_add_request_card(req, false)


func _clear_request_list() -> void:
	for child: Node in request_list.get_children():
		child.queue_free()


func _add_section_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.65))
	request_list.add_child(label)


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
			var lab: Node = get_node_or_null("/root/LabManager")
			if lab:
				lab.cancel_request(req_id)
				_refresh()
		)
		vbox.add_child(cancel_btn)

	request_list.add_child(card)
