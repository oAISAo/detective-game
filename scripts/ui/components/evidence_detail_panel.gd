## EvidenceDetailPanel
## Coordinator for the evidence detail right panel.
## Attaches to the RightVBox node in evidence_archive.tscn.
## Owns ValueSection, LabSection, NotesSection, and StatementsPanel sub-components.
class_name EvidenceDetailPanel
extends VBoxContainer


const EvidenceValueSectionScript := preload("res://scripts/ui/components/evidence_value_section.gd")
const _WRAPPING_LINK_FULL_TEXT_META := "wrapping_link_full_text"


signal pin_toggled(evidence_id: String)
signal evidence_requested(evidence_id: String)

@onready var _placeholder_title: Label = %PlaceholderTitle
@onready var _detail_title: Label = %DetailTitle
@onready var _pin_button: Button = %PinButton
@onready var _send_to_board_button: Button = %SendToBoardButton
@onready var _compare_button: Button = %CompareButton
@onready var _header_badges_row: HBoxContainer = %HeaderBadgesRow
@onready var _detail_panel: VBoxContainer = %DetailPanel
@onready var _column1_scroll: ScrollContainer = %Column1Scroll
@onready var _main_scroll: ScrollContainer = %MainScroll
@onready var _evidence_image: TextureRect = %EvidenceImage
@onready var _description_label: RichTextLabel = %DescriptionLabel
@onready var _lab_anchor: VBoxContainer = %LabSectionAnchor
@onready var _weight_anchor: VBoxContainer = %WeightSectionAnchor
@onready var _info_grid: GridContainer = %InfoGrid
@onready var _related_persons_list: VBoxContainer = %RelatedPersonsList
@onready var _legal_categories_list: VBoxContainer = %LegalCategoriesList
@onready var _comparison_panel: PanelContainer = %ComparisonPanel
@onready var _comparison_list: VBoxContainer = %ComparisonList
@onready var _related_statements_list: VBoxContainer = %RelatedStatementsList
@onready var _notes_anchor: VBoxContainer = %NotesSectionAnchor

var _selected_id: String = ""
var _comparing: bool = false
var _handwriting_font: Font = null
var _value_section: VBoxContainer = null
var _lab_section: EvidenceLabSection = null
var _notes_section: EvidenceNotesSection = null
var _statements_panel: EvidenceStatementsPanel = null

var _on_ev_pinned_cb: Callable
var _on_ev_unpinned_cb: Callable
var _on_ev_sent_to_board_cb: Callable
var _on_state_loaded_cb: Callable


func _ready() -> void:
	_main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_column1_scroll.get_v_scroll_bar().modulate = Color.TRANSPARENT
	_main_scroll.get_v_scroll_bar().modulate = Color.TRANSPARENT
	%RelationshipsScroll.get_v_scroll_bar().modulate = Color.TRANSPARENT

	_evidence_image.resized.connect(_sync_evidence_image_square)

	_pin_button.pressed.connect(_on_pin_pressed)
	_compare_button.pressed.connect(_on_compare_pressed)
	_send_to_board_button.pressed.connect(_on_send_to_board_pressed)

	_on_ev_pinned_cb = func(_id: String) -> void:
		_update_pin_button()
	_on_ev_unpinned_cb = func(_id: String) -> void:
		_update_pin_button()
	_on_ev_sent_to_board_cb = func(ev_id: String) -> void:
		if ev_id == _selected_id:
			_update_send_to_board_button()
	_on_state_loaded_cb = func() -> void:
		clear()

	EvidenceManager.evidence_pinned.connect(_on_ev_pinned_cb)
	EvidenceManager.evidence_unpinned.connect(_on_ev_unpinned_cb)
	EvidenceManager.evidence_sent_to_board.connect(_on_ev_sent_to_board_cb)
	EvidenceManager.state_loaded.connect(_on_state_loaded_cb)


func _exit_tree() -> void:
	UIHelper.safe_disconnect(EvidenceManager.evidence_pinned, _on_ev_pinned_cb)
	UIHelper.safe_disconnect(EvidenceManager.evidence_unpinned, _on_ev_unpinned_cb)
	UIHelper.safe_disconnect(EvidenceManager.evidence_sent_to_board, _on_ev_sent_to_board_cb)
	UIHelper.safe_disconnect(EvidenceManager.state_loaded, _on_state_loaded_cb)


## Called once by evidence_archive._ready() after this node's _ready() has run.
## Creates owned sub-components and wires their signals.
func setup(handwriting_font: Font) -> void:
	_handwriting_font = handwriting_font

	_value_section = EvidenceValueSectionScript.new()
	_weight_anchor.add_child(_value_section)

	_lab_section = EvidenceLabSection.new()
	_lab_anchor.add_child(_lab_section)
	_lab_section.lab_submitted.connect(_on_lab_submitted)
	_lab_section.output_evidence_requested.connect(_on_output_evidence_requested)

	_notes_section = EvidenceNotesSection.new()
	_notes_anchor.add_child(_notes_section)

	_statements_panel = EvidenceStatementsPanel.new()
	_related_statements_list.add_child(_statements_panel)
	_statements_panel.setup(_handwriting_font)

	clear()


