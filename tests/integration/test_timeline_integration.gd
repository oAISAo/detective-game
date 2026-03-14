## test_timeline_integration.gd
## Integration tests for the timeline system.
## Tests event→place→attach evidence→overlap pipeline and GameManager serialization.
extends GutTest


const TEST_CASE_FILE: String = "test_case_tl_integ.json"

var _test_case_data: Dictionary = {
	"id": "case_tl_integ",
	"title": "Timeline Integration",
	"description": "Integration tests.",
	"start_day": 1,
	"end_day": 2,
	"persons": [
		{
			"id": "p_julia",
			"name": "Julia Ross",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 5,
		},
	],
	"evidence": [
		{
			"id": "ev_elevator",
			"name": "Elevator Log",
			"description": "Electronic log.",
			"type": "DIGITAL",
			"location_found": "loc_hallway",
			"related_persons": ["p_julia"],
			"weight": 0.7,
			"importance_level": "SUPPORTING",
		},
	],
	"statements": [],
	"events": [
		{
			"id": "evt_julia_arrives",
			"description": "Julia arrives",
			"time": "20:15",
			"day": 1,
			"location": "loc_building",
			"involved_persons": ["p_julia"],
			"supporting_evidence": ["ev_elevator"],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_julia_dinner",
			"description": "Julia at restaurant",
			"time": "20:15",
			"day": 1,
			"location": "loc_restaurant",
			"involved_persons": ["p_julia"],
			"supporting_evidence": [],
			"certainty_level": "CLAIMED",
		},
	],
	"locations": [
		{"id": "loc_building", "name": "Building", "searchable": true, "evidence_pool": []},
		{"id": "loc_restaurant", "name": "Restaurant", "searchable": true, "evidence_pool": []},
		{"id": "loc_hallway", "name": "Hallway", "searchable": true, "evidence_pool": []},
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
	TimelineManager.reset()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Full Pipeline: event → place → attach evidence → contradiction detected
# =========================================================================

func test_event_place_attach_overlap_pipeline() -> void:
	# Place first event: Julia arrives at building
	var entry1: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	assert_false(entry1.is_empty(), "Entry should be created")

	# Place second event: Julia at restaurant at same time
	var entry2: Dictionary = TimelineManager.place_event("evt_julia_dinner", 1215, 1)
	assert_false(entry2.is_empty(), "Second entry should be created")

	# Attach evidence to first entry
	var attached: bool = TimelineManager.attach_evidence(entry1["id"], "ev_elevator")
	assert_true(attached, "Evidence should attach")

	# Check overlaps — Julia at two locations at 20:15
	var overlaps: Array[Dictionary] = TimelineManager.get_overlaps(1)
	assert_eq(overlaps.size(), 1, "Should detect 1 overlap")
	assert_eq(overlaps[0]["person_id"], "p_julia")
	assert_eq(overlaps[0]["time_minutes"], 1215)
	assert_eq(overlaps[0]["locations"].size(), 2)

	# Verify evidence attached
	var ev_list: Array[String] = TimelineManager.get_attached_evidence(entry1["id"])
	assert_has(ev_list, "ev_elevator")


# =========================================================================
# GameManager Serialization Integration
# =========================================================================

func test_game_manager_serialize_includes_timeline() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.add_hypothesis("Test hyp", 1230, 1)

	var save_data: Dictionary = GameManager.serialize()
	assert_true(save_data.has("timeline_manager"), "Save should include timeline_manager key")

	var tl_data: Dictionary = save_data["timeline_manager"]
	assert_true(tl_data.has("entries"))
	assert_true(tl_data.has("hypotheses"))


func test_game_manager_deserialize_restores_timeline() -> void:
	var e1: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.add_hypothesis("Hyp", 1230, 1, "loc_building", ["p_julia"])
	TimelineManager.attach_evidence(e1["id"], "ev_elevator")

	var save_data: Dictionary = GameManager.serialize()

	# Reset everything
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)

	assert_eq(TimelineManager.get_entry_count(), 0, "Should be empty after reset")

	GameManager.deserialize(save_data)

	assert_eq(TimelineManager.get_entry_count(), 1, "Should restore 1 entry")
	assert_eq(TimelineManager.get_hypothesis_count(), 1, "Should restore 1 hypothesis")

	var attached: Array[String] = TimelineManager.get_attached_evidence(e1["id"])
	assert_has(attached, "ev_elevator", "Should restore attached evidence")
