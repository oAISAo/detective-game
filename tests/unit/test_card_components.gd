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
# LocationCard Tests
# ============================================================

func test_location_card_setup_populates_name() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	assert_eq(card.get_location_id(), "loc_apartment", "Card should store location ID")
	var name_label: Label = card.get_node("%NameLabel")
	assert_eq(name_label.text, "Riverside Apartment", "Card should display location name")


func test_location_card_shows_placeholder_when_no_image() -> void:
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


func test_location_card_displays_status_badge() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	var badge_label: Label = card.get_node("%StatusLabel")
	assert_eq(badge_label.text, "NEW", "Unvisited location should show 'NEW'")


func test_location_card_displays_description() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	var desc: Label = card.get_node("%DescriptionLabel")
	assert_true(desc.text.length() > 0, "Card should have description text")
	assert_true(desc.text.ends_with("."), "Short description should end at first sentence")


func test_location_card_emits_signal() -> void:
	var card: Node = _location_card_scene.instantiate()
	add_child_autofree(card)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	card.setup(loc)
	watch_signals(card)
	card.card_pressed.emit("loc_apartment")
	assert_signal_emitted_with_parameters(card, "card_pressed", ["loc_apartment"])
