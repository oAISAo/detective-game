## evidence_statements_panel.gd
## Displays all player-unlocked statements linked to a given evidence item.
## Handles verdict display, expand/collapse, per-statement notes, and manual linking.
## Built programmatically — no .tscn needed.
class_name EvidenceStatementsPanel
extends VBoxContainer


var _evidence_id: String = ""

## Maps statement_id -> StatementItem for targeted updates.
var _items: Dictionary = {}

## Reusable dialog for linking statements manually.
var _link_dialog: AcceptDialog = null


func _ready() -> void:
	EvidenceManager.statement_verdict_changed.connect(_on_verdict_changed)
	EvidenceManager.statement_manually_linked.connect(_on_manual_link_changed)
	EvidenceManager.statement_manually_unlinked.connect(_on_manual_link_changed)


func _exit_tree() -> void:
	if EvidenceManager.statement_verdict_changed.is_connected(_on_verdict_changed):
		EvidenceManager.statement_verdict_changed.disconnect(_on_verdict_changed)
	if EvidenceManager.statement_manually_linked.is_connected(_on_manual_link_changed):
		EvidenceManager.statement_manually_linked.disconnect(_on_manual_link_changed)
	if EvidenceManager.statement_manually_unlinked.is_connected(_on_manual_link_changed):
		EvidenceManager.statement_manually_unlinked.disconnect(_on_manual_link_changed)


## Loads and renders all visible statements for the given evidence item.
func set_evidence(evidence_id: String) -> void:
	_evidence_id = evidence_id
	_reload()


func _reload() -> void:
	UIHelper.clear_children(self)
	_items.clear()

	var statements: Array[StatementData] = EvidenceManager.get_statements_for_evidence(_evidence_id)

	if statements.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No relevant statements yet."
		empty_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		add_child(empty_label)
	else:
		for stmt: StatementData in statements:
			var is_manual: bool = EvidenceManager.is_manually_linked(_evidence_id, stmt.id)
			var item: StatementItem = StatementItem.new()
			add_child(item)
			item.setup(_evidence_id, stmt, is_manual)
			_items[stmt.id] = item

	if not _evidence_id.is_empty():
		var link_btn: Button = Button.new()
		link_btn.text = "+ Link Statement"
		link_btn.flat = true
		link_btn.focus_mode = Control.FOCUS_NONE
		link_btn.add_theme_color_override("font_color", UIColors.BLUE)
		link_btn.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
		link_btn.pressed.connect(_show_link_statement_popup)
		add_child(link_btn)


func _on_verdict_changed(evidence_id: String, statement_id: String, _verdict: String) -> void:
	if evidence_id != _evidence_id:
		return
	var item: StatementItem = _items.get(statement_id, null)
	if item != null:
		item.update_verdict()


func _on_manual_link_changed(evidence_id: String, _statement_id: String) -> void:
	if evidence_id == _evidence_id:
		_reload()


func _show_link_statement_popup() -> void:
	# Build the set of already-linked statement IDs (case data + manual)
	var already_linked: Dictionary = {}
	for stmt: StatementData in EvidenceManager.get_statements_for_evidence(_evidence_id):
		already_linked[stmt.id] = true

	# Get all unlocked statements that are not already linked
	var candidates: Array[StatementData] = []
	for stmt: StatementData in EvidenceManager.get_testimony():
		if not already_linked.has(stmt.id):
			candidates.append(stmt)

	# Create or reuse the dialog
	if _link_dialog == null:
		_link_dialog = AcceptDialog.new()
		_link_dialog.title = "Link a Statement"
		_link_dialog.get_ok_button().hide()
		_link_dialog.get_cancel_button().text = "Close"
		add_child(_link_dialog)

	# Rebuild inner content
	for child: Node in _link_dialog.get_children():
		if child is VBoxContainer:
			child.queue_free()

	var outer: VBoxContainer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	_link_dialog.add_child(outer)

	var search_edit: LineEdit = LineEdit.new()
	search_edit.placeholder_text = "Search statements…"
	search_edit.custom_minimum_size = Vector2(380, 0)
	outer.add_child(search_edit)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 280)
	outer.add_child(scroll)

	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)

	var _build_list: Callable = func(filter: String) -> void:
		UIHelper.clear_children(list)
		for stmt: StatementData in candidates:
			if not filter.is_empty() and filter.to_lower() not in stmt.text.to_lower():
				continue
			var person: PersonData = CaseManager.get_person(stmt.person_id)
			var pname: String = person.name if person else stmt.person_id
			var preview: String = stmt.text.left(60) + ("…" if stmt.text.length() > 60 else "")
			var btn: Button = Button.new()
			btn.text = "%s · Day %d: \"%s\"" % [pname, stmt.day_given, preview]
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.focus_mode = Control.FOCUS_NONE
			var sid: String = stmt.id
			btn.pressed.connect(func() -> void:
				EvidenceManager.link_statement_manually(_evidence_id, sid)
				_link_dialog.hide()
			)
			list.add_child(btn)
		if list.get_child_count() == 0:
			var none_lbl: Label = Label.new()
			none_lbl.text = "No linkable statements found."
			none_lbl.add_theme_color_override("font_color", UIColors.TEXT_GREY)
			list.add_child(none_lbl)

	_build_list.call("")
	search_edit.text_changed.connect(_build_list)

	_link_dialog.popup_centered(Vector2(420, 380))
