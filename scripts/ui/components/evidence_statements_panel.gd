## evidence_statements_panel.gd
## Displays all player-unlocked statements linked to a given evidence item.
## Handles verdict display and reacts to verdict changes via EvidenceManager signal.
## Built programmatically — no .tscn needed.
class_name EvidenceStatementsPanel
extends VBoxContainer


var _evidence_id: String = ""

## Maps statement_id -> StatementItem for targeted updates.
var _items: Dictionary = {}


func _ready() -> void:
	EvidenceManager.statement_verdict_changed.connect(_on_verdict_changed)


func _exit_tree() -> void:
	if EvidenceManager.statement_verdict_changed.is_connected(_on_verdict_changed):
		EvidenceManager.statement_verdict_changed.disconnect(_on_verdict_changed)


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
		return

	for stmt: StatementData in statements:
		var item: StatementItem = StatementItem.new()
		add_child(item)
		item.setup(_evidence_id, stmt)
		_items[stmt.id] = item


func _on_verdict_changed(evidence_id: String, statement_id: String, _verdict: String) -> void:
	if evidence_id != _evidence_id:
		return
	var item: StatementItem = _items.get(statement_id, null)
	if item != null:
		item.update_verdict()
