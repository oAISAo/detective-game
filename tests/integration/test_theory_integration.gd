## test_theory_integration.gd
## Integration tests for the Theory Builder system.
## Tests the full pipeline: theory + timeline inconsistencies,
## theory + evidence attachment, theory + GameManager persistence.
extends GutTest


const TEST_CASE_FILE: String = "test_case_theory_integ.json"

var _test_case_data: Dictionary = {
	"id": "case_theory_integ",
	"title": "Theory Integration",
	"description": "Tests theory integration.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{
			"id": "p_victim",
			"name": "Daniel",
			"role": "VICTIM",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 0,
		},
		{
			"id": "p_mark",
			"name": "Mark",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 3,
		},
		{
			"id": "p_julia",
			"name": "Julia",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 5,
		},
	],
	"evidence": [
		{
			"id": "ev_knife",
			"name": "Kitchen Knife",
			"description": "Found in sink.",
			"type": "PHYSICAL",
			"location_found": "loc_apt",
			"related_persons": ["p_mark"],
			"weight": 0.8,
			"importance_level": "KEY",
		},
		{
			"id": "ev_prints",
			"name": "Fingerprints",
			"description": "On handle.",
			"type": "FORENSIC",
			"location_found": "loc_apt",
			"related_persons": ["p_julia"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_camera",
			"name": "Camera",
			"description": "Footage.",
			"type": "DIGITAL",
			"location_found": "loc_parking",
			"related_persons": ["p_mark"],
			"weight": 0.7,
			"importance_level": "SUPPORTING",
		},
	],
	"statements": [],
	"events": [
		{
			"id": "evt_mark_visit",
			"description": "Mark visits Daniel",
			"time": "19:30",
			"day": 1,
			"location": "loc_apt",
			"involved_persons": ["p_mark"],
			"supporting_evidence": [],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_julia_arrives",
			"description": "Julia arrives",
			"time": "21:00",
			"day": 1,
			"location": "loc_apt",
			"involved_persons": ["p_julia"],
			"supporting_evidence": ["ev_prints"],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_mark_parking",
			"description": "Mark at parking",
			"time": "21:00",
			"day": 1,
			"location": "loc_parking",
			"involved_persons": ["p_mark"],
			"supporting_evidence": ["ev_camera"],
			"certainty_level": "LIKELY",
		},
	],
	"locations": [
		{"id": "loc_apt", "name": "Apartment", "searchable": true, "evidence_pool": []},
		{"id": "loc_parking", "name": "Parking", "searchable": true, "evidence_pool": []},
	],
	"event_triggers": [],
	"interrogation_topics": [],
	"actions": [],
	"insights": [],
	"interrogation_triggers": [],
}


func before_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	DirAccess.make_dir_recursive_absolute("res://data/cases")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_test_case_data, "\t"))
	file.close()


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)
	TheoryManager.reset()
	TimelineManager.reset()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Theory + Timeline Integration
# =========================================================================

func test_theory_detects_timeline_entry_conflict() -> void:
	# Place Julia at apartment at 21:00
	TimelineManager.place_event("evt_julia_arrives", 1260, 1)

	# Create theory claiming Julia killed victim at 21:00
	var t: Dictionary = TheoryManager.create_theory("Julia did it")
	TheoryManager.set_suspect(t["id"], "p_julia")
	TheoryManager.set_time(t["id"], 1260, 1)

	var incon: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	assert_eq(incon.size(), 1, "Should detect Julia at apt at same time")
	assert_eq(incon[0]["type"], "timeline_conflict")
	assert_true(
		incon[0]["description"].find("p_julia") >= 0,
		"Description should mention Julia"
	)


func test_theory_detects_hypothesis_conflict() -> void:
	# Hypothesis: Julia at parking at 21:00
	TimelineManager.add_hypothesis(
		"Julia seen at parking", 1260, 1, "loc_parking", ["p_julia"]
	)

	var t: Dictionary = TheoryManager.create_theory("Julia")
	TheoryManager.set_suspect(t["id"], "p_julia")
	TheoryManager.set_time(t["id"], 1260, 1)

	var incon: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	assert_eq(incon.size(), 1, "Should detect hypothesis conflict")


func test_theory_no_conflict_when_different_suspect() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1260, 1)

	var t: Dictionary = TheoryManager.create_theory("Mark did it")
	TheoryManager.set_suspect(t["id"], "p_mark")
	TheoryManager.set_time(t["id"], 1260, 1)

	var incon: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	assert_eq(incon.size(), 0, "Mark is not in Julia's event")


func test_theory_multiple_conflicts() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1260, 1)
	TimelineManager.add_hypothesis(
		"Julia at parking", 1260, 1, "loc_parking", ["p_julia"]
	)

	var t: Dictionary = TheoryManager.create_theory("Julia")
	TheoryManager.set_suspect(t["id"], "p_julia")
	TheoryManager.set_time(t["id"], 1260, 1)

	var incon: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	assert_eq(incon.size(), 2, "Both entry and hypothesis conflict")


# =========================================================================
# Theory + GameManager Persistence
# =========================================================================

func test_game_manager_serialize_includes_theory() -> void:
	var t: Dictionary = TheoryManager.create_theory("Test Theory")
	TheoryManager.set_suspect(t["id"], "p_mark")

	var save_data: Dictionary = GameManager.serialize()
	assert_true(save_data.has("theory_manager"), "Save should include theory_manager")
	assert_true(save_data["theory_manager"].has("theories"), "Should have theories key")


