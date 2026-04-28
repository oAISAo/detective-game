## statement_item.gd
## Displays a single statement with its current verdict and a button to cycle verdicts.
## Built programmatically — no .tscn needed.
class_name StatementItem
extends VBoxContainer


var _evidence_id: String = ""
var _statement_id: String = ""
var _verdict_button: Button = null


## Initializes this item with its evidence context and statement data.
## Must be called after add_child().
func setup(evidence_id: String, stmt: StatementData) -> void:
	_evidence_id = evidence_id
	_statement_id = stmt.id

	var person: PersonData = CaseManager.get_person(stmt.person_id)
	var person_name: String = person.name if person else stmt.person_id

	var text_label: Label = Label.new()
	text_label.text = "[%s] \"%s\"" % [person_name, stmt.text]
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(text_label)

	_verdict_button = Button.new()
	_verdict_button.pressed.connect(_on_verdict_pressed)
	add_child(_verdict_button)

	_refresh_verdict()


## Updates the verdict button label to reflect the current stored verdict.
func update_verdict() -> void:
	_refresh_verdict()


func _refresh_verdict() -> void:
	if _verdict_button == null:
		return
	var verdict: String = EvidenceManager.get_statement_verdict(_evidence_id, _statement_id)
	_verdict_button.text = verdict.to_upper()


func _on_verdict_pressed() -> void:
	var current: String = EvidenceManager.get_statement_verdict(_evidence_id, _statement_id)
	var verdicts: Array[String] = StatementVerdictData.VALID_VERDICTS
	var idx: int = verdicts.find(current)
	var next_idx: int = (idx + 1) % verdicts.size()
	EvidenceManager.set_statement_verdict(_evidence_id, _statement_id, verdicts[next_idx])
