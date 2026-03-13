## relationship_data.gd
## Represents a relationship between two persons in the case.
class_name RelationshipData
extends Resource


## ID of the first person in the relationship.
@export var person_a: String = ""

## ID of the second person in the relationship.
@export var person_b: String = ""

## The type of relationship.
@export var type: Enums.RelationshipType = Enums.RelationshipType.FRIEND


## Creates a RelationshipData from a JSON dictionary.
static func from_dict(data: Dictionary) -> RelationshipData:
	var res := RelationshipData.new()
	res.person_a = data.get("person_a", "")
	res.person_b = data.get("person_b", "")
	res.type = EnumHelper.parse_enum(
		Enums.RelationshipType,
		data.get("type", "FRIEND"),
		Enums.RelationshipType.FRIEND
	) as Enums.RelationshipType
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if person_b.is_empty():
		errors.append("RelationshipData: person_b is required")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"person_a": person_a,
		"person_b": person_b,
		"type": EnumHelper.enum_to_string(Enums.RelationshipType, type),
	}
