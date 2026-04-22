## test_card_components.gd
## Unit tests for card UI components: EvidenceCard, SuspectCard, LocationCard.
## Verifies setup, state display, and signal wiring for Phase D6/D7 cards.
extends GutTest


## Path to the test case JSON file.
const TEST_CASE_FILE: String = "test_cards.json"

## Minimal test case data with evidence, persons, and locations.
var _test_case_data: Dictionary = {
	"id": "case_card_test",
	"title": "Card Test Case",
	"description": "Test case for card components.",
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
		{
			"id": "p_julia",
			"name": "Julia Ross",
			"role": "SUSPECT",
			"personality_traits": ["CALM"],
			"relationships": [{"person_b": "p_victim", "type": "SPOUSE"}],
			"pressure_threshold": 5,
		},
		{
			"id": "p_mark",
			"name": "Mark Bennett",
			"role": "WITNESS",
			"personality_traits": ["ANXIOUS"],
			"relationships": [{"person_b": "p_victim", "type": "COWORKER"}],
			"pressure_threshold": 3,
		},
	],
	"evidence": [
		{
			"id": "ev_fingerprint",
			"name": "Fingerprint on Glass",
			"description": "A partial fingerprint found on a glass at the scene.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": ["p_julia"],
			"tags": ["fingerprint", "forensic"],
			"weight": 0.8,
			"importance_level": "CRITICAL",
			"requires_lab_analysis": true,
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_photo",
			"name": "Crime Scene Photo",
			"description": "A photograph of the crime scene showing key details about placement of objects.",
			"type": "PHOTO",
			"location_found": "loc_apartment",
			"related_persons": ["p_victim"],
			"tags": ["photo"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_processed",
			"name": "Analyzed Knife",
			"description": "A knife with completed forensic analysis.",
			"type": "OBJECT",
			"location_found": "loc_apartment",
			"related_persons": [],
			"tags": ["weapon"],
			"weight": 0.9,
			"importance_level": "CRITICAL",
			"requires_lab_analysis": true,
			"lab_status": "COMPLETED",
			"lab_result_text": "Blood matches the victim.",
		},
		{
			"id": "ev_in_lab",
			"name": "Pending Sample",
			"description": "A sample currently being processed in the lab.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": [],
			"tags": ["lab"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
			"requires_lab_analysis": true,
			"lab_status": "PROCESSING",
		},
	],
	"statements": [],
	"locations": [
		{
			"id": "loc_apartment",
			"name": "Riverside Apartment",
			"description": "The victim's apartment where the crime took place. Located on the third floor.",
			"searchable": true,
			"image": "",
			"investigable_objects": [],
			"evidence_pool": ["ev_fingerprint", "ev_photo"],
		},
	],
	"events": [],
	"timeline": [],
	"discovery_rules": [],
}

# Use preload to get PackedScenes — avoids class_name resolution issues in headless mode
var _evidence_card_scene: PackedScene = preload("res://scenes/ui/components/evidence_card.tscn")
var _suspect_card_scene: PackedScene = preload("res://scenes/ui/components/suspect_card.tscn")
var _location_card_scene: PackedScene = preload("res://scenes/ui/components/location_card.tscn")


# --- Setup / Teardown --- #

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


# ============================================================
# EvidenceCard Tests
# ============================================================

func test_evidence_card_setup_populates_name() -> void:
	var card: Node = _evidence_card_scene.instantiate()
	add_child_autofree(card)
	var ev: EvidenceData = CaseManager.get_evidence("ev_fingerprint")
	card.setup(ev)
	assert_eq(card.get_evidence_id(), "ev_fingerprint", "Card should store evidence ID")
	var name_label: Label = card.get_node("%NameLabel")
	assert_eq(name_label.text, "Fingerprint on Glass", "Card should display evidence name")


func test_evidence_card_setup_populates_type_badge() -> void:
	var card: Node = _evidence_card_scene.instantiate()
	add_child_autofree(card)
	var ev: EvidenceData = CaseManager.get_evidence("ev_fingerprint")
	card.setup(ev)
	var type_badge: Label = card.get_node("%TypeBadge")
	assert_eq(type_badge.text, "Forensic", "Card should display evidence type")


func test_evidence_card_setup_populates_description() -> void:
	var card: Node = _evidence_card_scene.instantiate()
	add_child_autofree(card)
	var ev: EvidenceData = CaseManager.get_evidence("ev_fingerprint")
	card.setup(ev)
	var desc_label: Label = card.get_node("%DescriptionLabel")
	assert_true(desc_label.text.length() > 0, "Card should have description text")


func test_evidence_card_state_awaiting_analysis() -> void:
	var card: Node = _evidence_card_scene.instantiate()
	add_child_autofree(card)
	var ev: EvidenceData = CaseManager.get_evidence("ev_fingerprint")
	card.setup(ev)
	var state_label: Label = card.get_node("%StateLabel")
	assert_eq(state_label.text, "Awaiting Analysis", "Unsubmitted lab evidence should show 'Awaiting Analysis'")


func test_evidence_card_state_collected() -> void:
	var card: Node = _evidence_card_scene.instantiate()
	add_child_autofree(card)
	var ev: EvidenceData = CaseManager.get_evidence("ev_photo")
	card.setup(ev)
	var state_label: Label = card.get_node("%StateLabel")
	assert_eq(state_label.text, "Collected", "Non-lab evidence should show 'Collected'")


func test_evidence_card_state_processed() -> void:
	var card: Node = _evidence_card_scene.instantiate()
	add_child_autofree(card)
	var ev: EvidenceData = CaseManager.get_evidence("ev_processed")
	card.setup(ev)
	var state_label: Label = card.get_node("%StateLabel")
	assert_eq(state_label.text, "Processed", "Completed lab evidence should show 'Processed'")


func test_evidence_card_state_in_lab() -> void:
	var card: Node = _evidence_card_scene.instantiate()
	add_child_autofree(card)
	var ev: EvidenceData = CaseManager.get_evidence("ev_in_lab")
	card.setup(ev)
	var state_label: Label = card.get_node("%StateLabel")
	assert_eq(state_label.text, "In Lab", "Processing evidence should show 'In Lab'")


func test_evidence_card_emits_signal() -> void:
	var card: Node = _evidence_card_scene.instantiate()
	add_child_autofree(card)
	var ev: EvidenceData = CaseManager.get_evidence("ev_fingerprint")
	card.setup(ev)
	watch_signals(card)
	card.card_pressed.emit("ev_fingerprint")
	assert_signal_emitted_with_parameters(card, "card_pressed", ["ev_fingerprint"])


func test_evidence_card_truncates_long_description() -> void:
	var card: Node = _evidence_card_scene.instantiate()
	add_child_autofree(card)
	# Create evidence with a very long description
	var ev: EvidenceData = CaseManager.get_evidence("ev_fingerprint")
	ev.description = "A".repeat(120)
	card.setup(ev)
	var desc_label: Label = card.get_node("%DescriptionLabel")
	assert_eq(desc_label.text.length(), 100, "Long description should be truncated to 100 chars")
	assert_true(desc_label.text.ends_with("..."), "Truncated text should end with ellipsis")


# ============================================================
# SuspectCard Tests
# ============================================================

func test_suspect_card_setup_populates_name() -> void:
	var card: Node = _suspect_card_scene.instantiate()
	add_child_autofree(card)
	var person: PersonData = CaseManager.get_person("p_julia")
	card.setup(person, "p_julia")
	assert_eq(card.get_person_id(), "p_julia", "Card should store person ID")
	var name_label: Label = card.get_node("%NameLabel")
	assert_eq(name_label.text, "Julia Ross", "Card should display person name")


func test_suspect_card_setup_populates_role_badge() -> void:
	var card: Node = _suspect_card_scene.instantiate()
	add_child_autofree(card)
	var person: PersonData = CaseManager.get_person("p_julia")
	card.setup(person, "p_julia")
	var role_badge: Label = card.get_node("%RoleBadge")
	assert_eq(role_badge.text, "suspect", "Card should display role in lowercase")


func test_suspect_card_witness_role_badge() -> void:
	var card: Node = _suspect_card_scene.instantiate()
	add_child_autofree(card)
	var person: PersonData = CaseManager.get_person("p_mark")
	card.setup(person, "p_mark")
	var role_badge: Label = card.get_node("%RoleBadge")
	assert_eq(role_badge.text, "witness", "Witness role should display correctly")


func test_suspect_card_available_status() -> void:
	var card: Node = _suspect_card_scene.instantiate()
	add_child_autofree(card)
	GameManager.unlocked_interrogations.append("p_julia")
	var person: PersonData = CaseManager.get_person("p_julia")
	card.setup(person, "p_julia")
	var status_label: Label = card.get_node("%StatusLabel")
	assert_eq(status_label.text, "Available", "Suspect not yet interrogated should show 'Available'")


func test_suspect_card_emits_interrogate_signal() -> void:
	var card: Node = _suspect_card_scene.instantiate()
	add_child_autofree(card)
	var person: PersonData = CaseManager.get_person("p_julia")
	card.setup(person, "p_julia")
	watch_signals(card)
	card.interrogate_pressed.emit("p_julia")
	assert_signal_emitted_with_parameters(card, "interrogate_pressed", ["p_julia"])


# ============================================================
# LocationCard Tests Aisa TODO
# ============================================================

func _disabled_test_location_card_setup_populates_name() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	assert_eq(card.get_location_id(), "loc_apartment", "Card should store location ID")
	var name_label: Label = card.get_node("%NameLabel")
	assert_eq(name_label.text, "Riverside Apartment", "Card should display location name")
	assert_eq(name_label.theme_type_variation, &"SectionHeader",
		"Location name should use the bold SectionHeader variation")


func _disabled_test_location_card_shows_placeholder_when_no_image() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	var image_rect: TextureRect = card.get_node("%ImageRect")
	var placeholder: PanelContainer = card.get_node("%ImagePlaceholder")
	assert_false(image_rect.visible, "ImageRect should be hidden when no image")
	assert_true(placeholder.visible, "Placeholder should be visible when no image")
	var initial: Label = card.get_node("%PlaceholderInitial")
	assert_eq(initial.text, "RIVERSIDE APARTMENT", "Placeholder should show full location name in uppercase")


func _disabled_test_location_card_setup_rejects_null_location_data() -> void:
	var card: LocationCard = _location_card_scene.instantiate()
	add_child_autofree(card)
	card.setup(null)
	assert_push_error("[LocationCard] setup rejected: null location data")
	assert_eq(card.get_location_id(), "", "Invalid setup should not set a location id")
	watch_signals(card)
	card._on_pressed()
	assert_signal_not_emitted(card, "card_pressed")


func _disabled_test_location_card_setup_rejects_missing_location_id_and_blocks_press_signal() -> void:
	var card: LocationCard = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = LocationData.new()
	loc.name = "Nameless Reference"
	loc.description = "Missing id should be rejected."
	card.setup(loc)
	assert_push_error("[LocationCard] setup rejected: missing location id")
	assert_eq(card.get_location_id(), "")
	watch_signals(card)
	card._on_pressed()
	assert_signal_not_emitted(card, "card_pressed")


func _disabled_test_location_card_invalid_image_path_uses_placeholder() -> void:
	var card: LocationCard = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = LocationData.new()
	loc.id = "loc_bad_image"
	loc.name = "Broken Image"
	loc.description = "Invalid image path should safely fallback."
	loc.image = "res://assets/placeholders/does_not_exist.png"
	card.setup(loc)
	assert_push_warning(
		"[LocationCard] Image path not found for location 'loc_bad_image': res://assets/placeholders/does_not_exist.png"
	)
	var image_rect: TextureRect = card.get_node("%ImageRect")
	var placeholder: PanelContainer = card.get_node("%ImagePlaceholder")
	assert_false(image_rect.visible)
	assert_true(placeholder.visible)


func _disabled_test_location_card_non_texture_resource_image_uses_placeholder() -> void:
	var card: LocationCard = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = LocationData.new()
	loc.id = "loc_script_image"
	loc.name = "Script Image"
	loc.description = "Non-texture resources should be rejected as images."
	loc.image = "res://scripts/ui/components/location_card.gd"
	card.setup(loc)
	assert_push_warning(
		"[LocationCard] Image resource is not a Texture2D for location 'loc_script_image': res://scripts/ui/components/location_card.gd"
	)
	var image_rect: TextureRect = card.get_node("%ImageRect")
	var placeholder: PanelContainer = card.get_node("%ImagePlaceholder")
	assert_false(image_rect.visible)
	assert_true(placeholder.visible)


func _disabled_test_location_card_splits_evidence_prefix_from_value() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	var prefix_label: Label = card.get_node("%EvidencePrefixLabel")
	var value_label: Label = card.get_node("%EvidenceLabel")
	assert_eq(prefix_label.text, "Evidence:", "Evidence row should keep a separate bold prefix")
	assert_eq(prefix_label.theme_type_variation, &"SectionHeader",
		"Evidence prefix should use the bold SectionHeader variation")
	assert_eq(value_label.text, "?", "Evidence value should remain separate from the prefix")


func _disabled_test_location_card_has_no_gradient_overlay() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	assert_eq(card.get_node_or_null("%GradientOverlay"), null,
		"Location card should not create a gradient overlay anymore")


func _disabled_test_location_card_image_uses_rounded_mask_material() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	await get_tree().process_frame
	var image_rect: TextureRect = card.get_node("%ImageRect")
	assert_true(image_rect.material is ShaderMaterial,
		"Location image should use a shader material so its corners render rounded")
	var image_material: ShaderMaterial = image_rect.material as ShaderMaterial
	assert_almost_eq(image_material.get_shader_parameter("rect_size").x, image_rect.size.x, 0.01,
		"Image mask shader should track the actual image width")
	assert_almost_eq(image_material.get_shader_parameter("rect_size").y, image_rect.size.y, 0.01,
		"Image mask shader should track the actual image height")


func _disabled_test_location_card_status_badge_stays_compact_in_top_right() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	await get_tree().process_frame
	var media_frame: Control = card.get_node("%MediaFrame")
	var status_badge: Control = card.get_node("%StatusBadge")
	assert_true(status_badge.size.x < media_frame.size.x * 0.5,
		"Status badge should size to its text instead of stretching across the media frame")
	assert_true(status_badge.size.y < media_frame.size.y * 0.25,
		"Status badge should remain pill-height instead of stretching down the media frame")
	assert_gt(status_badge.global_position.x, media_frame.global_position.x + media_frame.size.x * 0.5,
		"Status badge should stay in the top-right area of the media frame")


func _disabled_test_location_card_hover_state_tracks_card_mouse_events() -> void:
	var card: LocationCard = _location_card_scene.instantiate()
	add_child_autofree(card)
	card._on_mouse_entered()
	assert_true(card._is_hovered,
		"Hover state should activate on card mouse enter")
	card._on_mouse_exited()
	assert_false(card._is_hovered,
		"Hover state should clear on card mouse exit")


func _disabled_test_location_card_hover_includes_image_and_footer_regions() -> void:
	var card: LocationCard = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)

	var image_area: Control = card.get_node("VBox/ImageArea")
	var media_frame: PanelContainer = card.get_node("%MediaFrame")
	var image_rect: TextureRect = card.get_node("%ImageRect")
	var image_placeholder: PanelContainer = card.get_node("%ImagePlaceholder")
	var overlay_margin: MarginContainer = card.get_node("VBox/ImageArea/MediaFrame/OverlayMargin")
	var badge_row: HBoxContainer = card.get_node("VBox/ImageArea/MediaFrame/OverlayMargin/BadgeRow")
	var status_badge: PanelContainer = card.get_node("%StatusBadge")
	var status_label: Label = card.get_node("%StatusLabel")
	var footer: VBoxContainer = card.get_node("%Footer")
	var name_label: Label = card.get_node("%NameLabel")
	var description_label: Label = card.get_node("%DescriptionLabel")
	var evidence_prefix: Label = card.get_node("%EvidencePrefixLabel")
	var evidence_value: Label = card.get_node("%EvidenceLabel")

	assert_eq(image_area.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Image area wrapper should ignore mouse so card hover and cursor styling remain active")
	assert_eq(media_frame.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Media frame should ignore mouse so image-area hover uses card-level hover state")
	assert_eq(image_rect.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Image rect should ignore mouse so image-area hover keeps card highlight active")
	assert_eq(image_placeholder.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Image placeholder should ignore mouse so empty-image hover keeps card highlight active")
	assert_eq(overlay_margin.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Overlay margin should ignore mouse so its full-rect bounds do not suppress card hover/cursor")
	assert_eq(badge_row.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Badge row should ignore mouse to keep image-region hover behavior consistent")
	assert_eq(status_badge.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Status badge should ignore mouse so badge hover does not drop card highlight")
	assert_eq(status_label.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Status label should ignore mouse so badge text does not suppress card hover/cursor")
	assert_eq(footer.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Footer container should ignore mouse so text regions route hover/clicks to the card")
	assert_eq(name_label.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Title label should ignore mouse so card hover stays unified")
	assert_eq(description_label.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Description label should ignore mouse so card hover stays unified")
	assert_eq(evidence_prefix.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Evidence prefix should ignore mouse so card hover stays unified")
	assert_eq(evidence_value.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Evidence value should ignore mouse so card hover stays unified")

	card._set_hovered_state(false)
	card._on_mouse_entered()
	assert_true(card._is_hovered,
		"Card hover should activate from card-level mouse entry")


func _disabled_test_location_card_hover_clears_after_fast_exit_from_image_region() -> void:
	var card: LocationCard = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)

	# Place card away from the default pointer origin so bounds checks resolve to outside.
	card.position = Vector2(900.0, 900.0)
	card._set_hovered_state(true)
	card._on_hover_source_exited()
	await get_tree().process_frame

	assert_false(card._is_hovered,
		"Hover state should clear after quick exits when pointer is outside card bounds")


func _disabled_test_location_card_click_emits_single_press_event() -> void:
	var card: LocationCard = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)

	var pressed_event: Dictionary = {
		"count": 0,
		"id": "",
	}
	card.card_pressed.connect(func(location_id: String) -> void:
		pressed_event["count"] = int(pressed_event["count"]) + 1
		pressed_event["id"] = location_id
	)

	var click_event: InputEventMouseButton = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	card._on_card_gui_input(click_event)

	assert_eq(pressed_event["count"], 1, "One card click should emit exactly one card_pressed event")
	assert_eq(pressed_event["id"], "loc_apartment", "Card click should emit the card's location id")


func _disabled_test_location_card_non_left_click_does_not_emit_signal() -> void:
	var card: LocationCard = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)

	var pressed_event: Dictionary = {
		"count": 0,
	}
	card.card_pressed.connect(func(_location_id: String) -> void:
		pressed_event["count"] = int(pressed_event["count"]) + 1
	)

	var right_click: InputEventMouseButton = InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	card._on_card_gui_input(right_click)

	assert_eq(pressed_event["count"], 0,
		"Non-left clicks should not emit a new press event")


func _disabled_test_location_card_media_and_text_use_same_left_padding() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	await get_tree().process_frame
	var media_frame: Control = card.get_node("%MediaFrame")
	var footer: Control = card.get_node("%Footer")
	var name_label: Label = card.get_node("%NameLabel")
	var footer_gap: float = footer.global_position.y - (media_frame.global_position.y + media_frame.size.y)
	assert_almost_eq(name_label.global_position.x, media_frame.global_position.x, 0.01,
		"Location title should align with the left edge of the media frame")
	assert_true(footer_gap >= 12.0 and footer_gap < 15.0,
		"Footer content should stay close to a 12px gap below the media frame")


func _disabled_test_location_card_displays_status_badge() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	var badge_label: Label = card.get_node("%StatusLabel")
	assert_eq(badge_label.text, "NEW", "Unvisited location should show 'NEW'")


func _disabled_test_location_card_displays_description() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	var desc: Label = card.get_node("%DescriptionLabel")
	assert_true(desc.text.length() > 0, "Card should have description text")
	assert_true(desc.text.ends_with("."), "Short description should end at first sentence")


func _disabled_test_location_card_emits_signal() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	watch_signals(card)
	card._on_pressed()
	assert_signal_emitted_with_parameters(card, "card_pressed", ["loc_apartment"])
