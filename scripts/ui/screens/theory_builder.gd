## TheoryBuilder.gd
## Screen for constructing and managing crime theories.
## Phase 10: Five-step narrative builder with evidence attachment and strength indicators.
extends Control


# --- Node References --- #

@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var theory_count_label: Label = %TheoryCountLabel
@onready var new_theory_button: Button = %NewTheoryButton
@onready var theory_list_container: VBoxContainer = %TheoryListContainer
@onready var detail_panel: VBoxContainer = %DetailPanel
@onready var detail_scroll: ScrollContainer = %DetailScroll
@onready var no_selection_label: Label = %NoSelectionLabel


# --- Constants --- #

## Step display data: label text and color.
const STEP_CONFIG: Dictionary = {
	"suspect": {"label": "1. Suspect", "color": Color(0.75, 0.38, 0.38)},
	"motive": {"label": "2. Motive", "color": Color(0.55, 0.65, 0.38)},
	"time": {"label": "3. Time of Crime", "color": Color(0.45, 0.55, 0.70)},
	"method": {"label": "4. Method / Weapon", "color": Color(0.70, 0.55, 0.35)},
	"timeline": {"label": "5. Timeline Links", "color": Color(0.60, 0.40, 0.65)},
}

## Strength labels.
const STRENGTH_LABELS: Dictionary = {
	Enums.TheoryStrength.NONE: "—",
	Enums.TheoryStrength.WEAK: "● Weak",
	Enums.TheoryStrength.MODERATE: "●● Moderate",
	Enums.TheoryStrength.STRONG: "●●● Strong",
}

## Strength colors.
const STRENGTH_COLORS: Dictionary = {
	Enums.TheoryStrength.NONE: Color(0.5, 0.48, 0.45),
	Enums.TheoryStrength.WEAK: Color(0.7, 0.5, 0.3),
	Enums.TheoryStrength.MODERATE: Color(0.6, 0.65, 0.35),
	Enums.TheoryStrength.STRONG: Color(0.35, 0.7, 0.4),
}


# --- State --- #

## Currently selected theory ID.
var _selected_theory_id: String = ""


# --- Lifecycle --- #

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	new_theory_button.pressed.connect(_on_new_theory_pressed)

	TheoryManager.theory_created.connect(_on_theory_changed)
	TheoryManager.theory_updated.connect(_on_theory_changed)
	TheoryManager.theory_removed.connect(_on_theory_removed)
	TheoryManager.theories_cleared.connect(_on_theories_cleared)

	_rebuild_theory_list()
	_show_no_selection()


func _exit_tree() -> void:
	_safe_disconnect(TheoryManager.theory_created, _on_theory_changed)
	_safe_disconnect(TheoryManager.theory_updated, _on_theory_changed)
	_safe_disconnect(TheoryManager.theory_removed, _on_theory_removed)
	_safe_disconnect(TheoryManager.theories_cleared, _on_theories_cleared)


func _safe_disconnect(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)


# --- Theory List --- #

func _rebuild_theory_list() -> void:
	for child: Node in theory_list_container.get_children():
		child.queue_free()

	var theories: Array[Dictionary] = TheoryManager.get_all_theories()
	theory_count_label.text = "%d theories" % theories.size()

	for theory: Dictionary in theories:
		var btn: Button = Button.new()
		btn.text = theory["name"]
		btn.custom_minimum_size = Vector2(0, 32)
		btn.pressed.connect(_on_theory_selected.bind(theory["id"]))
		if theory["id"] == _selected_theory_id:
			btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
		theory_list_container.add_child(btn)


func _show_no_selection() -> void:
	no_selection_label.visible = true
	detail_scroll.visible = false


func _show_detail() -> void:
	no_selection_label.visible = false
	detail_scroll.visible = true


# --- Detail Panel --- #

func _rebuild_detail() -> void:
	for child: Node in detail_panel.get_children():
		child.queue_free()

	var theory: Dictionary = TheoryManager.get_theory(_selected_theory_id)
	if theory.is_empty():
		_show_no_selection()
		return

	_show_detail()
	_add_theory_header(theory)
	_add_step_suspect(theory)
	_add_step_motive(theory)
	_add_step_time(theory)
	_add_step_method(theory)
	_add_step_timeline(theory)
	_add_inconsistency_section(theory)


