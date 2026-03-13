## person_data.gd
## Represents a person involved in the case.
class_name PersonData
extends Resource


## Unique identifier for this person.
@export var id: String = ""

## Display name of the person.
@export var name: String = ""

## Role this person plays in the case.
@export var role: Enums.PersonRole = Enums.PersonRole.WITNESS

## Personality traits that affect interrogation behavior.
var personality_traits: Array[int] = []  # Enums.PersonalityTrait values

## Relationships this person has with other persons.
var relationships: Array[RelationshipData] = []

## Pressure threshold before the suspect may crack during interrogation.
@export var pressure_threshold: int = 0


## Creates a PersonData from a JSON dictionary.
static func from_dict(data: Dictionary) -> PersonData:
	var res := PersonData.new()
	res.id = data.get("id", "")
	res.name = data.get("name", "")
	res.role = EnumHelper.parse_enum(
		Enums.PersonRole,
		data.get("role", "WITNESS"),
		Enums.PersonRole.WITNESS
	) as Enums.PersonRole
	res.personality_traits = EnumHelper.parse_enum_array(
		Enums.PersonalityTrait,
		data.get("personality_traits", [])
	)
	# Parse relationships
	res.relationships = []
	for rel_dict: Dictionary in data.get("relationships", []):
		# Inject person_a if not present (it's the owner of this person entry)
		if not rel_dict.has("person_a"):
			rel_dict["person_a"] = res.id
		res.relationships.append(RelationshipData.from_dict(rel_dict))
	res.pressure_threshold = int(data.get("pressure_threshold", 0))
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("PersonData: id is required")
	if name.is_empty():
		errors.append("PersonData: name is required")
	# Validate nested relationships
	for rel: RelationshipData in relationships:
		errors.append_array(rel.validate())
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	var rel_dicts: Array[Dictionary] = []
	for rel: RelationshipData in relationships:
		rel_dicts.append(rel.to_dict())
	return {
		"id": id,
		"name": name,
		"role": EnumHelper.enum_to_string(Enums.PersonRole, role),
		"personality_traits": EnumHelper.enum_array_to_strings(Enums.PersonalityTrait, personality_traits),
		"relationships": rel_dicts,
		"pressure_threshold": pressure_threshold,
	}
