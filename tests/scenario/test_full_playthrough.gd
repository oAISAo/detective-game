## test_full_playthrough.gd
## Phase 16.2 — Full Playthrough Tests.
## Simulates complete investigation flows from Day 1 to case conclusion.
extends GutTest


const TEST_CASE_FILE: String = "test_case_playthrough.json"

var _test_case_data: Dictionary = {
	"id": "case_playthrough",
	"title": "Playthrough Case",
	"description": "Full playthrough testing.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{"id": "p_victim", "name": "Daniel", "role": "VICTIM", "personality_traits": [], "relationships": [], "pressure_threshold": 0},
		{"id": "p_mark", "name": "Mark", "role": "SUSPECT", "personality_traits": ["DEFENSIVE"], "relationships": [], "pressure_threshold": 3},
		{"id": "p_julia", "name": "Julia", "role": "SUSPECT", "personality_traits": ["EVASIVE"], "relationships": [], "pressure_threshold": 5},
		{"id": "p_carol", "name": "Carol", "role": "SUSPECT", "personality_traits": [], "relationships": [], "pressure_threshold": 4},
	],
	"evidence": [
		{"id": "ev_knife", "name": "Kitchen Knife", "description": "Murder weapon.", "type": "PHYSICAL", "location_found": "loc_scene", "related_persons": ["p_mark"], "weight": 0.9, "importance_level": "CRITICAL", "legal_categories": ["PRESENCE"]},
		{"id": "ev_dna", "name": "DNA Results", "description": "DNA on weapon.", "type": "FORENSIC", "location_found": "lab", "related_persons": ["p_mark"], "weight": 0.95, "importance_level": "CRITICAL", "legal_categories": ["CONNECTION"]},
		{"id": "ev_insurance", "name": "Insurance Policy", "description": "Financial motive.", "type": "DOCUMENT", "location_found": "loc_office", "related_persons": ["p_mark"], "weight": 0.85, "importance_level": "CRITICAL", "legal_categories": ["MOTIVE"]},
		{"id": "ev_camera", "name": "Camera Footage", "description": "Lobby camera.", "type": "DIGITAL", "location_found": "loc_lobby", "related_persons": ["p_mark"], "weight": 0.7, "importance_level": "KEY", "legal_categories": ["PRESENCE"]},
		{"id": "ev_prints", "name": "Shoe Prints", "description": "At scene.", "type": "PHYSICAL", "location_found": "loc_scene", "related_persons": ["p_mark"], "weight": 0.6, "importance_level": "SUPPORTING", "legal_categories": ["PRESENCE"]},
		{"id": "ev_glass", "name": "Wine Glass", "description": "Fingerprints.", "type": "PHYSICAL", "location_found": "loc_scene", "related_persons": ["p_julia"], "weight": 0.5, "importance_level": "SUPPORTING", "legal_categories": ["PRESENCE"]},
		{"id": "ev_phone", "name": "Phone Records", "description": "Calls.", "type": "DIGITAL", "location_found": "loc_office", "related_persons": ["p_julia"], "weight": 0.4, "importance_level": "OPTIONAL", "legal_categories": ["CONNECTION"]},
	],
	"locations": [
		{"id": "loc_scene", "name": "Crime Scene", "description": "Where it happened.", "type": "CRIME_SCENE", "evidence_ids": ["ev_knife", "ev_prints", "ev_glass"]},
		{"id": "loc_office", "name": "Office", "description": "Office.", "type": "PUBLIC", "evidence_ids": ["ev_insurance", "ev_phone"]},
		{"id": "loc_lobby", "name": "Lobby", "description": "Building lobby.", "type": "PUBLIC", "evidence_ids": ["ev_camera"]},
	],
	"events": [
		{"id": "evt_arrival", "name": "Mark Arrives", "description": "Mark enters.", "time": "21:00", "day": 1, "location": "loc_lobby", "involved_persons": ["p_mark"]},
		{"id": "evt_argument", "name": "Argument", "description": "Loud argument.", "time": "21:30", "day": 1, "location": "loc_scene", "involved_persons": ["p_mark", "p_victim"]},
	],
	"interrogation_triggers": [
		{"id": "trig_knife", "person_id": "p_mark", "evidence_id": "ev_knife", "response": "I never saw it.", "impact_level": "MODERATE", "pressure_points": 1},
		{"id": "trig_dna", "person_id": "p_mark", "evidence_id": "ev_dna", "response": "Impossible!", "impact_level": "STRONG", "pressure_points": 2},
		{"id": "trig_glass", "person_id": "p_julia", "evidence_id": "ev_glass", "response": "I was there earlier.", "impact_level": "MODERATE", "pressure_points": 1},
	],
	"solution": {
		"suspect": "p_mark",
		"motive": "Insurance payout",
		"weapon": "Kitchen Knife",
		"time_minutes": 1290,
		"time_day": 1,
		"access": "Had building key",
	},
	"critical_evidence_ids": ["ev_knife", "ev_insurance"],
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
# Correct Accusation Path — Charge with right suspect
# =========================================================================

