## EvidenceDetail.gd
## Full-screen evidence examination view with metadata, relationships,
## pinning, and comparison features.
## Phase 5: Detailed evidence inspection screen.
extends Control


@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var pin_button: Button = %PinButton
@onready var evidence_image: TextureRect = %EvidenceImage
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var info_grid: GridContainer = %InfoGrid
@onready var tags_container: HFlowContainer = %TagsContainer
@onready var related_persons_list: VBoxContainer = %RelatedPersonsList
@onready var related_statements_list: VBoxContainer = %RelatedStatementsList
@onready var legal_categories_list: VBoxContainer = %LegalCategoriesList
@onready var compare_button: Button = %CompareButton
@onready var comparison_panel: PanelContainer = %ComparisonPanel
@onready var comparison_list: VBoxContainer = %ComparisonList
@onready var send_to_board_button: Button = %SendToBoardButton

var _evidence_id: String = ""
var _comparing: bool = false


func _ready() -> void:
	_evidence_id = ScreenManager.navigation_data.get("evidence_id", "")

	back_button.pressed.connect(_on_back_pressed)
	pin_button.pressed.connect(_on_pin_pressed)
	compare_button.pressed.connect(_on_compare_pressed)
	send_to_board_button.pressed.connect(_on_send_to_board_pressed)

	if _evidence_id.is_empty():
		title_label.text = "No Evidence Selected"
		return

	_populate_detail()


## Populates the full evidence detail view.
func _populate_detail() -> void:
	var ev: EvidenceData = CaseManager.get_evidence(_evidence_id)
	if ev == null:
		title_label.text = "Evidence Not Found"
		return

	title_label.text = ev.name
	_update_pin_button()

	# Description
	description_label.text = ev.description

	# Info grid (key-value pairs)
	_populate_info_grid(ev)

	# Tags
	_populate_tags(ev)

	# Related persons
	_populate_related_persons(ev)

	# Related statements
	_populate_related_statements(ev)

	# Legal categories
	_populate_legal_categories(ev)

	# Image placeholder
	evidence_image.visible = false


func _populate_info_grid(ev: EvidenceData) -> void:
	for child: Node in info_grid.get_children():
		child.queue_free()

	_add_info_row("Type", _get_type_label(ev.type))
	_add_info_row("Location", _get_location_name(ev.location_found))
	_add_info_row("Discovery Method", _get_discovery_method_label(ev.discovery_method))
	_add_info_row("Importance", _get_importance_label(ev.importance_level))
	_add_info_row("Weight", "%.0f%%" % (ev.weight * 100.0))

	if ev.requires_lab_analysis:
		_add_info_row("Lab Status", _get_lab_status_label(ev.lab_status))
		if not ev.lab_result_text.is_empty():
			_add_info_row("Lab Result", ev.lab_result_text)


func _add_info_row(key: String, value: String) -> void:
	var key_label: Label = Label.new()
	key_label.text = key + ":"
	key_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.55))
	info_grid.add_child(key_label)

	var value_label: Label = Label.new()
	value_label.text = value
	info_grid.add_child(value_label)


func _populate_tags(ev: EvidenceData) -> void:
	for child: Node in tags_container.get_children():
		child.queue_free()

	if ev.tags.is_empty():
		return

	for tag: String in ev.tags:
		var tag_label: Label = Label.new()
		tag_label.text = "  %s  " % tag
		tag_label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.65))
		tags_container.add_child(tag_label)


func _populate_related_persons(ev: EvidenceData) -> void:
	for child: Node in related_persons_list.get_children():
		child.queue_free()

	if ev.related_persons.is_empty():
		var none_label: Label = Label.new()
		none_label.text = "None"
		none_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		related_persons_list.add_child(none_label)
		return

	for pid: String in ev.related_persons:
		var person: PersonData = CaseManager.get_person(pid)
		var person_label: Label = Label.new()
		person_label.text = "• %s" % (person.name if person else pid)
		related_persons_list.add_child(person_label)


func _populate_related_statements(ev: EvidenceData) -> void:
	for child: Node in related_statements_list.get_children():
		child.queue_free()

	# Find statements that reference this evidence
	var all_stmts: Array[StatementData] = CaseManager.get_all_statements()
	var related: Array[StatementData] = []
	for stmt: StatementData in all_stmts:
		if _evidence_id in stmt.related_evidence or _evidence_id in stmt.contradicting_evidence:
			related.append(stmt)

	if related.is_empty():
		var none_label: Label = Label.new()
		none_label.text = "None"
		none_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		related_statements_list.add_child(none_label)
		return

	for stmt: StatementData in related:
		var person: PersonData = CaseManager.get_person(stmt.person_id)
		var stmt_label: RichTextLabel = RichTextLabel.new()
		stmt_label.bbcode_enabled = true
		stmt_label.fit_content = true
		var person_name: String = person.name if person else stmt.person_id
		stmt_label.text = '• [b]%s[/b]: "%s"' % [person_name, stmt.text]
		related_statements_list.add_child(stmt_label)


