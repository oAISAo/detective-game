## test_timeline_scenarios.gd
## Scenario tests for realistic timeline reconstruction workflows.
extends GutTest


const TEST_CASE_FILE: String = "test_case_tl_scenario.json"

var _test_case_data: Dictionary = {
	"id": "case_tl_scenario",
	"title": "Scenario Timeline",
	"description": "Scenario tests.",
	"start_day": 1,
	"end_day": 3,
	"persons": [
		{
			"id": "p_alice",
			"name": "Alice",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 5,
		},
		{
			"id": "p_bob",
			"name": "Bob",
			"role": "WITNESS",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 5,
		},
		{
			"id": "p_carol",
			"name": "Carol",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 5,
		},
	],
	"evidence": [
		{
			"id": "ev_receipt",
			"name": "Restaurant receipts",
			"description": "Two receipts.",
			"type": "PHYSICAL",
			"location_found": "loc_restaurant",
			"related_persons": ["p_alice"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_cctv",
			"name": "CCTV footage",
			"description": "Camera footage.",
			"type": "DIGITAL",
			"location_found": "loc_office",
			"related_persons": ["p_bob"],
			"weight": 0.9,
			"importance_level": "KEY",
		},
		{
			"id": "ev_note",
			"name": "Handwritten note",
			"description": "A note found in desk.",
			"type": "PHYSICAL",
			"location_found": "loc_office",
			"related_persons": ["p_carol"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
	],
	"statements": [],
	"events": [
		{
			"id": "evt_alice_meeting",
			"description": "Alice at meeting",
			"time": "10:00",
			"day": 1,
			"location": "loc_office",
			"involved_persons": ["p_alice", "p_bob"],
			"supporting_evidence": ["ev_cctv"],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_alice_lunch",
			"description": "Alice at lunch",
			"time": "12:30",
			"day": 1,
			"location": "loc_restaurant",
			"involved_persons": ["p_alice"],
			"supporting_evidence": ["ev_receipt"],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_bob_office",
			"description": "Bob stays at office",
			"time": "12:30",
			"day": 1,
			"location": "loc_office",
			"involved_persons": ["p_bob"],
			"supporting_evidence": ["ev_cctv"],
			"certainty_level": "LIKELY",
		},
		{
			"id": "evt_carol_park",
			"description": "Carol spotted at park",
			"time": "14:00",
			"day": 1,
			"location": "loc_park",
			"involved_persons": ["p_carol"],
			"supporting_evidence": [],
			"certainty_level": "CLAIMED",
		},
		{
			"id": "evt_alice_day2_morning",
			"description": "Alice at office day 2",
			"time": "09:00",
			"day": 2,
			"location": "loc_office",
			"involved_persons": ["p_alice"],
			"supporting_evidence": [],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_bob_day2_park",
			"description": "Bob at park day 2",
			"time": "15:00",
			"day": 2,
			"location": "loc_park",
			"involved_persons": ["p_bob"],
			"supporting_evidence": [],
			"certainty_level": "UNKNOWN",
		},
	],
	"locations": [
		{"id": "loc_office", "name": "Office", "searchable": true, "evidence_pool": ["ev_cctv", "ev_note"]},
		{"id": "loc_restaurant", "name": "Restaurant", "searchable": true, "evidence_pool": ["ev_receipt"]},
		{"id": "loc_park", "name": "Park", "searchable": true, "evidence_pool": []},
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
# Scenario 1: Reconstruct a full day with multiple persons
# =========================================================================

func test_scenario_reconstruct_day1_full() -> void:
	# Place all day-1 events
	var e_meeting: Dictionary = TimelineManager.place_event("evt_alice_meeting", 600, 1)
	var e_lunch: Dictionary = TimelineManager.place_event("evt_alice_lunch", 750, 1)
	var e_bob: Dictionary = TimelineManager.place_event("evt_bob_office", 750, 1)
	var e_carol: Dictionary = TimelineManager.place_event("evt_carol_park", 840, 1)

	assert_eq(TimelineManager.get_entry_count(), 4, "4 entries placed")

	# Day-1 filter
	var day1: Array[Dictionary] = TimelineManager.get_entries_for_day(1)
	assert_eq(day1.size(), 4, "All 4 are day 1")

	# Attach evidence where applicable
	TimelineManager.attach_evidence(e_meeting["id"], "ev_cctv")
	TimelineManager.attach_evidence(e_lunch["id"], "ev_receipt")
	TimelineManager.attach_evidence(e_bob["id"], "ev_cctv")

	# Verify evidence attached
	var meeting_ev: Array[String] = TimelineManager.get_attached_evidence(e_meeting["id"])
	assert_has(meeting_ev, "ev_cctv")

	# No overlaps — different persons at different locations
	var overlaps: Array[Dictionary] = TimelineManager.get_overlaps(1)
	assert_eq(overlaps.size(), 0, "No overlaps — distinct persons at distinct locations")


func test_scenario_add_hypothesis_reveals_overlap() -> void:
	# Place confirmed event: Alice at office meeting at 10:00
	TimelineManager.place_event("evt_alice_meeting", 600, 1)

	# Player hypothesizes Alice was also at restaurant at 10:00
	TimelineManager.add_hypothesis(
		"Alice was at restaurant at 10:00",
		600, 1, "loc_restaurant", ["p_alice"]
	)

	assert_eq(TimelineManager.get_hypothesis_count(), 1)

	# This should create an overlap — Alice in 2 places at 10:00
	var overlaps: Array[Dictionary] = TimelineManager.get_overlaps(1)
	assert_eq(overlaps.size(), 1, "Should detect overlap for Alice")
	assert_eq(overlaps[0]["person_id"], "p_alice")
	assert_eq(overlaps[0]["time_minutes"], 600)

	# Remove hypothesis — overlap should disappear
	var hyp_id: String = TimelineManager.get_all_hypotheses()[0]["id"]
	TimelineManager.remove_hypothesis(hyp_id)

	var overlaps_after: Array[Dictionary] = TimelineManager.get_overlaps(1)
	assert_eq(overlaps_after.size(), 0, "Overlap gone after removing hypothesis")


# =========================================================================
# Scenario 2: Multi-day reconstruction with full persistence
# =========================================================================

func test_scenario_multi_day_with_persistence() -> void:
	# Day 1: place events and hypothesis
	TimelineManager.place_event("evt_alice_meeting", 600, 1)
	TimelineManager.place_event("evt_alice_lunch", 750, 1)
	TimelineManager.add_hypothesis("Carol seen near office", 600, 1, "loc_office", ["p_carol"])

	# Day 2: place events
	var e_day2: Dictionary = TimelineManager.place_event("evt_alice_day2_morning", 540, 2)
	TimelineManager.place_event("evt_bob_day2_park", 900, 2)
	TimelineManager.attach_evidence(e_day2["id"], "ev_note")

	# Verify counts
	assert_eq(TimelineManager.get_entry_count(), 4, "4 entries total")
	assert_eq(TimelineManager.get_hypothesis_count(), 1, "1 hypothesis")
	assert_eq(TimelineManager.get_entries_for_day(1).size(), 2, "2 entries on day 1")
	assert_eq(TimelineManager.get_entries_for_day(2).size(), 2, "2 entries on day 2")

	# Save and restore
	var save_data: Dictionary = TimelineManager.serialize()
	TimelineManager.reset()
	assert_eq(TimelineManager.get_entry_count(), 0, "Empty after reset")

	TimelineManager.deserialize(save_data)
	assert_eq(TimelineManager.get_entry_count(), 4, "4 entries restored")
	assert_eq(TimelineManager.get_hypothesis_count(), 1, "1 hypothesis restored")
	assert_eq(TimelineManager.get_entries_for_day(1).size(), 2, "Day 1 entries restored")
	assert_eq(TimelineManager.get_entries_for_day(2).size(), 2, "Day 2 entries restored")

	var attached: Array[String] = TimelineManager.get_attached_evidence(e_day2["id"])
	assert_has(attached, "ev_note", "Evidence attachment restored")


# =========================================================================
# Scenario 3: Overlap detection across entries and hypotheses
# =========================================================================

func test_scenario_complex_overlap_detection() -> void:
	# Place Bob at office at 12:30
	TimelineManager.place_event("evt_bob_office", 750, 1)

	# Hypothesize Bob at park at 12:30 — should conflict
	TimelineManager.add_hypothesis("Bob at park", 750, 1, "loc_park", ["p_bob"])

	var overlaps: Array[Dictionary] = TimelineManager.get_overlaps(1)
	assert_eq(overlaps.size(), 1, "Bob overlap detected")
	assert_eq(overlaps[0]["person_id"], "p_bob")

	# Place Alice at restaurant at 12:30 — no overlap (different person)
	TimelineManager.place_event("evt_alice_lunch", 750, 1)
	overlaps = TimelineManager.get_overlaps(1)
	assert_eq(overlaps.size(), 1, "Still only Bob overlaps")

	# Add hypothesis putting Alice at office at 12:30
	TimelineManager.add_hypothesis("Alice at office", 750, 1, "loc_office", ["p_alice"])

	overlaps = TimelineManager.get_overlaps(1)
	assert_eq(overlaps.size(), 2, "Both Alice and Bob now overlap")


# =========================================================================
# Scenario 4: Move event resolves overlap
# =========================================================================

func test_scenario_move_event_resolves_overlap() -> void:
	# Alice at meeting (10:00) and hypothesis of Alice at restaurant (10:00)
	var e1: Dictionary = TimelineManager.place_event("evt_alice_meeting", 600, 1)
	TimelineManager.add_hypothesis("Alice at restaurant", 600, 1, "loc_restaurant", ["p_alice"])

	var overlaps: Array[Dictionary] = TimelineManager.get_overlaps(1)
	assert_eq(overlaps.size(), 1, "Overlap at 10:00")

	# Move the event to 11:00 — overlap should resolve
	TimelineManager.move_entry(e1["id"], 660)

	overlaps = TimelineManager.get_overlaps(1)
	assert_eq(overlaps.size(), 0, "No overlap after moving meeting to 11:00")


# =========================================================================
# Scenario 5: Clear timeline resets everything
# =========================================================================

func test_scenario_clear_and_rebuild() -> void:
	TimelineManager.place_event("evt_alice_meeting", 600, 1)
	TimelineManager.add_hypothesis("Test", 700, 1)
	assert_true(TimelineManager.has_content())

	TimelineManager.clear_timeline()
	assert_false(TimelineManager.has_content(), "No content after clear")
	assert_eq(TimelineManager.get_entry_count(), 0)
	assert_eq(TimelineManager.get_hypothesis_count(), 0)

	# Rebuild — IDs should continue incrementing (no collisions)
	var e: Dictionary = TimelineManager.place_event("evt_alice_meeting", 600, 1)
	assert_false(e.is_empty(), "Can rebuild after clear")
	assert_true(TimelineManager.has_content())
