## location_data.gd
## Represents a location that can be investigated.
class_name LocationData
extends Resource


## Unique identifier for this location.
@export var id: String = ""

## Display name of the location.
@export var name: String = ""

## Whether this location can be searched for evidence.
@export var searchable: bool = true

## Objects at this location that can be investigated.
var investigable_objects: Array[InvestigableObjectData] = []

## IDs of evidence available at this location.
@export var evidence_pool: Array[String] = []


## Creates a LocationData from a JSON dictionary.
static func from_dict(data: Dictionary) -> LocationData:
	var res := LocationData.new()
	res.id = data.get("id", "")
	res.name = data.get("name", "")
	res.searchable = data.get("searchable", true)
	# Parse investigable objects
	res.investigable_objects = []
	for obj_dict: Dictionary in data.get("investigable_objects", []):
		res.investigable_objects.append(InvestigableObjectData.from_dict(obj_dict))
	res.evidence_pool.assign(data.get("evidence_pool", []))
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("LocationData: id is required")
	if name.is_empty():
		errors.append("LocationData: name is required")
	# Validate nested objects
	for obj: InvestigableObjectData in investigable_objects:
		errors.append_array(obj.validate())
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	var obj_dicts: Array[Dictionary] = []
	for obj: InvestigableObjectData in investigable_objects:
		obj_dicts.append(obj.to_dict())
	return {
		"id": id,
		"name": name,
		"searchable": searchable,
		"investigable_objects": obj_dicts,
		"evidence_pool": evidence_pool.duplicate(),
	}
