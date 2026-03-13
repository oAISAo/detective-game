## test_screen_manager.gd
## Unit tests for the ScreenManager singleton.
## Phase 4A: Verify navigation, history, modals, and state management.
extends GutTest


# --- Setup / Teardown --- #

func before_each() -> void:
	ScreenManager.reset()


# --- Constants / Registry --- #

func test_screen_scenes_registry_has_all_screens() -> void:
	assert_true(ScreenManager.SCREEN_SCENES.has("desk_hub"), "Should have desk_hub")
	assert_true(ScreenManager.SCREEN_SCENES.has("evidence_archive"), "Should have evidence_archive")
	assert_true(ScreenManager.SCREEN_SCENES.has("detective_board"), "Should have detective_board")
	assert_true(ScreenManager.SCREEN_SCENES.has("timeline_board"), "Should have timeline_board")
	assert_true(ScreenManager.SCREEN_SCENES.has("location_map"), "Should have location_map")
	assert_true(ScreenManager.SCREEN_SCENES.has("investigation_log"), "Should have investigation_log")
	assert_eq(ScreenManager.SCREEN_SCENES.size(), 6, "Should have exactly 6 screens")


func test_modal_scenes_registry_has_all_modals() -> void:
	assert_true(ScreenManager.MODAL_SCENES.has("morning_briefing"), "Should have morning_briefing")
	assert_true(ScreenManager.MODAL_SCENES.has("notification_panel"), "Should have notification_panel")
	assert_eq(ScreenManager.MODAL_SCENES.size(), 2, "Should have exactly 2 modals")


func test_screen_scene_paths_are_valid() -> void:
	for screen_id: String in ScreenManager.SCREEN_SCENES:
		var path: String = ScreenManager.SCREEN_SCENES[screen_id]
		assert_true(path.begins_with("res://"), "Path for %s should start with res://" % screen_id)
		assert_true(path.ends_with(".tscn"), "Path for %s should end with .tscn" % screen_id)


func test_modal_scene_paths_are_valid() -> void:
	for modal_id: String in ScreenManager.MODAL_SCENES:
		var path: String = ScreenManager.MODAL_SCENES[modal_id]
		assert_true(path.begins_with("res://"), "Path for %s should start with res://" % modal_id)
		assert_true(path.ends_with(".tscn"), "Path for %s should end with .tscn" % modal_id)


# --- Initial State --- #

func test_initial_state_after_reset() -> void:
	assert_eq(ScreenManager.current_screen, "", "Current screen should be empty after reset")
	assert_eq(ScreenManager.get_nav_history().size(), 0, "History should be empty after reset")
	assert_false(ScreenManager.can_go_back(), "Should not be able to go back with empty history")
	assert_eq(ScreenManager.get_open_modals().size(), 0, "No modals should be open after reset")


# --- Navigation (without GameRoot) --- #

func test_navigate_to_unknown_screen_returns_false() -> void:
	var result: bool = ScreenManager.navigate_to("nonexistent_screen")
	assert_false(result, "Navigating to unknown screen should return false")
	assert_push_error("[ScreenManager] Unknown screen: nonexistent_screen")


func test_navigate_to_unknown_screen_pushes_error() -> void:
	ScreenManager.navigate_to("nonexistent_screen")
	assert_push_error("[ScreenManager] Unknown screen: nonexistent_screen")


func test_navigate_to_same_screen_returns_false() -> void:
	# Set current_screen manually since we have no GameRoot
	ScreenManager.current_screen = "desk_hub"
	var result: bool = ScreenManager.navigate_to("desk_hub")
	assert_false(result, "Navigating to the same screen should return false")


func test_navigate_to_valid_screen_without_game_root_returns_false() -> void:
	# Without GameRoot in the tree, navigation should fail gracefully
	var result: bool = ScreenManager.navigate_to("evidence_archive")
	assert_false(result, "Navigation should fail without GameRoot")
	assert_push_error("[ScreenManager] GameRoot not found.")


func test_navigate_to_valid_screen_without_game_root_pushes_error() -> void:
	ScreenManager.navigate_to("evidence_archive")
	assert_push_error("[ScreenManager] GameRoot not found.")


# --- Navigation History --- #

func test_get_nav_history_returns_empty_initially() -> void:
	assert_eq(ScreenManager.get_nav_history().size(), 0)


func test_can_go_back_returns_false_with_empty_history() -> void:
	assert_false(ScreenManager.can_go_back())


func test_navigate_back_with_empty_history_returns_false() -> void:
	var result: bool = ScreenManager.navigate_back()
	assert_false(result, "Back navigation should fail with empty history")


