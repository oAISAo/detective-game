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
			"discovery_method": "VISUAL",
			"location_found": "loc_room",
			"related_persons": [],
			"lab_analysis_results": ["ev_photo_result"],
			"weight": 0.5,
			"evidentiary_value_text": "Suggests the photo captures a meaningful detail from the scene.",
			"importance_level": "MAJOR",
			"linked_statements": ["stmt_photo_claim"],
		},
		{
			"id": "ev_photo_result",
			"name": "Enhanced Test Photo",
			"description": "An enhanced version of the original test photo.",
			"type": "PHOTO",
			"location_found": "loc_room",
			"related_persons": [],
			"weight": 0.7,
			"evidentiary_value_text": "Clarifies a previously obscured visual detail for closer review.",
			"importance_level": "MAJOR",
			"discovery_method": "FORENSIC",
			"derived_from": "ev_photo",
			"lab_result_text": "Output evidence lab_result_text should remain separate from the completed banner.",
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
			"completed_status_text": "Image enhancement complete. The processed photo is ready for review.",
		},
	],
	"statements": [
		{
			"id": "stmt_photo_claim",
			"person_id": "p_dummy",
			"text": "I never went into that room.",
			"day_given": 1,
			"related_evidence": ["ev_photo"],
			"contradicting_evidence": ["ev_photo"],
			"importance": "MAJOR",
		},
	],
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


func _get_detail_panel(screen: Control) -> EvidenceDetailPanel:
	return screen.get_node("%RightVBox") as EvidenceDetailPanel


func _get_value_section(screen: Control) -> VBoxContainer:
	var value_anchor: VBoxContainer = screen.get_node("%WeightSectionAnchor") as VBoxContainer
	assert_eq(value_anchor.get_child_count(), 1,
		"WeightSectionAnchor should contain the evidentiary value section instance.")
	return value_anchor.get_child(0) as VBoxContainer


func _collect_label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	if root is Label:
		texts.append((root as Label).text)
	for child: Node in root.get_children():
		texts.append_array(_collect_label_texts(child))
	return texts


func _collect_link_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	if root is LinkButton:
		texts.append((root as LinkButton).text)
	for child: Node in root.get_children():
		texts.append_array(_collect_link_texts(child))
	return texts


func _collect_button_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	if root is Button:
		texts.append((root as Button).text)
	for child: Node in root.get_children():
		texts.append_array(_collect_button_texts(child))
	return texts


func test_square_helper_sets_height_from_width() -> void:
	var screen: Control = _instantiate_screen()
	var detail: EvidenceDetailPanel = _get_detail_panel(screen)
	detail.call("_sync_evidence_image_square", 420.0)

	var evidence_image: TextureRect = screen.get_node("%EvidenceImage")
	assert_eq(evidence_image.custom_minimum_size.y, 420.0,
		"The evidence image height should match the provided width.")


func test_header_compare_button_and_forensic_analysis_layout() -> void:
	var screen: Control = _instantiate_screen()
	_get_detail_panel(screen).show_evidence("ev_photo")

	var compare_button: Button = screen.get_node("%CompareButton")
	assert_eq(compare_button.get_parent().name, "TitleRow",
		"Compare Evidence should live in the header button row.")

	var description_label: RichTextLabel = screen.get_node("%DescriptionLabel")
	var lab_anchor: VBoxContainer = screen.get_node("%LabSectionAnchor") as VBoxContainer
	var weight_anchor: VBoxContainer = screen.get_node("%WeightSectionAnchor") as VBoxContainer
	assert_not_null(lab_anchor)
	assert_not_null(weight_anchor)
	assert_eq(lab_anchor.get_parent(), description_label.get_parent(),
		"LabSectionAnchor should live in the first column.")
	assert_gt(lab_anchor.get_index(), description_label.get_index(),
		"Forensic Analysis should appear below Description.")
	assert_gt(weight_anchor.get_index(), lab_anchor.get_index(),
		"Evidentiary Value should appear below Forensic Analysis.")


func test_evidentiary_value_section_uses_tier_and_case_data_text() -> void:
	var screen: Control = _instantiate_screen()
	_get_detail_panel(screen).show_evidence("ev_photo")

	var value_section: VBoxContainer = _get_value_section(screen)
	var label_texts: Array[String] = _collect_label_texts(value_section)

	assert_has(label_texts, "Evidentiary Value",
		"The section header should use the new Evidentiary Value concept.")
	assert_has(label_texts, "Supporting",
		"The section should show the qualitative tier derived from internal weight.")
	assert_has(label_texts, "Suggests the photo captures a meaningful detail from the scene.",
		"The section should render the evidence-specific interpretation from case data.")
	assert_false("50%" in label_texts,
		"The Evidentiary Value section should not expose numeric percentages.")
	assert_eq(value_section.find_children("*", "ProgressBar", true, false).size(), 0,
		"The Evidentiary Value section should not render a progress bar.")


func test_evidentiary_value_section_shows_contested_warning_for_credible_contradiction() -> void:
	EvidenceManager.set_statement_verdict("ev_photo", "stmt_photo_claim", "contradiction")

	var screen: Control = _instantiate_screen()
	_get_detail_panel(screen).show_evidence("ev_photo")

	var value_section: VBoxContainer = _get_value_section(screen)
	var label_texts: Array[String] = _collect_label_texts(value_section)

	assert_has(label_texts, "Contested by a credible statement",
		"Credible contradictions should appear as a subtle warning in the value section.")


