## test_theory_manager.gd
## Unit tests for the TheoryManager autoload.
## Tests CRUD, step setters, evidence attachment, strength, completeness,
## timeline inconsistency detection, and serialization.
extends GutTest


const TEST_CASE_FILE: String = "test_case_theory.json"

var _test_case_data: Dictionary = {
	"id": "case_theory_test",
	"title": "Theory Test Case",
	"description": "Tests theory builder.",
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
			"name": "Mark Bennett",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 3,
		},
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
			"id": "ev_knife",
			"name": "Kitchen Knife",
			"description": "Found in sink.",
			"type": "PHYSICAL",
			"location_found": "loc_apartment",
			"related_persons": ["p_mark"],
			"weight": 0.8,
			"importance_level": "KEY",
		},
		{
			"id": "ev_prints",
			"name": "Fingerprints",
			"description": "On door handle.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": ["p_julia"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_camera",
			"name": "Camera Footage",
			"description": "Parking lot.",
			"type": "DIGITAL",
			"location_found": "loc_parking",
			"related_persons": ["p_mark"],
			"weight": 0.7,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_phone",
			"name": "Phone records",
			"description": "Call log.",
			"type": "DIGITAL",
			"location_found": "loc_office",
			"related_persons": ["p_julia"],
			"weight": 0.5,
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
			"location": "loc_apartment",
			"involved_persons": ["p_mark"],
			"supporting_evidence": [],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_julia_arrives",
			"description": "Julia arrives at building",
			"time": "21:00",
			"day": 1,
			"location": "loc_apartment",
			"involved_persons": ["p_julia"],
			"supporting_evidence": ["ev_prints"],
			"certainty_level": "CONFIRMED",
		},
	],
	"locations": [
		{"id": "loc_apartment", "name": "Apartment", "searchable": true, "evidence_pool": []},
		{"id": "loc_parking", "name": "Parking Lot", "searchable": true, "evidence_pool": []},
		{"id": "loc_office", "name": "Office", "searchable": true, "evidence_pool": []},
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
# Theory CRUD
# =========================================================================

func test_create_theory_returns_data() -> void:
	var theory: Dictionary = TheoryManager.create_theory("My Theory")
	assert_false(theory.is_empty(), "Should return data")
	assert_eq(theory["name"], "My Theory")
	assert_true(theory["id"].begins_with("theory_"))
	assert_eq(theory["suspect_id"], "")
	assert_eq(theory["motive"], "")
	assert_eq(theory["method"], "")
	assert_eq(theory["time_minutes"], -1)
	assert_eq(theory["time_day"], -1)


func test_create_theory_emits_signal() -> void:
	watch_signals(TheoryManager)
	TheoryManager.create_theory("Test")
	assert_signal_emitted(TheoryManager, "theory_created")


func test_create_theory_increments_count() -> void:
	TheoryManager.create_theory("A")
	TheoryManager.create_theory("B")
	assert_eq(TheoryManager.get_theory_count(), 2)


func test_create_theory_generates_unique_ids() -> void:
	var t1: Dictionary = TheoryManager.create_theory("A")
	var t2: Dictionary = TheoryManager.create_theory("B")
	assert_ne(t1["id"], t2["id"], "IDs should be unique")


func test_get_theory_returns_data() -> void:
	var created: Dictionary = TheoryManager.create_theory("Test")
	var retrieved: Dictionary = TheoryManager.get_theory(created["id"])
	assert_eq(retrieved["name"], "Test")


func test_get_theory_nonexistent_returns_empty() -> void:
	var result: Dictionary = TheoryManager.get_theory("nonexistent")
	assert_true(result.is_empty())


func test_get_all_theories() -> void:
	TheoryManager.create_theory("A")
	TheoryManager.create_theory("B")
	var all: Array[Dictionary] = TheoryManager.get_all_theories()
	assert_eq(all.size(), 2)


func test_remove_theory() -> void:
	var theory: Dictionary = TheoryManager.create_theory("Test")
	var removed: bool = TheoryManager.remove_theory(theory["id"])
	assert_true(removed)
	assert_eq(TheoryManager.get_theory_count(), 0)


func test_remove_theory_emits_signal() -> void:
	var theory: Dictionary = TheoryManager.create_theory("Test")
	watch_signals(TheoryManager)
	TheoryManager.remove_theory(theory["id"])
	assert_signal_emitted(TheoryManager, "theory_removed")


func test_remove_theory_nonexistent_returns_false() -> void:
	var result: bool = TheoryManager.remove_theory("nonexistent")
	assert_false(result)
	assert_push_warning("[TheoryManager]")


# =========================================================================
# Step Setters
# =========================================================================

func test_set_suspect() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	var ok: bool = TheoryManager.set_suspect(t["id"], "p_mark")
	assert_true(ok)
	var theory: Dictionary = TheoryManager.get_theory(t["id"])
	assert_eq(theory["suspect_id"], "p_mark")


func test_set_suspect_emits_updated() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	watch_signals(TheoryManager)
	TheoryManager.set_suspect(t["id"], "p_mark")
	assert_signal_emitted(TheoryManager, "theory_updated")


func test_set_suspect_nonexistent_returns_false() -> void:
	var ok: bool = TheoryManager.set_suspect("nonexistent", "p_mark")
	assert_false(ok)
	assert_push_warning("[TheoryManager]")


func test_set_motive() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_motive(t["id"], "Financial dispute")
	var theory: Dictionary = TheoryManager.get_theory(t["id"])
	assert_eq(theory["motive"], "Financial dispute")


func test_set_motive_nonexistent_returns_false() -> void:
	var ok: bool = TheoryManager.set_motive("nonexistent", "motive")
	assert_false(ok)
	assert_push_warning("[TheoryManager]")


func test_set_time() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_time(t["id"], 1260, 1)
	var theory: Dictionary = TheoryManager.get_theory(t["id"])
	assert_eq(theory["time_minutes"], 1260)
	assert_eq(theory["time_day"], 1)


func test_set_time_nonexistent_returns_false() -> void:
	var ok: bool = TheoryManager.set_time("nonexistent", 1260, 1)
	assert_false(ok)
	assert_push_warning("[TheoryManager]")


func test_set_method() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_method(t["id"], "Kitchen knife")
	var theory: Dictionary = TheoryManager.get_theory(t["id"])
	assert_eq(theory["method"], "Kitchen knife")


func test_set_method_nonexistent_returns_false() -> void:
	var ok: bool = TheoryManager.set_method("nonexistent", "method")
	assert_false(ok)
	assert_push_warning("[TheoryManager]")


func test_set_timeline_links() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	var ids: Array[String] = ["tl_1", "tl_2"]
	TheoryManager.set_timeline_links(t["id"], ids)
	var theory: Dictionary = TheoryManager.get_theory(t["id"])
	assert_eq(theory["timeline_entry_ids"].size(), 2)


func test_set_timeline_links_nonexistent_returns_false() -> void:
	var ids: Array[String] = ["tl_1"]
	var ok: bool = TheoryManager.set_timeline_links("nonexistent", ids)
	assert_false(ok)
	assert_push_warning("[TheoryManager]")


# =========================================================================
# Evidence Attachment
# =========================================================================

func test_attach_evidence() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	var ok: bool = TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")
	assert_true(ok)
	var ev: Array[String] = TheoryManager.get_step_evidence(t["id"], "suspect")
	assert_eq(ev.size(), 1)
	assert_has(ev, "ev_knife")


func test_attach_evidence_emits_updated() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	watch_signals(TheoryManager)
	TheoryManager.attach_evidence(t["id"], "motive", "ev_prints")
	assert_signal_emitted(TheoryManager, "theory_updated")


func test_attach_evidence_duplicate_returns_false() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")
	var ok: bool = TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")
	assert_false(ok, "Should not attach duplicate")


func test_attach_evidence_max_three_per_step() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_prints")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_camera")
	var ok: bool = TheoryManager.attach_evidence(t["id"], "suspect", "ev_phone")
	assert_false(ok, "Should reject 4th evidence")
	assert_eq(TheoryManager.get_step_evidence(t["id"], "suspect").size(), 3)
	assert_push_warning("[TheoryManager]")


