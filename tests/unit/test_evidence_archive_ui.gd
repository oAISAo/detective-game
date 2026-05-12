## Unit tests for the EvidenceArchive scene layout.
## Verifies the first-column evidence image is square, lab analysis sits between description and weight, and the notes section lives under Referenced Statements.
extends GutTest


const TEST_CASE_FILE: String = "test_evidence_archive_ui.json"
const WAIT_BUTTON_SCRIPT_PATH: String = "res://scripts/ui/components/wait_button.gd"
const ICON_BUTTON_CONTENT_NODE_NAME: String = "BackButtonContent"

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
			"name": "Two Wine Glasses on Dining Table Beside Open Balcony Door",
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


func _collect_badge_texts(badge_row: HBoxContainer) -> Array[String]:
	var texts: Array[String] = []
	for pill: Node in badge_row.get_children():
		if pill.get_child_count() == 0:
			continue
		var label: Label = pill.get_child(0) as Label
		if label != null:
			texts.append(label.text)
	return texts


func _collect_archive_card_titles(evidence_grid: GridContainer) -> Array[String]:
	var titles: Array[String] = []
	for child: Node in evidence_grid.get_children():
		var card: EvidencePolaroid = child as EvidencePolaroid
		if card == null:
			continue
		var name_label: Label = card.get_node("%NameLabel") as Label
		if name_label != null:
			titles.append(name_label.text)
	return titles


func _find_wait_buttons(root: Node) -> Array[Control]:
	var buttons: Array[Control] = []
	if _is_wait_button(root):
		buttons.append(root as Control)
	for child: Node in root.get_children():
		buttons.append_array(_find_wait_buttons(child))
	return buttons


func _is_wait_button(node: Node) -> bool:
	if not node is Control:
		return false
	var script: Script = node.get_script() as Script
	return script != null and script.resource_path == WAIT_BUTTON_SCRIPT_PATH


func _find_info_key_label(info_grid: GridContainer, key: String) -> Label:
	for child_idx: int in range(0, info_grid.get_child_count(), 2):
		var key_label: Label = info_grid.get_child(child_idx) as Label
		if key_label != null and key_label.text == "%s:" % key:
			return key_label
	return null


func _find_info_value_control(info_grid: GridContainer, key: String) -> Control:
	for child_idx: int in range(0, info_grid.get_child_count(), 2):
		var key_label: Label = info_grid.get_child(child_idx) as Label
		if key_label != null and key_label.text == "%s:" % key:
			return info_grid.get_child(child_idx + 1) as Control
	return null


func _collect_icon_button_texts(button: Button) -> Array[String]:
	var texts: Array[String] = []
	var content: MarginContainer = button.get_node_or_null(ICON_BUTTON_CONTENT_NODE_NAME) as MarginContainer
	if content == null or content.get_child_count() == 0:
		return texts

	var row: HBoxContainer = content.get_child(0) as HBoxContainer
	if row == null:
		return texts

	for child: Node in row.get_children():
		var label: Label = child as Label
		if label != null:
			texts.append(label.text)
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


