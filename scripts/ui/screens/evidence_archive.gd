## EvidenceArchive.gd
## Screen for viewing and managing collected evidence with filtering,
## search, pinning, and testimony with contradiction highlighting.
## Merged with Evidence Detail view for a cohesive layout.
extends Control

const POLAROID_SCENE: PackedScene = preload("res://scenes/ui/components/evidence_polaroid.tscn")
const STATEMENTS_PANEL_SCRIPT = preload("res://scripts/ui/components/evidence_statements_panel.gd")
const _HANDWRITING_FONT_PATH: String = "res://assets/fonts/Caveat-Regular.ttf"

var _handwriting_font: Font = null

@onready var filter_option: OptionButton = %FilterOption
@onready var search_box: LineEdit = %SearchBox

# Left Panel
@onready var pinned_bar: HBoxContainer = %PinnedBar
@onready var evidence_grid: GridContainer = %EvidenceGrid

# Right Panel
@onready var detail_panel: VBoxContainer = %DetailPanel
@onready var placeholder_title: Label = %PlaceholderTitle
@onready var detail_title: Label = %DetailTitle
@onready var pin_button: Button = %PinButton
@onready var compare_button: Button = %CompareButton
@onready var send_to_board_button: Button = %SendToBoardButton

@onready var _header_badges_row: HBoxContainer = %HeaderBadgesRow
@onready var _detail_column1_scroll: ScrollContainer = %Column1Scroll
@onready var _detail_column1_content: VBoxContainer = %Column1Content
@onready var evidence_image: TextureRect = %EvidenceImage
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var info_grid: GridContainer = %InfoGrid

@onready var related_persons_list: VBoxContainer = %RelatedPersonsList
@onready var related_statements_list: VBoxContainer = %RelatedStatementsList
@onready var legal_categories_list: VBoxContainer = %LegalCategoriesList

@onready var comparison_panel: PanelContainer = %ComparisonPanel
@onready var comparison_list: VBoxContainer = %ComparisonList

var _selected_evidence_id: String = ""
var _comparing: bool = false
var _lab_section: VBoxContainer = null
var _weight_section: Node = null
var _notes_section: Node = null
var _statements_panel: Node = null
## Maps evidence_id → EvidencePolaroid card node for targeted badge refreshes.
var _card_nodes: Dictionary = {}  # evidence_id: String → EvidencePolaroid

# Stored callables for signal disconnection on exit
var _on_evidence_discovered_cb: Callable
var _on_evidence_pinned_cb: Callable
var _on_evidence_unpinned_cb: Callable
var _on_evidence_reviewed_cb: Callable
var _on_evidence_sent_to_board_cb: Callable


func _ready() -> void:
	$MarginContainer/VBoxContainer/MainColumns/LeftPanel/LeftVBox/EvidenceContent/CardScroll.get_v_scroll_bar().modulate = Color.TRANSPARENT
	_detail_column1_scroll.get_v_scroll_bar().modulate = Color.TRANSPARENT
	$MarginContainer/VBoxContainer/MainColumns/RightPanel/RightVBox/DetailPanel/DetailColumns/MainScroll.get_v_scroll_bar().modulate = Color.TRANSPARENT
	$MarginContainer/VBoxContainer/MainColumns/RightPanel/RightVBox/DetailPanel/DetailColumns/RelationshipsScroll.get_v_scroll_bar().modulate = Color.TRANSPARENT
	evidence_image.resized.connect(_sync_evidence_image_square)

	if ResourceLoader.exists(_HANDWRITING_FONT_PATH):
		_handwriting_font = load(_HANDWRITING_FONT_PATH) as Font
	else:
		push_warning("[EvidenceArchive] Handwriting font not found: %s" % _HANDWRITING_FONT_PATH)

	filter_option.item_selected.connect(_on_filter_changed)
	search_box.text_changed.connect(_on_search_changed)
	_add_search_icon()
	
	pin_button.pressed.connect(_on_pin_pressed)
	compare_button.pressed.connect(_on_compare_pressed)
	send_to_board_button.pressed.connect(_on_send_to_board_pressed)

	_setup_filter_options()
	_populate_pinned_bar()
	_populate_evidence_list()
	_clear_detail()

	_statements_panel = STATEMENTS_PANEL_SCRIPT.new()
	related_statements_list.add_child(_statements_panel)

	# Store callables so we can disconnect them in _exit_tree
	_on_evidence_discovered_cb = func(_id: String) -> void: _refresh()
	_on_evidence_pinned_cb = func(id: String) -> void: _populate_pinned_bar(); _update_pin_button(); _refresh_card_badges(id)
	_on_evidence_unpinned_cb = func(id: String) -> void: _populate_pinned_bar(); _update_pin_button(); _refresh_card_badges(id)
	_on_evidence_reviewed_cb = func(id: String) -> void: _refresh_card_badges(id)
	_on_evidence_sent_to_board_cb = func(ev_id: String) -> void:
		if ev_id == _selected_evidence_id:
			_update_send_to_board_button()

	# Connect to live updates
	GameManager.evidence_discovered.connect(_on_evidence_discovered_cb)
	EvidenceManager.evidence_pinned.connect(_on_evidence_pinned_cb)
	EvidenceManager.evidence_unpinned.connect(_on_evidence_unpinned_cb)
	EvidenceManager.evidence_reviewed.connect(_on_evidence_reviewed_cb)
	EvidenceManager.evidence_sent_to_board.connect(_on_evidence_sent_to_board_cb)
	EvidenceManager.state_loaded.connect(_refresh)
	
	# Check if navigated with an evidence id
	var nav_data: Dictionary = ScreenManager.navigation_data
	if nav_data.has("evidence_id"):
		_show_evidence_detail(nav_data["evidence_id"])