func test_correct_accusation_path() -> void:
	# Day 1: Discover key evidence
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_camera")
	GameManager.visit_location("loc_scene")
	GameManager.visit_location("loc_lobby")
	GameManager.use_action()
	GameManager.use_action()

	# Day 2: More evidence and interrogation
	GameManager.current_day = 2
	GameManager.actions_remaining = GameManager.ACTIONS_PER_DAY
	GameManager.discover_evidence("ev_insurance")
	GameManager.discover_evidence("ev_dna")
	GameManager.visit_location("loc_office")

	# Interrogate Mark with evidence
	InterrogationManager.start_interrogation("p_mark")
	InterrogationManager.present_evidence("ev_knife")
	InterrogationManager.present_evidence("ev_dna")
	InterrogationManager.end_interrogation()

	# Day 3: Build theory and timeline
	GameManager.current_day = 3
	var theory: Dictionary = TheoryManager.create_theory("Mark is the killer")
	TheoryManager.set_suspect(theory["id"], "p_mark")
	TheoryManager.set_motive(theory["id"], "Insurance payout")
	TheoryManager.set_method(theory["id"], "Kitchen Knife")
	TheoryManager.set_time(theory["id"], 1290, 1)

	TimelineManager.place_event("evt_arrival", 1260, 1)
	TimelineManager.place_event("evt_argument", 1290, 1)

	# Day 4: Submit report and charge
	GameManager.current_day = 4
	var report: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": ["ev_knife", "ev_dna"]},
		"motive": {"answer": "Insurance payout", "evidence": ["ev_insurance"]},
		"weapon": {"answer": "Kitchen Knife", "evidence": ["ev_knife"]},
		"time": {"answer": "1290 1", "evidence": ["ev_camera"]},
		"access": {"answer": "Had building key", "evidence": []},
	}
	ConclusionManager.submit_report(report)
	assert_true(ConclusionManager.is_evaluated())
	assert_true(ConclusionManager.get_confidence_score() > 0.0)

	ConclusionManager.make_choice(ConclusionManager.CHOICE_CHARGE)
	assert_false(ConclusionManager.get_outcome_name().is_empty())


# =========================================================================
# Wrong Suspect Path — Accuse Julia instead of Mark
# =========================================================================

func test_wrong_suspect_path() -> void:
	GameManager.discover_evidence("ev_glass")
	GameManager.discover_evidence("ev_phone")

	var theory: Dictionary = TheoryManager.create_theory("Julia did it")
	TheoryManager.set_suspect(theory["id"], "p_julia")
	TheoryManager.set_motive(theory["id"], "Jealousy")
	TheoryManager.set_method(theory["id"], "Unknown")
	TheoryManager.set_time(theory["id"], 1290, 1)

	var report: Dictionary = {
		"suspect": {"answer": "p_julia", "evidence": ["ev_glass"]},
		"motive": {"answer": "Jealousy", "evidence": ["ev_phone"]},
		"weapon": {"answer": "Unknown", "evidence": []},
		"time": {"answer": "1290 1", "evidence": []},
		"access": {"answer": "Unknown", "evidence": []},
	}
	ConclusionManager.submit_report(report)
	assert_true(ConclusionManager.is_evaluated())

	# Wrong suspect should get lower confidence
	var score: float = ConclusionManager.get_confidence_score()
	assert_true(score < 0.9, "Wrong suspect should not get perfect score")

	ConclusionManager.make_choice(ConclusionManager.CHOICE_CHARGE)
	var outcome: Enums.CaseOutcome = ConclusionManager.get_outcome()
	assert_true(outcome >= 0)


