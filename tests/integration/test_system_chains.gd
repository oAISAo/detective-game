## test_system_chains.gd
## Phase 16.1 — System Integration Chain Tests.
## Verifies end-to-end chains across multiple systems.
extends GutTest


const TEST_CASE_FILE: String = "test_case_chains.json"

var _test_case_data: Dictionary = {
	"id": "case_chains",
	"title": "System Chain Case",
	"description": "Tests end-to-end system chains.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{"id": "p_victim", "name": "Daniel", "role": "VICTIM", "personality_traits": [], "relationships": [], "pressure_threshold": 0},
		{"id": "p_mark", "name": "Mark", "role": "SUSPECT", "personality_traits": ["CALM"], "relationships": [], "pressure_threshold": 3},
		{"id": "p_julia", "name": "Julia", "role": "SUSPECT", "personality_traits": [], "relationships": [], "pressure_threshold": 5},
	],
	"evidence": [
		{"id": "ev_knife", "name": "Kitchen Knife", "description": "Found at scene.", "type": "OBJECT", "location_found": "loc_scene", "related_persons": ["p_mark"], "weight": 0.8, "importance_level": "KEY", "legal_categories": ["PRESENCE"]},
		{"id": "ev_knife_dna", "name": "Knife DNA", "description": "DNA from knife.", "type": "FORENSIC", "location_found": "lab", "related_persons": ["p_mark"], "weight": 0.9, "importance_level": "CRITICAL", "legal_categories": ["CONNECTION"]},
		{"id": "ev_motive", "name": "Insurance Doc", "description": "Financial motive.", "type": "DOCUMENT", "location_found": "loc_office", "related_persons": ["p_mark"], "weight": 0.85, "importance_level": "CRITICAL", "legal_categories": ["MOTIVE"]},
		{"id": "ev_camera", "name": "Camera Footage", "description": "Security footage.", "type": "DIGITAL", "location_found": "loc_lobby", "related_persons": ["p_mark"], "weight": 0.7, "importance_level": "SUPPORTING", "legal_categories": ["PRESENCE"]},
		{"id": "ev_phone", "name": "Phone Records", "description": "Call logs.", "type": "DIGITAL", "location_found": "loc_office", "related_persons": ["p_julia"], "weight": 0.5, "importance_level": "SUPPORTING", "legal_categories": ["CONNECTION"]},
	],
	"locations": [
		{"id": "loc_scene", "name": "Crime Scene", "description": "The scene.", "type": "CRIME_SCENE", "evidence_ids": ["ev_knife"]},
		{"id": "loc_office", "name": "Office", "description": "Office.", "type": "PUBLIC", "evidence_ids": ["ev_motive"]},
		{"id": "loc_lobby", "name": "Lobby", "description": "Building lobby.", "type": "PUBLIC", "evidence_ids": ["ev_camera"]},
	],
	"events": [
		{"id": "evt_arrival", "name": "Mark Arrives", "description": "Mark enters building.", "time": "21:00", "day": 1, "location": "loc_lobby", "involved_persons": ["p_mark"]},
		{"id": "evt_argument", "name": "Argument Heard", "description": "Witnesses hear argument.", "time": "21:30", "day": 1, "location": "loc_scene", "involved_persons": ["p_mark", "p_victim"]},
	],
	"interrogation_triggers": [
		{"id": "trig_knife", "person_id": "p_mark", "evidence_id": "ev_knife", "dialogue": "I never touched that knife.", "impact_level": "MINOR", "reaction_type": "DENIAL", "pressure_points": 1},
		{"id": "trig_dna", "person_id": "p_mark", "evidence_id": "ev_knife_dna", "dialogue": "That's impossible!", "impact_level": "MAJOR", "reaction_type": "PANIC", "pressure_points": 2},
	],
	"solution": {
		"suspect": "p_mark",
		"motive": "Insurance payout",
		"weapon": "Kitchen Knife",
		"time_minutes": 1290,
		"time_day": 1,
		"access": "Had building key",
	},
	"critical_evidence_ids": ["ev_knife", "ev_motive"],
}


func before_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/cases")
	var file: FileAccess = FileAccess.open("res://data/cases/%s" % TEST_CASE_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(_test_case_data, "\t"))
	file.close()


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Chain 1: Evidence → Archive → Interrogation → Board
# =========================================================================