func test_attach_evidence_invalid_step_returns_false() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	var ok: bool = TheoryManager.attach_evidence(t["id"], "invalid_step", "ev_knife")
	assert_false(ok)
	assert_push_error("[TheoryManager] Invalid step: invalid_step")


func test_attach_evidence_nonexistent_theory_returns_false() -> void:
	var ok: bool = TheoryManager.attach_evidence("nonexistent", "suspect", "ev_knife")
	assert_false(ok)
	assert_push_warning("[TheoryManager]")


func test_detach_evidence() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")
	var ok: bool = TheoryManager.detach_evidence(t["id"], "suspect", "ev_knife")
	assert_true(ok)
	assert_eq(TheoryManager.get_step_evidence(t["id"], "suspect").size(), 0)


func test_detach_evidence_not_attached_returns_false() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	var ok: bool = TheoryManager.detach_evidence(t["id"], "suspect", "ev_knife")
	assert_false(ok)


func test_detach_evidence_invalid_step_returns_false() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	var ok: bool = TheoryManager.detach_evidence(t["id"], "invalid", "ev_knife")
	assert_false(ok)
	assert_push_error("[TheoryManager] Invalid step: invalid")


func test_get_step_evidence_nonexistent_theory() -> void:
	var ev: Array[String] = TheoryManager.get_step_evidence("nonexistent", "suspect")
	assert_eq(ev.size(), 0)