# =========================================================================
# Request More Time Path — Choose to investigate further
# =========================================================================

func test_request_more_investigation_path() -> void:
	GameManager.discover_evidence("ev_knife")

	var report: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": ["ev_knife"]},
		"motive": {"answer": "Unknown", "evidence": []},
		"weapon": {"answer": "Kitchen Knife", "evidence": ["ev_knife"]},
		"time": {"answer": "1290 1", "evidence": []},
		"access": {"answer": "Unknown", "evidence": []},
	}
	ConclusionManager.submit_report(report)
	assert_true(ConclusionManager.is_evaluated())

	# Choose to investigate more
	var chose: bool = ConclusionManager.make_choice(ConclusionManager.CHOICE_INVESTIGATE)
	assert_true(chose)
	assert_eq(ConclusionManager.get_player_choice(), ConclusionManager.CHOICE_INVESTIGATE)


# =========================================================================
# Review Evidence Path — Choose to review
# =========================================================================

func test_review_evidence_path() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_insurance")

	var report: Dictionary = {
		"suspect": {"answer": "p_mark", "evidence": ["ev_knife"]},
		"motive": {"answer": "Insurance payout", "evidence": ["ev_insurance"]},
		"weapon": {"answer": "Kitchen Knife", "evidence": ["ev_knife"]},
		"time": {"answer": "1290 1", "evidence": []},
		"access": {"answer": "Had building key", "evidence": []},
	}
	ConclusionManager.submit_report(report)
	ConclusionManager.make_choice(ConclusionManager.CHOICE_REVIEW)
	assert_eq(ConclusionManager.get_player_choice(), ConclusionManager.CHOICE_REVIEW)


# =========================================================================
# All Evidence Discoverable
# =========================================================================

func test_all_evidence_discoverable() -> void:
	var all_evidence: Array[EvidenceData] = CaseManager.get_all_evidence()
	assert_eq(all_evidence.size(), 7)
	for ev: EvidenceData in all_evidence:
		var result: bool = GameManager.discover_evidence(ev.id)
		assert_true(result, "Should discover %s" % ev.id)
	assert_eq(GameManager.discovered_evidence.size(), 7)


# =========================================================================
# All Interrogation Triggers Fire
# =========================================================================

func test_all_interrogation_triggers_fire() -> void:
	# Discover all evidence first
	for ev: EvidenceData in CaseManager.get_all_evidence():
		GameManager.discover_evidence(ev.id)

	# Interrogate Mark
	InterrogationManager.start_interrogation("p_mark")
	InterrogationManager.present_evidence("ev_knife")
	InterrogationManager.present_evidence("ev_dna")
	InterrogationManager.end_interrogation()

	var mark_fired: Array = InterrogationManager.get_fired_triggers_for_person("p_mark")
	assert_eq(mark_fired.size(), 2, "Both Mark triggers should fire")

	# Interrogate Julia
	InterrogationManager.start_interrogation("p_julia")
	InterrogationManager.present_evidence("ev_glass")
	InterrogationManager.end_interrogation()

	var julia_fired: Array = InterrogationManager.get_fired_triggers_for_person("p_julia")
	assert_eq(julia_fired.size(), 1, "Julia trigger should fire")


# =========================================================================
# Day Progression Full Cycle
# =========================================================================

func test_day_progression_full_cycle() -> void:
	assert_eq(GameManager.current_day, 1)
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.MORNING)

	# Progress through all time slots on day 1
	GameManager.advance_time_slot()
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.AFTERNOON)
	GameManager.advance_time_slot()
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.EVENING)
	GameManager.advance_time_slot()
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.NIGHT)

	# Night → Day 2
	GameManager.advance_time_slot()
	assert_eq(GameManager.current_day, 2)
	assert_eq(GameManager.current_time_slot, Enums.TimeSlot.MORNING)
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY)


# =========================================================================
# Action Economy Across Days
# =========================================================================

func test_action_economy_across_days() -> void:
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY)
	GameManager.use_action()
	GameManager.use_action()
	assert_false(GameManager.has_actions_remaining())

	# Advance to next day — actions reset
	GameManager.current_day = 2
	GameManager.current_time_slot = Enums.TimeSlot.MORNING
	GameManager.actions_remaining = GameManager.ACTIONS_PER_DAY
	assert_true(GameManager.has_actions_remaining())
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY)