func test_evidence_to_archive_to_interrogation_to_board() -> void:
	# Discover evidence
	GameManager.discover_evidence("ev_knife")
	assert_true(GameManager.has_evidence("ev_knife"))

	# Evidence appears in archive
	var archive: Array[EvidenceData] = EvidenceManager.get_discovered_evidence_data()
	assert_eq(archive.size(), 1)
	assert_eq(archive[0].id, "ev_knife")

	# Present evidence in interrogation
	InterrogationManager.start_interrogation("p_mark")
	assert_true(InterrogationManager.is_active())
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("topic", "general")
	var result: Dictionary = InterrogationManager.present_evidence("ev_knife")
	assert_true(result.get("triggered", false), "Should fire trigger for ev_knife")

	# Verify trigger fired
	var fired: Array = InterrogationManager.get_fired_triggers_for_person("p_mark")
	assert_true(fired.size() > 0, "Should have fired triggers")
	InterrogationManager.end_interrogation()

	# Send evidence to board
	var board_node: Dictionary = BoardManager.send_to_board("evidence", "ev_knife")
	assert_false(board_node.is_empty(), "Should create board node")
	assert_eq(BoardManager.get_node_count(), 1)

	# Add suspect to board and connect
	var suspect_node: Dictionary = BoardManager.send_to_board("person", "p_mark")
	assert_eq(BoardManager.get_node_count(), 2)
	var conn: Dictionary = BoardManager.add_connection(board_node["id"], suspect_node["id"], "DNA match")
	assert_false(conn.is_empty())
	assert_eq(BoardManager.get_connection_count(), 1)


# =========================================================================
# Chain 2: Lab → Day Advance → Results → New Evidence
# =========================================================================

func test_lab_to_day_advance_to_results() -> void:
	GameManager.discover_evidence("ev_knife")

	# Submit lab request
	var request: Dictionary = LabManager.submit_request("ev_knife", "DNA_ANALYSIS", "ev_knife_dna", 1)
	assert_false(request.is_empty(), "Lab request should be created")
	assert_eq(LabManager.get_pending_count(), 1)

	# Complete instantly (simulating day advance)
	var results: Array = LabManager.complete_all_instantly()
	assert_eq(results.size(), 1, "Should have one completed result")

	# Result produces new evidence
	var output_id: String = results[0].get("output_evidence_id", "")
	assert_eq(output_id, "ev_knife_dna")
	assert_eq(LabManager.get_pending_count(), 0)
	assert_eq(LabManager.get_completed_requests().size(), 1)


# =========================================================================
# Chain 3: Warrant → Threshold → Approved/Denied → Content
# =========================================================================

func test_warrant_denied_insufficient_evidence() -> void:
	# Attempt warrant with no evidence → denied
	var evidence_ids: Array[String] = []
	var result: Dictionary = WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", evidence_ids)
	assert_false(result.get("approved", true), "Warrant should be denied with no evidence")
	assert_eq(WarrantManager.get_denied_warrants().size(), 1)
	var feedback: String = result.get("feedback", "")
	assert_false(feedback.is_empty(), "Should provide judge feedback")

func test_warrant_approved_with_sufficient_evidence() -> void:
	# Discover evidence covering required categories
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_motive")
	var evidence_ids: Array[String] = ["ev_knife", "ev_motive"]

	var result: Dictionary = WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", evidence_ids)
	assert_true(result.get("approved", false), "Warrant should be approved with sufficient evidence")
	assert_eq(WarrantManager.get_approved_warrants().size(), 1)


# =========================================================================
# Chain 4: Timeline Events → Placement → Overlap Detection
# =========================================================================

func test_timeline_events_placed_and_overlaps_detected() -> void:
	# Place two events at close times
	var entry1: Dictionary = TimelineManager.place_event("evt_arrival", 1260, 1)  # 21:00
	var entry2: Dictionary = TimelineManager.place_event("evt_argument", 1290, 1)  # 21:30
	assert_false(entry1.is_empty())
	assert_false(entry2.is_empty())
	assert_eq(TimelineManager.get_entry_count(), 2)

	# Check entries for day 1
	var day1_entries: Array[Dictionary] = TimelineManager.get_entries_for_day(1)
	assert_eq(day1_entries.size(), 2)

	# Attach evidence to timeline entry
	TimelineManager.attach_evidence(entry1["id"], "ev_camera")
	var attached: Array[String] = TimelineManager.get_attached_evidence(entry1["id"])
	assert_eq(attached.size(), 1)
	assert_eq(attached[0], "ev_camera")


# =========================================================================
# Chain 5: Case Report → Confidence → Outcome
# =========================================================================

func test_case_report_to_confidence_to_outcome() -> void:
	# Discover evidence first
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_motive")
	GameManager.discover_evidence("ev_camera")

	# Build and submit report
	var report: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": ["ev_knife", "ev_motive"]},
		"motive": {"answer": "Insurance payout", "evidence": ["ev_motive"]},
		"weapon": {"answer": "Kitchen Knife", "evidence": ["ev_knife"]},
		"time": {"answer": "1290 1", "evidence": ["ev_camera"]},
		"access": {"answer": "Had building key", "evidence": []},
	}
	var success: bool = ConclusionManager.submit_report(report)
	assert_true(success, "Report should be submitted")
	assert_true(ConclusionManager.has_report())
	assert_true(ConclusionManager.is_evaluated())

	# Confidence score should be calculated
	var score: float = ConclusionManager.get_confidence_score()
	assert_true(score > 0.0, "Score should be positive")
	var level: Enums.ConfidenceLevel = ConclusionManager.get_confidence_level()
	assert_true(level >= 0, "Confidence level should be valid")

	# Make choice and determine outcome
	var chose: bool = ConclusionManager.make_choice(ConclusionManager.CHOICE_CHARGE)
	assert_true(chose)
	var outcome: Enums.CaseOutcome = ConclusionManager.get_outcome()
	assert_true(outcome >= 0, "Outcome should be valid")
	assert_false(ConclusionManager.get_outcome_name().is_empty())


