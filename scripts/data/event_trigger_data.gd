## event_trigger_data.gd
## Represents a trigger that fires events based on conditions or timing.
class_name EventTriggerData
extends Resource


## Unique identifier for this trigger.
@export var id: String = ""

## How the trigger is activated.
@export var trigger_type: Enums.TriggerType = Enums.TriggerType.TIMED

## Day the trigger fires (for TIMED and DAY_START types). -1 = any day.
@export var trigger_day: int = -1

## Conditions that must be met for the trigger to fire.
## Format: "condition_type:value" (e.g., "evidence_discovered:ev_knife")
@export var conditions: Array[String] = []

## Actions to execute when the trigger fires.
@export var actions: Array[String] = []

## IDs of events produced when this trigger fires.
@export var result_events: Array[String] = []


## Creates an EventTriggerData from a JSON dictionary.
static func from_dict(data: Dictionary) -> EventTriggerData:
	var res := EventTriggerData.new()
	res.id = data.get("id", "")
	res.trigger_type = EnumHelper.parse_enum(
		Enums.TriggerType,
		data.get("trigger_type", "TIMED"),
		Enums.TriggerType.TIMED
	) as Enums.TriggerType
	res.trigger_day = int(data.get("trigger_day", -1))
	res.conditions.assign(data.get("conditions", []))
	res.actions.assign(data.get("actions", []))
	res.result_events.assign(data.get("result_events", []))
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("EventTriggerData: id is required")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"trigger_type": EnumHelper.enum_to_string(Enums.TriggerType, trigger_type),
		"trigger_day": trigger_day,
		"conditions": conditions.duplicate(),
		"actions": actions.duplicate(),
		"result_events": result_events.duplicate(),
	}