func test_header_buttons_use_expected_material_icons() -> void:
	GameManager.discover_evidence("ev_photo")

	var screen: Control = _instantiate_screen()
	var detail_panel: EvidenceDetailPanel = _get_detail_panel(screen)
	detail_panel.show_evidence("ev_photo")

	var pin_button: Button = screen.get_node("%PinButton") as Button
	var send_to_board_button: Button = screen.get_node("%SendToBoardButton") as Button
	var compare_button: Button = screen.get_node("%CompareButton") as Button

	assert_eq(_collect_icon_button_texts(compare_button), ["folder_match", "Compare Evidence"],
		"Compare Evidence should render the folder_match icon to the left of its label.")
	assert_eq(_collect_icon_button_texts(send_to_board_button), ["pinboard", "Send to Board"],
		"Send to Board should render the pinboard icon to the left of its label.")
	assert_eq(_collect_icon_button_texts(pin_button), ["keep", "Pin"],
		"Pin should render the keep icon before the label when evidence is not pinned.")

	detail_panel.call("_on_pin_pressed")

	assert_eq(_collect_icon_button_texts(pin_button), ["keep_off", "Unpin"],
		"Pinned evidence should flip the header button to keep_off + Unpin.")


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
	var margin_containers: Array[MarginContainer] = []
	for child: Node in lab_section.get_children():
		if child is MarginContainer:
			margin_containers.append(child as MarginContainer)
	var wait_buttons: Array[Control] = _find_wait_buttons(lab_section)

	assert_eq(margin_containers.size(), 1,
		"Available lab analyses should be wrapped in a margin container so the side glow remains visible.")
	var button_margin: MarginContainer = margin_containers[0] as MarginContainer
	assert_not_null(button_margin)
	if button_margin != null:
		assert_eq(button_margin.get_theme_constant("margin_left"), 8)
		assert_eq(button_margin.get_theme_constant("margin_right"), 8)
		assert_eq(button_margin.size_flags_horizontal, Control.SIZE_EXPAND_FILL)

	assert_eq(wait_buttons.size(), 1,
		"Available lab analyses should render as a single WaitButton.")
	assert_eq(wait_buttons[0].size_flags_horizontal, Control.SIZE_EXPAND_FILL,
		"The WaitButton should stretch across the first column width inside its margin wrapper.")
	assert_eq(String(wait_buttons[0].get("action_text")), "Photo Analysis")
	assert_false(bool(wait_buttons[0].get("submitted")),
		"Available lab analyses should be interactive until submitted.")


func test_archive_card_shows_lab_badge_immediately_after_submit() -> void:
	GameManager.discover_evidence("ev_photo")

	var screen: Control = _instantiate_screen()
	var detail_panel: EvidenceDetailPanel = _get_detail_panel(screen)
	detail_panel.show_evidence("ev_photo")

	var evidence_grid: GridContainer = screen.get_node("%EvidenceGrid") as GridContainer
	var card: EvidencePolaroid = evidence_grid.get_child(0) as EvidencePolaroid
	assert_not_null(card)
	if card == null:
		return

	var badge_row: HBoxContainer = card.get_node("%BadgeRow") as HBoxContainer
	assert_not_null(badge_row)
	if badge_row == null:
		return

	assert_false("LAB" in _collect_badge_texts(badge_row),
		"Cards should not show a LAB badge before the evidence is submitted.")

	var success: bool = EvidenceManager.submit_to_lab_request("lab_photo")
	assert_true(success, "The test evidence should submit to the lab successfully.")

	assert_has(_collect_badge_texts(badge_row), "LAB",
		"Evidence archive cards should refresh their LAB badge immediately after submission.")


func test_pinned_evidence_moves_to_top_of_archive_and_returns_when_unpinned() -> void:
	GameManager.discover_evidence("ev_photo")
	GameManager.discover_evidence("ev_photo_result")

	var screen: Control = _instantiate_screen()
	var detail_panel: EvidenceDetailPanel = _get_detail_panel(screen)
	var evidence_grid: GridContainer = screen.get_node("%EvidenceGrid") as GridContainer

	assert_eq(
		_collect_archive_card_titles(evidence_grid),
		["Enhanced Test Photo", "Two Wine Glasses on Dining Table Beside Open Balcony Door"],
		"Archive should start with the newest discovered evidence first when nothing is pinned."
	)

	detail_panel.show_evidence("ev_photo")
	detail_panel.call("_on_pin_pressed")

	assert_eq(
		_collect_archive_card_titles(evidence_grid),
		["Two Wine Glasses on Dining Table Beside Open Balcony Door", "Enhanced Test Photo"],
		"Pinning from the detail panel should rebuild the archive with the pinned evidence first."
	)

	detail_panel.call("_on_pin_pressed")

	assert_eq(
		_collect_archive_card_titles(evidence_grid),
		["Enhanced Test Photo", "Two Wine Glasses on Dining Table Beside Open Balcony Door"],
		"Unpinning should restore the default archive ordering."
	)