func test_game_manager_deserialize_restores_theory() -> void:
	var t: Dictionary = TheoryManager.create_theory("Persist Test")
	TheoryManager.set_suspect(t["id"], "p_julia")
	TheoryManager.set_motive(t["id"], "Financial")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")

	var save_data: Dictionary = GameManager.serialize()

	# Reset everything
	GameManager.new_game()
	CaseManager.load_case(TEST_CASE_FILE)
	assert_eq(TheoryManager.get_theory_count(), 0, "Reset should clear theories")

	# Restore
	GameManager.deserialize(save_data)
	assert_eq(TheoryManager.get_theory_count(), 1, "Theory should be restored")

	var restored: Dictionary = TheoryManager.get_theory(t["id"])
	assert_eq(restored["suspect_id"], "p_julia")
	assert_eq(restored["motive"], "Financial")
	var ev: Array[String] = TheoryManager.get_step_evidence(t["id"], "suspect")
	assert_has(ev, "ev_knife", "Evidence attachment should persist")


func test_game_manager_new_game_resets_theories() -> void:
	TheoryManager.create_theory("Should be cleared")
	assert_eq(TheoryManager.get_theory_count(), 1)

	GameManager.new_game()
	assert_eq(TheoryManager.get_theory_count(), 0, "new_game should reset theories")


# =========================================================================
# Theory + Evidence Discovery Flow
# =========================================================================

func test_attach_discovered_evidence_to_theory() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_prints")

	var t: Dictionary = TheoryManager.create_theory("Knife Theory")
	TheoryManager.set_suspect(t["id"], "p_mark")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_prints")

	assert_eq(TheoryManager.get_step_strength(t["id"], "suspect"), Enums.TheoryStrength.MODERATE)
	var ev: Array[String] = TheoryManager.get_step_evidence(t["id"], "suspect")
	assert_eq(ev.size(), 2)


func test_theory_strength_progression() -> void:
	var t: Dictionary = TheoryManager.create_theory("Progressive")

	# Start at NONE
	assert_eq(TheoryManager.get_step_strength(t["id"], "motive"), Enums.TheoryStrength.NONE)

	# Add 1 → WEAK
	TheoryManager.attach_evidence(t["id"], "motive", "ev_knife")
	assert_eq(TheoryManager.get_step_strength(t["id"], "motive"), Enums.TheoryStrength.WEAK)

	# Add 2 → MODERATE
	TheoryManager.attach_evidence(t["id"], "motive", "ev_prints")
	assert_eq(TheoryManager.get_step_strength(t["id"], "motive"), Enums.TheoryStrength.MODERATE)

	# Add 3 → STRONG
	TheoryManager.attach_evidence(t["id"], "motive", "ev_camera")
	assert_eq(TheoryManager.get_step_strength(t["id"], "motive"), Enums.TheoryStrength.STRONG)


# =========================================================================
# Combined Theory + Timeline + Evidence
# =========================================================================

func test_full_theory_with_timeline_and_evidence() -> void:
	# Build timeline
	var e1: Dictionary = TimelineManager.place_event("evt_mark_visit", 1170, 1)
	var e2: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1260, 1)

	# Build theory
	var t: Dictionary = TheoryManager.create_theory("Julia killed Daniel")
	TheoryManager.set_suspect(t["id"], "p_julia")
	TheoryManager.set_motive(t["id"], "Relationship conflict")
	TheoryManager.set_time(t["id"], 1260, 1)
	TheoryManager.set_method(t["id"], "Kitchen knife")

	# Link timeline entries
	var links: Array[String] = [e1["id"], e2["id"]]
	TheoryManager.set_timeline_links(t["id"], links)

	# Attach evidence
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_prints")
	TheoryManager.attach_evidence(t["id"], "method", "ev_knife")

	# Verify completeness
	assert_true(TheoryManager.is_complete(t["id"]), "Theory should be complete")

	# Verify strengths
	assert_eq(TheoryManager.get_step_strength(t["id"], "suspect"), Enums.TheoryStrength.WEAK)
	assert_eq(TheoryManager.get_step_strength(t["id"], "method"), Enums.TheoryStrength.WEAK)
	assert_eq(TheoryManager.get_step_strength(t["id"], "timeline"), Enums.TheoryStrength.MODERATE)

	# Check inconsistencies — Julia at apt at 21:00 in timeline matches theory time
	var incon: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	assert_eq(incon.size(), 1, "Julia at apt conflicts with theory time")

	# Serialize and restore, verify integrity
	var data: Dictionary = GameManager.serialize()
	GameManager.new_game()
	CaseManager.load_case(TEST_CASE_FILE)
	TimelineManager.reset()

	GameManager.deserialize(data)
	assert_true(TheoryManager.is_complete(t["id"]), "Theory still complete after restore")
	assert_eq(TheoryManager.get_theory(t["id"])["suspect_id"], "p_julia")


# =========================================================================
# Screen Manager Registration
# =========================================================================

func test_screen_manager_has_theory_builder() -> void:
	assert_true(
		ScreenManager.SCREEN_SCENES.has("theory_builder"),
		"Should have theory_builder screen"
	)
	assert_eq(
		ScreenManager.SCREEN_SCENES["theory_builder"],
		"res://scenes/ui/theory_builder.tscn"
	)


func test_screen_count_is_thirteen() -> void:
	assert_eq(ScreenManager.SCREEN_SCENES.size(), 17, "Should have 17 screens")


# =========================================================================
# TheoryStrength Enum
# =========================================================================

func test_theory_strength_enum_values() -> void:
	assert_eq(Enums.TheoryStrength.NONE, 0)
	assert_eq(Enums.TheoryStrength.WEAK, 1)
	assert_eq(Enums.TheoryStrength.MODERATE, 2)
	assert_eq(Enums.TheoryStrength.STRONG, 3)
