## action_data.gd
## Represents an action the player can perform during investigation.
class_name ActionData
extends Resource


## Unique identifier for this action.
@export var id: String = ""

## Display name of the action.
@export var name: String = ""

## The type of action.
@export var type: Enums.ActionType = Enums.ActionType.VISIT_LOCATION

## How many time slots this action costs (0 = passive action).
@export var time_cost: int = 1

## ID of the target (person, location, evidence, etc.).
@export var target: String = ""

## Requirements that must be met for this action to be available.
## Format: "requirement_type:value" (e.g., "evidence:ev_knife", "warrant:w_01")
@export var requirements: Array[String] = []

## Results produced by completing this action.
## Format: "result_type:value" (e.g., "evidence:ev_new", "event:evt_reveal")
@export var results: Array[String] = []


## Creates an ActionData from a JSON dictionary.
static func from_dict(data: Dictionary) -> ActionData:
	var res := ActionData.new()
	res.id = data.get("id", "")
	res.name = data.get("name", "")
	res.type = EnumHelper.parse_enum(
		Enums.ActionType,
		data.get("type", "VISIT_LOCATION"),
		Enums.ActionType.VISIT_LOCATION
	) as Enums.ActionType
	res.time_cost = int(data.get("time_cost", 1))
	res.target = data.get("target", "")
	res.requirements.assign(data.get("requirements", []))
	res.results.assign(data.get("results", []))
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("ActionData: id is required")
	if name.is_empty():
		errors.append("ActionData: name is required")
	if time_cost < 0:
		errors.append("ActionData: time_cost must be non-negative")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"type": EnumHelper.enum_to_string(Enums.ActionType, type),
		"time_cost": time_cost,
		"target": target,
		"requirements": requirements.duplicate(),
		"results": results.duplicate(),
	}
