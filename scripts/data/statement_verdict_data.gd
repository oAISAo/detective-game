## statement_verdict_data.gd
## Stores the player's classification of a statement relative to one piece of evidence.
class_name StatementVerdictData


const VALID_VERDICTS: Array[String] = ["unclassified", "contradiction", "supports", "unresolved"]

var evidence_id: String = ""
var statement_id: String = ""
var verdict: String = "unclassified"
var player_note: String = ""


func _init(ev_id: String, stmt_id: String) -> void:
	evidence_id = ev_id
	statement_id = stmt_id


func to_dict() -> Dictionary:
	return {
		"evidence_id": evidence_id,
		"statement_id": statement_id,
		"verdict": verdict,
		"player_note": player_note,
	}


static func from_dict(data: Dictionary) -> StatementVerdictData:
	var obj := StatementVerdictData.new(
		data.get("evidence_id", ""),
		data.get("statement_id", "")
	)
	obj.verdict = data.get("verdict", "unclassified")
	obj.player_note = data.get("player_note", "")
	return obj
