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
var _lab_section: VBoxContainer = null


func _ready() -> void:
	_evidence_id = ScreenManager.navigation_data.get("evidence_id", "")
	UIHelper.apply_back_button_icon(back_button, "Back")

	back_button.pressed.connect(_on_back_pressed)
	pin_button.pressed.connect(_on_pin_pressed)
	compare_button.pressed.connect(_on_compare_pressed)
	send_to_board_button.pressed.connect(_on_send_to_board_pressed)

	if _evidence_id.is_empty():
		title_label.text = "No Evidence Selected"
		pin_button.visible = false
		compare_button.visible = false
		send_to_board_button.visible = false
		evidence_image.visible = false
		comparison_panel.visible = false
		description_label.text = ""
		return

	_populate_detail()


## Populates the full evidence detail view.
func _populate_detail() -> void:
	var ev: EvidenceData = CaseManager.get_evidence(_evidence_id)
	if ev == null:
		title_label.text = "Evidence Not Found"
		pin_button.visible = false
		compare_button.visible = false
		send_to_board_button.visible = false
		evidence_image.visible = false
		comparison_panel.visible = false
		description_label.text = ""
		return

	title_label.text = ev.name
	_update_pin_button()

	# Description
	description_label.text = ev.description

	# Info grid (key-value pairs)
	_populate_info_grid(ev)

	# Lab submission section
	_populate_lab_section(ev)

	# Tags
	_populate_tags(ev)

	# Related persons
	_populate_related_persons(ev)

	# Related statements
	_populate_related_statements(ev)

	# Legal categories
	_populate_legal_categories(ev)

	# Evidence image via AssetFallback
	var image_path: String = ev.image
	if image_path.is_empty():
		image_path = "res://assets/evidence_images/%s.png" % ev.id
	evidence_image.texture = AssetFallback.get_texture(image_path)
	evidence_image.visible = true


func _populate_info_grid(ev: EvidenceData) -> void:
	for child: Node in info_grid.get_children():
		info_grid.remove_child(child)
		child.queue_free()

	_add_info_row("Type", UIHelper.get_evidence_type_label(ev.type))
	_add_info_row("Location", UIHelper.get_location_name(ev.location_found))
	_add_info_row("Discovery Method", _get_discovery_method_label(ev.discovery_method))
	_add_info_row("Importance", _get_importance_label(ev.importance_level))
	_add_info_row("Weight", "%.0f%%" % (ev.weight * 100.0))

	if ev.requires_lab_analysis:
		if not ev.lab_result_text.is_empty():
			_add_info_row("Lab Result", ev.lab_result_text)
		else:
			_add_info_row("Lab Status", _get_lab_status_label(ev.lab_status))

	# Also show lab status for raw evidence that can be submitted
	if not ev.requires_lab_analysis and CaseManager.get_lab_request_for_evidence(ev.id) != null:
		_add_info_row("Lab Status", _get_lab_status_label(ev.lab_status))


func _add_info_row(key: String, value: String) -> void:
	var key_label: Label = Label.new()
	key_label.text = key + ":"
	key_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	key_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	info_grid.add_child(key_label)

	var value_label: Label = Label.new()
	value_label.text = value
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_grid.add_child(value_label)


func _populate_tags(ev: EvidenceData) -> void:
	for child: Node in tags_container.get_children():
		tags_container.remove_child(child)
		child.queue_free()

	if ev.tags.is_empty():
		return

	for tag: String in ev.tags:
		var tag_label: Label = Label.new()
		tag_label.text = "  %s  " % tag
		tag_label.add_theme_color_override("font_color", UIColors.TEXT_HIGHLIGHTED)
		tags_container.add_child(tag_label)


func _populate_related_persons(ev: EvidenceData) -> void:
	for child: Node in related_persons_list.get_children():
		related_persons_list.remove_child(child)
		child.queue_free()

	if ev.related_persons.is_empty():
		var none_label: Label = Label.new()
		none_label.text = "None"
		none_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		related_persons_list.add_child(none_label)
		return

	for pid: String in ev.related_persons:
		var person: PersonData = CaseManager.get_person(pid)
		var person_label: Label = Label.new()
		person_label.text = "• %s" % (person.name if person else pid)
		related_persons_list.add_child(person_label)


