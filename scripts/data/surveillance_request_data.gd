## surveillance_request_data.gd
## Represents a surveillance operation installed on a person.
class_name SurveillanceRequestData
extends Resource


## Unique identifier for this surveillance request.
@export var id: String = ""

## ID of the person being surveilled.
@export var target_person: String = ""

## Type of surveillance installed.
@export var type: Enums.SurveillanceType = Enums.SurveillanceType.PHONE_TAP

## Day the surveillance was installed.
@export var day_installed: int = 0

## Number of days the surveillance remains active.
@export var active_days: int = 1

## IDs of events produced by this surveillance.
@export var result_events: Array[String] = []


## Creates a SurveillanceRequestData from a JSON dictionary.
static func from_dict(data: Dictionary) -> SurveillanceRequestData:
	var res := SurveillanceRequestData.new()
	res.id = data.get("id", "")
	res.target_person = data.get("target_person", "")
	res.type = EnumHelper.parse_enum(
		Enums.SurveillanceType,
		data.get("type", "PHONE_TAP"),
		Enums.SurveillanceType.PHONE_TAP
	) as Enums.SurveillanceType
	res.day_installed = int(data.get("day_installed", 0))
	res.active_days = int(data.get("active_days", 1))
	res.result_events.assign(data.get("result_events", []))
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("SurveillanceRequestData: id is required")
	if target_person.is_empty():
		errors.append("SurveillanceRequestData: target_person is required")
	if active_days <= 0:
		errors.append("SurveillanceRequestData: active_days must be positive")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"target_person": target_person,
		"type": EnumHelper.enum_to_string(Enums.SurveillanceType, type),
		"day_installed": day_installed,
		"active_days": active_days,
		"result_events": result_events.duplicate(),
	}
