## Unit tests for the EvidenceArchive scene layout.
## Verifies the first-column evidence image is square, lab analysis sits between description and weight, and the notes section lives under Referenced Statements.
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
			"requires_lab_analysis": true,
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
	],
	"lab_requests": [
		{
			"id": "lab_photo",
			"input_evidence_id": "ev_photo",
			"analysis_type": "photo_analysis",
			"day_submitted": 1,
			"completion_day": 2,
			"output_evidence_id": "ev_photo_result",
			"lab_transform": "derive",
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


func test_header_compare_button_and_forensic_analysis_layout() -> void:
	var screen: Control = _instantiate_screen()
	screen.call("_show_evidence_detail", "ev_photo")

	var compare_button: Button = screen.get_node("%CompareButton")
	assert_eq(compare_button.get_parent().name, "TitleRow",
		"Compare Evidence should live in the header button row.")

	var description_label: RichTextLabel = screen.get_node("%DescriptionLabel")
	var weight_section: VBoxContainer = screen.find_child("WeightSection", true, false) as VBoxContainer
	var forensic_section: VBoxContainer = screen.find_child("ForensicAnalysisSection", true, false) as VBoxContainer
	assert_not_null(weight_section)
	assert_not_null(forensic_section)
	assert_eq(forensic_section.get_parent(), description_label.get_parent(),
		"Forensic Analysis should live in the first column.")
	assert_gt(forensic_section.get_index(), description_label.get_index(),
		"Forensic Analysis should appear below Description.")
	assert_gt(weight_section.get_index(), forensic_section.get_index(),
		"Evidentiary Weight should appear below Forensic Analysis.")


func test_notes_section_lives_in_third_column_and_stays_open() -> void:
	var screen: Control = _instantiate_screen()
	screen.call("_show_evidence_detail", "ev_photo")

	var statements_section: VBoxContainer = screen.find_child("StatementsSection", true, false) as VBoxContainer
	var notes_section: VBoxContainer = screen.find_child("NotesSection", true, false) as VBoxContainer
	assert_not_null(statements_section)
	assert_not_null(notes_section)
	assert_eq(notes_section.get_parent(), statements_section.get_parent(),
		"Notes should live in the same third-column container as Referenced Statements.")
	assert_gt(notes_section.get_index(), statements_section.get_index(),
		"Notes should appear below Referenced Statements.")

	var header_label: Label = notes_section.get_child(0) as Label
	var notes_edit: TextEdit = notes_section.get_child(1) as TextEdit
	assert_eq(header_label.text, "My Notes")
	assert_eq(header_label.theme_type_variation, &"SectionHeader")
	assert_true(notes_edit.visible, "Player notes should always be visible.")
	assert_eq(notes_section.get_child_count(), 2,
		"The notes section should not include any collapse toggle controls.")