func test_info_grid_labels_importance_as_case_relevance() -> void:
	var screen: Control = _instantiate_screen()
	_get_detail_panel(screen).show_evidence("ev_photo")

	var info_grid: GridContainer = screen.get_node("%InfoGrid") as GridContainer
	var label_texts: Array[String] = _collect_label_texts(info_grid)

	assert_has(label_texts, "Case Relevance:",
		"The evidence metadata label should distinguish case-role importance from evidentiary strength.")
	assert_has(label_texts, "Major")


func test_completed_lab_state_uses_lab_request_status_text() -> void:
	GameManager.discover_evidence("ev_photo")
	GameManager.discover_evidence("ev_photo_result")

	var screen: Control = _instantiate_screen()
	_get_detail_panel(screen).show_evidence("ev_photo")

	var lab_anchor: VBoxContainer = screen.get_node("%LabSectionAnchor") as VBoxContainer
	assert_eq(lab_anchor.get_child_count(), 1,
		"LabSectionAnchor should contain the EvidenceLabSection instance.")

	var lab_section: EvidenceLabSection = lab_anchor.get_child(0) as EvidenceLabSection
	assert_not_null(lab_section)
	assert_eq(lab_section.get_child_count(), 3,
		"Completed lab state should render a header, status label, and result link.")

	var status_label: Label = lab_section.get_child(1) as Label
	assert_not_null(status_label)
	assert_eq(status_label.text,
		"Image enhancement complete. The processed photo is ready for review.",
		"Completed lab banner text should come from lab request case data, not a hardcoded UI string.")


func test_submit_state_lists_available_analysis_and_expected_result() -> void:
	GameManager.discover_evidence("ev_photo")

	var screen: Control = _instantiate_screen()
	_get_detail_panel(screen).show_evidence("ev_photo")

	var lab_anchor: VBoxContainer = screen.get_node("%LabSectionAnchor") as VBoxContainer
	assert_eq(lab_anchor.get_child_count(), 1,
		"LabSectionAnchor should contain the EvidenceLabSection instance.")

	var lab_section: EvidenceLabSection = lab_anchor.get_child(0) as EvidenceLabSection
	var label_texts: Array[String] = _collect_label_texts(lab_section)
	var button_texts: Array[String] = _collect_button_texts(lab_section)

	assert_has(label_texts, "Expected result: Enhanced Test Photo")
	assert_has(button_texts, "LAB: Photo Analysis")


func test_derived_from_row_uses_navigation_link_when_parent_is_discovered() -> void:
	GameManager.discover_evidence("ev_photo")
	GameManager.discover_evidence("ev_photo_result")

	var screen: Control = _instantiate_screen()
	_get_detail_panel(screen).show_evidence("ev_photo_result")

	var info_grid: GridContainer = screen.get_node("%InfoGrid") as GridContainer
	var label_texts: Array[String] = _collect_label_texts(info_grid)
	var link_texts: Array[String] = _collect_link_texts(info_grid)

	assert_has(label_texts, "Derived From:")
	assert_has(link_texts, "Test Photo")


func test_derived_from_row_falls_back_to_plain_text_when_parent_not_discovered() -> void:
	GameManager.discover_evidence("ev_photo_result")

	var screen: Control = _instantiate_screen()
	_get_detail_panel(screen).show_evidence("ev_photo_result")

	var info_grid: GridContainer = screen.get_node("%InfoGrid") as GridContainer
	var label_texts: Array[String] = _collect_label_texts(info_grid)
	var link_texts: Array[String] = _collect_link_texts(info_grid)

	assert_has(label_texts, "Derived From:")
	assert_has(label_texts, "Test Photo")
	assert_false("Test Photo" in link_texts,
		"Parent evidence should not be navigable when it is not in the discovered archive.")


func test_notes_section_lives_in_third_column_and_stays_open() -> void:
	var screen: Control = _instantiate_screen()
	_get_detail_panel(screen).show_evidence("ev_photo")

	var statements_section: VBoxContainer = screen.find_child("StatementsSection", true, false) as VBoxContainer
	var notes_anchor: VBoxContainer = screen.get_node("%NotesSectionAnchor") as VBoxContainer
	assert_not_null(statements_section)
	assert_not_null(notes_anchor)
	assert_eq(notes_anchor.get_parent(), statements_section.get_parent(),
		"NotesSectionAnchor should live in the same third-column container as Referenced Statements.")
	assert_gt(notes_anchor.get_index(), statements_section.get_index(),
		"Notes should appear below Referenced Statements.")

	assert_eq(notes_anchor.get_child_count(), 1,
		"NotesSectionAnchor should contain exactly one EvidenceNotesSection child.")
	var notes_section: VBoxContainer = notes_anchor.get_child(0) as VBoxContainer
	assert_not_null(notes_section)
	var header_label: Label = notes_section.get_child(0) as Label
	var notes_edit: TextEdit = notes_section.get_child(1) as TextEdit
	assert_eq(header_label.text, "My Notes")
	assert_eq(header_label.theme_type_variation, &"SectionHeader")
	assert_true(notes_edit.visible, "Player notes should always be visible.")
	assert_eq(notes_section.get_child_count(), 2,
		"The notes section should not include any collapse toggle controls.")