func _add_theory_header(theory: Dictionary) -> void:
	var hbox: HBoxContainer = HBoxContainer.new()

	var name_label: Label = Label.new()
	name_label.text = theory["name"]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	var complete_label: Label = Label.new()
	if TheoryManager.is_complete(_selected_theory_id):
		complete_label.text = "✓ Complete"
		complete_label.add_theme_color_override("font_color", Color(0.35, 0.7, 0.4))
	else:
		complete_label.text = "Incomplete"
		complete_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	complete_label.add_theme_font_size_override("font_size", 15)
	hbox.add_child(complete_label)

	var delete_btn: Button = Button.new()
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(_on_delete_theory.bind(theory["id"]))
	hbox.add_child(delete_btn)

	detail_panel.add_child(hbox)
	detail_panel.add_child(HSeparator.new())


# --- Step Builders --- #

func _add_step_suspect(theory: Dictionary) -> void:
	var panel: PanelContainer = _create_step_panel("suspect")
	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)

	var suspect_id: String = theory["suspect_id"]
	var value_label: Label = Label.new()
	if suspect_id.is_empty():
		value_label.text = "No suspect selected"
		value_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	else:
		var person: PersonData = CaseManager.get_person(suspect_id)
		value_label.text = person.name if person else suspect_id
	vbox.add_child(value_label)

	var change_btn: Button = Button.new()
	change_btn.text = "Select Suspect..."
	change_btn.pressed.connect(_on_select_suspect)
	vbox.add_child(change_btn)

	_add_strength_label(vbox, "suspect")
	_add_evidence_section(vbox, "suspect")
	detail_panel.add_child(panel)


func _add_step_motive(theory: Dictionary) -> void:
	var panel: PanelContainer = _create_step_panel("motive")
	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)

	var motive: String = theory["motive"]
	var value_label: Label = Label.new()
	if motive.is_empty():
		value_label.text = "No motive described"
		value_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	else:
		value_label.text = motive
	vbox.add_child(value_label)

	var edit_btn: Button = Button.new()
	edit_btn.text = "Set Motive..."
	edit_btn.pressed.connect(_on_set_motive)
	vbox.add_child(edit_btn)

	_add_strength_label(vbox, "motive")
	_add_evidence_section(vbox, "motive")
	detail_panel.add_child(panel)


func _add_step_time(theory: Dictionary) -> void:
	var panel: PanelContainer = _create_step_panel("time")
	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)

	var t_min: int = theory["time_minutes"]
	var t_day: int = theory["time_day"]
	var value_label: Label = Label.new()
	if t_min < 0 or t_day < 0:
		value_label.text = "No time set"
		value_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	else:
		value_label.text = "Day %d at %s" % [t_day, TimelineManager.format_time(t_min)]
	vbox.add_child(value_label)

	var edit_btn: Button = Button.new()
	edit_btn.text = "Set Time..."
	edit_btn.pressed.connect(_on_set_time)
	vbox.add_child(edit_btn)

	_add_strength_label(vbox, "time")
	_add_evidence_section(vbox, "time")
	detail_panel.add_child(panel)


func _add_step_method(theory: Dictionary) -> void:
	var panel: PanelContainer = _create_step_panel("method")
	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)

	var method: String = theory["method"]
	var value_label: Label = Label.new()
	if method.is_empty():
		value_label.text = "No method described"
		value_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	else:
		value_label.text = method
	vbox.add_child(value_label)

	var edit_btn: Button = Button.new()
	edit_btn.text = "Set Method..."
	edit_btn.pressed.connect(_on_set_method)
	vbox.add_child(edit_btn)

	_add_strength_label(vbox, "method")
	_add_evidence_section(vbox, "method")
	detail_panel.add_child(panel)


func _add_step_timeline(theory: Dictionary) -> void:
	var panel: PanelContainer = _create_step_panel("timeline")
	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)

	var entry_ids: Array = theory.get("timeline_entry_ids", [])
	var value_label: Label = Label.new()
	if entry_ids.is_empty():
		value_label.text = "No timeline entries linked"
		value_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	else:
		value_label.text = "%d timeline entries linked" % entry_ids.size()
	vbox.add_child(value_label)

	var edit_btn: Button = Button.new()
	edit_btn.text = "Link Timeline Entries..."
	edit_btn.pressed.connect(_on_link_timeline)
	vbox.add_child(edit_btn)

	_add_strength_label(vbox, "timeline")
	detail_panel.add_child(panel)


# --- Inconsistency Section --- #