func test_get_step_evidence_invalid_step() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	var ev: Array[String] = TheoryManager.get_step_evidence(t["id"], "invalid")
	assert_eq(ev.size(), 0)


func test_evidence_per_step_independence() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")
	TheoryManager.attach_evidence(t["id"], "motive", "ev_prints")
	assert_eq(TheoryManager.get_step_evidence(t["id"], "suspect").size(), 1)
	assert_eq(TheoryManager.get_step_evidence(t["id"], "motive").size(), 1)


# =========================================================================
# Strength Calculation
# =========================================================================

func test_strength_none_with_no_evidence() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	var strength: Enums.TheoryStrength = TheoryManager.get_step_strength(t["id"], "suspect")
	assert_eq(strength, Enums.TheoryStrength.NONE)


func test_strength_weak_with_one_evidence() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")
	var strength: Enums.TheoryStrength = TheoryManager.get_step_strength(t["id"], "suspect")
	assert_eq(strength, Enums.TheoryStrength.WEAK)


func test_strength_moderate_with_two_evidence() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_prints")
	var strength: Enums.TheoryStrength = TheoryManager.get_step_strength(t["id"], "suspect")
	assert_eq(strength, Enums.TheoryStrength.MODERATE)


func test_strength_strong_with_three_evidence() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_prints")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_camera")
	var strength: Enums.TheoryStrength = TheoryManager.get_step_strength(t["id"], "suspect")
	assert_eq(strength, Enums.TheoryStrength.STRONG)


func test_strength_timeline_uses_entry_count() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	var ids: Array[String] = ["tl_1"]
	TheoryManager.set_timeline_links(t["id"], ids)
	var strength: Enums.TheoryStrength = TheoryManager.get_step_strength(t["id"], "timeline")
	assert_eq(strength, Enums.TheoryStrength.WEAK)


func test_strength_timeline_strong_with_three_links() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	var ids: Array[String] = ["tl_1", "tl_2", "tl_3"]
	TheoryManager.set_timeline_links(t["id"], ids)
	var strength: Enums.TheoryStrength = TheoryManager.get_step_strength(t["id"], "timeline")
	assert_eq(strength, Enums.TheoryStrength.STRONG)


# =========================================================================
# Completeness
# =========================================================================

func test_incomplete_by_default() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	assert_false(TheoryManager.is_complete(t["id"]))


func test_complete_when_all_steps_filled() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_suspect(t["id"], "p_mark")
	TheoryManager.set_motive(t["id"], "Money")
	TheoryManager.set_time(t["id"], 1260, 1)
	TheoryManager.set_method(t["id"], "Knife")
	var ids: Array[String] = ["tl_1"]
	TheoryManager.set_timeline_links(t["id"], ids)
	assert_true(TheoryManager.is_complete(t["id"]))


