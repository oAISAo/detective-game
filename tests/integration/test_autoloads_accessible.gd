## test_autoloads_accessible.gd
## Integration test: verifies all autoload singletons are accessible
## from any script context and respond correctly.
extends GutTest


func test_game_manager_accessible() -> void:
	assert_not_null(GameManager, "GameManager should be accessible")
	# Verify it responds to a method call
	GameManager.new_game()
	assert_eq(GameManager.current_day, 1)


func test_case_manager_accessible() -> void:
	assert_not_null(CaseManager, "CaseManager should be accessible")
	# Verify it responds to method calls (don't assume initial state — other tests may have run)
	CaseManager.unload_case()
	assert_false(CaseManager.case_loaded_flag)


func test_save_manager_accessible() -> void:
	assert_not_null(SaveManager, "SaveManager should be accessible")
	# Verify it responds to a method call
	assert_false(SaveManager.has_save(1))


func test_notification_manager_accessible() -> void:
	assert_not_null(NotificationManager, "NotificationManager should be accessible")
	# Verify it responds to a method call
	NotificationManager.clear_all()
	assert_eq(NotificationManager.get_all().size(), 0)


func test_enums_accessible() -> void:
	# Verify enum values exist and are distinct
	assert_ne(Enums.DayPhase.MORNING, Enums.DayPhase.DAYTIME)
	assert_ne(Enums.EvidenceType.FORENSIC, Enums.EvidenceType.DOCUMENT)
	assert_ne(Enums.PersonRole.VICTIM, Enums.PersonRole.SUSPECT)
	assert_ne(Enums.ReactionType.DENIAL, Enums.ReactionType.DEFLECTION)


func test_event_system_accessible() -> void:
	assert_not_null(EventSystem, "EventSystem should be accessible")
	EventSystem.reset()
	assert_eq(EventSystem.get_fired_triggers().size(), 0)


func test_dialogue_system_accessible() -> void:
	assert_not_null(DialogueSystem, "DialogueSystem should be accessible")
	DialogueSystem.reset()
	assert_false(DialogueSystem.is_active())


func test_tool_manager_accessible() -> void:
	var tool_mgr: Node = get_node_or_null("/root/ToolManager")
	assert_not_null(tool_mgr, "ToolManager should be accessible")
	tool_mgr.reset()
	assert_eq(tool_mgr.get_available_tools().size(), 3)


func test_location_investigation_manager_accessible() -> void:
	var loc_inv_mgr: Node = get_node_or_null("/root/LocationInvestigationManager")
	assert_not_null(loc_inv_mgr, "LocationInvestigationManager should be accessible")
	loc_inv_mgr.reset()
	assert_eq(loc_inv_mgr.current_location_id, "")