func _exit_tree() -> void:
	GameManager.evidence_discovered.disconnect(_on_evidence_discovered_cb)
	EvidenceManager.evidence_pinned.disconnect(_on_evidence_pinned_cb)
	EvidenceManager.evidence_unpinned.disconnect(_on_evidence_unpinned_cb)
	if EvidenceManager.evidence_reviewed.is_connected(_on_evidence_reviewed_cb):
		EvidenceManager.evidence_reviewed.disconnect(_on_evidence_reviewed_cb)
	if EvidenceManager.evidence_sent_to_board.is_connected(_on_evidence_sent_to_board_cb):
		EvidenceManager.evidence_sent_to_board.disconnect(_on_evidence_sent_to_board_cb)
	if EvidenceManager.state_loaded.is_connected(_refresh):
		EvidenceManager.state_loaded.disconnect(_refresh)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if search_box.has_focus() and not search_box.get_global_rect().has_point(event.global_position):
			search_box.release_focus()


## Adds a Material Symbols search icon as a left overlay inside the search input.
func _add_search_icon() -> void:
	var icon_font := FontVariation.new()
	icon_font.base_font = load("res://assets/fonts/MaterialSymbolsOutlined.ttf")
	icon_font.opentype_features = {"liga": 1, "calt": 1}

	var icon := Label.new()
	icon.text = "search"
	icon.add_theme_font_override("font", icon_font)
	icon.add_theme_font_size_override("font_size", 18)
	icon.add_theme_color_override("font_color", UIColors.TEXT_GREY)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	icon.custom_minimum_size = Vector2(36, 0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	search_box.add_child(icon)


## Configures the filter dropdown with all evidence types.
func _setup_filter_options() -> void:
	filter_option.clear()
	filter_option.add_item("All Types", 0)
	filter_option.add_item("Forensic", 1)
	filter_option.add_item("Document", 2)
	filter_option.add_item("Photo", 3)
	filter_option.add_item("Recording", 4)
	filter_option.add_item("Financial", 5)
	filter_option.add_item("Digital", 6)
	filter_option.add_item("Object", 7)


## Populates the evidence grid with card components.
func _populate_evidence_list() -> void:
	UIHelper.clear_children(evidence_grid)
	_card_nodes.clear()

	var items: Array[EvidenceData] = _get_filtered_evidence()

	if items.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No evidence found."
		empty_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		evidence_grid.add_child(empty_label)
		return

	for ev: EvidenceData in items:
		var card: EvidencePolaroid = POLAROID_SCENE.instantiate() as EvidencePolaroid
		evidence_grid.add_child(card)
		card.setup(ev, _handwriting_font)
		card.card_pressed.connect(_on_card_pressed)
		_card_nodes[ev.id] = card


## Refreshes badges on a single card without rebuilding or reordering the grid.
func _refresh_card_badges(evidence_id: String) -> void:
	var card: EvidencePolaroid = _card_nodes.get(evidence_id) as EvidencePolaroid
	if card != null and is_instance_valid(card):
		card.refresh_badges()

func _on_card_pressed(evidence_id: String) -> void:
	_show_evidence_detail(evidence_id)

## Returns the filtered and searched evidence list.
func _get_filtered_evidence() -> Array[EvidenceData]:
	var query: String = search_box.text.strip_edges()
	var type_idx: int = filter_option.selected

	var items: Array[EvidenceData]
	if query.is_empty():
		items = EvidenceManager.get_discovered_evidence_data()
	else:
		items = EvidenceManager.search_evidence(query)

	# Apply type filter if not "All Types"
	if type_idx > 0:
		var type_filter: Enums.EvidenceType = (type_idx - 1) as Enums.EvidenceType
		var filtered: Array[EvidenceData] = []
		for ev: EvidenceData in items:
			if ev.type == type_filter:
				filtered.append(ev)
		items = filtered

	return _sort_evidence(items)


## Sorts evidence for display in the grid.
## Order: unreviewed first → most recently discovered → most important.
func _sort_evidence(items: Array[EvidenceData]) -> Array[EvidenceData]:
	var result: Array[EvidenceData] = items.duplicate()
	result.sort_custom(func(a: EvidenceData, b: EvidenceData) -> bool:
		# Primary: unreviewed first (false < true)
		var a_reviewed: bool = EvidenceManager.is_reviewed(a.id)
		var b_reviewed: bool = EvidenceManager.is_reviewed(b.id)
		if a_reviewed != b_reviewed:
			return not a_reviewed  # unreviewed (false) sorts before reviewed (true)

		# Secondary: most recently discovered first
		var a_day: int = GameManager.get_evidence_discovery_day(a.id)
		var b_day: int = GameManager.get_evidence_discovery_day(b.id)
		if a_day != b_day:
			return a_day > b_day

		# Fallback: discovery order in discovered_evidence list (most recent = higher index)
		var a_idx: int = GameManager.discovered_evidence.find(a.id)
		var b_idx: int = GameManager.discovered_evidence.find(b.id)
		if a_idx != b_idx:
			return a_idx > b_idx

		# Tertiary: importance (CRITICAL=0 first, higher number = less important)
		return a.importance_level < b.importance_level
	)
	return result


## Populates the pinned evidence bar.
func _populate_pinned_bar() -> void:
	# Clear everything except the first child (the "PINNED" label)
	while pinned_bar.get_child_count() > 1:
		var child: Node = pinned_bar.get_child(pinned_bar.get_child_count() - 1)
		pinned_bar.remove_child(child)
		child.queue_free()

	var pinned: Array[String] = EvidenceManager.get_pinned_evidence()
	if pinned.is_empty():
		pinned_bar.visible = false
		return
	
	pinned_bar.visible = true

	for eid: String in pinned:
		var ev: EvidenceData = CaseManager.get_evidence(eid)
		if ev == null:
			continue
		var btn: Button = Button.new()
		btn.text = ev.name
		btn.flat = true
		btn.pressed.connect(_show_evidence_detail.bind(eid))
		pinned_bar.add_child(btn)


## Refreshes the current tab content.
func _refresh() -> void:
	_populate_evidence_list()
	_populate_pinned_bar()


# --- Details Panel --- #

func _clear_detail() -> void:
	placeholder_title.visible = true
	detail_title.visible = false
	pin_button.visible = false
	compare_button.visible = false
	send_to_board_button.visible = false
	_header_badges_row.visible = false
	UIHelper.clear_children(_header_badges_row)
	evidence_image.visible = false
	evidence_image.custom_minimum_size = Vector2.ZERO
	comparison_panel.visible = false
	detail_panel.visible = false
	description_label.text = ""
	_selected_evidence_id = ""


func _show_evidence_detail(evidence_id: String) -> void:
	var ev: EvidenceData = CaseManager.get_evidence(evidence_id)
	if ev == null:
		_clear_detail()
		return

	_selected_evidence_id = evidence_id
	EvidenceManager.mark_reviewed(evidence_id)
	
	placeholder_title.visible = false
	detail_title.visible = true
	pin_button.visible = true
	compare_button.visible = true
	send_to_board_button.visible = true
	detail_panel.visible = true
	
	detail_title.text = ev.name
	_populate_header_badges(ev)
	_update_pin_button()
	_update_send_to_board_button()

	# Description
	description_label.text = ev.description

	# Evidentiary weight bar (inserted in the first column below the description)
	_populate_weight_section(ev)

	# Info grid (key-value pairs)
	_populate_info_grid(ev)

	# Lab submission section
	_populate_lab_section()

	# Related persons
	_populate_related_persons(ev)

	# Related statements
	_populate_related_statements(ev)

	# Legal categories
	_populate_legal_categories(ev)

	# Player notes (appended at end of MainContent, below Compare section)
	_populate_notes_section(ev)

	# Evidence image via AssetFallback
	var image_path: String = ev.image
	if image_path.is_empty():
		image_path = "res://assets/evidence_images/%s.png" % ev.id
	evidence_image.texture = AssetFallback.get_texture(image_path)
	evidence_image.visible = true
	_sync_evidence_image_square()


func _sync_evidence_image_square(image_width: float = -1.0) -> void:
	if image_width <= 0.0:
		image_width = evidence_image.size.x
	if image_width <= 0.0:
		return
	var minimum_size: Vector2 = evidence_image.custom_minimum_size
	if is_equal_approx(minimum_size.y, image_width):
		return
	minimum_size.y = image_width
	evidence_image.custom_minimum_size = minimum_size


func _populate_info_grid(ev: EvidenceData) -> void:
	UIHelper.clear_children(info_grid)

	_add_info_row("Type", UIHelper.get_evidence_type_label(ev.type))
	_add_info_row("Location", UIHelper.get_location_name(ev.location_found))
	_add_info_row("Discovery", _get_discovery_method_label(ev.discovery_method))
	_add_info_row("Day Found", "Day %d" % GameManager.get_evidence_discovery_day(ev.id))
	_add_info_row("Importance", _get_importance_label(ev.importance_level))
	# weight rendered by _populate_weight_section() in the first column

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


func _populate_notes_section(ev: EvidenceData) -> void:
	if _notes_section != null:
		_notes_section.queue_free()
		_notes_section = null

	_notes_section = VBoxContainer.new()
	_notes_section.add_theme_constant_override("separation", 6)

	# Header row: "My Notes" label + collapse/expand toggle button.
	var header_row: HBoxContainer = HBoxContainer.new()
	var section_label: Label = Label.new()
	section_label.text = "My Notes"
	section_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	section_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	section_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(section_label)
	var toggle_btn: Button = Button.new()
	toggle_btn.flat = true
	toggle_btn.add_theme_color_override("font_color", UIColors.TEXT_GREY)
	header_row.add_child(toggle_btn)
	_notes_section.add_child(header_row)

	# TextEdit with handwriting font.
	var text_edit: TextEdit = TextEdit.new()
	text_edit.placeholder_text = "Your private notes about this evidence…"
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size.y = 80
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	if _handwriting_font != null:
		text_edit.add_theme_font_override("font", _handwriting_font)
	text_edit.add_theme_font_size_override("font_size", UIFonts.SIZE_BODY)
	text_edit.text = EvidenceManager.get_player_notes(ev.id)
	_notes_section.add_child(text_edit)

	# Start expanded only if the player already has notes for this item.
	var has_existing_notes: bool = not EvidenceManager.get_player_notes(ev.id).is_empty()
	text_edit.visible = has_existing_notes
	toggle_btn.text = "▼" if has_existing_notes else "▶"

	toggle_btn.pressed.connect(func() -> void:
		text_edit.visible = not text_edit.visible
		toggle_btn.text = "▼" if text_edit.visible else "▶"
		if text_edit.visible:
			text_edit.grab_focus())

	# Auto-save on every keystroke — no explicit save button required.
	text_edit.text_changed.connect(func() -> void:
		EvidenceManager.set_player_notes(ev.id, text_edit.text))

	# Append to the end of the first column.
	_detail_column1_content.add_child(_notes_section)


func _populate_related_persons(ev: EvidenceData) -> void:
	UIHelper.clear_children(related_persons_list)

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
	_statements_panel.set_evidence(ev.id)


func _populate_legal_categories(ev: EvidenceData) -> void:
	UIHelper.clear_children(legal_categories_list)

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


func _populate_weight_section(ev: EvidenceData) -> void:
	if _weight_section != null:
		_weight_section.queue_free()
		_weight_section = null

	var bar_color: Color = _get_weight_bar_color(ev)

	_weight_section = VBoxContainer.new()
	_weight_section.add_theme_constant_override("separation", 6)

	# Header row: label on left, percentage on right
	var header_row: HBoxContainer = HBoxContainer.new()
	var header_label: Label = Label.new()
	header_label.text = "Evidentiary Weight"
	header_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	header_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_label)
	var pct_label: Label = Label.new()
	pct_label.text = "%.0f%%" % (ev.weight * 100.0)
	pct_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	pct_label.add_theme_color_override("font_color", bar_color)
	header_row.add_child(pct_label)
	_weight_section.add_child(header_row)

	# Progress bar
	var bar: ProgressBar = ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = ev.weight
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size.y = 10
	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	fill_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.18)
	bg_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg_style)
	_weight_section.add_child(bar)

	# Prose label
	var prose_label: Label = Label.new()
	prose_label.text = _get_weight_prose(ev.weight)
	prose_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	prose_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	prose_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_weight_section.add_child(prose_label)

	# Insert into the first column right after the description.
	_detail_column1_content.add_child(_weight_section)
	_detail_column1_content.move_child(_weight_section, description_label.get_index() + 1)


