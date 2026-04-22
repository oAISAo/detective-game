## investigable_object_data.gd
## Represents an object at a location that can be investigated.
class_name InvestigableObjectData
extends Resource


## Unique identifier for this object.
@export var id: String = ""

## Display name of the object.
@export var name: String = ""

## Description of the object.
@export var description: String = ""

## Available investigative actions (e.g., "visual_inspection", "fingerprint_analysis").
@export var available_actions: Array[String] = []

## Tools required to perform certain actions (e.g., "fingerprint_powder", "uv_light").
@export var tool_requirements: Array[String] = []

## IDs of evidence that can be found through this object.
@export var evidence_results: Array[String] = []

## Current investigation state of this object.
@export var investigation_state: Enums.InvestigationState = Enums.InvestigationState.NOT_INSPECTED

## Condition that must be met for this object to become visible.
## Format: { "requires_evidence": ["ev_id1", "ev_id2"] }
## Empty dictionary means always visible.
@export var discovery_condition: Dictionary = {}


## Creates an InvestigableObjectData from a JSON dictionary.
static func from_dict(data: Dictionary) -> InvestigableObjectData:
	var res := InvestigableObjectData.new()
	res.id = data.get("id", "")
	res.name = data.get("name", "")
	res.description = data.get("description", "")
	res.available_actions.assign(data.get("available_actions", []))
	res.tool_requirements.assign(data.get("tool_requirements", []))
	res.evidence_results.assign(data.get("evidence_results", []))
	res.investigation_state = EnumHelper.parse_enum(
		Enums.InvestigationState,
		data.get("investigation_state", "NOT_INSPECTED"),
		Enums.InvestigationState.NOT_INSPECTED
	) as Enums.InvestigationState
	res.discovery_condition = data.get("discovery_condition", {})
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("InvestigableObjectData: id is required")
	if name.is_empty():
		errors.append("InvestigableObjectData: name is required")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"available_actions": available_actions.duplicate(),
		"tool_requirements": tool_requirements.duplicate(),
		"evidence_results": evidence_results.duplicate(),
		"investigation_state": EnumHelper.enum_to_string(Enums.InvestigationState, investigation_state),
		"discovery_condition": discovery_condition.duplicate(),
	}
