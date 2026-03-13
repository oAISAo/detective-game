## insight_data.gd
## Represents a deductive insight derived from connecting evidence.
class_name InsightData
extends Resource


## Unique identifier for this insight.
@export var id: String = ""

## Description of the insight.
@export var description: String = ""

## IDs of evidence that led to this insight.
@export var source_evidence: Array[String] = []

## ID of the theory this insight strengthens (optional).
@export var strengthens_theory: String = ""

## ID of the warrant this insight enables (optional).
@export var enables_warrant: String = ""

## ID of the interrogation topic this insight unlocks (optional).
@export var unlocks_topic: String = ""


## Creates an InsightData from a JSON dictionary.
static func from_dict(data: Dictionary) -> InsightData:
	var res := InsightData.new()
	res.id = data.get("id", "")
	res.description = data.get("description", "")
	res.source_evidence.assign(data.get("source_evidence", []))
	res.strengthens_theory = data.get("strengthens_theory", "")
	res.enables_warrant = data.get("enables_warrant", "")
	res.unlocks_topic = data.get("unlocks_topic", "")
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("InsightData: id is required")
	if description.is_empty():
		errors.append("InsightData: description is required")
	if source_evidence.is_empty():
		errors.append("InsightData: source_evidence must not be empty")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"description": description,
		"source_evidence": source_evidence.duplicate(),
		"strengthens_theory": strengthens_theory,
		"enables_warrant": enables_warrant,
		"unlocks_topic": unlocks_topic,
	}