func _add_inconsistency_section(theory: Dictionary) -> void:
	var inconsistencies: Array[Dictionary] = TheoryManager.get_inconsistencies(theory["id"])
	if inconsistencies.is_empty():
		return

	var sep: HSeparator = HSeparator.new()
	detail_panel.add_child(sep)

	var header: Label = Label.new()
	header.text = "⚠ Inconsistencies Found"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.9, 0.55, 0.3))
	detail_panel.add_child(header)

	for incon: Dictionary in inconsistencies:
		var lbl: Label = Label.new()
		lbl.text = "• %s" % incon.get("description", "Unknown conflict")
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.55, 0.35))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		detail_panel.add_child(lbl)


# --- Shared UI Helpers --- #

func _create_step_panel(step: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var config: Dictionary = STEP_CONFIG.get(step, {})
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = config.get("color", Color(0.4, 0.4, 0.4))
	style.bg_color.a = 0.25
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.border_width_left = 3
	style.border_color = config.get("color", Color(0.5, 0.5, 0.5))
	panel.add_theme_stylebox_override("panel", style)

	# Add step title as first element (caller adds VBox after)
	var title: Label = Label.new()
	title.text = config.get("label", step)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", config.get("color", Color.WHITE))
	# Title will be child 0; caller's VBox child 1
	panel.add_child(title)
	return panel


func _add_strength_label(parent: VBoxContainer, step: String) -> void:
	var strength: Enums.TheoryStrength = TheoryManager.get_step_strength(
		_selected_theory_id, step
	)
	var lbl: Label = Label.new()
	lbl.text = STRENGTH_LABELS.get(strength, "—")
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", STRENGTH_COLORS.get(strength, Color.WHITE))
	parent.add_child(lbl)


func _add_evidence_section(parent: VBoxContainer, step: String) -> void:
	var evidence_ids: Array[String] = TheoryManager.get_step_evidence(
		_selected_theory_id, step
	)
	if not evidence_ids.is_empty():
		for ev_id: String in evidence_ids:
			var hbox: HBoxContainer = HBoxContainer.new()
			var ev_data: EvidenceData = CaseManager.get_evidence(ev_id)
			var ev_label: Label = Label.new()
			ev_label.text = "📎 %s" % (ev_data.name if ev_data else ev_id)
			ev_label.add_theme_font_size_override("font_size", 13)
			ev_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(ev_label)

			var remove_btn: Button = Button.new()
			remove_btn.text = "✕"
			remove_btn.custom_minimum_size = Vector2(24, 24)
			remove_btn.pressed.connect(
				TheoryManager.detach_evidence.bind(_selected_theory_id, step, ev_id)
			)
			hbox.add_child(remove_btn)
			parent.add_child(hbox)

	if evidence_ids.size() < TheoryManager.MAX_EVIDENCE_PER_STEP:
		var attach_btn: Button = Button.new()
		attach_btn.text = "+ Attach Evidence"
		attach_btn.pressed.connect(_on_attach_evidence.bind(step))
		parent.add_child(attach_btn)


# --- Dialogs --- #

func _on_new_theory_pressed() -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "New Theory"
	var line_edit: LineEdit = LineEdit.new()
	line_edit.placeholder_text = "Theory name..."
	dialog.add_child(line_edit)
	dialog.confirmed.connect(func() -> void:
		var name: String = line_edit.text.strip_edges()
		if not name.is_empty():
			var t: Dictionary = TheoryManager.create_theory(name)
			_selected_theory_id = t["id"]
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(300, 80))


func _on_select_suspect() -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Select Suspect"
	var vbox: VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)
	var suspects: Array[PersonData] = CaseManager.get_suspects()
	for suspect: PersonData in suspects:
		var btn: Button = Button.new()
		btn.text = suspect.name
		btn.pressed.connect(func() -> void:
			TheoryManager.set_suspect(_selected_theory_id, suspect.id)
			dialog.queue_free()
		)
		vbox.add_child(btn)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(300, 200))


func _on_set_motive() -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Set Motive"
	var line_edit: LineEdit = LineEdit.new()
	line_edit.placeholder_text = "Describe the motive..."
	var theory: Dictionary = TheoryManager.get_theory(_selected_theory_id)
	line_edit.text = theory.get("motive", "")
	dialog.add_child(line_edit)
	dialog.confirmed.connect(func() -> void:
		TheoryManager.set_motive(_selected_theory_id, line_edit.text.strip_edges())
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(350, 80))