func test_incomplete_without_suspect() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_motive(t["id"], "Money")
	TheoryManager.set_time(t["id"], 1260, 1)
	TheoryManager.set_method(t["id"], "Knife")
	var ids: Array[String] = ["tl_1"]
	TheoryManager.set_timeline_links(t["id"], ids)
	assert_false(TheoryManager.is_complete(t["id"]))


func test_incomplete_without_motive() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_suspect(t["id"], "p_mark")
	TheoryManager.set_time(t["id"], 1260, 1)
	TheoryManager.set_method(t["id"], "Knife")
	var ids: Array[String] = ["tl_1"]
	TheoryManager.set_timeline_links(t["id"], ids)
	assert_false(TheoryManager.is_complete(t["id"]))


func test_incomplete_without_time() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_suspect(t["id"], "p_mark")
	TheoryManager.set_motive(t["id"], "Money")
	TheoryManager.set_method(t["id"], "Knife")
	var ids: Array[String] = ["tl_1"]
	TheoryManager.set_timeline_links(t["id"], ids)
	assert_false(TheoryManager.is_complete(t["id"]))


func test_incomplete_without_method() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_suspect(t["id"], "p_mark")
	TheoryManager.set_motive(t["id"], "Money")
	TheoryManager.set_time(t["id"], 1260, 1)
	var ids: Array[String] = ["tl_1"]
	TheoryManager.set_timeline_links(t["id"], ids)
	assert_false(TheoryManager.is_complete(t["id"]))


func test_incomplete_without_timeline() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_suspect(t["id"], "p_mark")
	TheoryManager.set_motive(t["id"], "Money")
	TheoryManager.set_time(t["id"], 1260, 1)
	TheoryManager.set_method(t["id"], "Knife")
	assert_false(TheoryManager.is_complete(t["id"]))


func test_is_complete_nonexistent_returns_false() -> void:
	assert_false(TheoryManager.is_complete("nonexistent"))


# =========================================================================
# Timeline Inconsistency Detection
# =========================================================================

func test_no_inconsistencies_when_no_data() -> void:
	var t: Dictionary = TheoryManager.create_theory("T")
	var result: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	assert_eq(result.size(), 0)


func test_inconsistency_when_suspect_in_timeline_entry_at_same_time() -> void:
	# Place Julia at building at 21:00
	TimelineManager.place_event("evt_julia_arrives", 1260, 1)

	# Theory says Julia killed victim at 21:00 day 1
	var t: Dictionary = TheoryManager.create_theory("Julia Theory")
	TheoryManager.set_suspect(t["id"], "p_julia")
	TheoryManager.set_time(t["id"], 1260, 1)

	var inconsistencies: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	assert_eq(inconsistencies.size(), 1, "Should detect Julia conflict at 21:00")
	assert_eq(inconsistencies[0]["type"], "timeline_conflict")


func test_inconsistency_emits_signal() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1260, 1)
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_suspect(t["id"], "p_julia")
	TheoryManager.set_time(t["id"], 1260, 1)
	watch_signals(TheoryManager)
	TheoryManager.get_inconsistencies(t["id"])
	assert_signal_emitted(TheoryManager, "inconsistency_detected")


func test_no_inconsistency_different_time() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1260, 1)
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_suspect(t["id"], "p_julia")
	TheoryManager.set_time(t["id"], 1200, 1)  # 20:00 — different time
	var result: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	assert_eq(result.size(), 0)


func test_no_inconsistency_different_person() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1260, 1)
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_suspect(t["id"], "p_mark")  # Mark, not Julia
	TheoryManager.set_time(t["id"], 1260, 1)
	var result: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	assert_eq(result.size(), 0)


func test_no_inconsistency_different_day() -> void:
	TimelineManager.place_event("evt_julia_arrives", 1260, 1)
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_suspect(t["id"], "p_julia")
	TheoryManager.set_time(t["id"], 1260, 2)  # Day 2
	var result: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	assert_eq(result.size(), 0)


