## interrogation_session_data.gd
## Data definition for a suspect's interrogation session.
## Bundles the initial dialogue, statement entries, base topics,
## rejection texts, and pressure threshold for one suspect.
class_name InterrogationSessionData
extends Resource


## ID of the person this session data belongs to.
@export var person_id: String = ""

## The suspect's initial story shown during statement intake.
@export var initial_dialogue: String = ""

## Statement IDs that are generated from the initial dialogue.
## Each represents a single challengeable claim.
@export var initial_statement_ids: Array[String] = []

## Topic IDs available from the start (no conditions required).
@export var base_topic_ids: Array[String] = []

## Number of contradictions required before Apply Pressure becomes usable.
@export var pressure_gate: int = 1

## Natural rejection texts shown when evidence doesn't match the current focus.
## Randomized from this pool to avoid repetitive feedback.
@export var rejection_texts: Array[String] = []

## Dialogue shown when player applies pressure but break moment is not yet reached.
@export var pressure_dialogue: String = ""

## Dialogue shown when the suspect breaks under pressure.
@export var break_dialogue: String = ""

## Statement IDs auto-recorded when the break moment triggers.
@export var break_statement_ids: Array[String] = []

## Topic or evidence IDs unlocked when the break moment triggers.
@export var break_unlocks: Array[String] = []


## Creates an InterrogationSessionData from a JSON dictionary.
static func from_dict(data: Dictionary) -> InterrogationSessionData:
	var res := InterrogationSessionData.new()
	res.person_id = data.get("person_id", "")
	res.initial_dialogue = data.get("initial_dialogue", "")
	res.initial_statement_ids.assign(data.get("initial_statement_ids", []))
	res.base_topic_ids.assign(data.get("base_topic_ids", []))
	res.pressure_gate = int(data.get("pressure_gate", 1))
	res.rejection_texts.assign(data.get("rejection_texts", []))
	res.pressure_dialogue = data.get("pressure_dialogue", "")
	res.break_dialogue = data.get("break_dialogue", "")
	res.break_statement_ids.assign(data.get("break_statement_ids", []))
	res.break_unlocks.assign(data.get("break_unlocks", []))
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if person_id.is_empty():
		errors.append("InterrogationSessionData: person_id is required")
	if initial_dialogue.is_empty():
		errors.append("InterrogationSessionData: initial_dialogue is required")
	if initial_statement_ids.is_empty():
		errors.append("InterrogationSessionData: initial_statement_ids must not be empty")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"person_id": person_id,
		"initial_dialogue": initial_dialogue,
		"initial_statement_ids": initial_statement_ids.duplicate(),
		"base_topic_ids": base_topic_ids.duplicate(),
		"pressure_gate": pressure_gate,
		"rejection_texts": rejection_texts.duplicate(),
		"pressure_dialogue": pressure_dialogue,
		"break_dialogue": break_dialogue,
		"break_statement_ids": break_statement_ids.duplicate(),
		"break_unlocks": break_unlocks.duplicate(),
	}
