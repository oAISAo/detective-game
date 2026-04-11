## Unit tests for the LocationMap scene layout.
## Verifies the scroll viewport includes inner padding so card shadows are not clipped.
extends GutTest


const TEST_CASE_FILE: String = "test_location_map_ui.json"

var _test_case_data: Dictionary = {
	"id": "case_location_map_ui_test",
	"title": "Location Map UI Test Case",
	"description": "Test case for location map UI behavior.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{
			"id": "p_victim",
			"name": "Daniel Whitfield",
			"role": "VICTIM",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 0,
		},
	],
	"evidence": [
		{
			"id": "ev_note",
			"name": "Desk Note",
			"description": "A short note found on the desk.",
			"type": "DOCUMENT",
			"discovery_method": "VISUAL",
			"location_found": "loc_apt",
			"related_persons": [],
			"tags": ["note"],
			"weight": 0.4,
			"importance_level": "SUPPORTING",
			"legal_categories": [],
		},
	],
	"statements": [],
	"events": [],
	"locations": [
		{
			"id": "loc_apt",
			"name": "Victim Apartment",
			"description": "Primary crime scene apartment.",
			"searchable": true,
			"image": "",
			"investigable_objects": [
				{
					"id": "obj_desk",
					"name": "Desk",
					"description": "A desk near the window.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["ev_note"],
					"investigation_state": "NOT_INSPECTED",
				},
			],
			"evidence_pool": ["ev_note"],
		},
		{
			"id": "loc_office",
			"name": "Victim Office",
			"description": "A locked office location.",
			"searchable": true,
			"image": "",
			"investigable_objects": [],
			"evidence_pool": [],
		},
	],
	"event_triggers": [],
	"interrogation_topics": [],
	"actions": [],
	"insights": [],
}


var _location_map_scene: PackedScene = preload("res://scenes/ui/location_map.tscn")


func before_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	var dir: DirAccess = DirAccess.open("res://data/cases")
	if dir == null:
		DirAccess.make_dir_recursive_absolute("res://data/cases")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_test_case_data, "\t"))
	file.close()


func before_each() -> void:
	GameManager.new_game()
	NotificationManager.clear_all()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)
	LocationInvestigationManager.reset()
	GameManager.unlock_location("loc_apt")


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _instantiate_map_screen() -> Control:
	var screen: Control = _location_map_scene.instantiate()
	add_child_autofree(screen)
	return screen


func _get_first_location_card(screen: Control) -> LocationCard:
	var grid: HFlowContainer = screen.get_node("%LocationGrid")
	for child: Node in grid.get_children():
		if child is LocationCard:
			return child as LocationCard
	return null


func _get_location_card_count(screen: Control) -> int:
	var grid: HFlowContainer = screen.get_node("%LocationGrid")
	var count: int = 0
	for child: Node in grid.get_children():
		if child is LocationCard:
			count += 1
	return count


func _find_location_card(screen: Control, location_id: String) -> LocationCard:
	var grid: HFlowContainer = screen.get_node("%LocationGrid")
	for child: Node in grid.get_children():
		if child is LocationCard:
			var card: LocationCard = child as LocationCard
			if card.get_location_id() == location_id:
				return card
	return null


func test_location_map_scroll_content_has_shadow_padding() -> void:
	var screen: Control = _instantiate_map_screen()
	var scroll: ScrollContainer = screen.get_node("MarginContainer/VBoxContainer/LocationScroll")
	var content_margin: MarginContainer = scroll.get_node("ScrollContentMargin")
	var grid: HFlowContainer = screen.get_node("%LocationGrid")
	assert_eq(grid.get_parent(), content_margin,
		"Location grid should live inside a padded margin container within the scroll viewport")
	assert_true(content_margin.get_theme_constant("margin_left") >= 16,
		"Location grid should have at least 16px left padding for card shadows")
	assert_true(content_margin.get_theme_constant("margin_top") >= 16,
		"Location grid should have at least 16px top padding for card shadows")
	assert_true(content_margin.get_theme_constant("margin_right") >= 16,
		"Location grid should have right padding so trailing card shadows remain visible")
	assert_true(content_margin.get_theme_constant("margin_bottom") >= 16,
		"Location grid should have bottom padding so card shadows remain visible when scrolled")


