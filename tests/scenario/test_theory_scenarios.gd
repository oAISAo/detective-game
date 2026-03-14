## test_theory_scenarios.gd
## Scenario tests for realistic theory builder workflows.
## Tests competing theories, evidence comparison, progressive building,
## and timeline integration in realistic investigation contexts.
extends GutTest


const TEST_CASE_FILE: String = "test_case_theory_scenario.json"

var _test_case_data: Dictionary = {
	"id": "case_theory_scenario",
	"title": "Theory Scenarios",
	"description": "Scenario tests.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{
			"id": "p_victim",
			"name": "Daniel Ross",
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
		{
			"id": "p_sarah",
			"name": "Sarah Klein",
			"role": "WITNESS",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 4,
		},
	],
	"evidence": [
		{
			"id": "ev_knife",
			"name": "Kitchen Knife",
			"description": "Murder weapon in sink.",
			"type": "PHYSICAL",
			"location_found": "loc_apt",
			"related_persons": [],
			"weight": 0.9,
			"importance_level": "KEY",
		},
		{
			"id": "ev_prints_mark",
			"name": "Mark's Fingerprints",
			"description": "On apartment door.",
			"type": "FORENSIC",
			"location_found": "loc_apt",
			"related_persons": ["p_mark"],
			"weight": 0.7,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_prints_julia",
			"name": "Julia's Fingerprints",
			"description": "On kitchen cabinet.",
			"type": "FORENSIC",
			"location_found": "loc_apt",
			"related_persons": ["p_julia"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_camera",
			"name": "CCTV Footage",
			"description": "Mark leaving at 20:40.",
			"type": "DIGITAL",
			"location_found": "loc_parking",
			"related_persons": ["p_mark"],
			"weight": 0.8,
			"importance_level": "KEY",
		},
		{
			"id": "ev_phone",
			"name": "Phone Records",
			"description": "Call between Julia and victim.",
			"type": "DIGITAL",
			"location_found": "loc_office",
			"related_persons": ["p_julia"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_noise",
			"name": "Noise Report",
			"description": "Sarah heard argument at 20:15.",
			"type": "TESTIMONIAL",
			"location_found": "loc_neighbor",
			"related_persons": ["p_sarah"],
			"weight": 0.4,
			"importance_level": "SUPPORTING",
		},
	],
	"statements": [],
	"events": [
		{
			"id": "evt_mark_visits",
			"description": "Mark visits Daniel",
			"time": "19:30",
			"day": 1,
			"location": "loc_apt",
			"involved_persons": ["p_mark"],
			"supporting_evidence": ["ev_prints_mark"],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_argument",
			"description": "Argument heard",
			"time": "20:15",
			"day": 1,
			"location": "loc_apt",
			"involved_persons": ["p_mark", "p_victim"],
			"supporting_evidence": ["ev_noise"],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_mark_leaves",
			"description": "Mark leaves building",
			"time": "20:40",
			"day": 1,
			"location": "loc_parking",
			"involved_persons": ["p_mark"],
			"supporting_evidence": ["ev_camera"],
			"certainty_level": "CONFIRMED",
		},
		{
			"id": "evt_julia_arrives",
			"description": "Julia arrives at building",
			"time": "20:50",
			"day": 1,
			"location": "loc_apt",
			"involved_persons": ["p_julia"],
			"supporting_evidence": [],
			"certainty_level": "CLAIMED",
		},
		{
			"id": "evt_death",
			"description": "Estimated time of death",
			"time": "21:00",
			"day": 1,
			"location": "loc_apt",
			"involved_persons": ["p_victim"],
			"supporting_evidence": [],
			"certainty_level": "LIKELY",
		},
	],
	"locations": [
		{"id": "loc_apt", "name": "Victim Apartment", "searchable": true, "evidence_pool": ["ev_knife", "ev_prints_mark", "ev_prints_julia"]},
		{"id": "loc_parking", "name": "Parking Lot", "searchable": true, "evidence_pool": ["ev_camera"]},
		{"id": "loc_office", "name": "Office", "searchable": true, "evidence_pool": ["ev_phone"]},
		{"id": "loc_neighbor", "name": "Neighbor Apt", "searchable": true, "evidence_pool": ["ev_noise"]},
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
# Scenario 1: Two competing theories with evidence comparison
# =========================================================================

func test_scenario_competing_theories() -> void:
	# Theory 1: Mark killed Daniel over money
	var t_mark: Dictionary = TheoryManager.create_theory("Mark did it")
	TheoryManager.set_suspect(t_mark["id"], "p_mark")
	TheoryManager.set_motive(t_mark["id"], "Financial dispute from business partnership")
	TheoryManager.set_time(t_mark["id"], 1215, 1)  # 20:15
	TheoryManager.set_method(t_mark["id"], "Kitchen knife during argument")

	# Attach evidence to Mark's theory
	TheoryManager.attach_evidence(t_mark["id"], "suspect", "ev_prints_mark")
	TheoryManager.attach_evidence(t_mark["id"], "suspect", "ev_camera")
	TheoryManager.attach_evidence(t_mark["id"], "motive", "ev_noise")
	TheoryManager.attach_evidence(t_mark["id"], "method", "ev_knife")

	# Theory 2: Julia killed Daniel over relationship
	var t_julia: Dictionary = TheoryManager.create_theory("Julia did it")
	TheoryManager.set_suspect(t_julia["id"], "p_julia")
	TheoryManager.set_motive(t_julia["id"], "Marriage problems, relationship conflict")
	TheoryManager.set_time(t_julia["id"], 1260, 1)  # 21:00
	TheoryManager.set_method(t_julia["id"], "Kitchen knife")

	# Attach evidence to Julia's theory
	TheoryManager.attach_evidence(t_julia["id"], "suspect", "ev_prints_julia")
	TheoryManager.attach_evidence(t_julia["id"], "suspect", "ev_phone")
	TheoryManager.attach_evidence(t_julia["id"], "method", "ev_knife")

	# Compare theories
	assert_eq(TheoryManager.get_theory_count(), 2)

	# Mark's suspect evidence is MODERATE (2), Julia's is also MODERATE (2)
	assert_eq(
		TheoryManager.get_step_strength(t_mark["id"], "suspect"),
		Enums.TheoryStrength.MODERATE
	)
	assert_eq(
		TheoryManager.get_step_strength(t_julia["id"], "suspect"),
		Enums.TheoryStrength.MODERATE
	)

	# Mark has motive evidence (WEAK), Julia has none (NONE)
	assert_eq(
		TheoryManager.get_step_strength(t_mark["id"], "motive"),
		Enums.TheoryStrength.WEAK
	)
	assert_eq(
		TheoryManager.get_step_strength(t_julia["id"], "motive"),
		Enums.TheoryStrength.NONE
	)

	# Both incomplete — no timeline links yet
	assert_false(TheoryManager.is_complete(t_mark["id"]))
	assert_false(TheoryManager.is_complete(t_julia["id"]))


# =========================================================================
# Scenario 2: Progressive theory building
# =========================================================================

func test_scenario_progressive_building() -> void:
	# Player starts with a vague theory
	var t: Dictionary = TheoryManager.create_theory("Initial theory")
	assert_false(TheoryManager.is_complete(t["id"]))

	# Step 1: Select suspect
	TheoryManager.set_suspect(t["id"], "p_julia")
	assert_eq(TheoryManager.get_theory(t["id"])["suspect_id"], "p_julia")
	assert_false(TheoryManager.is_complete(t["id"]))

	# Step 2: Add motive
	TheoryManager.set_motive(t["id"], "Marriage problems")
	assert_false(TheoryManager.is_complete(t["id"]))

	# Step 3: Set time
	TheoryManager.set_time(t["id"], 1260, 1)
	assert_false(TheoryManager.is_complete(t["id"]))

	# Step 4: Set method
	TheoryManager.set_method(t["id"], "Kitchen knife")
	assert_false(TheoryManager.is_complete(t["id"]))

	# Step 5: Link timeline — now complete
	var links: Array[String] = ["tl_1"]
	TheoryManager.set_timeline_links(t["id"], links)
	assert_true(TheoryManager.is_complete(t["id"]))

	# Build up evidence strength over time
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_prints_julia")
	assert_eq(TheoryManager.get_step_strength(t["id"], "suspect"), Enums.TheoryStrength.WEAK)

	TheoryManager.attach_evidence(t["id"], "suspect", "ev_phone")
	assert_eq(TheoryManager.get_step_strength(t["id"], "suspect"), Enums.TheoryStrength.MODERATE)


# =========================================================================
# Scenario 3: Theory with full timeline integration
# =========================================================================

func test_scenario_timeline_integrated_theory() -> void:
	# Place events on timeline
	var e1: Dictionary = TimelineManager.place_event("evt_mark_visits", 1170, 1)
	var e2: Dictionary = TimelineManager.place_event("evt_argument", 1215, 1)
	var e3: Dictionary = TimelineManager.place_event("evt_mark_leaves", 1240, 1)
	var e4: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1250, 1)
	var e5: Dictionary = TimelineManager.place_event("evt_death", 1260, 1)

	assert_eq(TimelineManager.get_entry_count(), 5)

	# Build Julia theory with timeline links
	var t: Dictionary = TheoryManager.create_theory("Julia's Timeline")
	TheoryManager.set_suspect(t["id"], "p_julia")
	TheoryManager.set_motive(t["id"], "Relationship")
	TheoryManager.set_time(t["id"], 1260, 1)
	TheoryManager.set_method(t["id"], "Knife")

	var links: Array[String] = [e4["id"], e5["id"]]
	TheoryManager.set_timeline_links(t["id"], links)

	# Complete theory
	assert_true(TheoryManager.is_complete(t["id"]))

	# Timeline step has 2 links → MODERATE
	assert_eq(
		TheoryManager.get_step_strength(t["id"], "timeline"),
		Enums.TheoryStrength.MODERATE
	)

	# Check inconsistencies — Julia at apt at 20:50 in evt_julia_arrives
	# but theory says crime at 21:00 — no conflict (different times)
	# However evt_death at 21:00 involves p_victim not p_julia — no conflict
	var incon: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	# evt_julia_arrives at 20:50 involves p_julia, theory time is 21:00 (1260)
	# evt_julia_arrives time is 1250, theory time is 1260 — different, no conflict
	assert_eq(incon.size(), 0, "No conflicts — different times")


# =========================================================================
# Scenario 4: Revise theory when new evidence contradicts
# =========================================================================

func test_scenario_theory_revision() -> void:
	# Initial theory: Mark did it at 20:15 during argument
	var t: Dictionary = TheoryManager.create_theory("Mark theory")
	TheoryManager.set_suspect(t["id"], "p_mark")
	TheoryManager.set_motive(t["id"], "Money dispute")
	TheoryManager.set_time(t["id"], 1215, 1)  # 20:15
	TheoryManager.set_method(t["id"], "Knife")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_prints_mark")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_noise")

	# Camera footage shows Mark leaving at 20:40 — still possible
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_camera")
	assert_eq(
		TheoryManager.get_step_strength(t["id"], "suspect"),
		Enums.TheoryStrength.STRONG
	)

	# Place timeline: Mark at parking at 21:00 (CCTV confirms he left)
	TimelineManager.place_event("evt_mark_leaves", 1240, 1)

	# Place hypothesis: Mark seen at parking lot at 21:00
	TimelineManager.add_hypothesis(
		"Mark at parking", 1260, 1, "loc_parking", ["p_mark"]
	)

	# Now reconsider: if Mark left at 20:40, he couldn't be at apt at 21:00
	# Let's check if putting theory time to 21:00 conflicts with timeline
	TheoryManager.set_time(t["id"], 1260, 1)

	var incon: Array[Dictionary] = TheoryManager.get_inconsistencies(t["id"])
	# Mark has hypothesis at parking at 21:00 — conflicts with theory
	assert_true(incon.size() > 0, "Mark at parking at 21:00 conflicts with theory")

	# Revise theory: switch suspect to Julia
	TheoryManager.set_suspect(t["id"], "p_julia")

	# Evidence attached to suspect step is still Mark's — need to detach
	TheoryManager.detach_evidence(t["id"], "suspect", "ev_prints_mark")
	TheoryManager.detach_evidence(t["id"], "suspect", "ev_noise")
	TheoryManager.detach_evidence(t["id"], "suspect", "ev_camera")

	# Attach Julia's evidence
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_prints_julia")
	TheoryManager.attach_evidence(t["id"], "suspect", "ev_phone")

	assert_eq(TheoryManager.get_theory(t["id"])["suspect_id"], "p_julia")
	assert_eq(TheoryManager.get_step_strength(t["id"], "suspect"), Enums.TheoryStrength.MODERATE)


# =========================================================================
# Scenario 5: Full investigation with save/load
# =========================================================================

func test_scenario_full_investigation_with_persistence() -> void:
	# Build timeline
	var e1: Dictionary = TimelineManager.place_event("evt_mark_visits", 1170, 1)
	var e2: Dictionary = TimelineManager.place_event("evt_argument", 1215, 1)
	var e3: Dictionary = TimelineManager.place_event("evt_mark_leaves", 1240, 1)
	var e4: Dictionary = TimelineManager.place_event("evt_julia_arrives", 1250, 1)
	var e5: Dictionary = TimelineManager.place_event("evt_death", 1260, 1)

	# Create two competing theories
	var t1: Dictionary = TheoryManager.create_theory("Mark Theory")
	TheoryManager.set_suspect(t1["id"], "p_mark")
	TheoryManager.set_motive(t1["id"], "Money")
	TheoryManager.set_time(t1["id"], 1215, 1)
	TheoryManager.set_method(t1["id"], "Knife")
	var links1: Array[String] = [e1["id"], e2["id"], e3["id"]]
	TheoryManager.set_timeline_links(t1["id"], links1)
	TheoryManager.attach_evidence(t1["id"], "suspect", "ev_prints_mark")
	TheoryManager.attach_evidence(t1["id"], "method", "ev_knife")

	var t2: Dictionary = TheoryManager.create_theory("Julia Theory")
	TheoryManager.set_suspect(t2["id"], "p_julia")
	TheoryManager.set_motive(t2["id"], "Relationship")
	TheoryManager.set_time(t2["id"], 1260, 1)
	TheoryManager.set_method(t2["id"], "Knife")
	var links2: Array[String] = [e4["id"], e5["id"]]
	TheoryManager.set_timeline_links(t2["id"], links2)
	TheoryManager.attach_evidence(t2["id"], "suspect", "ev_prints_julia")

	# Verify state before save
	assert_eq(TheoryManager.get_theory_count(), 2)
	assert_true(TheoryManager.is_complete(t1["id"]))
	assert_true(TheoryManager.is_complete(t2["id"]))

	# Save everything
	var save_data: Dictionary = GameManager.serialize()

	# Complete reset
	GameManager.new_game()
	CaseManager.load_case(TEST_CASE_FILE)
	assert_eq(TheoryManager.get_theory_count(), 0)
	assert_eq(TimelineManager.get_entry_count(), 0)

	# Restore
	GameManager.deserialize(save_data)

	# Verify theories
	assert_eq(TheoryManager.get_theory_count(), 2)
	var r_mark: Dictionary = TheoryManager.get_theory(t1["id"])
	assert_eq(r_mark["suspect_id"], "p_mark")
	assert_eq(r_mark["motive"], "Money")
	assert_true(TheoryManager.is_complete(t1["id"]))

	var r_julia: Dictionary = TheoryManager.get_theory(t2["id"])
	assert_eq(r_julia["suspect_id"], "p_julia")
	assert_true(TheoryManager.is_complete(t2["id"]))

	# Verify evidence survived
	var mark_ev: Array[String] = TheoryManager.get_step_evidence(t1["id"], "suspect")
	assert_has(mark_ev, "ev_prints_mark")
	var julia_ev: Array[String] = TheoryManager.get_step_evidence(t2["id"], "suspect")
	assert_has(julia_ev, "ev_prints_julia")

	# Verify timeline survived
	assert_eq(TimelineManager.get_entry_count(), 5)


# =========================================================================
# Scenario 6: Delete theory and create new one
# =========================================================================

func test_scenario_delete_and_recreate() -> void:
	var t1: Dictionary = TheoryManager.create_theory("Wrong Theory")
	TheoryManager.set_suspect(t1["id"], "p_sarah")
	TheoryManager.attach_evidence(t1["id"], "suspect", "ev_noise")

	assert_eq(TheoryManager.get_theory_count(), 1)

	# Player realizes Sarah is witness, deletes theory
	TheoryManager.remove_theory(t1["id"])
	assert_eq(TheoryManager.get_theory_count(), 0)

	# Create new theory — ID should not collide
	var t2: Dictionary = TheoryManager.create_theory("Correct Theory")
	assert_ne(t1["id"], t2["id"], "New theory should have different ID")
	assert_eq(TheoryManager.get_theory_count(), 1)

	# Old theory data gone
	var old: Dictionary = TheoryManager.get_theory(t1["id"])
	assert_true(old.is_empty(), "Old theory should be gone")
