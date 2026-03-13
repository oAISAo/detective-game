## enum_helper.gd
## Utility class for converting between enum string names and values.
## Used by all Resource data classes when parsing JSON case data.
class_name EnumHelper


## Converts a string name to an enum integer value.
## enum_type: the enum dictionary (e.g., Enums.EvidenceType)
## value: the string key to parse (e.g., "FORENSIC")
## default_value: returned if the string doesn't match any key
static func parse_enum(enum_type, value: String, default_value: int = 0) -> int:
	var key := value.to_upper().strip_edges()
	if key == "":
		return default_value
	if key in enum_type:
		return enum_type[key]
	push_warning("EnumHelper: Unknown enum value '%s'" % value)
	return default_value


## Converts an enum integer value back to its string name.
static func enum_to_string(enum_type, value: int) -> String:
	for key: String in enum_type:
		if enum_type[key] == value:
			return key
	return "UNKNOWN"


## Parses an array of string names to an array of enum integer values.
static func parse_enum_array(enum_type, values: Array) -> Array[int]:
	var result: Array[int] = []
	for v in values:
		if v is String:
			result.append(parse_enum(enum_type, v))
	return result


## Converts an array of enum integer values back to string names.
static func enum_array_to_strings(enum_type, values: Array) -> Array[String]:
	var result: Array[String] = []
	for v in values:
		if v is int:
			result.append(enum_to_string(enum_type, v))
	return result
