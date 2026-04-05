## test_debug_state_loader.gd
## Tests for the DebugStateLoader system.
## Validates that debug presets load correctly and apply state to GameManager.
extends GutTest


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()


func after_each() -> void:
	if InterrogationManager.is_active():
		InterrogationManager.end_interrogation()
	CaseManager.unload_case()


# =========================================================================
# Debug Preset Discovery
# =========================================================================

func test_list_presets_finds_debug_files() -> void:
	var presets: Array[String] = DebugStateLoader.list_presets()
	assert_true(presets.size() > 0, "Should find at least one debug preset")
	assert_has(presets, "debug_mark_interrogation.json",
		"Should find the Mark interrogation debug preset")


# =========================================================================
# Debug State Loading
# =========================================================================

func test_load_debug_state_succeeds() -> void:
	var result: bool = DebugStateLoader.load_debug_state("debug_mark_interrogation.json")
	assert_true(result, "Should load debug state successfully")


func test_load_debug_state_sets_case() -> void:
	DebugStateLoader.load_debug_state("debug_mark_interrogation.json")
	assert_not_null(CaseManager.get_case_data(), "Case should be loaded after debug state")


func test_load_debug_state_sets_day() -> void:
	DebugStateLoader.load_debug_state("debug_mark_interrogation.json")
	assert_eq(GameManager.current_day, 2, "Day should be 2")


func test_load_debug_state_sets_phase() -> void:
	DebugStateLoader.load_debug_state("debug_mark_interrogation.json")
	assert_eq(GameManager.current_phase, Enums.DayPhase.DAYTIME,
		"Phase should be DAYTIME (value 1)")


func test_load_debug_state_sets_actions() -> void:
	DebugStateLoader.load_debug_state("debug_mark_interrogation.json")
	assert_eq(GameManager.actions_remaining, 4, "Should have 4 actions")


func test_load_debug_state_sets_evidence() -> void:
	DebugStateLoader.load_debug_state("debug_mark_interrogation.json")
	assert_true(GameManager.has_evidence("ev_parking_camera"),
		"Should have parking camera evidence")
	assert_true(GameManager.has_evidence("ev_bank_transfer"),
		"Should have bank transfer evidence")
	assert_true(GameManager.has_evidence("ev_hidden_safe"),
		"Should have hidden safe evidence")


func test_load_debug_state_sets_locations() -> void:
	DebugStateLoader.load_debug_state("debug_mark_interrogation.json")
	assert_true(GameManager.is_location_unlocked("loc_victim_apartment"),
		"Victim apartment should be unlocked")
	assert_true(GameManager.is_location_unlocked("loc_parking_lot"),
		"Parking lot should be unlocked")


func test_load_debug_state_sets_interrogations() -> void:
	DebugStateLoader.load_debug_state("debug_mark_interrogation.json")
	assert_true(GameManager.is_interrogation_unlocked("p_mark"),
		"Mark should be unlocked for interrogation")
	assert_true(GameManager.is_interrogation_unlocked("p_sarah"),
		"Sarah should be unlocked for interrogation")
	assert_true(GameManager.is_interrogation_unlocked("p_julia"),
		"Julia should be unlocked for interrogation")
	assert_true(GameManager.is_interrogation_unlocked("p_lucas"),
		"Lucas should be unlocked for interrogation")


func test_load_debug_state_game_is_active() -> void:
	DebugStateLoader.load_debug_state("debug_mark_interrogation.json")
	assert_true(GameManager.game_active, "Game should be active")


func test_load_nonexistent_file_fails() -> void:
	var result: bool = DebugStateLoader.load_debug_state("nonexistent.json")
	assert_false(result, "Should fail for nonexistent file")
	assert_push_error("[DebugStateLoader] Debug file not found: res://data/debug/nonexistent.json")


# =========================================================================
# Debug State Enables Interrogation
# =========================================================================

func test_debug_state_allows_mark_interrogation() -> void:
	DebugStateLoader.load_debug_state("debug_mark_interrogation.json")

	# Should be able to start interrogation with Mark
	var started: bool = InterrogationManager.start_interrogation("p_mark")
	assert_true(started, "Should be able to interrogate Mark after debug load")
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION,
		"Should start directly in INTERROGATION phase")

	# Evidence should be usable
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	var result: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_true(result.get("triggered", false),
		"Should be able to present evidence in debug-loaded game")