func _get_weight_bar_color(ev: EvidenceData) -> Color:
	if EvidenceManager.is_contradicted(ev.id):
		return UIColors.RED
	return UIColors.AMBER


func _get_weight_prose(weight: float) -> String:
	var pct: float = weight * 100.0
	if pct >= 85.0:
		return "Airtight. Will convict on its own."
	elif pct >= 65.0:
		return "Strong. Holds up under cross-examination."
	elif pct >= 40.0:
		return "Corroborating. Strengthens the case when combined with other evidence."
	elif pct >= 20.0:
		return "Weak. Circumstantial \u2014 the defense will challenge this."
	return "Marginal. Context only."


func _update_pin_button() -> void:
	if _selected_evidence_id.is_empty(): return
	if EvidenceManager.is_pinned(_selected_evidence_id):
		pin_button.text = "📌 Unpin"
	else:
		pin_button.text = "📌 Pin"


func _update_send_to_board_button() -> void:
	if _selected_evidence_id.is_empty(): return
	if EvidenceManager.is_sent_to_board(_selected_evidence_id):
		send_to_board_button.text = "View on Board ↗"
	else:
		send_to_board_button.text = "📋 Send to Board"
	send_to_board_button.disabled = false


func _populate_lab_section() -> void:
	if _lab_section != null:
		_lab_section.queue_free()
		_lab_section = null

	var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(_selected_evidence_id)
	if lab_req == null: return

	_lab_section = VBoxContainer.new()
	_lab_section.add_theme_constant_override("separation", 8)

	var header: Label = Label.new()
	header.text = "FORENSIC ANALYSIS"
	header.theme_type_variation = &"SectionHeader"
	_lab_section.add_child(header)

	var output_ev: EvidenceData = CaseManager.get_evidence(lab_req.output_evidence_id)
	var output_discovered: bool = GameManager.has_evidence(lab_req.output_evidence_id)
	var already_submitted: bool = LabManager.is_evidence_submitted(_selected_evidence_id)

	if output_discovered:
		var status_label: Label = Label.new()
		status_label.text = "Lab analysis complete."
		status_label.add_theme_color_override("font_color", UIColors.GREEN)
		_lab_section.add_child(status_label)
		if output_ev:
			var result_label: Label = Label.new()
			result_label.text = "Result: %s" % output_ev.name
			result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lab_section.add_child(result_label)
			var view_btn: Button = Button.new()
			view_btn.text = "→ View: %s" % output_ev.name
			view_btn.flat = true
			view_btn.add_theme_color_override("font_color", UIColors.BLUE)
			view_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			var out_id: String = lab_req.output_evidence_id
			view_btn.pressed.connect(func() -> void: _show_evidence_detail(out_id))
			_lab_section.add_child(view_btn)
	elif already_submitted:
		var status_label: Label = Label.new()
		status_label.text = "Submitted to Lab — Results pending."
		status_label.add_theme_color_override("font_color", UIColors.AMBER)
		_lab_section.add_child(status_label)
	else:
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

	var info_section: Node = info_grid.get_parent()
	var main_content: Node = info_section.get_parent()
	var idx: int = info_section.get_index() + 1
	main_content.add_child(_lab_section)
	main_content.move_child(_lab_section, idx)