func show_evidence(evidence_id: String) -> void:
	var ev: EvidenceData = CaseManager.get_evidence(evidence_id)
	if ev == null:
		clear()
		return

	_comparing = false
	_comparison_panel.visible = false
	_selected_id = evidence_id
	EvidenceManager.mark_reviewed(evidence_id)

	_placeholder_title.visible = false
	_detail_title.visible = true
	_pin_button.visible = true
	_compare_button.visible = true
	_send_to_board_button.visible = true
	_detail_panel.visible = true

	_detail_title.text = ev.name
	_populate_header_badges(ev)
	_update_pin_button()
	_update_send_to_board_button()

	_description_label.text = ev.description
	_populate_info_grid(ev)
	_lab_section.populate(evidence_id)
	_value_section.populate(ev)
	_populate_related_persons(ev)
	_statements_panel.set_evidence(evidence_id)
	_populate_legal_categories(ev)
	_notes_section.populate(evidence_id, _handwriting_font)

	var image_path: String = ev.image
	if image_path.is_empty():
		image_path = "res://assets/evidence_images/%s.png" % ev.id
	_evidence_image.texture = AssetFallback.get_texture(image_path)
	_evidence_image.visible = true
	_sync_evidence_image_square()


func clear() -> void:
	_placeholder_title.visible = true
	_detail_title.visible = false
	_pin_button.visible = false
	_compare_button.visible = false
	_send_to_board_button.visible = false
	_header_badges_row.visible = false
	UIHelper.clear_children(_header_badges_row)
	_evidence_image.visible = false
	_evidence_image.custom_minimum_size = Vector2.ZERO
	_comparison_panel.visible = false
	_detail_panel.visible = false
	_description_label.text = ""
	_selected_id = ""
	_comparing = false


func get_selected_id() -> String:
	return _selected_id


# --- Private: sections ---

func _populate_header_badges(ev: EvidenceData) -> void:
	UIHelper.clear_children(_header_badges_row)
	_header_badges_row.add_child(
		UIHelper.make_badge_pill(
			UIHelper.get_importance_label(ev.importance_level),
			UIHelper.get_importance_badge_color(ev.importance_level)
		)
	)
	_header_badges_row.add_child(
		UIHelper.make_badge_pill(UIHelper.get_evidence_type_label(ev.type), UIColors.TEXT_HIGHLIGHTED)
	)
	for cat_val: int in ev.legal_categories:
		_header_badges_row.add_child(
			UIHelper.make_badge_pill(UIHelper.get_legal_category_label(cat_val), UIColors.GREEN)
		)
	_header_badges_row.visible = true


func _populate_info_grid(ev: EvidenceData) -> void:
	UIHelper.clear_children(_info_grid)
	_add_info_row("Type", UIHelper.get_evidence_type_label(ev.type))
	_add_info_row("Location", UIHelper.get_location_name(ev.location_found))
	_add_info_row("Discovery", UIHelper.get_discovery_method_label(ev.discovery_method))
	_populate_lineage_rows(ev)
	_add_info_row("Day Found", "Day %d" % GameManager.get_evidence_discovery_day(ev.id))
	_add_info_row("Case Relevance", UIHelper.get_importance_label(ev.importance_level))

	var lab_requests: Array[LabRequestData] = CaseManager.get_lab_requests_for_evidence(ev.id)
	if not ev.lab_result_text.is_empty():
		_add_info_row("Lab Result", ev.lab_result_text)
	elif not lab_requests.is_empty():
		_add_info_row("Lab Status", UIHelper.get_lab_status_label(ev.lab_status))


func _populate_lineage_rows(ev: EvidenceData) -> void:
	var parent_ev: EvidenceData = CaseManager.get_parent_evidence(ev.id)
	if parent_ev != null:
		_add_info_control_row(
			"Derived From",
			_build_lineage_value(parent_ev, GameManager.has_evidence(parent_ev.id))
		)


func _add_info_row(key: String, value: String) -> void:
	_info_grid.add_child(_make_info_key_label(key))
	_info_grid.add_child(_make_info_value_label(value))


func _add_info_control_row(key: String, value_control: Control) -> void:
	_info_grid.add_child(_make_info_key_label(key))
	_info_grid.add_child(_prepare_info_value_control(value_control))


func _make_info_key_label(key: String) -> Label:
	var key_label := Label.new()
	key_label.text = key + ":"
	key_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	key_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	key_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	return key_label


