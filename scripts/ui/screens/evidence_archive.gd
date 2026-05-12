## EvidenceArchive
## Screen for viewing and managing collected evidence.
## Handles the evidence grid, filtering, searching, and card selection.
## The detail panel and card grid are coordinated here while each card and
## detail sub-section keeps its own presentation logic.
extends Control

const POLAROID_SCENE: PackedScene = preload("res://scenes/ui/components/evidence_polaroid.tscn")

var _handwriting_font: Font = null
## Maps evidence_id → EvidencePolaroid node for the current visible grid.
var _card_nodes: Dictionary = {}  # evidence_id: String → EvidencePolaroid
var _selected_card: EvidencePolaroid = null

@onready var filter_option: OptionButton = %FilterOption
@onready var search_box: LineEdit = %SearchBox
@onready var evidence_grid: GridContainer = %EvidenceGrid
@onready var card_scroll: ScrollContainer = %CardScroll
@onready var detail_panel: EvidenceDetailPanel = %RightVBox

# Stored callables for signal disconnection on exit
var _on_evidence_discovered_cb: Callable
var _on_evidence_pinned_cb: Callable
var _on_evidence_unpinned_cb: Callable
var _on_evidence_reviewed_cb: Callable
var _on_lab_submitted_cb: Callable


func _ready() -> void:
	card_scroll.get_v_scroll_bar().modulate = Color.TRANSPARENT

	if ResourceLoader.exists(UIFonts.HANDWRITING_FONT_PATH):
		_handwriting_font = load(UIFonts.HANDWRITING_FONT_PATH) as Font
	else:
		push_warning("[EvidenceArchive] Handwriting font not found: %s" % UIFonts.HANDWRITING_FONT_PATH)

	filter_option.item_selected.connect(_on_filter_changed)
	search_box.text_changed.connect(_on_search_changed)
	_add_search_icon()

	detail_panel.setup(_handwriting_font)
	detail_panel.pin_toggled.connect(_on_detail_pin_toggled)
	detail_panel.evidence_requested.connect(_on_evidence_requested)

	_setup_filter_options()
	_populate_evidence_list()

	_on_evidence_discovered_cb = func(_id: String) -> void:
		_refresh()
		_refresh_selected_detail()
	_on_evidence_pinned_cb = func(_id: String) -> void:
		_refresh()
	_on_evidence_unpinned_cb = func(_id: String) -> void:
		_refresh()
	_on_evidence_reviewed_cb = func(id: String) -> void:
		_refresh_card_badges(id)
	_on_lab_submitted_cb = func(_request_id: String, input_evidence_id: String) -> void:
		_refresh_card_badges(input_evidence_id)

	GameManager.evidence_discovered.connect(_on_evidence_discovered_cb)
	EvidenceManager.evidence_pinned.connect(_on_evidence_pinned_cb)
	EvidenceManager.evidence_unpinned.connect(_on_evidence_unpinned_cb)
	EvidenceManager.evidence_reviewed.connect(_on_evidence_reviewed_cb)
	LabManager.lab_submitted.connect(_on_lab_submitted_cb)
	EvidenceManager.state_loaded.connect(_refresh)

	var nav_data: Dictionary = ScreenManager.navigation_data
	if nav_data.has("evidence_id"):
		detail_panel.show_evidence(nav_data["evidence_id"])


func _exit_tree() -> void:
	UIHelper.safe_disconnect(GameManager.evidence_discovered, _on_evidence_discovered_cb)
	UIHelper.safe_disconnect(EvidenceManager.evidence_pinned, _on_evidence_pinned_cb)
	UIHelper.safe_disconnect(EvidenceManager.evidence_unpinned, _on_evidence_unpinned_cb)
	UIHelper.safe_disconnect(EvidenceManager.evidence_reviewed, _on_evidence_reviewed_cb)
	UIHelper.safe_disconnect(LabManager.lab_submitted, _on_lab_submitted_cb)
	UIHelper.safe_disconnect(EvidenceManager.state_loaded, _refresh)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if search_box.has_focus() and not search_box.get_global_rect().has_point(event.global_position):
			search_box.release_focus()