func test_pending_lab_state_keeps_wait_button_visible_after_submit() -> void:
	GameManager.discover_evidence("ev_photo")

	var screen: Control = _instantiate_screen()
	var detail_panel: EvidenceDetailPanel = _get_detail_panel(screen)
	detail_panel.show_evidence("ev_photo")

	var lab_anchor: VBoxContainer = screen.get_node("%LabSectionAnchor") as VBoxContainer
	var lab_section: EvidenceLabSection = lab_anchor.get_child(0) as EvidenceLabSection
	lab_section.call("_on_submit_pressed", "lab_photo")

	var wait_buttons: Array[Control] = _find_wait_buttons(lab_section)
	var info_grid: GridContainer = screen.get_node("%InfoGrid") as GridContainer
	var lab_status_value: Label = _find_info_value_control(info_grid, "Lab Status") as Label

	assert_eq(wait_buttons.size(), 1,
		"Submitted analyses should stay visible as a pending WaitButton.")
	assert_true(bool(wait_buttons[0].get("submitted")),
		"The pending WaitButton should switch into its submitted state after submission.")
	assert_eq(String(wait_buttons[0].get("action_text")), "Photo Analysis")
	assert_not_null(lab_status_value)
	assert_eq(lab_status_value.text, "Processing...",
		"The evidence metadata should show Processing once the lab request is submitted.")


func test_pending_wait_button_disappears_when_result_arrives_next_day() -> void:
	GameManager.discover_evidence("ev_photo")

	var screen: Control = _instantiate_screen()
	var detail_panel: EvidenceDetailPanel = _get_detail_panel(screen)
	detail_panel.show_evidence("ev_photo")

	var lab_anchor: VBoxContainer = screen.get_node("%LabSectionAnchor") as VBoxContainer
	var lab_section: EvidenceLabSection = lab_anchor.get_child(0) as EvidenceLabSection
	lab_section.call("_on_submit_pressed", "lab_photo")

	DaySystem.force_advance_day()
	DaySystem.process_morning()
	await get_tree().process_frame

	assert_eq(_find_wait_buttons(lab_section).size(), 0,
		"The pending WaitButton should disappear once the lab result arrives.")
	assert_has(_collect_link_texts(lab_section), "\u2192 Enhanced Test Photo",
		"Completed lab results should replace the pending button with the output evidence link.")


func test_derived_from_row_uses_wrapping_navigation_link_when_parent_is_discovered() -> void:
	GameManager.discover_evidence("ev_photo")
	GameManager.discover_evidence("ev_photo_result")

	var screen: Control = _instantiate_screen()
	var detail_panel: EvidenceDetailPanel = _get_detail_panel(screen)
	detail_panel.show_evidence("ev_photo_result")

	var info_grid: GridContainer = screen.get_node("%InfoGrid") as GridContainer
	var label_texts: Array[String] = _collect_label_texts(info_grid)
	var link_texts: Array[String] = _collect_link_texts(info_grid)
	var derived_link: LinkButton = _find_info_value_control(info_grid, "Derived From") as LinkButton

	assert_has(label_texts, "Derived From:")
	assert_not_null(derived_link)
	assert_has(link_texts, derived_link.text)
	var link_font: Font = derived_link.get_theme_font("font")
	var link_font_size: int = derived_link.get_theme_font_size("font_size")
	var constrained_width: float = detail_panel.call(
		"_measure_text_width",
		link_font,
		link_font_size,
		"Two Wine Glasses"
	)
	var wrapped_text: String = detail_panel.call(
		"_wrap_text_to_width",
		"Two Wine Glasses on Dining Table Beside Open Balcony Door",
		link_font,
		link_font_size,
		constrained_width
	) as String
	assert_true("\n" in wrapped_text,
		"Derived From navigation should wrap onto multiple lines when space is tight.")
	assert_eq(
		wrapped_text.replace("\n", " "),
		"Two Wine Glasses on Dining Table Beside Open Balcony Door"
	)
	assert_eq(derived_link.text_overrun_behavior, TextServer.OVERRUN_NO_TRIMMING,
		"Derived From navigation should wrap instead of trimming with ellipsis.")
	assert_eq(derived_link.underline, LinkButton.UNDERLINE_MODE_NEVER)


