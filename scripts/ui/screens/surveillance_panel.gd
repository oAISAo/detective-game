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

	var active: Array[Dictionary] = SurveillanceManager.get_active_operations()
	var all_ops: int = SurveillanceManager.get_operation_count()

	active_count_label.text = "%d active" % active.size()
	no_operations_label.visible = all_ops == 0

	# Show active operations
	if not active.is_empty():
		UIHelper.add_section_header("Active Surveillance", operation_list)
		for op: Dictionary in active:
			_add_operation_card(op, true)

	# Show other operations (cancelled/expired)
	var other_count: int = all_ops - active.size()
	if other_count > 0:
		UIHelper.add_section_header("Past Operations", operation_list)
		# Get all and filter non-active
		for surv_id: String in _get_all_operation_ids():
			var op: Dictionary = SurveillanceManager.get_operation(surv_id)
			if op.get("status", "") != "active":
				_add_operation_card(op, false)

	# Add install surveillance button
	_add_install_button()


func _clear_operation_list() -> void:
	for child: Node in operation_list.get_children():
		operation_list.remove_child(child)
		child.queue_free()


func _get_all_operation_ids() -> Array[String]:
	var ids: Array[String] = []
	var all_ops: Array[Dictionary] = SurveillanceManager.get_all_operations()
	for op: Dictionary in all_ops:
		ids.append(op.get("id", ""))
	return ids


func _add_operation_card(op: Dictionary, is_active: bool) -> void:
	var card := PanelContainer.new()
	UIHelper.apply_surface_style(card)
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Target and type
	var header := Label.new()
	var type_name: String = _get_type_name(op.get("type", 0))
	header.text = "%s — %s" % [type_name, op.get("target_person", "?")]
	header.add_theme_font_size_override("font_size", 16)
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
		status.add_theme_color_override("font_color", UIColors.STATUS_PROCESSING)
	else:
		status.text = "Status: %s" % op.get("status", "unknown")
		status.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	status.theme_type_variation = &"MetadataLabel"
	vbox.add_child(status)

	# Cancel button for active
	if is_active:
		var cancel_btn := Button.new()
		cancel_btn.text = "Cancel"
		cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		var surv_id: String = op.get("id", "")
		cancel_btn.pressed.connect(func() -> void:
			SurveillanceManager.cancel_surveillance(surv_id)
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


# --- Install Surveillance Section --- #

func _add_install_button() -> void:
	var sep := HSeparator.new()
	operation_list.add_child(sep)

	var btn := Button.new()
	btn.text = "Install New Surveillance..."
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_install_surveillance_pressed)
	operation_list.add_child(btn)


func _on_install_surveillance_pressed() -> void:
	if not GameManager.has_actions_remaining():
		NotificationManager.notify("No Actions", "You have no actions remaining today.")
		return

	var dialog := AcceptDialog.new()
	dialog.title = "Install Surveillance"
	var vbox := VBoxContainer.new()
	dialog.add_child(vbox)

	# Surveillance type dropdown
	var type_label := Label.new()
	type_label.text = "Surveillance Type:"
	type_label.theme_type_variation = &"MetadataLabel"
	vbox.add_child(type_label)

	var type_dropdown := OptionButton.new()
	type_dropdown.add_item("Phone Tap")
	type_dropdown.set_item_metadata(0, Enums.SurveillanceType.PHONE_TAP)
	type_dropdown.add_item("Home Surveillance")
	type_dropdown.set_item_metadata(1, Enums.SurveillanceType.HOME_SURVEILLANCE)
	type_dropdown.add_item("Financial Monitoring")
	type_dropdown.set_item_metadata(2, Enums.SurveillanceType.FINANCIAL_MONITORING)
	vbox.add_child(type_dropdown)

	# Target suspect dropdown
	var target_label := Label.new()
	target_label.text = "Target Suspect:"
	target_label.theme_type_variation = &"MetadataLabel"
	vbox.add_child(target_label)

	var target_dropdown := OptionButton.new()
	var suspects: Array[PersonData] = CaseManager.get_suspects()
	if suspects.is_empty():
		target_dropdown.add_item("No suspects available")
		target_dropdown.disabled = true
	else:
		for suspect: PersonData in suspects:
			target_dropdown.add_item(suspect.name if not suspect.name.is_empty() else suspect.id)
			target_dropdown.set_item_metadata(target_dropdown.item_count - 1, suspect.id)
	vbox.add_child(target_dropdown)

	dialog.confirmed.connect(func() -> void:
		_submit_surveillance(type_dropdown, target_dropdown)
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(350, 200))


func _submit_surveillance(type_dropdown: OptionButton, target_dropdown: OptionButton) -> void:
	if not GameManager.has_actions_remaining():
		NotificationManager.notify("No Actions", "You have no actions remaining today.")
		return

	if target_dropdown.disabled or target_dropdown.selected < 0:
		NotificationManager.notify("Error", "No target selected.")
		return

	var surv_type: Enums.SurveillanceType = type_dropdown.get_item_metadata(
		type_dropdown.selected
	) as Enums.SurveillanceType
	var target_person: String = target_dropdown.get_item_metadata(target_dropdown.selected)

	var result: Dictionary = SurveillanceManager.install_surveillance(target_person, surv_type)
	if result.is_empty():
		NotificationManager.notify("Installation Failed", "Could not install surveillance. Target may already be monitored or max limit reached.")
		return

	GameManager.use_action()
	var type_name: String = _get_type_name(surv_type)
	NotificationManager.notify_surveillance("%s installed on %s." % [type_name, target_person])
	UIHelper.confirmation_flash("Surveillance Installed", self)
	_refresh()