func _make_info_value_label(value: String) -> Label:
	var value_label := Label.new()
	value_label.text = value
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	return value_label


func _prepare_info_value_control(value_control: Control) -> Control:
	value_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return value_control


func _build_lineage_value(target_ev: EvidenceData, is_navigable: bool) -> Control:
	if is_navigable:
		var target_id: String = target_ev.id
		return _make_wrapping_link_button(
			target_ev.name,
			func() -> void: evidence_requested.emit(target_id),
			_get_info_value_wrap_width
		)

	return _make_info_value_label(target_ev.name)


func _make_wrapping_link_button(
	text: String,
	pressed_action: Callable,
	wrap_width_provider: Callable = Callable()
) -> LinkButton:
	var link_button := LinkButton.new()
	link_button.text = text
	link_button.underline = LinkButton.UNDERLINE_MODE_NEVER
	link_button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	link_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	link_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	link_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	link_button.set_meta(_WRAPPING_LINK_FULL_TEXT_META, text)
	link_button.resized.connect(_refresh_wrapping_link_text.bind(link_button, wrap_width_provider))
	if wrap_width_provider.is_valid():
		_info_grid.resized.connect(_refresh_wrapping_link_text.bind(link_button, wrap_width_provider))
		_main_scroll.resized.connect(_refresh_wrapping_link_text.bind(link_button, wrap_width_provider))
	link_button.pressed.connect(pressed_action)
	_refresh_wrapping_link_text.call_deferred(link_button, wrap_width_provider)
	return link_button


func _refresh_wrapping_link_text(
	link_button: LinkButton,
	wrap_width_provider: Callable = Callable()
) -> void:
	if link_button == null or not is_instance_valid(link_button):
		return

	var full_text: String = str(link_button.get_meta(_WRAPPING_LINK_FULL_TEXT_META, link_button.text))
	var available_width: float = _get_wrapping_link_available_width(link_button, wrap_width_provider)
	if available_width <= 0.0:
		link_button.text = full_text
		return

	var font: Font = link_button.get_theme_font("font")
	var font_size: int = link_button.get_theme_font_size("font_size")
	var wrapped_text: String = _wrap_text_to_width(full_text, font, font_size, available_width)
	if link_button.text != wrapped_text:
		link_button.text = wrapped_text


func _get_wrapping_link_available_width(
	link_button: LinkButton,
	wrap_width_provider: Callable
) -> float:
	if wrap_width_provider.is_valid():
		var provided_width: Variant = wrap_width_provider.call()
		if provided_width is float or provided_width is int:
			return max(float(provided_width), 0.0)

	return max(link_button.size.x, link_button.custom_minimum_size.x)


func _get_info_value_wrap_width() -> float:
	var viewport_width: float = _main_scroll.size.x
	if viewport_width <= 0.0:
		viewport_width = _info_grid.size.x
	if viewport_width <= 0.0:
		return 0.0

	var key_column_width: float = 0.0
	for child_idx: int in range(0, _info_grid.get_child_count(), 2):
		var key_control: Control = _info_grid.get_child(child_idx) as Control
		if key_control == null:
			continue
		key_column_width = max(key_column_width, key_control.get_combined_minimum_size().x)

	var h_separation: float = _info_grid.get_theme_constant("h_separation")
	return max(viewport_width - key_column_width - h_separation, 0.0)


func _wrap_text_to_width(text: String, font: Font, font_size: int, max_width: float) -> String:
	if font == null or text.is_empty() or max_width <= 0.0:
		return text
	if font_size <= 0:
		font_size = 16

	var wrapped_source_lines: Array[String] = []
	for source_line: String in text.split("\n", false):
		wrapped_source_lines.append(_wrap_single_line_to_width(source_line, font, font_size, max_width))
	return "\n".join(wrapped_source_lines)


func _wrap_single_line_to_width(line: String, font: Font, font_size: int, max_width: float) -> String:
	if line.is_empty():
		return ""

	var words: PackedStringArray = line.split(" ", false)
	if words.is_empty():
		return line

	var wrapped_lines: Array[String] = []
	var current_line: String = words[0]
	for idx: int in range(1, words.size()):
		var candidate: String = "%s %s" % [current_line, words[idx]]
		if _measure_text_width(font, font_size, candidate) <= max_width:
			current_line = candidate
			continue
		wrapped_lines.append(current_line)
		current_line = words[idx]

	wrapped_lines.append(current_line)
	return "\n".join(wrapped_lines)


func _measure_text_width(font: Font, font_size: int, text: String) -> float:
	if font == null or text.is_empty():
		return 0.0
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _build_derived_children_list(children: Array[EvidenceData]) -> VBoxContainer:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	for child_ev: EvidenceData in children:
		var child_id: String = child_ev.id
		list.add_child(
			_make_wrapping_link_button(
				child_ev.name,
				func() -> void: evidence_requested.emit(child_id)
			)
		)
	return list


