## Unit tests for the EvidenceArchive scene layout.
## Verifies the first-column evidence image can be kept square from its width.
extends GutTest


const TEST_CASE_FILE: String = "test_evidence_archive_ui.json"

var _test_case_data: Dictionary = {
	"id": "case_evidence_archive_ui_test",
	"title": "Evidence Archive UI Test Case",
	"description": "Test case for the evidence archive UI layout.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{
			"id": "p_dummy",
			"name": "Dummy Person",
			"role": "WITNESS",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 0,
		},
	],
	"evidence": [
		{
			"id": "ev_photo",
			"name": "Test Photo",
			"description": "A test image for evidence archive layout checks.",
			"type": "PHOTO",
			"location_found": "loc_room",
			"related_persons": [],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
	],
	"statements": [],
	"locations": [
		{
			"id": "loc_room",
			"name": "Test Room",
			"description": "A test room.",
			"searchable": true,
			"image": "",
			"investigable_objects": [],
			"evidence_pool": ["ev_photo"],
		},
	],
	"events": [],
	"timeline": [],
	"discovery_rules": [],
}

var _evidence_archive_scene: PackedScene = preload("res://scenes/ui/evidence_archive.tscn")


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
	EvidenceManager.reset()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _instantiate_screen() -> Control:
	var screen: Control = _evidence_archive_scene.instantiate()
	add_child_autofree(screen)
	return screen


func test_square_helper_sets_height_from_width() -> void:
	var screen: Control = _instantiate_screen()
	screen.call("_sync_evidence_image_square", 420.0)

	var evidence_image: TextureRect = screen.get_node("%EvidenceImage")
	assert_eq(evidence_image.custom_minimum_size.y, 420.0,
		"The evidence image height should match the provided width.")