func _populate_legal_categories(ev: EvidenceData) -> void:
	for child: Node in legal_categories_list.get_children():
		child.queue_free()

	if ev.legal_categories.is_empty():
		var none_label: Label = Label.new()
		none_label.text = "None"
		none_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		legal_categories_list.add_child(none_label)
		return

	for cat_val: int in ev.legal_categories:
		var cat_label: Label = Label.new()
		cat_label.text = "• %s" % _get_legal_category_label(cat_val)
		legal_categories_list.add_child(cat_label)


func _update_pin_button() -> void:
	if EvidenceManager.is_pinned(_evidence_id):
		pin_button.text = "📌 Unpin"
	else:
		pin_button.text = "📌 Pin"


func _on_pin_pressed() -> void:
	if EvidenceManager.is_pinned(_evidence_id):
		EvidenceManager.unpin_evidence(_evidence_id)
	else:
		EvidenceManager.pin_evidence(_evidence_id)
	_update_pin_button()


func _on_compare_pressed() -> void:
	_comparing = not _comparing
	comparison_panel.visible = _comparing
	if _comparing:
		_populate_comparison_targets()


func _populate_comparison_targets() -> void:
	for child: Node in comparison_list.get_children():
		child.queue_free()

	var targets: Array[String] = EvidenceManager.get_valid_comparisons_for(_evidence_id)

	if targets.is_empty():
		var none_label: Label = Label.new()
		none_label.text = "No valid comparisons available."
		none_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		comparison_list.add_child(none_label)
		return

	for target_id: String in targets:
		var ev: EvidenceData = CaseManager.get_evidence(target_id)
		if ev == null:
			continue
		var btn: Button = Button.new()
		btn.text = "Compare with: %s" % ev.name
		btn.pressed.connect(_on_compare_with.bind(target_id))
		comparison_list.add_child(btn)


func _on_compare_with(other_id: String) -> void:
	var insight: InsightData = EvidenceManager.compare_evidence(_evidence_id, other_id)
	for child: Node in comparison_list.get_children():
		child.queue_free()

	if insight != null:
		var result_label: RichTextLabel = RichTextLabel.new()
		result_label.bbcode_enabled = true
		result_label.fit_content = true
		result_label.text = "[b]💡 New Insight![/b]\n%s" % insight.description
		comparison_list.add_child(result_label)
	else:
		var result_label: Label = Label.new()
		result_label.text = "No new insights from this comparison."
		result_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		comparison_list.add_child(result_label)


func _on_back_pressed() -> void:
	ScreenManager.navigate_back()


## Sends this evidence to the detective board as a new node.
func _on_send_to_board_pressed() -> void:
	BoardManager.send_to_board("evidence", _evidence_id)
	send_to_board_button.text = "✓ Sent to Board"
	send_to_board_button.disabled = true


# --- Label Helpers --- #

func _get_type_label(type: Enums.EvidenceType) -> String:
	match type:
		Enums.EvidenceType.FORENSIC: return "Forensic"
		Enums.EvidenceType.DOCUMENT: return "Document"
		Enums.EvidenceType.PHOTO: return "Photo"
		Enums.EvidenceType.RECORDING: return "Recording"
		Enums.EvidenceType.FINANCIAL: return "Financial"
		Enums.EvidenceType.DIGITAL: return "Digital"
		Enums.EvidenceType.OBJECT: return "Object"
	return "Unknown"


func _get_location_name(location_id: String) -> String:
	if location_id.is_empty():
		return "Unknown"
	var loc: LocationData = CaseManager.get_location(location_id)
	return loc.name if loc else location_id


func _get_discovery_method_label(method: Enums.DiscoveryMethod) -> String:
	match method:
		Enums.DiscoveryMethod.VISUAL: return "Visual Inspection"
		Enums.DiscoveryMethod.TOOL: return "Tool Analysis"
		Enums.DiscoveryMethod.COMPARISON: return "Evidence Comparison"
		Enums.DiscoveryMethod.LAB: return "Lab Analysis"
		Enums.DiscoveryMethod.SURVEILLANCE: return "Surveillance"
	return "Unknown"


func _get_importance_label(level: Enums.ImportanceLevel) -> String:
	match level:
		Enums.ImportanceLevel.CRITICAL: return "Critical"
		Enums.ImportanceLevel.SUPPORTING: return "Supporting"
		Enums.ImportanceLevel.OPTIONAL: return "Optional"
	return "Unknown"


func _get_lab_status_label(status: Enums.LabStatus) -> String:
	match status:
		Enums.LabStatus.NOT_SUBMITTED: return "Not Submitted"
		Enums.LabStatus.PROCESSING: return "Processing..."
		Enums.LabStatus.COMPLETED: return "Complete"
	return "Unknown"


func _get_legal_category_label(cat: int) -> String:
	match cat:
		Enums.LegalCategory.PRESENCE: return "Presence"
		Enums.LegalCategory.MOTIVE: return "Motive"
		Enums.LegalCategory.OPPORTUNITY: return "Opportunity"
		Enums.LegalCategory.CONNECTION: return "Connection"
	return "Unknown"