func _populate_related_persons(ev: EvidenceData) -> void:
	UIHelper.clear_children(_related_persons_list)

	if ev.related_persons.is_empty():
		var none_label := Label.new()
		none_label.text = "No related persons yet."
		none_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		none_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_related_persons_list.add_child(none_label)
		return

	for pid: String in ev.related_persons:
		var person: PersonData = CaseManager.get_person(pid)
		var person_label := Label.new()
		person_label.text = "\u2022 %s" % (person.name if person else pid)
		person_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		person_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_related_persons_list.add_child(person_label)


func _populate_legal_categories(ev: EvidenceData) -> void:
	UIHelper.clear_children(_legal_categories_list)

	if ev.legal_categories.is_empty():
		var none_label := Label.new()
		none_label.text = "None"
		none_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		_legal_categories_list.add_child(none_label)
		return

	for cat_val: int in ev.legal_categories:
		var cat_label := Label.new()
		cat_label.text = "\u2022 %s" % UIHelper.get_legal_category_label(cat_val)
		cat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_legal_categories_list.add_child(cat_label)


func _populate_comparison_targets() -> void:
	UIHelper.clear_children(_comparison_list)
	var targets: Array[String] = EvidenceManager.get_valid_comparisons_for(_selected_id)

	if targets.is_empty():
		var none_label := Label.new()
		none_label.text = "No valid comparisons available."
		none_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		_comparison_list.add_child(none_label)
		return

	for target_id: String in targets:
		var ev: EvidenceData = CaseManager.get_evidence(target_id)
		if ev == null:
			continue
		var btn := Button.new()
		btn.text = "Compare with: %s" % ev.name
		btn.pressed.connect(_on_compare_with.bind(target_id))
		_comparison_list.add_child(btn)


# --- Private: button state ---

func _update_pin_button() -> void:
	if _selected_id.is_empty():
		return
	_pin_button.text = "Unpin" if EvidenceManager.is_pinned(_selected_id) else "Pin"


func _update_send_to_board_button() -> void:
	if _selected_id.is_empty():
		return
	if EvidenceManager.is_sent_to_board(_selected_id):
		_send_to_board_button.text = "View on Board \u2197"
	else:
		_send_to_board_button.text = "Send to Board"
	_send_to_board_button.disabled = false


func _sync_evidence_image_square(image_width: float = -1.0) -> void:
	if image_width <= 0.0:
		image_width = _evidence_image.size.x
	if image_width <= 0.0:
		return
	var minimum_size: Vector2 = _evidence_image.custom_minimum_size
	if is_equal_approx(minimum_size.y, image_width):
		return
	minimum_size.y = image_width
	_evidence_image.custom_minimum_size = minimum_size


# --- Private: callbacks ---

func _on_pin_pressed() -> void:
	if _selected_id.is_empty():
		return
	if EvidenceManager.is_pinned(_selected_id):
		EvidenceManager.unpin_evidence(_selected_id)
	else:
		EvidenceManager.pin_evidence(_selected_id)
	_update_pin_button()
	pin_toggled.emit(_selected_id)


func _on_compare_pressed() -> void:
	if _selected_id.is_empty():
		return
	_comparing = not _comparing
	_comparison_panel.visible = _comparing
	if _comparing:
		_populate_comparison_targets()


func _on_compare_with(other_id: String) -> void:
	var insight: InsightData = EvidenceManager.compare_evidence(_selected_id, other_id)
	UIHelper.clear_children(_comparison_list)

	if insight != null:
		var result_label := RichTextLabel.new()
		result_label.bbcode_enabled = true
		result_label.fit_content = true
		result_label.text = "[b]💡 New Insight![/b]\n%s" % insight.description
		_comparison_list.add_child(result_label)
	else:
		var result_label := Label.new()
		result_label.text = "No new insights from this comparison."
		result_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		_comparison_list.add_child(result_label)


func _on_send_to_board_pressed() -> void:
	if _selected_id.is_empty():
		return
	if EvidenceManager.is_sent_to_board(_selected_id):
		ScreenManager.navigate_to("detective_board")
		return
	BoardManager.send_to_board("evidence", _selected_id)
	EvidenceManager.mark_sent_to_board(_selected_id)
	UIHelper.confirmation_flash("Added to Board", self, UIColors.BLUE)
	_update_send_to_board_button()


func _on_lab_submitted() -> void:
	if _selected_id.is_empty():
		return
	_lab_section.populate(_selected_id)
	var ev: EvidenceData = CaseManager.get_evidence(_selected_id)
	if ev != null:
		_populate_info_grid(ev)


func _on_output_evidence_requested(output_id: String) -> void:
	evidence_requested.emit(output_id)