func test_location_map_shows_failure_notification_when_no_actions() -> void:
	GameManager.actions_remaining = 0
	var screen: Control = _instantiate_map_screen()
	var card: LocationCard = _get_first_location_card(screen)
	assert_not_null(card, "Expected an unlocked location card in the map")

	NotificationManager.clear_all()
	card.card_pressed.emit(card.get_location_id())

	var notifications: Array[Dictionary] = NotificationManager.get_all()
	assert_eq(notifications.size(), 1, "Failed location navigation should create one notification")
	assert_eq(notifications[0].get("title", ""), "Cannot Visit Location")
	var message: String = str(notifications[0].get("message", "")).to_lower()
	assert_true(message.contains("no actions remaining"), "Failure should explain action shortage")


func test_location_map_shows_failure_notification_for_invalid_location() -> void:
	var screen: Control = _instantiate_map_screen()

	NotificationManager.clear_all()
	screen._on_location_pressed("loc_nonexistent")
	assert_push_error("Unknown location: loc_nonexistent")

	var notifications: Array[Dictionary] = NotificationManager.get_all()
	assert_eq(notifications.size(), 1, "Invalid location should produce one failure notification")
	assert_eq(notifications[0].get("title", ""), "Cannot Visit Location")
	assert_eq(
		notifications[0].get("message", ""),
		LocationInvestigationManager.START_ERROR_MESSAGE_UNKNOWN_LOCATION
	)


func test_location_map_refreshes_when_location_unlocks_while_open() -> void:
	var screen: Control = _instantiate_map_screen()
	assert_eq(_get_location_card_count(screen), 1, "Only initially unlocked location should be visible")

	GameManager.unlock_location("loc_office")
	await get_tree().process_frame

	assert_eq(_get_location_card_count(screen), 2, "Map should repopulate after runtime unlock")
	var office_card: LocationCard = _find_location_card(screen, "loc_office")
	assert_not_null(office_card, "Newly unlocked location should appear without reopening the screen")


func test_location_map_refreshes_card_metrics_and_status_after_runtime_updates() -> void:
	var screen: Control = _instantiate_map_screen()
	var initial_card: LocationCard = _find_location_card(screen, "loc_apt")
	assert_not_null(initial_card)
	var initial_evidence: Label = initial_card.get_node("%EvidenceLabel")
	var initial_status: Label = initial_card.get_node("%StatusLabel")
	assert_eq(initial_evidence.text, "?", "Before first visit evidence count should be hidden")
	assert_eq(initial_status.text, LocationCard.STATUS_NEW.to_upper())

	GameManager.visit_location("loc_apt")
	await get_tree().process_frame

	var open_card: LocationCard = _find_location_card(screen, "loc_apt")
	var open_evidence: Label = open_card.get_node("%EvidenceLabel")
	var open_status: Label = open_card.get_node("%StatusLabel")
	assert_eq(open_evidence.text, "0 / 1", "Visited location should show live completion counts")
	assert_eq(open_status.text, LocationCard.STATUS_OPEN.to_upper())

	GameManager.discover_evidence("ev_note")
	await get_tree().process_frame

	var exhausted_card: LocationCard = _find_location_card(screen, "loc_apt")
	var exhausted_evidence: Label = exhausted_card.get_node("%EvidenceLabel")
	var exhausted_status: Label = exhausted_card.get_node("%StatusLabel")
	assert_eq(exhausted_evidence.text, "1 / 1", "Completion counts should update while map is open")
	assert_eq(exhausted_status.text, LocationCard.STATUS_EXHAUSTED.to_upper())