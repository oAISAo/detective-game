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

	var warrant_mgr: Node = get_node_or_null("/root/WarrantManager")
	if warrant_mgr == null:
		no_warrants_label.visible = true
		no_warrants_label.text = "Warrant system not available."
		return

	var approved: Array[Dictionary] = warrant_mgr.get_approved_warrants()
	var denied: Array[Dictionary] = warrant_mgr.get_denied_warrants()
	var total: int = approved.size() + denied.size()

	warrant_count_label.text = "%d approved" % approved.size()
	no_warrants_label.visible = total == 0

	# Show approved warrants
	if not approved.is_empty():
		_add_section_header("Approved Warrants")
		for w: Dictionary in approved:
			_add_warrant_card(w, true)

	# Show denied warrants
	if not denied.is_empty():
		_add_section_header("Denied Requests")
		for w: Dictionary in denied:
			_add_warrant_card(w, false)

	# Show arrest status
	_update_arrest_section(warrant_mgr)


func _clear_warrant_list() -> void:
	for child: Node in warrant_list.get_children():
		child.queue_free()
	for child: Node in arrest_section.get_children():
		child.queue_free()


func _add_section_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.65))
	warrant_list.add_child(label)


func _add_warrant_card(w: Dictionary, is_approved: bool) -> void:
	var card := PanelContainer.new()
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
		status.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	else:
		var feedback: String = w.get("feedback", "Insufficient evidence.")
		status.text = "Denied — %s" % feedback
		status.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	status.add_theme_font_size_override("font_size", 14)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(status)

	# Categories provided
	var cats: Array = w.get("categories_provided", [])
	if not cats.is_empty():
		var cat_label := Label.new()
		var cat_names: Array[String] = []
		for cat: int in cats:
			cat_names.append(_get_category_name(cat))
		cat_label.text = "Categories: %s" % ", ".join(cat_names)
		cat_label.add_theme_font_size_override("font_size", 13)
		cat_label.add_theme_color_override("font_color", Color(0.55, 0.52, 0.48))
		vbox.add_child(cat_label)

	warrant_list.add_child(card)


func _update_arrest_section(warrant_mgr: Node) -> void:
	var arrested: Array[String] = warrant_mgr.get_arrested_suspects()
	if arrested.is_empty():
		return

	var header := Label.new()
	header.text = "Arrested Suspects"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	arrest_section.add_child(header)

	for person_id: String in arrested:
		var person: PersonData = CaseManager.get_person(person_id)
		var name_text: String = person.name if person else person_id
		var label := Label.new()
		label.text = "  %s — In custody" % name_text
		label.add_theme_font_size_override("font_size", 15)
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


func _get_category_name(cat: int) -> String:
	match cat:
		Enums.LegalCategory.PRESENCE:
			return "Presence"
		Enums.LegalCategory.MOTIVE:
			return "Motive"
		Enums.LegalCategory.OPPORTUNITY:
			return "Opportunity"
		Enums.LegalCategory.CONNECTION:
			return "Connection"
	return "Unknown"
