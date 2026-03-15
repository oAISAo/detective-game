## discovery_rule_data.gd
## Represents a conditional rule that gates evidence availability at a location.
## When all conditions are met, the specified evidence becomes discoverable.
class_name DiscoveryRuleData
extends Resource


## Unique identifier for this discovery rule.
@export var id: String = ""

## ID of the evidence this rule makes available.
@export var evidence_id: String = ""

## ID of the location where evidence becomes available.
@export var location_id: String = ""

## Conditions that must all be met for evidence to be discoverable.
## Format: "condition_type:value" (same as EventTriggerData conditions).
## Supported: day_gte, evidence_discovered, location_visited, warrant_obtained,
##            trigger_fired, action_completed, insight_discovered
@export var conditions: Array[String] = []

## Optional description explaining what makes this evidence available.
@export var description: String = ""


## Creates a DiscoveryRuleData from a JSON dictionary.
static func from_dict(data: Dictionary) -> DiscoveryRuleData:
	var res := DiscoveryRuleData.new()
	res.id = data.get("id", "")
	res.evidence_id = data.get("evidence_id", "")
	res.location_id = data.get("location_id", "")
	res.conditions.assign(data.get("conditions", []))
	res.description = data.get("description", "")
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("DiscoveryRuleData: id is required")
	if evidence_id.is_empty():
		errors.append("DiscoveryRuleData: evidence_id is required")
	if location_id.is_empty():
		errors.append("DiscoveryRuleData: location_id is required")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"evidence_id": evidence_id,
		"location_id": location_id,
		"conditions": conditions.duplicate(),
		"description": description,
	}