func _populate_related_statements(ev: EvidenceData) -> void:
	for child: Node in related_statements_list.get_children():
		related_statements_list.remove_child(child)
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
		none_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
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
		legal_categories_list.remove_child(child)
		child.queue_free()

	if ev.legal_categories.is_empty():
		var none_label: Label = Label.new()
		none_label.text = "None"
		none_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		legal_categories_list.add_child(none_label)
		return

	for cat_val: int in ev.legal_categories:
		var cat_label: Label = Label.new()
		cat_label.text = "• %s" % UIHelper.get_legal_category_label(cat_val)
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


## Populates the lab submission section for raw evidence that can be analyzed.
func _populate_lab_section(ev: EvidenceData) -> void:
	# Remove previous lab section if it exists
	if _lab_section != null:
		_lab_section.queue_free()
		_lab_section = null

	# Check if this evidence has a lab request template
	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(_evidence_id)
	if lab_req == null:
		return

	_lab_section = VBoxContainer.new()
	_lab_section.add_theme_constant_override("separation", 8)

	var header: Label = Label.new()
	header.text = "FORENSIC ANALYSIS"
	header.theme_type_variation = &"SectionHeader"
	_lab_section.add_child(header)

	var output_ev: EvidenceData = CaseManager.get_evidence(lab_req.output_evidence_id)
	var output_discovered: bool = GameManager.has_evidence(lab_req.output_evidence_id)
	var already_submitted: bool = LabManager.is_evidence_submitted(_evidence_id)

	if output_discovered:
		# Lab analysis complete — show result
		var status_label: Label = Label.new()
		status_label.text = "Lab analysis complete."
		status_label.add_theme_color_override("font_color", UIColors.GREEN)
		_lab_section.add_child(status_label)
		if output_ev:
			var result_label: Label = Label.new()
			result_label.text = "Result: %s" % output_ev.name
			result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lab_section.add_child(result_label)
	elif already_submitted:
		# Pending lab analysis
		var status_label: Label = Label.new()
		status_label.text = "Submitted to Lab — Results pending."
		status_label.add_theme_color_override("font_color", UIColors.AMBER)
		_lab_section.add_child(status_label)
	else:
		# Can be submitted
		var desc_label: Label = Label.new()
		desc_label.text = "This evidence can be submitted for forensic analysis."
		desc_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lab_section.add_child(desc_label)
		var submit_btn: Button = Button.new()
		submit_btn.text = "Submit to Lab"
		submit_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		submit_btn.pressed.connect(_on_submit_to_lab)
		_lab_section.add_child(submit_btn)

	# Insert lab section after the info grid (before tags)
	var info_section: Node = info_grid.get_parent()
	var main_content: Node = info_section.get_parent()
	var idx: int = info_section.get_index() + 1
	main_content.add_child(_lab_section)
	main_content.move_child(_lab_section, idx)


## Handles lab submission from the evidence detail screen.
func _on_submit_to_lab() -> void:
	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(_evidence_id)
	if lab_req == null:
		return

	var result: Dictionary = LabManager.submit_request(
		_evidence_id,
		lab_req.analysis_type,
		lab_req.output_evidence_id,
		1
	)

	if result.is_empty():
		NotificationManager.notify("Submission Failed", "Could not submit lab request.")
		return

	var ev: EvidenceData = CaseManager.get_evidence(_evidence_id)
	var ev_name: String = ev.name if ev else _evidence_id
	NotificationManager.notify_lab_result("%s submitted for %s." % [ev_name, lab_req.analysis_type])
	UIHelper.confirmation_flash("Submitted to Lab", self)
	_populate_detail()


func _populate_comparison_targets() -> void:
	for child: Node in comparison_list.get_children():
		comparison_list.remove_child(child)
		child.queue_free()

	var targets: Array[String] = EvidenceManager.get_valid_comparisons_for(_evidence_id)

	if targets.is_empty():
		var none_label: Label = Label.new()
		none_label.text = "No valid comparisons available."
		none_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
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
		comparison_list.remove_child(child)
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
		result_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		comparison_list.add_child(result_label)


func _on_back_pressed() -> void:
	ScreenManager.navigate_back()


## Sends this evidence to the detective board as a new node.
func _on_send_to_board_pressed() -> void:
	BoardManager.send_to_board("evidence", _evidence_id)
	send_to_board_button.text = "Sent to Board"
	send_to_board_button.disabled = true
	UIHelper.confirmation_flash("Added to Board", self, UIColors.BLUE)


# --- Label Helpers --- #

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