func test_clear_history() -> void:
	# Manually push items to history for testing
	ScreenManager._nav_history.append("desk_hub")
	ScreenManager._nav_history.append("evidence_archive")
	assert_eq(ScreenManager.get_nav_history().size(), 2)
	ScreenManager.clear_history()
	assert_eq(ScreenManager.get_nav_history().size(), 0)


func test_get_nav_history_returns_duplicate() -> void:
	ScreenManager._nav_history.append("desk_hub")
	var history: Array[String] = ScreenManager.get_nav_history()
	history.append("test_mutation")
	assert_eq(ScreenManager.get_nav_history().size(), 1, "Modifying returned history should not affect internal state")


# --- Modal Management (without GameRoot) --- #

func test_open_unknown_modal_returns_null() -> void:
	var result: Node = ScreenManager.open_modal("nonexistent_modal")
	assert_null(result, "Opening unknown modal should return null")
	assert_push_error("[ScreenManager] Unknown modal: nonexistent_modal")


func test_open_unknown_modal_pushes_error() -> void:
	ScreenManager.open_modal("nonexistent_modal")
	assert_push_error("[ScreenManager] Unknown modal: nonexistent_modal")


func test_open_modal_without_game_root_returns_null() -> void:
	var result: Node = ScreenManager.open_modal("morning_briefing")
	assert_null(result, "Opening modal without GameRoot should return null")


func test_is_modal_open_returns_false_initially() -> void:
	assert_false(ScreenManager.is_modal_open("morning_briefing"))
	assert_false(ScreenManager.is_modal_open("notification_panel"))


func test_get_open_modals_returns_empty_initially() -> void:
	assert_eq(ScreenManager.get_open_modals().size(), 0)


func test_close_modal_noop_when_not_open() -> void:
	# Should not error — just do nothing
	ScreenManager.close_modal("morning_briefing")
	assert_false(ScreenManager.is_modal_open("morning_briefing"))


func test_close_all_modals_noop_when_none_open() -> void:
	# Should not error
	ScreenManager.close_all_modals()
	assert_eq(ScreenManager.get_open_modals().size(), 0)


# --- Transition Lock --- #

func test_transitioning_flag_blocks_navigation() -> void:
	ScreenManager._transitioning = true
	var result: bool = ScreenManager.navigate_to("desk_hub")
	assert_false(result, "Navigation should be blocked during transition")
	assert_push_warning("[ScreenManager] Navigation blocked")
	ScreenManager._transitioning = false


func test_transitioning_flag_blocks_back_navigation() -> void:
	ScreenManager._nav_history.append("desk_hub")
	ScreenManager._transitioning = true
	var result: bool = ScreenManager.navigate_back()
	assert_false(result, "Back navigation should be blocked during transition")
	ScreenManager._transitioning = false


# --- Signals --- #

func test_navigate_to_unknown_does_not_emit_signals() -> void:
	watch_signals(ScreenManager)
	ScreenManager.navigate_to("nonexistent")
	assert_signal_not_emitted(ScreenManager, "screen_changing")
	assert_signal_not_emitted(ScreenManager, "screen_changed")
	assert_push_error("[ScreenManager] Unknown screen: nonexistent")


func test_close_modal_emits_signal_when_modal_exists() -> void:
	# Manually register a modal for testing
	var fake_node: Node = Node.new()
	add_child_autofree(fake_node)
	ScreenManager._active_modals["test_modal"] = fake_node
	watch_signals(ScreenManager)
	ScreenManager.close_modal("test_modal")
	assert_signal_emitted(ScreenManager, "modal_closed")


func test_close_modal_does_not_emit_signal_when_not_open() -> void:
	watch_signals(ScreenManager)
	ScreenManager.close_modal("nonexistent")
	assert_signal_not_emitted(ScreenManager, "modal_closed")


# --- Reset --- #

func test_reset_clears_all_state() -> void:
	ScreenManager.current_screen = "evidence_archive"
	ScreenManager._nav_history.append("desk_hub")
	ScreenManager._transitioning = true
	var fake_node: Node = Node.new()
	add_child_autofree(fake_node)
	ScreenManager._active_modals["test"] = fake_node

	ScreenManager.reset()

	assert_eq(ScreenManager.current_screen, "", "Current screen should be empty after reset")
	assert_eq(ScreenManager.get_nav_history().size(), 0, "History should be cleared")
	assert_false(ScreenManager._transitioning, "Transitioning flag should be cleared")
	assert_eq(ScreenManager.get_open_modals().size(), 0, "Active modals should be cleared")


func test_reset_clears_scene_cache() -> void:
	ScreenManager._scene_cache["test_key"] = null
	ScreenManager.reset()
	assert_eq(ScreenManager._scene_cache.size(), 0, "Scene cache should be cleared after reset")
