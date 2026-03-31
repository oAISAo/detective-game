## case_loader.gd
## Loads case data from a multi-file folder structure.
## Each case folder contains separate JSON files for different data categories.
## Merges all files into a single dictionary and returns CaseData.
class_name CaseLoader
extends RefCounted


## File names expected inside a case folder (order matters for merging).
const CASE_FILES: Array[String] = [
	"case.json",
	"suspects.json",
	"locations.json",
	"evidence.json",
	"timeline.json",
	"events.json",
	"discovery_rules.json",
]

## Required files that must exist for a valid case.
const REQUIRED_FILES: Array[String] = [
	"case.json",
	"suspects.json",
	"locations.json",
	"evidence.json",
]


## Loads a case from a folder under res://data/cases/.
## Returns CaseData on success, null on failure.
## Errors are appended to the provided errors array.
static func load_from_folder(folder_name: String, errors: Array[String]) -> CaseData:
	var base_path: String = "res://data/cases/%s" % folder_name

	# Validate folder exists by checking for the required case.json
	if not FileAccess.file_exists("%s/case.json" % base_path):
		errors.append("Case folder not found or missing case.json: %s" % base_path)
		return null

	# Check required files exist
	for required_file: String in REQUIRED_FILES:
		var file_path: String = "%s/%s" % [base_path, required_file]
		if not FileAccess.file_exists(file_path):
			errors.append("Required file missing: %s" % file_path)
			return null

	# Load and merge all JSON files
	var merged: Dictionary = {}
	for file_name: String in CASE_FILES:
		var file_path: String = "%s/%s" % [base_path, file_name]
		if not FileAccess.file_exists(file_path):
			continue

		var file_data: Dictionary = _load_json_file(file_path, errors)
		if file_data.is_empty() and file_name in REQUIRED_FILES:
			return null

		_merge_file_data(merged, file_data, file_name)

	# Convert merged dictionary to CaseData
	var case_data: CaseData = CaseData.from_dict(merged)
	return case_data


## Loads and parses a single JSON file. Returns empty dict on error.
static func _load_json_file(path: String, errors: Array[String]) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Failed to open file: %s" % path)
		return {}

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_text)
	if parse_result != OK:
		errors.append("JSON parse error in %s at line %d: %s" % [
			path, json.get_error_line(), json.get_error_message()
		])
		return {}

	if json.data is Dictionary:
		return json.data as Dictionary

	errors.append("Expected JSON object in %s, got %s" % [path, typeof(json.data)])
	return {}


## Merges data from a specific file into the combined case dictionary.
## Each file maps to specific keys in the merged structure.
static func _merge_file_data(merged: Dictionary, data: Dictionary, file_name: String) -> void:
	match file_name:
		"case.json":
			# case.json provides top-level metadata and solution
			for key: String in data.keys():
				merged[key] = data[key]

		"suspects.json":
			# suspects.json provides the persons array
			if data.has("persons"):
				merged["persons"] = data["persons"]

		"locations.json":
			# locations.json provides the locations array
			if data.has("locations"):
				merged["locations"] = data["locations"]

		"evidence.json":
			# evidence.json provides the evidence array
			if data.has("evidence"):
				merged["evidence"] = data["evidence"]

		"timeline.json":
			# timeline.json provides events, statements, and actions
			if data.has("events"):
				merged["events"] = data["events"]
			if data.has("statements"):
				merged["statements"] = data["statements"]
			if data.has("actions"):
				merged["actions"] = data["actions"]
			if data.has("insights"):
				merged["insights"] = data["insights"]
			if data.has("lab_requests"):
				merged["lab_requests"] = data["lab_requests"]
			if data.has("surveillance_requests"):
				merged["surveillance_requests"] = data["surveillance_requests"]

		"events.json":
			# events.json provides event triggers, interrogation topics/triggers
			if data.has("event_triggers"):
				merged["event_triggers"] = data["event_triggers"]
			if data.has("interrogation_topics"):
				merged["interrogation_topics"] = data["interrogation_topics"]
			if data.has("interrogation_triggers"):
				merged["interrogation_triggers"] = data["interrogation_triggers"]
			if data.has("interrogation_sessions"):
				merged["interrogation_sessions"] = data["interrogation_sessions"]

		"discovery_rules.json":
			# discovery_rules.json provides discovery rules
			if data.has("discovery_rules"):
				merged["discovery_rules"] = data["discovery_rules"]
