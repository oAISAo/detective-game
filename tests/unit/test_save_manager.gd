## test_save_manager.gd
## Unit tests for the SaveManager autoload singleton.
## Phase 0: Verify save/load, version checking, slot management.
extends GutTest


# --- Setup / Teardown --- #

func before_each() -> void:
	GameManager.new_game()
	# Clean up any test saves
	for slot: int in range(1, SaveManager.MAX_SAVE_SLOTS + 1):
		SaveManager.delete_save(slot)


func after_all() -> void:
	# Final cleanup
	for slot: int in range(1, SaveManager.MAX_SAVE_SLOTS + 1):
		SaveManager.delete_save(slot)


# --- Save / Load --- #

func test_save_game_succeeds() -> void:
	var result: bool = SaveManager.save_game(1)
	assert_true(result, "Save should succeed")


func test_save_game_emits_signal() -> void:
	watch_signals(SaveManager)
	SaveManager.save_game(1)
	assert_signal_emitted_with_parameters(SaveManager, "game_saved", [1])


func test_load_game_succeeds() -> void:
	SaveManager.save_game(1)
	GameManager.new_game()  # Reset state
	var result: bool = SaveManager.load_game(1)
	assert_true(result, "Load should succeed")


func test_load_game_emits_signal() -> void:
	SaveManager.save_game(1)
	watch_signals(SaveManager)
	SaveManager.load_game(1)
	assert_signal_emitted_with_parameters(SaveManager, "game_loaded", [1])


func test_save_load_preserves_state() -> void:
	# Set up some state
	GameManager.discover_evidence("ev_test_01")
	GameManager.discover_evidence("ev_test_02")
	GameManager.visit_location("loc_apartment")
	GameManager.use_action()
	GameManager.use_hint()

	# Save
	SaveManager.save_game(1)

	# Reset
	GameManager.new_game()
	assert_eq(GameManager.discovered_evidence.size(), 0)

	# Load
	SaveManager.load_game(1)
	assert_eq(GameManager.discovered_evidence.size(), 2)
	assert_true(GameManager.has_evidence("ev_test_01"))
	assert_true(GameManager.has_evidence("ev_test_02"))
	assert_true(GameManager.has_visited_location("loc_apartment"))
	assert_eq(GameManager.hints_used, 1)


# --- Slot Validation --- #

func test_invalid_slot_zero() -> void:
	var result: bool = SaveManager.save_game(0)
	assert_false(result, "Slot 0 should be invalid")


func test_invalid_slot_too_high() -> void:
	var result: bool = SaveManager.save_game(SaveManager.MAX_SAVE_SLOTS + 1)
	assert_false(result, "Slot above max should be invalid")


func test_load_nonexistent_save() -> void:
	var result: bool = SaveManager.load_game(1)
	assert_false(result, "Loading nonexistent save should fail")


# --- Has Save --- #

func test_has_save_false_initially() -> void:
	assert_false(SaveManager.has_save(1))


func test_has_save_true_after_save() -> void:
	SaveManager.save_game(1)
	assert_true(SaveManager.has_save(1))


# --- Delete Save --- #

func test_delete_save() -> void:
	SaveManager.save_game(1)
	assert_true(SaveManager.has_save(1))
	SaveManager.delete_save(1)
	assert_false(SaveManager.has_save(1))


func test_delete_nonexistent_save() -> void:
	var result: bool = SaveManager.delete_save(1)
	assert_false(result, "Deleting nonexistent save should return false")


# --- Save Info --- #

func test_get_save_info_no_save() -> void:
	var info: Dictionary = SaveManager.get_save_info(1)
	assert_eq(info.get("exists", true), false)


func test_get_save_info_with_save() -> void:
	GameManager.discover_evidence("ev_test")
	SaveManager.save_game(1)
	var info: Dictionary = SaveManager.get_save_info(1)
	assert_true(info.get("exists", false))
	assert_eq(int(info.get("save_version", 0)), SaveManager.SAVE_VERSION)
	assert_eq(int(info.get("current_day", 0)), 1)
	assert_eq(int(info.get("evidence_count", 0)), 1)


# --- Multiple Slots --- #

func test_three_save_slots_independent() -> void:
	# Save different states to different slots
	GameManager.discover_evidence("ev_01")
	SaveManager.save_game(1)

	GameManager.discover_evidence("ev_02")
	SaveManager.save_game(2)

	GameManager.discover_evidence("ev_03")
	SaveManager.save_game(3)

	# Load slot 1 — should have 1 evidence
	SaveManager.load_game(1)
	assert_eq(GameManager.discovered_evidence.size(), 1)

	# Load slot 3 — should have 3 evidence
	SaveManager.load_game(3)
	assert_eq(GameManager.discovered_evidence.size(), 3)

	# Load slot 2 — should have 2 evidence
	SaveManager.load_game(2)
	assert_eq(GameManager.discovered_evidence.size(), 2)
