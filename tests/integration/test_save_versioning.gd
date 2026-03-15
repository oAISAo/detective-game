## test_save_versioning.gd
## Phase 16.6 — Save/Load Versioning Tests.
## Verifies save version tracking, mismatch detection, and round-trip integrity.
extends GutTest


const SAVE_DIR: String = "user://test_saves_versioning/"


func before_each() -> void:
	GameManager.new_game()
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func after_each() -> void:
	# Cleanup test save files
	var dir: DirAccess = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while not file_name.is_empty():
			if not dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()


# =========================================================================
# Save Version Constant
# =========================================================================

func test_save_version_is_defined() -> void:
	assert_eq(SaveManager.SAVE_VERSION, 1)


func test_save_version_is_positive() -> void:
	assert_true(SaveManager.SAVE_VERSION > 0)


# =========================================================================
# Save File Contains Version
# =========================================================================

func test_save_file_contains_version() -> void:
	GameManager.discover_evidence("test_ev")
	var saved: bool = SaveManager.save_game(1)
	assert_true(saved)

	# Read the save file and verify version
	var info: Dictionary = SaveManager.get_save_info(1)
	assert_true(info.get("exists", false))
	assert_eq(info.get("save_version", 0), SaveManager.SAVE_VERSION)


# =========================================================================
# Version Mismatch Detection
# =========================================================================

func test_version_mismatch_signal_emitted() -> void:
	# Save a game normally
	SaveManager.save_game(1)

	# Read, modify version, and rewrite
	var path: String = SaveManager._get_save_path(1)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	json.parse(json_text)
	var data: Dictionary = json.data
	data["save_version"] = 999  # Fake future version

	var write_file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	write_file.store_string(JSON.stringify(data, "\t"))
	write_file.close()

	# Track signal
	watch_signals(SaveManager)

	# Load should still succeed but emit mismatch
	var loaded: bool = SaveManager.load_game(1)
	assert_true(loaded)
	assert_signal_emitted(SaveManager, "version_mismatch")


# =========================================================================
# Save/Load Round Trip
# =========================================================================

func test_save_load_round_trip() -> void:
	# Build up state
	GameManager.discover_evidence("ev_one")
	GameManager.discover_evidence("ev_two")
	GameManager.visit_location("loc_a")
	GameManager.current_day = 3
	GameManager.current_time_slot = Enums.TimeSlot.EVENING
	GameManager.hints_used = 2

	# Save
	var saved: bool = SaveManager.save_game(1)
	assert_true(saved)

	# Reset
	GameManager.new_game()
	assert_eq(GameManager.current_day, 1)
	assert_eq(GameManager.discovered_evidence.size(), 0)

	# Load
	var loaded: bool = SaveManager.load_game(1)
	assert_true(loaded)

	# Verify restored state
	assert_eq(GameManager.current_day, 3)
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.EVENING)
	assert_eq(GameManager.discovered_evidence.size(), 2)
	assert_true(GameManager.has_evidence("ev_one"))
	assert_true(GameManager.has_evidence("ev_two"))
	assert_true(GameManager.has_visited_location("loc_a"))
	assert_eq(GameManager.hints_used, 2)


# =========================================================================
# Multiple Save Slots
# =========================================================================

func test_three_save_slots_independent() -> void:
	# Save different states to slots 1, 2, 3
	GameManager.current_day = 1
	SaveManager.save_game(1)

	GameManager.current_day = 2
	SaveManager.save_game(2)

	GameManager.current_day = 3
	SaveManager.save_game(3)

	# Verify each slot has correct data
	for slot: int in [1, 2, 3]:
		assert_true(SaveManager.has_save(slot))
		var info: Dictionary = SaveManager.get_save_info(slot)
		assert_eq(info.get("current_day", 0), slot)


# =========================================================================
# Invalid Slot Handling
# =========================================================================

func test_invalid_slot_save_fails() -> void:
	assert_false(SaveManager.save_game(0))
	assert_false(SaveManager.save_game(4))
	assert_false(SaveManager.save_game(-1))


func test_invalid_slot_load_fails() -> void:
	assert_false(SaveManager.load_game(0))
	assert_false(SaveManager.load_game(4))


# =========================================================================
# Load Nonexistent Save
# =========================================================================

func test_load_nonexistent_save_fails() -> void:
	# Slot 3 should not have a save
	SaveManager.delete_save(3)
	assert_false(SaveManager.has_save(3))

	watch_signals(SaveManager)
	var loaded: bool = SaveManager.load_game(3)
	assert_false(loaded)
	assert_signal_emitted(SaveManager, "save_error")


# =========================================================================
# Delete Save
# =========================================================================

func test_delete_save() -> void:
	SaveManager.save_game(1)
	assert_true(SaveManager.has_save(1))

	var deleted: bool = SaveManager.delete_save(1)
	assert_true(deleted)
	assert_false(SaveManager.has_save(1))


func test_delete_nonexistent_save() -> void:
	SaveManager.delete_save(2)
	assert_false(SaveManager.delete_save(2))


# =========================================================================
# Save Info Metadata
# =========================================================================

func test_save_info_metadata() -> void:
	GameManager.discover_evidence("ev_a")
	GameManager.discover_evidence("ev_b")
	GameManager.current_day = 2
	SaveManager.save_game(1)

	var info: Dictionary = SaveManager.get_save_info(1)
	assert_true(info.get("exists", false))
	assert_eq(info.get("save_version", 0), SaveManager.SAVE_VERSION)
	assert_eq(info.get("current_day", 0), 2)
	assert_eq(info.get("evidence_count", 0), 2)
	assert_false(info.get("save_timestamp", "").is_empty())


# =========================================================================
# Corrupted Save File — Verify metadata detects missing fields
# =========================================================================

func test_corrupted_save_missing_fields() -> void:
	SaveManager.save_game(1)
	var path: String = SaveManager._get_save_path(1)

	# Overwrite with valid JSON but missing save data
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": 0}, "\t"))
	file.close()

	var info: Dictionary = SaveManager.get_save_info(1)
	assert_true(info.get("exists", false))
	assert_eq(info.get("save_version", -1), 0, "Should read version 0")
	assert_eq(info.get("current_day", -1), 1, "Missing field defaults to 1")


# =========================================================================
# Signals Emitted on Save/Load
# =========================================================================

func test_save_emits_signal() -> void:
	watch_signals(SaveManager)
	SaveManager.save_game(1)
	assert_signal_emitted(SaveManager, "game_saved")


func test_load_emits_signal() -> void:
	SaveManager.save_game(1)
	watch_signals(SaveManager)
	SaveManager.load_game(1)
	assert_signal_emitted(SaveManager, "game_loaded")
