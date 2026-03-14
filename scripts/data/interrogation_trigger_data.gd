## interrogation_trigger_data.gd
## Represents an evidence-based interrogation trigger.
## When the player presents matching evidence to a suspect, this trigger fires,
## producing a reaction, dialogue, new statement, and pressure accumulation.
class_name InterrogationTriggerData
extends Resource


## Unique identifier for this trigger.
@export var id: String = ""

## ID of the person (suspect) this trigger applies to.
@export var person_id: String = ""

## ID of the evidence that activates this trigger.
@export var evidence_id: String = ""

## Optional: ID of a statement that must have been heard before this trigger fires at full strength.
## If the player presents evidence before hearing the relevant claim, the reaction is weaker.
@export var requires_statement_id: String = ""

## How impactful this trigger is (MINOR, MAJOR, BREAKPOINT).
@export var impact_level: Enums.ImpactLevel = Enums.ImpactLevel.MINOR

## The type of reaction the suspect displays.
@export var reaction_type: Enums.ReactionType = Enums.ReactionType.DENIAL

## The dialogue text the suspect says when this trigger fires.
@export var dialogue: String = ""

## ID of the new statement produced when this trigger fires.
@export var new_statement_id: String = ""

## IDs of evidence or topics unlocked when this trigger fires.
@export var unlocks: Array[String] = []

## How many pressure points this trigger adds to the suspect.
@export var pressure_points: int = 0

## ID of the person referenced in a DEFLECTION reaction (e.g., "talk to Julia").
@export var deflection_target_id: String = ""


## Creates an InterrogationTriggerData from a JSON dictionary.
static func from_dict(data: Dictionary) -> InterrogationTriggerData:
	var res := InterrogationTriggerData.new()
	res.id = data.get("id", "")
	res.person_id = data.get("person_id", "")
	res.evidence_id = data.get("evidence_id", "")
	res.requires_statement_id = data.get("requires_statement_id", "")
	res.impact_level = EnumHelper.parse_enum(
		Enums.ImpactLevel,
		data.get("impact_level", "MINOR"),
		Enums.ImpactLevel.MINOR
	) as Enums.ImpactLevel
	res.reaction_type = EnumHelper.parse_enum(
		Enums.ReactionType,
		data.get("reaction_type", "DENIAL"),
		Enums.ReactionType.DENIAL
	) as Enums.ReactionType
	res.dialogue = data.get("dialogue", "")
	res.new_statement_id = data.get("new_statement_id", "")
	res.unlocks.assign(data.get("unlocks", []))
	res.pressure_points = int(data.get("pressure_points", 0))
	res.deflection_target_id = data.get("deflection_target_id", "")
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("InterrogationTriggerData: id is required")
	if person_id.is_empty():
		errors.append("InterrogationTriggerData: person_id is required")
	if evidence_id.is_empty():
		errors.append("InterrogationTriggerData: evidence_id is required")
	if dialogue.is_empty():
		errors.append("InterrogationTriggerData: dialogue is required")
	if reaction_type == Enums.ReactionType.DEFLECTION and deflection_target_id.is_empty():
		errors.append("InterrogationTriggerData: deflection_target_id required for DEFLECTION reaction")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"person_id": person_id,
		"evidence_id": evidence_id,
		"requires_statement_id": requires_statement_id,
		"impact_level": EnumHelper.enum_to_string(Enums.ImpactLevel, impact_level),
		"reaction_type": EnumHelper.enum_to_string(Enums.ReactionType, reaction_type),
		"dialogue": dialogue,
		"new_statement_id": new_statement_id,
		"unlocks": unlocks.duplicate(),
		"pressure_points": pressure_points,
		"deflection_target_id": deflection_target_id,
	}
