## WarrantOfficeScreen.gd
## UI screen for requesting warrants and viewing warrant history.
## Shows legal category coverage, judge feedback, and arrest status.
extends Control


@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var warrant_count_label: Label = %WarrantCountLabel
@onready var warrant_list: VBoxContainer = %WarrantListContainer
@onready var no_warrants_label: Label = %NoWarrantsLabel
@onready var arrest_section: VBoxContainer = %ArrestSection


func _ready() -> void:
	back_button.pressed.connect(func() -> void: ScreenManager.navigate_back())
	_refresh()


func _refresh() -> void:
	_clear_warrant_list()

	var approved: Array[Dictionary] = WarrantManager.get_approved_warrants()
	var denied: Array[Dictionary] = WarrantManager.get_denied_warrants()
	var total: int = approved.size() + denied.size()

	warrant_count_label.text = "%d approved" % approved.size()
	no_warrants_label.visible = total == 0

	# Show approved warrants
	if not approved.is_empty():
		UIHelper.add_section_header("Approved Warrants", warrant_list)
		for w: Dictionary in approved:
			_add_warrant_card(w, true)

	# Show denied warrants
	if not denied.is_empty():
		UIHelper.add_section_header("Denied Requests", warrant_list)
		for w: Dictionary in denied:
			_add_warrant_card(w, false)

	# Show arrest status
	_update_arrest_section()

	# Add request warrant button at end of warrant list
	_add_request_warrant_button()


func _clear_warrant_list() -> void:
	for child: Node in warrant_list.get_children():
		warrant_list.remove_child(child)
		child.queue_free()
	for child: Node in arrest_section.get_children():
		arrest_section.remove_child(child)
		child.queue_free()


func _add_warrant_card(w: Dictionary, is_approved: bool) -> void:
	var card := PanelContainer.new()
	UIHelper.apply_surface_style(card)
	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Warrant type and target
	var header := Label.new()
	var type_name: String = _get_warrant_type_name(w.get("type", 0))
	header.text = "%s — Target: %s" % [type_name, w.get("target", "?")]
	header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(header)

	# Status and details
	var status := Label.new()
	if is_approved:
		status.text = "Approved (Day %d)" % w.get("day_requested", 0)
		status.add_theme_color_override("font_color", UIColors.ACCENT_PROCESSED)
	else:
		var feedback: String = w.get("feedback", "Insufficient evidence.")
		status.text = "Denied — %s" % feedback
		status.add_theme_color_override("font_color", UIColors.ACCENT_CRITICAL)
	status.theme_type_variation = &"MetadataLabel"
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(status)

	# Categories provided
	var cats: Array = w.get("categories_provided", [])
	if not cats.is_empty():
		var cat_label := Label.new()
		var cat_names: Array[String] = []
		for cat: int in cats:
			cat_names.append(UIHelper.get_legal_category_label(cat))
		cat_label.text = "Categories: %s" % ", ".join(cat_names)
		cat_label.add_theme_font_size_override("font_size", 13)
		cat_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
		vbox.add_child(cat_label)

	warrant_list.add_child(card)


func _update_arrest_section() -> void:
	var arrested: Array[String] = WarrantManager.get_arrested_suspects()
	if arrested.is_empty():
		return

	var header := Label.new()
	header.text = "ARRESTED SUSPECTS"
	header.theme_type_variation = &"SectionHeader"
	header.add_theme_color_override("font_color", UIColors.ACCENT_CRITICAL)
	arrest_section.add_child(header)

	for person_id: String in arrested:
		var person: PersonData = CaseManager.get_person(person_id)
		var name_text: String = person.name if person else person_id
		var label := Label.new()
		label.text = "  %s — In custody" % name_text
		arrest_section.add_child(label)


func _get_warrant_type_name(warrant_type: int) -> String:
	match warrant_type:
		Enums.WarrantType.SEARCH:
			return "Search Warrant"
		Enums.WarrantType.SURVEILLANCE:
			return "Surveillance Warrant"
		Enums.WarrantType.DIGITAL:
			return "Digital Warrant"
		Enums.WarrantType.ARREST:
			return "Arrest Warrant"
	return "Unknown Warrant"


# --- Request Warrant Section --- #

