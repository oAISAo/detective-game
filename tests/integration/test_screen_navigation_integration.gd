## test_screen_navigation_integration.gd
## Integration tests for screen navigation with ScreenManager and GameRoot.
## Phase 4A: Tests full navigation flow, command bar updates, and modal overlays.
extends GutTest


var _game_root: Node = null
var _screen_container: Control = null
var _modal_layer: CanvasLayer = null


# --- Setup / Teardown --- #

func before_each() -> void:
	# Reset all relevant systems
	GameManager.new_game()
	ScreenManager.reset()

	# Clean up any leftover GameRoot from a previous test (safety net)
	var existing: Node = get_tree().root.get_node_or_null("GameRoot")
	if existing:
		get_tree().root.remove_child(existing)
		existing.free()

	# Create a mock GameRoot with ScreenContainer and ModalLayer children.
	# ScreenManager finds these by node path, not script properties.
	_game_root = Control.new()
	_game_root.name = "GameRoot"

	_screen_container = Control.new()
	_screen_container.name = "ScreenContainer"
	_game_root.add_child(_screen_container)

	_modal_layer = CanvasLayer.new()
	_modal_layer.name = "ModalLayer"
	_modal_layer.layer = 10
	_game_root.add_child(_modal_layer)

	get_tree().root.add_child(_game_root)


func after_each() -> void:
	ScreenManager.reset()
	if _game_root and is_instance_valid(_game_root):
		if _game_root.get_parent():
			_game_root.get_parent().remove_child(_game_root)
		_game_root.free()
		_game_root = null
	_screen_container = null
	_modal_layer = null


# --- Screen Navigation --- #

func test_navigate_to_desk_hub_loads_screen() -> void:
	var result: bool = ScreenManager.navigate_to("desk_hub")
	assert_true(result, "Should navigate to desk_hub successfully")
	assert_eq(ScreenManager.current_screen, "desk_hub")
	assert_eq(_screen_container.get_child_count(), 1, "Screen container should have one child")


func test_navigate_to_evidence_archive_loads_screen() -> void:
	var result: bool = ScreenManager.navigate_to("evidence_archive")
	assert_true(result, "Should navigate to evidence_archive successfully")
	assert_eq(ScreenManager.current_screen, "evidence_archive")


func test_navigate_to_detective_board_loads_screen() -> void:
	var result: bool = ScreenManager.navigate_to("detective_board")
	assert_true(result, "Should navigate to detective_board successfully")
	assert_eq(ScreenManager.current_screen, "detective_board")


func test_navigate_to_timeline_board_loads_screen() -> void:
	var result: bool = ScreenManager.navigate_to("timeline_board")
	assert_true(result, "Should navigate to timeline_board successfully")
	assert_eq(ScreenManager.current_screen, "timeline_board")


func test_navigate_to_location_map_loads_screen() -> void:
	var result: bool = ScreenManager.navigate_to("location_map")
	assert_true(result, "Should navigate to location_map successfully")
	assert_eq(ScreenManager.current_screen, "location_map")


func test_navigate_to_investigation_log_loads_screen() -> void:
	var result: bool = ScreenManager.navigate_to("investigation_log")
	assert_true(result, "Should navigate to investigation_log successfully")
	assert_eq(ScreenManager.current_screen, "investigation_log")


# --- Navigation History --- #

func test_navigation_builds_history() -> void:
	ScreenManager.navigate_to("desk_hub")
	ScreenManager.navigate_to("evidence_archive")
	ScreenManager.navigate_to("detective_board")

	var history: Array[String] = ScreenManager.get_nav_history()
	assert_eq(history.size(), 2, "History should have 2 entries (desk_hub, evidence_archive)")
	assert_eq(history[0], "desk_hub")
	assert_eq(history[1], "evidence_archive")


func test_navigate_back_returns_to_previous() -> void:
	ScreenManager.navigate_to("desk_hub")
	ScreenManager.navigate_to("evidence_archive")

	var result: bool = ScreenManager.navigate_back()
	assert_true(result, "Should navigate back successfully")
	assert_eq(ScreenManager.current_screen, "desk_hub", "Should return to desk_hub")
	assert_eq(ScreenManager.get_nav_history().size(), 0, "History should be empty after going back")


func test_navigate_back_chain() -> void:
	ScreenManager.navigate_to("desk_hub")
	ScreenManager.navigate_to("evidence_archive")
	ScreenManager.navigate_to("detective_board")

	ScreenManager.navigate_back()
	assert_eq(ScreenManager.current_screen, "evidence_archive")
	ScreenManager.navigate_back()
	assert_eq(ScreenManager.current_screen, "desk_hub")
	assert_false(ScreenManager.navigate_back(), "Cannot go back further")


