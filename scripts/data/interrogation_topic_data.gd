## interrogation_topic_data.gd
## Represents a topic that can be discussed during interrogation.
class_name InterrogationTopicData
extends Resource


## Unique identifier for this topic.
@export var id: String = ""

## ID of the person this topic is about.
@export var person_id: String = ""

## Display name of the topic.
@export var topic_name: String = ""

## Conditions that must be met for this topic to appear.
## Format: "condition_type:value" (e.g., "evidence:ev_knife")
@export var trigger_conditions: Array[String] = []

## IDs of evidence that become available when this topic is discussed.
@export var unlock_evidence: Array[String] = []

## IDs of statements produced by discussing this topic.
@export var statements: Array[String] = []

## IDs of evidence required to confront the suspect with this topic.
@export var required_evidence: Array[String] = []

## ID of a statement that must exist before this topic can be raised.
@export var requires_statement_id: String = ""

## How impactful this topic is during interrogation.
@export var impact_level: Enums.ImpactLevel = Enums.ImpactLevel.MINOR


## Creates an InterrogationTopicData from a JSON dictionary.
static func from_dict(data: Dictionary) -> InterrogationTopicData:
	var res := InterrogationTopicData.new()
	res.id = data.get("id", "")
	res.person_id = data.get("person_id", "")
	res.topic_name = data.get("topic_name", "")
	res.trigger_conditions.assign(data.get("trigger_conditions", []))
	res.unlock_evidence.assign(data.get("unlock_evidence", []))
	res.statements.assign(data.get("statements", []))
	res.required_evidence.assign(data.get("required_evidence", []))
	res.requires_statement_id = data.get("requires_statement_id", "")
	res.impact_level = EnumHelper.parse_enum(
		Enums.ImpactLevel,
		data.get("impact_level", "MINOR"),
		Enums.ImpactLevel.MINOR
	) as Enums.ImpactLevel
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("InterrogationTopicData: id is required")
	if person_id.is_empty():
		errors.append("InterrogationTopicData: person_id is required")
	if topic_name.is_empty():
		errors.append("InterrogationTopicData: topic_name is required")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"person_id": person_id,
		"topic_name": topic_name,
		"trigger_conditions": trigger_conditions.duplicate(),
		"unlock_evidence": unlock_evidence.duplicate(),
		"statements": statements.duplicate(),
		"required_evidence": required_evidence.duplicate(),
		"requires_statement_id": requires_statement_id,
		"impact_level": EnumHelper.enum_to_string(Enums.ImpactLevel, impact_level),
	}