func _add_request_warrant_button() -> void:
	var sep := HSeparator.new()
	warrant_list.add_child(sep)

	var btn := Button.new()
	btn.text = "Request New Warrant..."
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(_on_request_warrant_pressed)
	warrant_list.add_child(btn)


func _on_request_warrant_pressed() -> void:
	if not GameManager.has_actions_remaining():
		NotificationManager.notify("No Actions", "You have no actions remaining today.")
		return

	var dialog := AcceptDialog.new()
	dialog.title = "Request Warrant"
	var vbox := VBoxContainer.new()
	dialog.add_child(vbox)

	# Warrant type dropdown
	var type_label := Label.new()
	type_label.text = "Warrant Type:"
	type_label.theme_type_variation = &"MetadataLabel"
	vbox.add_child(type_label)

	var type_dropdown := OptionButton.new()
	type_dropdown.add_item("Search")
	type_dropdown.set_item_metadata(0, Enums.WarrantType.SEARCH)
	type_dropdown.add_item("Surveillance")
	type_dropdown.set_item_metadata(1, Enums.WarrantType.SURVEILLANCE)
	type_dropdown.add_item("Digital")
	type_dropdown.set_item_metadata(2, Enums.WarrantType.DIGITAL)
	type_dropdown.add_item("Arrest")
	type_dropdown.set_item_metadata(3, Enums.WarrantType.ARREST)
	vbox.add_child(type_dropdown)

	# Target input
	var target_label := Label.new()
	target_label.text = "Target (person/location ID):"
	target_label.theme_type_variation = &"MetadataLabel"
	vbox.add_child(target_label)

	var target_edit := LineEdit.new()
	target_edit.placeholder_text = "Enter target ID..."
	vbox.add_child(target_edit)

	# Evidence checkboxes
	var ev_label := Label.new()
	ev_label.text = "Supporting Evidence:"
	ev_label.theme_type_variation = &"MetadataLabel"
	vbox.add_child(ev_label)

	var ev_scroll := ScrollContainer.new()
	ev_scroll.custom_minimum_size = Vector2(0, 120)
	var ev_vbox := VBoxContainer.new()
	ev_scroll.add_child(ev_vbox)
	vbox.add_child(ev_scroll)

	var discovered: Array[EvidenceData] = EvidenceManager.get_discovered_evidence_data()
	if discovered.is_empty():
		var none_label := Label.new()
		none_label.text = "No evidence discovered yet."
		none_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
		ev_vbox.add_child(none_label)
	else:
		for ev: EvidenceData in discovered:
			var check := CheckButton.new()
			check.text = ev.name if not ev.name.is_empty() else ev.id
			check.set_meta("evidence_id", ev.id)
			ev_vbox.add_child(check)

	dialog.confirmed.connect(func() -> void:
		_submit_warrant_request(type_dropdown, target_edit, ev_vbox)
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(400, 350))


func _submit_warrant_request(
	type_dropdown: OptionButton,
	target_edit: LineEdit,
	ev_vbox: VBoxContainer
) -> void:
	if not GameManager.has_actions_remaining():
		NotificationManager.notify("No Actions", "You have no actions remaining today.")
		return

	var target: String = target_edit.text.strip_edges()
	if target.is_empty():
		NotificationManager.notify("Error", "Please enter a target.")
		return

	var warrant_type: Enums.WarrantType = type_dropdown.get_item_metadata(
		type_dropdown.selected
	) as Enums.WarrantType

	var evidence_ids: Array[String] = []
	for child: Node in ev_vbox.get_children():
		if child is CheckButton and child.button_pressed:
			evidence_ids.append(child.get_meta("evidence_id") as String)

	var result: Dictionary = WarrantManager.request_warrant(warrant_type, target, evidence_ids)
	if result.is_empty():
		NotificationManager.notify("Warrant Failed", "Could not submit warrant request.")
		return

	GameManager.use_action()
	var approved: bool = result.get("approved", false)
	var feedback: String = result.get("feedback", "")
	if approved:
		NotificationManager.notify_warrant("Warrant approved! %s" % feedback)
		UIHelper.confirmation_flash("Warrant Approved", self, UIColors.ACCENT_PROCESSED)
	else:
		NotificationManager.notify_warrant("Warrant denied. %s" % feedback)
		UIHelper.confirmation_flash("Warrant Denied", self, UIColors.ACCENT_CRITICAL)
	_refresh()