func _populate_comparison_targets() -> void:
	UIHelper.clear_children(comparison_list)
	var targets: Array[String] = EvidenceManager.get_valid_comparisons_for(_selected_evidence_id)

	if targets.is_empty():
		var none_label: Label = Label.new()
		none_label.text = "No valid comparisons available."
		none_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		comparison_list.add_child(none_label)
		return

	for target_id: String in targets:
		var ev: EvidenceData = CaseManager.get_evidence(target_id)
		if ev == null: continue
		var btn: Button = Button.new()
		btn.text = "Compare with: %s" % ev.name
		btn.pressed.connect(_on_compare_with.bind(target_id))
		comparison_list.add_child(btn)

# --- Callbacks --- #

func _on_back_pressed() -> void:
	ScreenManager.navigate_back()


func _on_filter_changed(_index: int) -> void:
	_populate_evidence_list()


func _on_search_changed(_text: String) -> void:
	_populate_evidence_list()


func _on_pin_pressed() -> void:
	if _selected_evidence_id.is_empty(): return
	if EvidenceManager.is_pinned(_selected_evidence_id):
		EvidenceManager.unpin_evidence(_selected_evidence_id)
	else:
		EvidenceManager.pin_evidence(_selected_evidence_id)
	_update_pin_button()


func _on_compare_pressed() -> void:
	if _selected_evidence_id.is_empty(): return
	_comparing = not _comparing
	comparison_panel.visible = _comparing
	if _comparing:
		_populate_comparison_targets()


