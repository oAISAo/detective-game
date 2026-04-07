## EvidenceArchive.gd
## Screen for viewing and managing collected evidence with filtering,
## search, pinning, and testimony with contradiction highlighting.
## Phase D6: Uses EvidenceCard grid instead of button rows.
extends Control


const EvidenceCardScene: PackedScene = preload("res://scenes/ui/components/evidence_card.tscn")

@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var filter_option: OptionButton = %FilterOption
@onready var search_box: LineEdit = %SearchBox
@onready var tab_evidence_button: Button = %TabEvidenceButton
@onready var tab_testimony_button: Button = %TabTestimonyButton
@onready var pinned_bar: HBoxContainer = %PinnedBar
@onready var evidence_content: VBoxContainer = %EvidenceContent
@onready var evidence_grid: GridContainer = %EvidenceGrid
@onready var testimony_content: VBoxContainer = %TestimonyContent
@onready var testimony_list: VBoxContainer = %TestimonyList

var _current_tab: String = "evidence"

# Stored callables for signal disconnection on exit
var _on_evidence_discovered_cb: Callable
var _on_evidence_pinned_cb: Callable
var _on_evidence_unpinned_cb: Callable


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	tab_evidence_button.pressed.connect(_on_tab_evidence)
	tab_testimony_button.pressed.connect(_on_tab_testimony)
	filter_option.item_selected.connect(_on_filter_changed)
	search_box.text_changed.connect(_on_search_changed)

	_setup_filter_options()
	_show_tab("evidence")
	_populate_pinned_bar()
	_populate_evidence_list()

	# Store callables so we can disconnect them in _exit_tree
	_on_evidence_discovered_cb = func(_id: String) -> void: _refresh()
	_on_evidence_pinned_cb = func(_id: String) -> void: _populate_pinned_bar()
	_on_evidence_unpinned_cb = func(_id: String) -> void: _populate_pinned_bar()

	# Connect to live updates
	GameManager.evidence_discovered.connect(_on_evidence_discovered_cb)
	EvidenceManager.evidence_pinned.connect(_on_evidence_pinned_cb)
	EvidenceManager.evidence_unpinned.connect(_on_evidence_unpinned_cb)
	EvidenceManager.state_loaded.connect(_refresh)


func _exit_tree() -> void:
	GameManager.evidence_discovered.disconnect(_on_evidence_discovered_cb)
	EvidenceManager.evidence_pinned.disconnect(_on_evidence_pinned_cb)
	EvidenceManager.evidence_unpinned.disconnect(_on_evidence_unpinned_cb)
	if EvidenceManager.state_loaded.is_connected(_refresh):
		EvidenceManager.state_loaded.disconnect(_refresh)


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


## Switches between evidence and testimony tabs.
func _show_tab(tab: String) -> void:
	_current_tab = tab
	evidence_content.visible = tab == "evidence"
	testimony_content.visible = tab == "testimony"
	tab_evidence_button.disabled = tab == "evidence"
	tab_testimony_button.disabled = tab == "testimony"
	if tab == "testimony":
		_populate_testimony_list()


## Populates the evidence grid with card components.
func _populate_evidence_list() -> void:
	for child: Node in evidence_grid.get_children():
		evidence_grid.remove_child(child)
		child.queue_free()

	var items: Array[EvidenceData] = _get_filtered_evidence()

	if items.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No evidence found."
		empty_label.add_theme_color_override("font_color", UIColors.MUTED)
		evidence_grid.add_child(empty_label)
		return

	for ev: EvidenceData in items:
		var card: EvidenceCard = EvidenceCardScene.instantiate()
		evidence_grid.add_child(card)
		card.setup(ev)
		card.card_pressed.connect(_on_card_pressed)


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

	return items


## Populates the pinned evidence bar.
func _populate_pinned_bar() -> void:
	# Clear everything except the first child (the "PINNED" label)
	while pinned_bar.get_child_count() > 1:
		var child: Node = pinned_bar.get_child(pinned_bar.get_child_count() - 1)
		pinned_bar.remove_child(child)
		child.queue_free()

	var pinned: Array[String] = EvidenceManager.get_pinned_evidence()
	if pinned.is_empty():
		return

	for eid: String in pinned:
		var ev: EvidenceData = CaseManager.get_evidence(eid)
		if ev == null:
			continue
		var btn: Button = Button.new()
		btn.text = ev.name
		btn.flat = true
		btn.pressed.connect(_on_card_pressed.bind(eid))
		pinned_bar.add_child(btn)


## Populates the testimony list with contradiction markers.
func _populate_testimony_list() -> void:
	for child: Node in testimony_list.get_children():
		testimony_list.remove_child(child)
		child.queue_free()

	# Check contradictions first
	EvidenceManager.check_contradictions()

	var testimony: Array[StatementData] = EvidenceManager.get_testimony()
	if testimony.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No testimony recorded yet."
		empty_label.add_theme_color_override("font_color", UIColors.MUTED)
		testimony_list.add_child(empty_label)
		return

	for stmt: StatementData in testimony:
		var panel: PanelContainer = PanelContainer.new()
		UIHelper.apply_surface_style(panel)
		var vbox: VBoxContainer = VBoxContainer.new()
		panel.add_child(vbox)

		var person: PersonData = CaseManager.get_person(stmt.person_id)
		var person_name: String = person.name if person else stmt.person_id

		var header_label: Label = Label.new()
		header_label.text = "%s — Day %d" % [person_name, stmt.day_given]
		header_label.add_theme_font_size_override("font_size", 16)
		vbox.add_child(header_label)

		var text_label: RichTextLabel = RichTextLabel.new()
		text_label.bbcode_enabled = true
		text_label.fit_content = true
		text_label.text = '"%s"' % stmt.text
		vbox.add_child(text_label)

		# Contradiction marker
		if EvidenceManager.has_contradiction(stmt.id):
			var warning_label: Label = Label.new()
			warning_label.text = "Possible contradiction"
			warning_label.add_theme_color_override("font_color", UIColors.ACCENT_CLUE)
			vbox.add_child(warning_label)

		testimony_list.add_child(panel)


# --- Callbacks --- #

func _on_back_pressed() -> void:
	ScreenManager.navigate_back()


func _on_tab_evidence() -> void:
	_show_tab("evidence")
	_populate_evidence_list()


func _on_tab_testimony() -> void:
	_show_tab("testimony")


func _on_filter_changed(_index: int) -> void:
	_populate_evidence_list()


func _on_search_changed(_text: String) -> void:
	_populate_evidence_list()


func _on_card_pressed(evidence_id: String) -> void:
	ScreenManager.navigate_to("evidence_detail", {"evidence_id": evidence_id})


## Refreshes the current tab content.
func _refresh() -> void:
	if _current_tab == "evidence":
		_populate_evidence_list()
	else:
		_populate_testimony_list()
	_populate_pinned_bar()
