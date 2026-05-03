## statement_item.gd
## Displays a single statement with expand/collapse, verdict popup, and per-statement note.
## Built programmatically — no .tscn needed.
class_name StatementItem
extends VBoxContainer


const HANDWRITING_FONT_PATH: String = "res://assets/fonts/Caveat-Regular.ttf"

var _evidence_id: String = ""
var _statement_id: String = ""
var _verdict_button: Button = null
var _verdict_popup: PopupMenu = null
var _body: VBoxContainer = null
var _toggle_button: Button = null
var _note_edit: TextEdit = null
var _is_expanded: bool = false


## Initializes this item with its evidence context and statement data.
## Must be called after add_child().
func setup(evidence_id: String, stmt: StatementData, _legacy_manual_link: bool = false) -> void:
	_evidence_id = evidence_id
	_statement_id = stmt.id

	add_theme_constant_override("separation", 4)

	var person: PersonData = CaseManager.get_person(stmt.person_id)
	var person_name: String = person.name if person else stmt.person_id

	# --- Header row --- #
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	add_child(header)

	_toggle_button = Button.new()
	_toggle_button.text = "▶"
	_toggle_button.flat = true
	_toggle_button.focus_mode = Control.FOCUS_NONE
	_toggle_button.custom_minimum_size = Vector2(20, 0)
	_toggle_button.pressed.connect(_on_toggle_pressed)
	header.add_child(_toggle_button)

	var name_label: Label = Label.new()
	name_label.text = person_name
	name_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	header.add_child(name_label)

	var day_label: Label = Label.new()
	day_label.text = " · Day %d" % stmt.day_given
	day_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
	day_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	header.add_child(day_label)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_verdict_button = Button.new()
	_verdict_button.flat = true
	_verdict_button.focus_mode = Control.FOCUS_NONE
	_verdict_button.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	_verdict_button.pressed.connect(_on_verdict_button_pressed)
	header.add_child(_verdict_button)

	# Verdict popup
	_verdict_popup = PopupMenu.new()
	_verdict_popup.add_item("Contradiction", 0)
	_verdict_popup.add_item("Supports", 1)
	_verdict_popup.add_item("Unresolved", 2)
	_verdict_popup.add_item("Unclassified", 3)
	_verdict_popup.id_pressed.connect(_on_verdict_popup_id_pressed)
	add_child(_verdict_popup)

	# --- Quote label (always visible) --- #
	var quote_margin: MarginContainer = MarginContainer.new()
	quote_margin.add_theme_constant_override("margin_left", 20)
	add_child(quote_margin)

	var quote_label: Label = Label.new()
	quote_label.text = "\"%s\"" % stmt.text
	quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	quote_label.add_theme_font_size_override("font_size", UIFonts.SIZE_BODY)
	quote_margin.add_child(quote_label)

	# --- Collapsible body --- #
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 4)
	_body.visible = false
	add_child(_body)

	var body_margin: MarginContainer = MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 20)
	_body.add_child(body_margin)

	var body_inner: VBoxContainer = VBoxContainer.new()
	body_inner.add_theme_constant_override("separation", 4)
	body_margin.add_child(body_inner)

	var note_header: Label = Label.new()
	note_header.text = "ANALYSIS NOTE"
	note_header.add_theme_color_override("font_color", UIColors.TEXT_GREY)
	note_header.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	body_inner.add_child(note_header)

	_note_edit = TextEdit.new()
	_note_edit.custom_minimum_size = Vector2(0, 60)
	_note_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_note_edit.text = EvidenceManager.get_statement_note(_evidence_id, _statement_id)
	_note_edit.text_changed.connect(_on_note_changed)
	if ResourceLoader.exists(HANDWRITING_FONT_PATH):
		var hw_font: Font = ResourceLoader.load(HANDWRITING_FONT_PATH)
		_note_edit.add_theme_font_override("font", hw_font)
		_note_edit.add_theme_font_size_override("font_size", UIFonts.SIZE_BODY)
	body_inner.add_child(_note_edit)

	# Expand automatically if a note already exists
	if not _note_edit.text.is_empty():
		_is_expanded = true
		_body.visible = true
		_toggle_button.text = "▼"

	# Bottom separator
	var sep: HSeparator = HSeparator.new()
	add_child(sep)

	_refresh_verdict()


## Updates the verdict button label and color to reflect the current stored verdict.
func update_verdict() -> void:
	_refresh_verdict()


func _refresh_verdict() -> void:
	if _verdict_button == null:
		return
	var verdict: String = EvidenceManager.get_statement_verdict(_evidence_id, _statement_id)
	_verdict_button.text = verdict.to_upper()
	_verdict_button.add_theme_color_override("font_color", _get_verdict_color(verdict))


func _get_verdict_color(verdict: String) -> Color:
	match verdict:
		"contradiction": return UIColors.RED
		"supports": return UIColors.GREEN
		"unresolved": return UIColors.AMBER
		_: return UIColors.TEXT_GREY


func _on_toggle_pressed() -> void:
	_is_expanded = not _is_expanded
	_body.visible = _is_expanded
	_toggle_button.text = "▼" if _is_expanded else "▶"


func _on_verdict_button_pressed() -> void:
	var btn_rect: Rect2 = Rect2(_verdict_button.global_position, _verdict_button.size)
	_verdict_popup.popup(btn_rect)


func _on_verdict_popup_id_pressed(id: int) -> void:
	match id:
		0: EvidenceManager.set_statement_verdict(_evidence_id, _statement_id, "contradiction")
		1: EvidenceManager.set_statement_verdict(_evidence_id, _statement_id, "supports")
		2: EvidenceManager.set_statement_verdict(_evidence_id, _statement_id, "unresolved")
		3: EvidenceManager.set_statement_verdict(_evidence_id, _statement_id, "unclassified")


func _on_note_changed() -> void:
	if _note_edit != null:
		EvidenceManager.set_statement_note(_evidence_id, _statement_id, _note_edit.text)
