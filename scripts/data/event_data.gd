## event_data.gd
## Represents an event that occurred during the case timeline.
class_name EventData
extends Resource


## Unique identifier for this event.
@export var id: String = ""

## Description of what happened.
@export var description: String = ""

## Time the event occurred (e.g., "20:15").
@export var time: String = ""

## Day the event occurred (1-based).
@export var day: int = 0

## ID of the location where the event took place.
@export var location: String = ""

## IDs of persons involved in this event.
@export var involved_persons: Array[String] = []

## IDs of evidence that supports this event.
@export var supporting_evidence: Array[String] = []

## How certain we are this event occurred.
@export var certainty_level: Enums.CertaintyLevel = Enums.CertaintyLevel.UNKNOWN


## Creates an EventData from a JSON dictionary.
static func from_dict(data: Dictionary) -> EventData:
	var res := EventData.new()
	res.id = data.get("id", "")
	res.description = data.get("description", "")
	res.time = data.get("time", "")
	res.day = int(data.get("day", 0))
	res.location = data.get("location", "")
	res.involved_persons.assign(data.get("involved_persons", []))
	res.supporting_evidence.assign(data.get("supporting_evidence", []))
	res.certainty_level = EnumHelper.parse_enum(
		Enums.CertaintyLevel,
		data.get("certainty_level", "UNKNOWN"),
		Enums.CertaintyLevel.UNKNOWN
	) as Enums.CertaintyLevel
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("EventData: id is required")
	if description.is_empty():
		errors.append("EventData: description is required")
	if day <= 0:
		errors.append("EventData: day must be positive")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"description": description,
		"time": time,
		"day": day,
		"location": location,
		"involved_persons": involved_persons.duplicate(),
		"supporting_evidence": supporting_evidence.duplicate(),
		"certainty_level": EnumHelper.enum_to_string(Enums.CertaintyLevel, certainty_level),
	}
