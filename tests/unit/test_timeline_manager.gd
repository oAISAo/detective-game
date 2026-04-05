## test_timeline_manager.gd
## Unit tests for the TimelineManager autoload.
## Tests time snapping, entry CRUD, hypothesis CRUD, overlap detection,
## evidence attachment, and serialization.
extends GutTest


const TEST_CASE_FILE: String = "test_case_timeline.json"

var _test_case_data: Dictionary = {
	"id": "case_timeline_test",
	"title": "Timeline Test Case",
	"description": "Tests timeline reconstruction.",
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
			"personality_traits": ["MANIPULATIVE"],
			"relationships": [],
			"pressure_threshold": 5,
		},
		{
			"id": "p_mark",
			"name": "Mark Bennett",
			"role": "SUSPECT",
			"personality_traits": ["AGGRESSIVE"],
			"relationships": [],
			"pressure_threshold": 3,
		},
	],
	"evidence": [
		{
			"id": "ev_elevator",
			"name": "Elevator Log",
			"description": "Electronic log from elevator.",
			"type": "DIGITAL",
			"location_found": "loc_hallway",
			"related_persons": ["p_julia"],
			"weight": 0.7,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_camera",
			"name": "Camera Footage",
			"description": "Parking camera.",
			"type": "RECORDING",
			"location_found": "loc_parking",
			"related_persons": ["p_mark"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
		},
	],
	"statements": [],
	"events": [
		{
			"id": "evt_julia_arrives",
			"description": "Julia arrives at the building",
			"time": "20:15",
			"day": 1,
			"location": "loc_building",
			"involved_persons": ["p_julia"],
			"supporting_evidence": ["ev_elevator"],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_julia_leaves",
			"description": "Julia leaves the building",
			"time": "20:45",
			"day": 1,
			"location": "loc_parking",
			"involved_persons": ["p_julia"],
			"supporting_evidence": [],
			"certainty_level": "CLAIMED",
		},
		{
			"id": "evt_mark_arrives",
			"description": "Mark arrives at parking lot",
			"time": "20:30",
			"day": 1,
			"location": "loc_parking",
			"involved_persons": ["p_mark"],
			"supporting_evidence": ["ev_camera"],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_day2_meeting",
			"description": "Mark and Julia meet",
			"time": "14:00",
			"day": 2,
			"location": "loc_office",
			"involved_persons": ["p_mark", "p_julia"],
			"supporting_evidence": [],
			"certainty_level": "LIKELY",
		},
	],
	"locations": [
		{"id": "loc_building", "name": "Building", "searchable": true, "evidence_pool": []},
		{"id": "loc_parking", "name": "Parking Lot", "searchable": true, "evidence_pool": []},
		{"id": "loc_office", "name": "Office", "searchable": true, "evidence_pool": []},
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
# Time Utilities
# =========================================================================

func test_snap_time_exact_multiple() -> void:
	assert_eq(TimelineManager.snap_time(1200), 1200, "Exact multiple should not change")


func test_snap_time_rounds_down() -> void:
	assert_eq(TimelineManager.snap_time(1202), 1200, "Should round down 2 min")


func test_snap_time_rounds_up() -> void:
	assert_eq(TimelineManager.snap_time(1203), 1205, "Should round up 3 min")


func test_snap_time_boundary() -> void:
	assert_eq(TimelineManager.snap_time(1202), 1200, "2 min rounds down")
	assert_eq(TimelineManager.snap_time(1203), 1205, "3 min rounds up (>= half)")


func test_snap_time_clamps_min() -> void:
	assert_eq(TimelineManager.snap_time(-10), 0, "Should clamp to minimum")


func test_snap_time_clamps_max() -> void:
	assert_eq(TimelineManager.snap_time(9999), TimelineManager.MAX_TIME, "Should clamp to maximum")


func test_parse_time_string_valid() -> void:
	assert_eq(TimelineManager.parse_time_string("20:15"), 1215)
	assert_eq(TimelineManager.parse_time_string("00:00"), 0)
	assert_eq(TimelineManager.parse_time_string("06:30"), 390)


func test_parse_time_string_empty() -> void:
	assert_eq(TimelineManager.parse_time_string(""), 0)


func test_parse_time_string_invalid() -> void:
	assert_eq(TimelineManager.parse_time_string("invalid"), 0)


func test_format_time() -> void:
	assert_eq(TimelineManager.format_time(1215), "20:15")
	assert_eq(TimelineManager.format_time(0), "00:00")
	assert_eq(TimelineManager.format_time(390), "06:30")


# =========================================================================
# Entry Placement
# =========================================================================

func test_place_event_returns_entry() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	assert_false(entry.is_empty(), "Should return non-empty entry")
	assert_eq(entry["event_id"], "evt_julia_arrives")
	assert_eq(entry["time_minutes"], 1215)
	assert_eq(entry["day"], 1)
	assert_true(entry["id"].begins_with("tl_"))


func test_place_event_snaps_time() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1217, 1)
	assert_eq(entry["time_minutes"], 1215, "Should snap to nearest 5 min")


func test_place_event_emits_signal() -> void:
	watch_signals(TimelineManager)
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	assert_signal_emitted(TimelineManager, "entry_placed")


func test_place_event_invalid_event_fails() -> void:
	var entry: Dictionary = TimelineManager.place_event("nonexistent", 1215, 1)
	assert_true(entry.is_empty(), "Should return empty for invalid event")
	assert_push_error("[TimelineManager] Event not found: nonexistent")


func test_place_event_increments_count() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.place_event("evt_mark_arrives", 1230, 1)
	assert_eq(TimelineManager.get_entry_count(), 2)


func test_get_entry_returns_data() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	var retrieved: Dictionary = TimelineManager.get_entry(entry["id"])
	assert_eq(retrieved["event_id"], "evt_julia_arrives")


func test_get_entry_nonexistent_returns_empty() -> void:
	var result: Dictionary = TimelineManager.get_entry("nonexistent")
	assert_true(result.is_empty())


func test_get_all_entries() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.place_event("evt_mark_arrives", 1230, 1)
	var entries: Array[Dictionary] = TimelineManager.get_all_entries()
	assert_eq(entries.size(), 2)


func test_get_entries_for_day() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.place_event("evt_day2_meeting", 840, 2)
	var day1: Array[Dictionary] = TimelineManager.get_entries_for_day(1)
	var day2: Array[Dictionary] = TimelineManager.get_entries_for_day(2)
	assert_eq(day1.size(), 1, "Day 1 should have 1 entry")
	assert_eq(day2.size(), 1, "Day 2 should have 1 entry")
	assert_eq(day1[0]["event_id"], "evt_julia_arrives")


# =========================================================================
# Entry Removal
# =========================================================================

func test_remove_entry() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	var removed: bool = TimelineManager.remove_entry(entry["id"])
	assert_true(removed)
	assert_eq(TimelineManager.get_entry_count(), 0)


func test_remove_entry_emits_signal() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	watch_signals(TimelineManager)
	TimelineManager.remove_entry(entry["id"])
	assert_signal_emitted(TimelineManager, "entry_removed")


func test_remove_entry_nonexistent_returns_false() -> void:
	var removed: bool = TimelineManager.remove_entry("nonexistent")
	assert_false(removed)
	assert_push_warning("[TimelineManager]")


func test_remove_entry_clears_attached_evidence() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.attach_evidence(entry["id"], "ev_elevator")
	TimelineManager.remove_entry(entry["id"])
	var attached: Array[String] = TimelineManager.get_attached_evidence(entry["id"])
	assert_eq(attached.size(), 0, "Attached evidence should be cleared on removal")


# =========================================================================
# Entry Movement
# =========================================================================

func test_move_entry() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	var moved: bool = TimelineManager.move_entry(entry["id"], 1230)
	assert_true(moved)
	var updated: Dictionary = TimelineManager.get_entry(entry["id"])
	assert_eq(updated["time_minutes"], 1230)


func test_move_entry_snaps() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.move_entry(entry["id"], 1217)
	var updated: Dictionary = TimelineManager.get_entry(entry["id"])
	assert_eq(updated["time_minutes"], 1215, "Move should snap to nearest 5 min")


func test_move_entry_emits_signal() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	watch_signals(TimelineManager)
	TimelineManager.move_entry(entry["id"], 1230)
	assert_signal_emitted(TimelineManager, "entry_moved")


func test_move_entry_nonexistent_returns_false() -> void:
	var moved: bool = TimelineManager.move_entry("nonexistent", 1230)
	assert_false(moved)
	assert_push_warning("[TimelineManager]")


# =========================================================================
# Hypothesis Management
# =========================================================================

func test_add_hypothesis() -> void:
	var hyp: Dictionary = TimelineManager.add_hypothesis(
		"Mark enters apartment", 1240, 1, "loc_building", ["p_mark"]
	)
	assert_false(hyp.is_empty())
	assert_eq(hyp["description"], "Mark enters apartment")
	assert_eq(hyp["time_minutes"], 1240)
	assert_eq(hyp["day"], 1)
	assert_eq(hyp["location"], "loc_building")
	assert_true(hyp["id"].begins_with("hyp_"))


func test_add_hypothesis_snaps_time() -> void:
	var hyp: Dictionary = TimelineManager.add_hypothesis("Test", 1242, 1)
	assert_eq(hyp["time_minutes"], 1240)


func test_add_hypothesis_emits_signal() -> void:
	watch_signals(TimelineManager)
	TimelineManager.add_hypothesis("Test", 1200, 1)
	assert_signal_emitted(TimelineManager, "hypothesis_added")


func test_add_hypothesis_increments_count() -> void:
	TimelineManager.add_hypothesis("Test 1", 1200, 1)
	TimelineManager.add_hypothesis("Test 2", 1210, 1)
	assert_eq(TimelineManager.get_hypothesis_count(), 2)


func test_get_hypothesis() -> void:
	var hyp: Dictionary = TimelineManager.add_hypothesis("Test", 1200, 1)
	var retrieved: Dictionary = TimelineManager.get_hypothesis(hyp["id"])
	assert_eq(retrieved["description"], "Test")


func test_get_hypothesis_nonexistent() -> void:
	var result: Dictionary = TimelineManager.get_hypothesis("nonexistent")
	assert_true(result.is_empty())


func test_get_all_hypotheses() -> void:
	TimelineManager.add_hypothesis("H1", 1200, 1)
	TimelineManager.add_hypothesis("H2", 1210, 1)
	var all: Array[Dictionary] = TimelineManager.get_all_hypotheses()
	assert_eq(all.size(), 2)


func test_update_hypothesis() -> void:
	var hyp: Dictionary = TimelineManager.add_hypothesis("Old desc", 1200, 1)
	var updated: bool = TimelineManager.update_hypothesis(
		hyp["id"], "New desc", 1230, 1, "loc_office", ["p_julia"]
	)
	assert_true(updated)
	var result: Dictionary = TimelineManager.get_hypothesis(hyp["id"])
	assert_eq(result["description"], "New desc")
	assert_eq(result["time_minutes"], 1230)
	assert_eq(result["location"], "loc_office")


func test_update_hypothesis_emits_signal() -> void:
	var hyp: Dictionary = TimelineManager.add_hypothesis("Test", 1200, 1)
	watch_signals(TimelineManager)
	TimelineManager.update_hypothesis(hyp["id"], "Updated", 1205, 1)
	assert_signal_emitted(TimelineManager, "hypothesis_updated")


func test_update_hypothesis_nonexistent_returns_false() -> void:
	var result: bool = TimelineManager.update_hypothesis("nonexistent", "X", 1200, 1)
	assert_false(result)
	assert_push_warning("[TimelineManager]")


func test_remove_hypothesis() -> void:
	var hyp: Dictionary = TimelineManager.add_hypothesis("Test", 1200, 1)
	var removed: bool = TimelineManager.remove_hypothesis(hyp["id"])
	assert_true(removed)
	assert_eq(TimelineManager.get_hypothesis_count(), 0)


func test_remove_hypothesis_emits_signal() -> void:
	var hyp: Dictionary = TimelineManager.add_hypothesis("Test", 1200, 1)
	watch_signals(TimelineManager)
	TimelineManager.remove_hypothesis(hyp["id"])
	assert_signal_emitted(TimelineManager, "hypothesis_removed")


func test_remove_hypothesis_nonexistent_returns_false() -> void:
	var removed: bool = TimelineManager.remove_hypothesis("nonexistent")
	assert_false(removed)
	assert_push_warning("[TimelineManager]")


# =========================================================================
# Evidence Attachment
# =========================================================================

func test_attach_evidence() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	var attached: bool = TimelineManager.attach_evidence(entry["id"], "ev_elevator")
	assert_true(attached)
	var list: Array[String] = TimelineManager.get_attached_evidence(entry["id"])
	assert_eq(list.size(), 1)
	assert_has(list, "ev_elevator")


func test_attach_evidence_duplicate_returns_false() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.attach_evidence(entry["id"], "ev_elevator")
	var second: bool = TimelineManager.attach_evidence(entry["id"], "ev_elevator")
	assert_false(second, "Should not attach same evidence twice")


func test_attach_evidence_nonexistent_entry_returns_false() -> void:
	var attached: bool = TimelineManager.attach_evidence("nonexistent", "ev_elevator")
	assert_false(attached)
	assert_push_warning("[TimelineManager]")


func test_detach_evidence() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.attach_evidence(entry["id"], "ev_elevator")
	var detached: bool = TimelineManager.detach_evidence(entry["id"], "ev_elevator")
	assert_true(detached)
	assert_eq(TimelineManager.get_attached_evidence(entry["id"]).size(), 0)


func test_detach_evidence_not_attached_returns_false() -> void:
	var entry: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	var detached: bool = TimelineManager.detach_evidence(entry["id"], "ev_elevator")
	assert_false(detached)


func test_get_attached_evidence_nonexistent_entry() -> void:
	var list: Array[String] = TimelineManager.get_attached_evidence("nonexistent")
	assert_eq(list.size(), 0)


# =========================================================================
# Overlap Detection
# =========================================================================

func test_overlap_same_person_different_locations() -> void:
	# Julia arrives at building at 20:15
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	# Add hypothesis: Julia at parking at 20:15
	TimelineManager.add_hypothesis("Julia at parking", 1215, 1, "loc_parking", ["p_julia"])

	var overlaps: Array[Dictionary] = TimelineManager.get_overlaps(1)
	assert_eq(overlaps.size(), 1, "Should detect 1 overlap")
	assert_eq(overlaps[0]["person_id"], "p_julia")
	assert_eq(overlaps[0]["time_minutes"], 1215)


func test_no_overlap_different_persons() -> void:
	# Julia at building 20:15, Mark at parking 20:15 — no overlap
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.place_event("evt_mark_arrives", 1215, 1)  # snap: already correct
	var overlaps: Array[Dictionary] = TimelineManager.get_overlaps(1)
	# These are different persons at different locations, no overlap
	assert_eq(overlaps.size(), 0, "Different persons should not cause overlap")


func test_no_overlap_same_location() -> void:
	# Two events at same location for same person — no overlap (same place)
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	# Add hypothesis: Julia at same building at 20:15
	TimelineManager.add_hypothesis("Julia still at building", 1215, 1, "loc_building", ["p_julia"])
	var overlaps: Array[Dictionary] = TimelineManager.get_overlaps(1)
	assert_eq(overlaps.size(), 0, "Same location should not cause overlap")


func test_no_overlap_different_times() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.add_hypothesis("Julia at parking", 1230, 1, "loc_parking", ["p_julia"])
	var overlaps: Array[Dictionary] = TimelineManager.get_overlaps(1)
	assert_eq(overlaps.size(), 0, "Different times should not cause overlap")


func test_no_overlap_different_days() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.add_hypothesis("Julia at parking", 1215, 2, "loc_parking", ["p_julia"])
	var overlaps_day1: Array[Dictionary] = TimelineManager.get_overlaps(1)
	var overlaps_day2: Array[Dictionary] = TimelineManager.get_overlaps(2)
	assert_eq(overlaps_day1.size(), 0)
	assert_eq(overlaps_day2.size(), 0)


func test_overlap_emits_signal() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	watch_signals(TimelineManager)
	TimelineManager.add_hypothesis("Julia at parking", 1215, 1, "loc_parking", ["p_julia"])
	assert_signal_emitted(TimelineManager, "overlap_detected")


# =========================================================================
# Board State
# =========================================================================

func test_has_content_false_initially() -> void:
	assert_false(TimelineManager.has_content())


func test_has_content_true_with_entry() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	assert_true(TimelineManager.has_content())


func test_has_content_true_with_hypothesis() -> void:
	TimelineManager.add_hypothesis("Test", 1200, 1)
	assert_true(TimelineManager.has_content())


func test_clear_timeline() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.add_hypothesis("Test", 1200, 1)
	TimelineManager.clear_timeline()
	assert_eq(TimelineManager.get_entry_count(), 0)
	assert_eq(TimelineManager.get_hypothesis_count(), 0)
	assert_false(TimelineManager.has_content())


func test_clear_timeline_emits_signal() -> void:
	watch_signals(TimelineManager)
	TimelineManager.clear_timeline()
	assert_signal_emitted(TimelineManager, "timeline_cleared")


# =========================================================================
# Serialization
# =========================================================================

func test_serialize_round_trip() -> void:
	var e1: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	var h1: Dictionary = TimelineManager.add_hypothesis("Test hyp", 1230, 1, "loc_building", ["p_mark"])
	TimelineManager.attach_evidence(e1["id"], "ev_elevator")

	var data: Dictionary = TimelineManager.serialize()
	TimelineManager.reset()
	assert_eq(TimelineManager.get_entry_count(), 0, "Should be empty after reset")

	TimelineManager.deserialize(data)
	assert_eq(TimelineManager.get_entry_count(), 1, "Should restore 1 entry")
	assert_eq(TimelineManager.get_hypothesis_count(), 1, "Should restore 1 hypothesis")

	var restored_entry: Dictionary = TimelineManager.get_entry(e1["id"])
	assert_eq(restored_entry["event_id"], "evt_julia_arrives")
	assert_eq(restored_entry["time_minutes"], 1215)

	var restored_hyp: Dictionary = TimelineManager.get_hypothesis(h1["id"])
	assert_eq(restored_hyp["description"], "Test hyp")

	var attached: Array[String] = TimelineManager.get_attached_evidence(e1["id"])
	assert_has(attached, "ev_elevator")


func test_reset_clears_all() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1215, 1)
	TimelineManager.add_hypothesis("Test", 1200, 1)
	TimelineManager.reset()
	assert_eq(TimelineManager.get_entry_count(), 0)
	assert_eq(TimelineManager.get_hypothesis_count(), 0)