func test_derived_from_row_wraps_without_horizontal_scrolling() -> void:
	GameManager.discover_evidence("ev_photo")
	GameManager.discover_evidence("ev_photo_result")

	var screen: Control = _instantiate_screen()
	var detail_panel: EvidenceDetailPanel = _get_detail_panel(screen)
	detail_panel.show_evidence("ev_photo_result")

	await get_tree().process_frame

	var info_grid: GridContainer = screen.get_node("%InfoGrid") as GridContainer
	var main_scroll: ScrollContainer = screen.get_node("%MainScroll") as ScrollContainer
	var derived_link: LinkButton = _find_info_value_control(info_grid, "Derived From") as LinkButton
	assert_not_null(derived_link)
	if derived_link == null:
		return

	var link_font: Font = derived_link.get_theme_font("font")
	var link_font_size: int = derived_link.get_theme_font_size("font_size")
	var constrained_width: float = detail_panel.call(
		"_measure_text_width",
		link_font,
		link_font_size,
		"Two Wine Glasses on Dining"
	)
	detail_panel.call(
		"_refresh_wrapping_link_text",
		derived_link,
		func() -> float: return constrained_width
	)

	assert_true("\n" in derived_link.text,
		"Derived From should wrap when the metadata value column is constrained.")
	assert_eq(main_scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED,
		"The details column should disable horizontal scrolling so wrapped metadata stays vertically readable.")
	assert_false(main_scroll.get_h_scroll_bar().visible,
		"Derived From wrapping should not make the details column show a horizontal scrollbar.")


func test_derived_from_row_falls_back_to_plain_text_when_parent_not_discovered() -> void:
	GameManager.discover_evidence("ev_photo_result")

	var screen: Control = _instantiate_screen()
	_get_detail_panel(screen).show_evidence("ev_photo_result")

	var info_grid: GridContainer = screen.get_node("%InfoGrid") as GridContainer
	var label_texts: Array[String] = _collect_label_texts(info_grid)
	var derived_value_control: Control = _find_info_value_control(info_grid, "Derived From")
	var derived_value: Label = derived_value_control as Label

	assert_has(label_texts, "Derived From:")
	assert_has(label_texts, "Two Wine Glasses on Dining Table Beside Open Balcony Door")
	assert_not_null(derived_value)
	assert_eq(derived_value.text, "Two Wine Glasses on Dining Table Beside Open Balcony Door")
	assert_eq(derived_value.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
	assert_eq(derived_value.vertical_alignment, VERTICAL_ALIGNMENT_TOP)
	assert_true(derived_value_control is Label,
		"Parent evidence should not be navigable when it is not in the discovered archive.")


func test_multiline_metadata_rows_are_top_aligned() -> void:
	GameManager.discover_evidence("ev_photo")
	GameManager.discover_evidence("ev_photo_result")

	var screen: Control = _instantiate_screen()
	_get_detail_panel(screen).show_evidence("ev_photo_result")

	var info_grid: GridContainer = screen.get_node("%InfoGrid") as GridContainer
	var derived_key: Label = _find_info_key_label(info_grid, "Derived From")
	var lab_key: Label = _find_info_key_label(info_grid, "Lab Result")
	var lab_value: Label = _find_info_value_control(info_grid, "Lab Result") as Label

	assert_not_null(derived_key)
	assert_not_null(lab_key)
	assert_not_null(lab_value)
	assert_eq(derived_key.vertical_alignment, VERTICAL_ALIGNMENT_TOP,
		"Metadata keys should top-align when the row value wraps to multiple lines.")
	assert_eq(lab_key.vertical_alignment, VERTICAL_ALIGNMENT_TOP,
		"Lab Result label should top-align with multi-line result text.")
	assert_eq(lab_value.vertical_alignment, VERTICAL_ALIGNMENT_TOP,
		"Lab Result text should stay top-aligned when it wraps.")


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