func _on_set_time() -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Set Time of Crime"
	var vbox: VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)

	var time_edit: LineEdit = LineEdit.new()
	time_edit.placeholder_text = "Time (e.g. 21:00)"
	vbox.add_child(time_edit)

	var day_edit: LineEdit = LineEdit.new()
	day_edit.placeholder_text = "Day (e.g. 1)"
	vbox.add_child(day_edit)

	dialog.confirmed.connect(func() -> void:
		var t_min: int = TimelineManager.parse_time_string(time_edit.text)
		var day: int = int(day_edit.text.strip_edges()) if day_edit.text.strip_edges().is_valid_int() else -1
		if t_min >= 0 and day > 0:
			TheoryManager.set_time(_selected_theory_id, t_min, day)
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(300, 120))


func _on_set_method() -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Set Method / Weapon"
	var line_edit: LineEdit = LineEdit.new()
	line_edit.placeholder_text = "Describe the method..."
	var theory: Dictionary = TheoryManager.get_theory(_selected_theory_id)
	line_edit.text = theory.get("method", "")
	dialog.add_child(line_edit)
	dialog.confirmed.connect(func() -> void:
		TheoryManager.set_method(_selected_theory_id, line_edit.text.strip_edges())
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(350, 80))


func _on_link_timeline() -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Link Timeline Entries"
	var vbox: VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)

	var theory: Dictionary = TheoryManager.get_theory(_selected_theory_id)
	var linked: Array = theory.get("timeline_entry_ids", [])

	# Show all timeline entries across days
	var case_data: CaseData = CaseManager.get_case_data()
	var max_day: int = case_data.end_day if case_data else 4
	for day: int in range(1, max_day + 1):
		var entries: Array[Dictionary] = TimelineManager.get_entries_for_day(day)
		for entry: Dictionary in entries:
			var check: CheckButton = CheckButton.new()
			var event: EventData = CaseManager.get_event(entry.get("event_id", ""))
			var desc: String = event.description if event else entry.get("event_id", "?")
			check.text = "Day %d %s — %s" % [
				day, TimelineManager.format_time(entry["time_minutes"]), desc
			]
			check.button_pressed = entry["id"] in linked
			check.set_meta("entry_id", entry["id"])
			vbox.add_child(check)

	dialog.confirmed.connect(func() -> void:
		var new_ids: Array[String] = []
		for child: Node in vbox.get_children():
			if child is CheckButton and child.button_pressed:
				new_ids.append(child.get_meta("entry_id") as String)
		TheoryManager.set_timeline_links(_selected_theory_id, new_ids)
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(450, 300))


func _on_attach_evidence(step: String) -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Attach Evidence to %s" % step.capitalize()
	var vbox: VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)

	var discovered: Array[EvidenceData] = EvidenceManager.get_discovered_evidence_data()
	var already: Array[String] = TheoryManager.get_step_evidence(_selected_theory_id, step)
	for ev_dict: EvidenceData in discovered:
		var ev_id: String = ev_dict.id
		if ev_id in already:
			continue
		var btn: Button = Button.new()
		btn.text = ev_dict.name if not ev_dict.name.is_empty() else ev_id
		btn.pressed.connect(func() -> void:
			TheoryManager.attach_evidence(_selected_theory_id, step, ev_id)
			dialog.queue_free()
		)
		vbox.add_child(btn)

	if vbox.get_child_count() == 0:
		var lbl: Label = Label.new()
		lbl.text = "No available evidence to attach."
		vbox.add_child(lbl)

	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(350, 250))


# --- Signal Handlers --- #

func _on_theory_changed(_theory_id: String) -> void:
	_rebuild_theory_list()
	if _selected_theory_id == _theory_id or _selected_theory_id.is_empty():
		_rebuild_detail()


func _on_theory_removed(theory_id: String) -> void:
	if _selected_theory_id == theory_id:
		_selected_theory_id = ""
		_show_no_selection()
	_rebuild_theory_list()


func _on_theories_cleared() -> void:
	_selected_theory_id = ""
	_rebuild_theory_list()
	_show_no_selection()


func _on_theory_selected(theory_id: String) -> void:
	_selected_theory_id = theory_id
	_rebuild_theory_list()
	_rebuild_detail()


func _on_delete_theory(theory_id: String) -> void:
	TheoryManager.remove_theory(theory_id)


func _on_back_pressed() -> void:
	ScreenManager.navigate_back()
