## SurveillancePanelScreen.gd
## UI screen for managing surveillance operations.
## Shows active and expired surveillance, allows installing new ones.
extends Control


@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var active_count_label: Label = %ActiveCountLabel
@onready var operation_list: VBoxContainer = %OperationListContainer
@onready var no_operations_label: Label = %NoOperationsLabel


func _ready() -> void:
	back_button.pressed.connect(func() -> void: ScreenManager.navigate_back())
	_refresh()


func _refresh() -> void:
	_clear_operation_list()

	var surv_mgr: Node = get_node_or_null("/root/SurveillanceManager")
	if surv_mgr == null:
		no_operations_label.visible = true
		no_operations_label.text = "Surveillance system not available."
		return

	var active: Array[Dictionary] = surv_mgr.get_active_operations()
	var all_ops: int = surv_mgr.get_operation_count()

	active_count_label.text = "%d active" % active.size()
	no_operations_label.visible = all_ops == 0

	# Show active operations
	if not active.is_empty():
		_add_section_header("Active Surveillance")
		for op: Dictionary in active:
			_add_operation_card(op, true)

	# Show other operations (cancelled/expired)
	var other_count: int = all_ops - active.size()
	if other_count > 0:
		_add_section_header("Past Operations")
		# Get all and filter non-active
		for surv_id: String in _get_all_operation_ids(surv_mgr):
			var op: Dictionary = surv_mgr.get_operation(surv_id)
			if op.get("status", "") != "active":
				_add_operation_card(op, false)


func _clear_operation_list() -> void:
	for child: Node in operation_list.get_children():
		child.queue_free()


func _get_all_operation_ids(surv_mgr: Node) -> Array[String]:
	# Build list from active + checking state
	var ids: Array[String] = []
	var active: Array[Dictionary] = surv_mgr.get_active_operations()
	for op: Dictionary in active:
		ids.append(op.get("id", ""))
	return ids


func _add_section_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.65))
	operation_list.add_child(label)


func _add_operation_card(op: Dictionary, is_active: bool) -> void:
	var card := PanelContainer.new()
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Target and type
	var header := Label.new()
	var type_name: String = _get_type_name(op.get("type", 0))
	header.text = "%s — %s" % [type_name, op.get("target_person", "?")]
	header.add_theme_font_size_override("font_size", 14)
	vbox.add_child(header)

	# Status line
	var status := Label.new()
	if is_active:
		var installed: int = op.get("day_installed", 0)
		var active_days: int = op.get("active_days", 0)
		var expires: int = installed + active_days
		status.text = "Active until Day %d — %d event(s) configured" % [
			expires, op.get("result_events", []).size()
		]
		status.add_theme_color_override("font_color", Color(0.3, 0.7, 0.9))
	else:
		status.text = "Status: %s" % op.get("status", "unknown")
		status.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	status.add_theme_font_size_override("font_size", 12)
	vbox.add_child(status)

	# Cancel button for active
	if is_active:
		var cancel_btn := Button.new()
		cancel_btn.text = "Cancel"
		cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		var surv_id: String = op.get("id", "")
		cancel_btn.pressed.connect(func() -> void:
			var mgr: Node = get_node_or_null("/root/SurveillanceManager")
			if mgr:
				mgr.cancel_surveillance(surv_id)
				_refresh()
		)
		vbox.add_child(cancel_btn)

	operation_list.add_child(card)


func _get_type_name(surv_type: int) -> String:
	match surv_type:
		Enums.SurveillanceType.PHONE_TAP:
			return "Phone Tap"
		Enums.SurveillanceType.HOME_SURVEILLANCE:
			return "Home Surveillance"
		Enums.SurveillanceType.FINANCIAL_MONITORING:
			return "Financial Monitoring"
	return "Unknown"
