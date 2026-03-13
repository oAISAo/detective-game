## statement_data.gd
## Represents a statement made by a person during interrogation.
class_name StatementData
extends Resource


## Unique identifier for this statement.
@export var id: String = ""

## ID of the person who made the statement.
@export var person_id: String = ""

## The text of the statement.
@export var text: String = ""

## The day the statement was given (1-based).
@export var day_given: int = 0

## IDs of evidence items related to this statement.
@export var related_evidence: Array[String] = []

## ID of the event this statement relates to (optional).
@export var related_event: String = ""

## IDs of evidence items that potentially contradict this statement.
@export var contradicting_evidence: Array[String] = []


## Creates a StatementData from a JSON dictionary.
static func from_dict(data: Dictionary) -> StatementData:
	var res := StatementData.new()
	res.id = data.get("id", "")
	res.person_id = data.get("person_id", "")
	res.text = data.get("text", "")
	res.day_given = int(data.get("day_given", 0))
	res.related_evidence.assign(data.get("related_evidence", []))
	res.related_event = data.get("related_event", "")
	res.contradicting_evidence.assign(data.get("contradicting_evidence", []))
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("StatementData: id is required")
	if person_id.is_empty():
		errors.append("StatementData: person_id is required")
	if text.is_empty():
		errors.append("StatementData: text is required")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"person_id": person_id,
		"text": text,
		"day_given": day_given,
		"related_evidence": related_evidence.duplicate(),
		"related_event": related_event,
		"contradicting_evidence": contradicting_evidence.duplicate(),
	}