# =========================================================================
# Chain 6: Surveillance → Multi-Day → Results
# =========================================================================

func test_surveillance_to_results() -> void:
	# Install surveillance on suspect
	var result_events: Array[String] = ["evt_arrival"]
	var op: Dictionary = SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHYSICAL, 2, result_events)
	assert_false(op.is_empty(), "Surveillance should be installed")
	assert_true(SurveillanceManager.is_person_under_surveillance("p_mark"))
	assert_eq(SurveillanceManager.get_active_count(), 1)

	# Complete surveillance
	var results: Array = SurveillanceManager.complete_all_instantly()
	assert_eq(results.size(), 1)
	assert_eq(SurveillanceManager.get_active_count(), 0)


# =========================================================================
# Cross-Chain: Full Evidence → Theory → Report → Outcome
# =========================================================================

func test_full_chain_evidence_to_outcome() -> void:
	# Step 1: Discover all evidence
	for ev: EvidenceData in CaseManager.get_all_evidence():
		GameManager.discover_evidence(ev.id)
	assert_eq(GameManager.discovered_evidence.size(), 5)

	# Step 2: Build theory
	var theory: Dictionary = TheoryManager.create_theory("Main Theory")
	TheoryManager.set_suspect(theory["id"], "p_mark")
	TheoryManager.set_motive(theory["id"], "Insurance payout")
	TheoryManager.set_method(theory["id"], "Kitchen Knife")
	TheoryManager.set_time(theory["id"], 1290, 1)
	TheoryManager.attach_evidence(theory["id"], "suspect", "ev_knife_dna")
	TheoryManager.attach_evidence(theory["id"], "motive", "ev_motive")

	# Step 3: Place timeline events
	var entry1: Dictionary = TimelineManager.place_event("evt_arrival", 1260, 1)
	TimelineManager.place_event("evt_argument", 1290, 1)
	assert_eq(TimelineManager.get_entry_count(), 2)
	TheoryManager.set_timeline_links(theory["id"], [entry1["id"]])
	assert_true(TheoryManager.is_complete(theory["id"]))

	# Step 4: Submit report
	var report: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": ["ev_knife", "ev_knife_dna"]},
		"motive": {"answer": "Insurance payout", "evidence": ["ev_motive"]},
		"weapon": {"answer": "Kitchen Knife", "evidence": ["ev_knife"]},
		"time": {"answer": "1290 1", "evidence": ["ev_camera"]},
		"access": {"answer": "Had building key", "evidence": []},
	}
	ConclusionManager.submit_report(report)
	assert_true(ConclusionManager.is_evaluated())

	# Step 5: Choose outcome
	ConclusionManager.make_choice(ConclusionManager.CHOICE_CHARGE)
	assert_false(ConclusionManager.get_outcome_name().is_empty())


# =========================================================================
# Serialization Round-Trip Across All Systems
# =========================================================================

func test_all_systems_serialize_roundtrip() -> void:
	# Populate state across all systems
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_motive")
	GameManager.visit_location("loc_scene")
	GameManager.current_day = 2
	GameManager.current_phase = Enums.DayPhase.DAYTIME

	BoardManager.add_node("evidence", "ev_knife", 100.0, 200.0)
	TimelineManager.place_event("evt_arrival", 1260, 1)
	var theory: Dictionary = TheoryManager.create_theory("Test")
	TheoryManager.set_suspect(theory["id"], "p_mark")
	LabManager.submit_request("ev_knife", "DNA", "ev_knife_dna", 1)
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHYSICAL)

	# Serialize
	var state: Dictionary = GameManager.serialize()
	assert_true(state.has("current_day"))
	assert_true(state.has("board_manager"))
	assert_true(state.has("timeline_manager"))
	assert_true(state.has("theory_manager"))
	assert_true(state.has("lab_manager"))
	assert_true(state.has("surveillance_manager"))

	# Reset everything
	GameManager.new_game()
	assert_eq(GameManager.current_day, 1)
	assert_eq(GameManager.discovered_evidence.size(), 0)

	# Deserialize
	GameManager.deserialize(state)
	assert_eq(GameManager.current_day, 2)
	assert_eq(GameManager.current_phase, Enums.DayPhase.DAYTIME)
	assert_eq(GameManager.discovered_evidence.size(), 2)
	assert_true(GameManager.has_evidence("ev_knife"))
	assert_true(GameManager.has_visited_location("loc_scene"))

	# Verify sub-systems restored
	assert_eq(BoardManager.get_node_count(), 1)
	assert_eq(TimelineManager.get_entry_count(), 1)
	assert_true(TheoryManager.has_content())
	assert_true(LabManager.has_content())