func _on_compare_with(other_id: String) -> void:
	var insight: InsightData = EvidenceManager.compare_evidence(_selected_evidence_id, other_id)
	UIHelper.clear_children(comparison_list)

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


func _on_send_to_board_pressed() -> void:
	if _selected_evidence_id.is_empty(): return
	if EvidenceManager.is_sent_to_board(_selected_evidence_id):
		ScreenManager.navigate_to("detective_board")
		return
	BoardManager.send_to_board("evidence", _selected_evidence_id)
	EvidenceManager.mark_sent_to_board(_selected_evidence_id)
	UIHelper.confirmation_flash("Added to Board", self, UIColors.BLUE)


func _on_submit_to_lab() -> void:
	if _selected_evidence_id.is_empty(): return
	var success: bool = EvidenceManager.submit_to_lab(_selected_evidence_id)
	if not success:
		NotificationManager.notify("Submission Failed", "Could not submit lab request.")
		return
	UIHelper.confirmation_flash("Submitted to Lab", self)
	_show_evidence_detail(_selected_evidence_id)


# --- Label Helpers --- #

func _populate_header_badges(ev: EvidenceData) -> void:
	UIHelper.clear_children(_header_badges_row)
	_header_badges_row.add_child(
			_make_header_badge_pill(_get_importance_label(ev.importance_level),
					_get_importance_badge_color(ev.importance_level)))
	_header_badges_row.add_child(
			_make_header_badge_pill(UIHelper.get_evidence_type_label(ev.type),
					UIColors.TEXT_HIGHLIGHTED))
	for cat_val: int in ev.legal_categories:
		_header_badges_row.add_child(
				_make_header_badge_pill(UIHelper.get_legal_category_label(cat_val),
						UIColors.GREEN))
	_header_badges_row.visible = true


func _make_header_badge_pill(text: String, color: Color) -> PanelContainer:
	var pill: PanelContainer = PanelContainer.new()
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var bg_color: Color = color
	bg_color.a = 0.12
	style.bg_color = bg_color
	var border_color: Color = color
	border_color.a = 0.5
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", style)
	var label: Label = Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(label)
	return pill


func _get_importance_badge_color(level: Enums.ImportanceLevel) -> Color:
	match level:
		Enums.ImportanceLevel.CRITICAL: return UIColors.RED
		Enums.ImportanceLevel.SUPPORTING: return UIColors.BLUE
		Enums.ImportanceLevel.OPTIONAL: return UIColors.TEXT_GREY
		Enums.ImportanceLevel.KEY: return UIColors.AMBER
	return UIColors.TEXT_GREY


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
