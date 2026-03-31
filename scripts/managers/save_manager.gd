## SaveManager.gd
## Handles saving and loading game state to disk.
## Supports 3 save slots with version tracking.
extends Node


# --- Constants --- #

## Current save data version. Increment when save format changes.
const SAVE_VERSION: int = 1

## Number of available save slots.
const MAX_SAVE_SLOTS: int = 3

## Directory where save files are stored.
const SAVE_DIR: String = "user://saves/"

## File extension for save files.
const SAVE_EXTENSION: String = ".json"


# --- Signals --- #

## Emitted when a game is saved successfully.
signal game_saved(slot: int)

## Emitted when a game is loaded successfully.
signal game_loaded(slot: int)

## Emitted when a save/load operation fails.
signal save_error(message: String)

## Emitted when a save version mismatch is detected.
signal version_mismatch(save_version: int, current_version: int)


# --- Lifecycle --- #

func _ready() -> void:
	_ensure_save_directory()
	print("[SaveManager] Initialized. Save directory: %s" % SAVE_DIR)


# --- Public API --- #

## Saves the current game state to the specified slot (1-3).
func save_game(slot: int) -> bool:
	if not _is_valid_slot(slot):
		save_error.emit("Invalid save slot: %d" % slot)
		return false
	
	var save_data: Dictionary = _build_save_data()
	var json_string: String = JSON.stringify(save_data, "\t")
	var path: String = _get_save_path(slot)
	var tmp_path: String = path + ".tmp"

	# Write to a temp file first so a crash mid-write won't corrupt the real save
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		var error_msg: String = "Failed to open save file: %s (Error: %s)" % [
			tmp_path, error_string(FileAccess.get_open_error())
		]
		push_error(error_msg)
		save_error.emit(error_msg)
		return false

	file.store_string(json_string)
	file.close()

	# Atomic rename: replaces the target file in one operation
	var rename_err: Error = DirAccess.rename_absolute(tmp_path, path)
	if rename_err != OK:
		var error_msg: String = "Failed to rename temp save to final path: %s" % error_string(rename_err)
		push_error(error_msg)
		save_error.emit(error_msg)
		return false

	game_saved.emit(slot)
	print("[SaveManager] Game saved to slot %d." % slot)
	return true


## Loads game state from the specified slot (1-3).
func load_game(slot: int) -> bool:
	if not _is_valid_slot(slot):
		save_error.emit("Invalid save slot: %d" % slot)
		return false
	
	var path: String = _get_save_path(slot)
	
	if not FileAccess.file_exists(path):
		save_error.emit("No save file found in slot %d." % slot)
		return false
	
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var error_msg: String = "Failed to open save file: %s" % path
		push_error(error_msg)
		save_error.emit(error_msg)
		return false
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_text)
	if parse_result != OK:
		var error_msg: String = "Corrupted save file in slot %d: %s" % [
			slot, json.get_error_message()
		]
		push_error(error_msg)
		save_error.emit(error_msg)
		return false
	
	var save_data: Dictionary = json.data
	
	# Version check
	var file_version: int = save_data.get("save_version", 0)
	if file_version != SAVE_VERSION:
		version_mismatch.emit(file_version, SAVE_VERSION)
		push_warning("[SaveManager] Save version mismatch: file=%d, current=%d" % [
			file_version, SAVE_VERSION
		])
	
	# Restore state
	_restore_save_data(save_data)
	
	game_loaded.emit(slot)
	print("[SaveManager] Game loaded from slot %d." % slot)
	return true


## Deletes the save file in the specified slot.
func delete_save(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	
	var path: String = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false
	
	var err: Error = DirAccess.remove_absolute(path)
	if err != OK:
		push_error("[SaveManager] Failed to delete save in slot %d." % slot)
		return false
	
	print("[SaveManager] Save slot %d deleted." % slot)
	return true


## Returns true if a save file exists in the given slot.
func has_save(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	return FileAccess.file_exists(_get_save_path(slot))


## Returns metadata about a save slot (for display in the UI).
func get_save_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {"exists": false}
	
	var path: String = _get_save_path(slot)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": false}
	
	var json_text: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	if json.parse(json_text) != OK:
		return {"exists": false}
	
	var data: Dictionary = json.data
	return {
		"exists": true,
		"save_version": data.get("save_version", 0),
		"current_day": data.get("game_state", {}).get("current_day", 1),
		"save_timestamp": data.get("save_timestamp", ""),
		"evidence_count": data.get("game_state", {}).get("discovered_evidence", []).size(),
	}


# --- Internal --- #

## Ensures the save directory exists.
func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


## Returns the file path for a given save slot.
func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_slot_%d%s" % [slot, SAVE_EXTENSION]


## Returns true if the slot number is valid.
func _is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= MAX_SAVE_SLOTS


## Builds the complete save data dictionary.
func _build_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"save_timestamp": Time.get_datetime_string_from_system(),
		"game_state": GameManager.serialize(),
		"player_board": GameManager.player_board_state.duplicate(true),
		"player_timeline": GameManager.player_timeline.duplicate(true),
		"player_theories": GameManager.player_theories.duplicate(true),
	}


## Restores game state from saved data.
func _restore_save_data(data: Dictionary) -> void:
	var game_state: Dictionary = data.get("game_state", {})
	GameManager.deserialize(game_state)
	GameManager.player_board_state = data.get("player_board", {})
	GameManager.player_timeline = data.get("player_timeline", [])
	GameManager.player_theories = data.get("player_theories", [])