func test_inconsistency_with_hypothesis() -> void:
	TimelineManager.add_hypothesis("Julia at parking", 1260, 1, "loc_parking", ["p_julia"])
	var t: Dictionary = TheoryManager.create_theory("T")
	TheoryManager.set_suspect(t["id"], "p_julia")
	TheoryManager.set_time(t["id"], 1260, 1)
	var result: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	assert_eq(result.size(), 1, "Should detect hypothesis conflict")


func test_inconsistencies_nonexistent_theory() -> void:
	var result: Array[Dictionary] = TheoryManager.get_inconsistencies("nonexistent")
	assert_eq(result.size(), 0)


# =========================================================================
# Housekeeping
# =========================================================================

func test_has_content_false_initially() -> void:
	assert_false(TheoryManager.has_content())


func test_has_content_true_after_create() -> void:
	TheoryManager.create_theory("Test")
	assert_true(TheoryManager.has_content())


func test_clear_theories() -> void:
	TheoryManager.create_theory("A")
	TheoryManager.create_theory("B")
	TheoryManager.clear_theories()
	assert_eq(TheoryManager.get_theory_count(), 0)
	assert_false(TheoryManager.has_content())


func test_clear_theories_emits_signal() -> void:
	watch_signals(TheoryManager)
	TheoryManager.clear_theories()
	assert_signal_emitted(TheoryManager, "theories_cleared")


# =========================================================================
# Serialization
# =========================================================================

func test_serialize_round_trip() -> void:
	var t: Dictionary = TheoryManager.create_theory("My Theory")
	TheoryManager.set_suspect(t["id"], "p_mark")
	TheoryManager.set_motive(t["id"], "Financial dispute")
	TheoryManager.set_time(t["id"], 1260, 1)
	TheoryManager.set_method(t["id"], "Kitchen knife")
	var links: Array[String] = ["tl_1"]
	TheoryManager.set_timeline_links(t["id"], links)
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_knife")
	TheoryManager.attach_evidence(t["id"], "motive", "ev_prints")

	var data: Dictionary = TheoryManager.serialize()
	TheoryManager.reset()
	assert_eq(TheoryManager.get_theory_count(), 0, "Empty after reset")

	TheoryManager.deserialize(data)
	assert_eq(TheoryManager.get_theory_count(), 1, "Restored 1 theory")

	var restored: Dictionary = TheoryManager.get_theory(t["id"])
	assert_eq(restored["name"], "My Theory")
	assert_eq(restored["suspect_id"], "p_mark")
	assert_eq(restored["motive"], "Financial dispute")
	assert_eq(restored["time_minutes"], 1260)
	assert_eq(restored["time_day"], 1)
	assert_eq(restored["method"], "Kitchen knife")
	assert_eq(restored["timeline_entry_ids"].size(), 1)

	var suspect_ev: Array[String] = TheoryManager.get_step_evidence(t["id"], "suspect")
	assert_has(suspect_ev, "ev_knife")
	var motive_ev: Array[String] = TheoryManager.get_step_evidence(t["id"], "motive")
	assert_has(motive_ev, "ev_prints")


func test_serialize_multiple_theories() -> void:
	TheoryManager.create_theory("Theory A")
	TheoryManager.create_theory("Theory B")

	var data: Dictionary = TheoryManager.serialize()
	TheoryManager.reset()
	TheoryManager.deserialize(data)

	assert_eq(TheoryManager.get_theory_count(), 2, "Both theories restored")


func test_reset_clears_all() -> void:
	TheoryManager.create_theory("Test")
	TheoryManager.reset()
	assert_eq(TheoryManager.get_theory_count(), 0)
	assert_false(TheoryManager.has_content())


# =========================================================================
# Constants
# =========================================================================

func test_step_names_has_five_entries() -> void:
	assert_eq(TheoryManager.STEP_NAMES.size(), 5)
	assert_has(TheoryManager.STEP_NAMES, "suspect")
	assert_has(TheoryManager.STEP_NAMES, "motive")
	assert_has(TheoryManager.STEP_NAMES, "time")
	assert_has(TheoryManager.STEP_NAMES, "method")
	assert_has(TheoryManager.STEP_NAMES, "timeline")


func test_max_evidence_per_step_is_three() -> void:
	assert_eq(TheoryManager.MAX_EVIDENCE_PER_STEP, 3)
