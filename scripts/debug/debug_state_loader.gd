## debug_state_loader.gd
## Loads a debug preset JSON file and applies it to the game state.
## Used to quickly set up specific game scenarios for testing.
class_name DebugStateLoader
extends RefCounted


## Default path for debug preset files.
const DEBUG_DIR: String = "res://data/debug/"


## Loads a debug preset from a JSON file and applies it to the game state.
## Returns true if the debug state was loaded and applied successfully.
static func load_debug_state(filename: String) -> bool:
	var path: String = DEBUG_DIR + filename
	if not FileAccess.file_exists(path):
		push_error("[DebugStateLoader] Debug file not found: %s" % path)
		return false

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[DebugStateLoader] Cannot open debug file: %s" % path)
		return false

	var json_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var error: Error = json.parse(json_text)
	if error != OK:
		push_error("[DebugStateLoader] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return false

	var data: Dictionary = json.data
	if not data.has("case_id") or not data.has("game_state"):
		push_error("[DebugStateLoader] Debug file missing required fields: case_id, game_state")
		return false

	return _apply_debug_state(data)


## Lists all available debug preset files in the debug directory.
static func list_presets() -> Array[String]:
	var presets: Array[String] = []
	var dir: DirAccess = DirAccess.open(DEBUG_DIR)
	if dir == null:
		return presets

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			presets.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return presets


## Applies the parsed debug data to game systems.
static func _apply_debug_state(data: Dictionary) -> bool:
	var case_id: String = data.get("case_id", "")
	var game_state: Dictionary = data.get("game_state", {})
	var notifications: Array = data.get("notifications", [])

	# Reset and prepare game state
	GameManager.new_game()

	# Load the case
	CaseManager.unload_case()
	if not CaseManager.load_case_folder(case_id):
		push_error("[DebugStateLoader] Failed to load case: %s" % case_id)
		return false

	# Apply game state via deserialize for core fields
	GameManager.deserialize(game_state)

	# Send notifications
	var notif_mgr: Node = Engine.get_singleton("NotificationManager") if Engine.has_singleton("NotificationManager") else null
	if notif_mgr == null:
		notif_mgr = GameManager.get_node_or_null("/root/NotificationManager")
	if notif_mgr and notif_mgr.has_method("notify"):
		for msg: String in notifications:
			notif_mgr.call("notify", msg, msg)

	print("[DebugStateLoader] Debug state loaded: %s" % data.get("name", case_id))
	return true