func test_navigation_replaces_screen_content() -> void:
	ScreenManager.navigate_to("desk_hub")
	assert_eq(_screen_container.get_child_count(), 1)

	ScreenManager.navigate_to("evidence_archive")
	# Previous child gets queue_freed — we need to wait for it to process
	# But the new child should be added immediately
	assert_true(_screen_container.get_child_count() >= 1, "Should have at least the new screen")


# --- Screen Signals --- #

func test_navigate_emits_screen_changing_signal() -> void:
	watch_signals(ScreenManager)
	ScreenManager.navigate_to("desk_hub")
	assert_signal_emitted(ScreenManager, "screen_changing")


func test_navigate_emits_screen_changed_signal() -> void:
	watch_signals(ScreenManager)
	ScreenManager.navigate_to("desk_hub")
	assert_signal_emitted(ScreenManager, "screen_changed")


func test_navigate_screen_changed_has_correct_id() -> void:
	watch_signals(ScreenManager)
	ScreenManager.navigate_to("evidence_archive")
	assert_signal_emitted_with_parameters(ScreenManager, "screen_changed", ["evidence_archive"])


func test_navigate_screen_changing_has_correct_ids() -> void:
	ScreenManager.navigate_to("desk_hub")
	watch_signals(ScreenManager)
	ScreenManager.navigate_to("evidence_archive")
	assert_signal_emitted_with_parameters(ScreenManager, "screen_changing", ["desk_hub", "evidence_archive"])


# --- Modal Overlay --- #

func test_open_morning_briefing_modal() -> void:
	var modal: Node = ScreenManager.open_modal("morning_briefing")
	assert_not_null(modal, "Morning briefing modal should be instantiated")
	assert_true(ScreenManager.is_modal_open("morning_briefing"), "Modal should be tracked as open")
	assert_eq(_modal_layer.get_child_count(), 1, "Modal layer should have one child")


func test_open_notification_panel_modal() -> void:
	var modal: Node = ScreenManager.open_modal("notification_panel")
	assert_not_null(modal, "Notification panel modal should be instantiated")
	assert_true(ScreenManager.is_modal_open("notification_panel"), "Modal should be tracked as open")


func test_open_duplicate_modal_returns_existing() -> void:
	var modal1: Node = ScreenManager.open_modal("morning_briefing")
	var modal2: Node = ScreenManager.open_modal("morning_briefing")
	assert_eq(modal1, modal2, "Opening same modal twice should return same instance")
	assert_eq(_modal_layer.get_child_count(), 1, "Should still be only one modal")


func test_close_modal() -> void:
	ScreenManager.open_modal("morning_briefing")
	assert_true(ScreenManager.is_modal_open("morning_briefing"))

	ScreenManager.close_modal("morning_briefing")
	assert_false(ScreenManager.is_modal_open("morning_briefing"))


func test_close_modal_emits_signal() -> void:
	ScreenManager.open_modal("morning_briefing")
	watch_signals(ScreenManager)
	ScreenManager.close_modal("morning_briefing")
	assert_signal_emitted_with_parameters(ScreenManager, "modal_closed", ["morning_briefing"])


func test_open_modal_emits_signal() -> void:
	watch_signals(ScreenManager)
	ScreenManager.open_modal("morning_briefing")
	assert_signal_emitted_with_parameters(ScreenManager, "modal_opened", ["morning_briefing"])


func test_close_all_modals() -> void:
	ScreenManager.open_modal("morning_briefing")
	ScreenManager.open_modal("notification_panel")
	assert_eq(ScreenManager.get_open_modals().size(), 2)

	ScreenManager.close_all_modals()
	assert_eq(ScreenManager.get_open_modals().size(), 0)


func test_modal_renders_above_screen() -> void:
	ScreenManager.navigate_to("desk_hub")
	ScreenManager.open_modal("morning_briefing")

	# Screen is in screen_container, modal is in modal_layer (CanvasLayer layer=10)
	assert_eq(_screen_container.get_child_count(), 1, "Screen should still be loaded")
	assert_eq(_modal_layer.get_child_count(), 1, "Modal should be in modal layer")


# --- Multiple Screens with Modals --- #

func test_modal_persists_across_screen_navigation() -> void:
	ScreenManager.navigate_to("desk_hub")
	ScreenManager.open_modal("morning_briefing")

	ScreenManager.navigate_to("evidence_archive")
	assert_true(ScreenManager.is_modal_open("morning_briefing"), "Modal should persist across navigation")


# --- Game Reset Integration --- #

func test_game_reset_clears_screen_manager() -> void:
	ScreenManager.navigate_to("desk_hub")
	ScreenManager.navigate_to("evidence_archive")
	ScreenManager._nav_history.append("desk_hub")

	# Calling reset directly (GameManager.new_game -> ScreenManager.reset)
	ScreenManager.reset()

	assert_eq(ScreenManager.current_screen, "", "Current screen should be cleared")
	assert_eq(ScreenManager.get_nav_history().size(), 0, "History should be cleared")
	assert_eq(ScreenManager.get_open_modals().size(), 0, "Modals should be cleared")