## Adds a Material Symbols search icon as a left overlay inside the search input.
func _add_search_icon() -> void:
	var icon := Label.new()
	var icon_font := FontVariation.new()
	icon_font.base_font = load("res://assets/fonts/MaterialSymbolsOutlined.ttf")
	icon_font.opentype_features = {"liga": 1, "calt": 1}
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
## Each type item's ID is set to its EvidenceType enum value so the filter
## comparison is robust against future item reordering.
func _setup_filter_options() -> void:
	filter_option.clear()
	filter_option.add_item("All Types")  # index 0 — always the "no filter" sentinel
	filter_option.add_item("Forensic", Enums.EvidenceType.FORENSIC)
	filter_option.add_item("Document", Enums.EvidenceType.DOCUMENT)
	filter_option.add_item("Photo", Enums.EvidenceType.PHOTO)
	filter_option.add_item("Recording", Enums.EvidenceType.RECORDING)
	filter_option.add_item("Financial", Enums.EvidenceType.FINANCIAL)
	filter_option.add_item("Digital", Enums.EvidenceType.DIGITAL)
	filter_option.add_item("Object", Enums.EvidenceType.OBJECT)


func _populate_evidence_list() -> void:
	UIHelper.clear_children(evidence_grid)
	_card_nodes.clear()
	_selected_card = null

	var items: Array[EvidenceData] = _get_filtered_evidence()

	if items.is_empty():
		var empty_label := Label.new()
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

	var selected_id: String = detail_panel.get_selected_id()
	if not selected_id.is_empty() and _card_nodes.has(selected_id):
		_selected_card = _card_nodes[selected_id] as EvidencePolaroid
		_selected_card.set_selected(true)


func _refresh_card_badges(evidence_id: String) -> void:
	var card: EvidencePolaroid = _card_nodes.get(evidence_id) as EvidencePolaroid
	if card != null and is_instance_valid(card):
		card.refresh_badges()


func _get_filtered_evidence() -> Array[EvidenceData]:
	var query: String = search_box.text.strip_edges()
	var type_idx: int = filter_option.selected

	var items: Array[EvidenceData]
	if query.is_empty():
		items = EvidenceManager.get_discovered_evidence_data()
	else:
		items = EvidenceManager.search_evidence(query)

	if type_idx > 0:
		var type_filter: Enums.EvidenceType = filter_option.get_item_id(type_idx) as Enums.EvidenceType
		var filtered: Array[EvidenceData] = []
		for ev: EvidenceData in items:
			if ev.type == type_filter:
				filtered.append(ev)
		items = filtered

	return _sort_evidence(items)


## Sorts evidence: pinned first → unreviewed first → most recently discovered → most important.
func _sort_evidence(items: Array[EvidenceData]) -> Array[EvidenceData]:
	var result: Array[EvidenceData] = items.duplicate()
	result.sort_custom(func(a: EvidenceData, b: EvidenceData) -> bool:
		var a_pinned: bool = EvidenceManager.is_pinned(a.id)
		var b_pinned: bool = EvidenceManager.is_pinned(b.id)
		if a_pinned != b_pinned:
			return a_pinned

		var a_reviewed: bool = EvidenceManager.is_reviewed(a.id)
		var b_reviewed: bool = EvidenceManager.is_reviewed(b.id)
		if a_reviewed != b_reviewed:
			return not a_reviewed

		var a_day: int = GameManager.get_evidence_discovery_day(a.id)
		var b_day: int = GameManager.get_evidence_discovery_day(b.id)
		if a_day != b_day:
			return a_day > b_day

		var a_idx: int = GameManager.discovered_evidence.find(a.id)
		var b_idx: int = GameManager.discovered_evidence.find(b.id)
		if a_idx != b_idx:
			return a_idx > b_idx

		return a.importance_level < b.importance_level
	)
	return result


func _refresh() -> void:
	_populate_evidence_list()


func _refresh_selected_detail() -> void:
	var selected_id: String = detail_panel.get_selected_id()
	if selected_id.is_empty():
		return
	if not GameManager.has_evidence(selected_id):
		detail_panel.clear()
		return
	detail_panel.show_evidence(selected_id)


# --- Callbacks ---

func _on_back_pressed() -> void:
	ScreenManager.navigate_back()


func _on_filter_changed(_index: int) -> void:
	_populate_evidence_list()


func _on_search_changed(_text: String) -> void:
	_populate_evidence_list()


func _on_card_pressed(evidence_id: String) -> void:
	if _selected_card != null and is_instance_valid(_selected_card):
		_selected_card.set_selected(false)
	_selected_card = _card_nodes.get(evidence_id) as EvidencePolaroid
	if _selected_card != null:
		_selected_card.set_selected(true)
	detail_panel.show_evidence(evidence_id)


func _on_detail_pin_toggled(_evidence_id: String) -> void:
	_refresh()


func _on_evidence_requested(evidence_id: String) -> void:
	if _selected_card != null and is_instance_valid(_selected_card):
		_selected_card.set_selected(false)
	_selected_card = _card_nodes.get(evidence_id) as EvidencePolaroid
	if _selected_card != null:
		_selected_card.set_selected(true)
	detail_panel.show_evidence(evidence_id)
