## test_interrogation_scenarios.gd
## Scenario tests for the interrogation system.
## Tests complete interrogation sequences with specific suspects.
## Scenario 1: Mark Bennett — 3 triggers in sequence.
## Scenario 2: Julia Ross — reaching break point at threshold 5.
extends GutTest


## Path to a test case JSON file for scenario tests.
const TEST_CASE_FILE: String = "test_case_interr_scenario.json"

## Uses the same comprehensive test data as unit tests.
var _test_case_data: Dictionary = {
	"id": "case_interr_scenario",
	"title": "Scenario Test Case",
	"description": "Tests complete interrogation scenarios.",
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
			"id": "p_mark",
			"name": "Mark Bennett",
			"role": "SUSPECT",
			"personality_traits": ["AGGRESSIVE"],
			"relationships": [],
			"pressure_threshold": 3,
		},
		{
			"id": "p_julia",
			"name": "Julia Ross",
			"role": "SUSPECT",
			"personality_traits": ["MANIPULATIVE"],
			"relationships": [],
			"pressure_threshold": 5,
		},
	],
	"evidence": [
		{
			"id": "ev_parking_camera",
			"name": "Parking Camera Footage",
			"description": "Security footage.",
			"type": "RECORDING",
			"location_found": "loc_parking",
			"related_persons": ["p_mark"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_financial",
			"name": "Financial Records",
			"description": "Irregular transactions.",
			"type": "FINANCIAL",
			"location_found": "loc_office",
			"related_persons": ["p_mark"],
			"weight": 0.7,
			"importance_level": "CRITICAL",
		},
		{
			"id": "ev_safe",
			"name": "Office Safe Contents",
			"description": "Documents from safe.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": ["p_mark"],
			"weight": 0.8,
			"importance_level": "CRITICAL",
		},
		{
			"id": "ev_fingerprint",
			"name": "Fingerprint on Glass",
			"description": "Fingerprint found on wine glass.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": ["p_julia"],
			"weight": 0.8,
			"importance_level": "CRITICAL",
		},
		{
			"id": "ev_elevator_log",
			"name": "Elevator Log",
			"description": "Electronic log from elevator.",
			"type": "DIGITAL",
			"location_found": "loc_hallway",
			"related_persons": ["p_julia"],
			"weight": 0.7,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_shoe_print",
			"name": "Shoe Print",
			"description": "Shoe print at scene.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": ["p_julia"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_journal",
			"name": "Victim Journal",
			"description": "Personal journal.",
			"type": "DOCUMENT",
			"location_found": "loc_apartment",
			"related_persons": ["p_julia"],
			"weight": 0.9,
			"importance_level": "CRITICAL",
		},
	],
	"statements": [
		{
			"id": "s_mark_left_early",
			"person_id": "p_mark",
			"text": "I left the office at 19:30.",
			"day_given": 1,
			"related_evidence": ["ev_parking_camera"],
			"contradicting_evidence": ["ev_parking_camera"],
		},
		{
			"id": "s_mark_admission_time",
			"person_id": "p_mark",
			"text": "Maybe it was closer to 20:40.",
			"day_given": 1,
			"related_evidence": ["ev_parking_camera"],
		},
		{
			"id": "s_mark_embezzlement",
			"person_id": "p_mark",
			"text": "I moved some money around.",
			"day_given": 1,
			"related_evidence": ["ev_financial"],
		},
		{
			"id": "s_mark_safe_panic",
			"person_id": "p_mark",
			"text": "I did not think you would find the safe.",
			"day_given": 1,
			"related_evidence": ["ev_safe"],
		},
		{
			"id": "s_julia_was_away",
			"person_id": "p_julia",
			"text": "I was out of town that night.",
			"day_given": 1,
			"related_evidence": [],
			"contradicting_evidence": ["ev_fingerprint", "ev_elevator_log"],
		},
		{
			"id": "s_julia_deflection_fingerprint",
			"person_id": "p_julia",
			"text": "Those prints could be from weeks ago.",
			"day_given": 1,
			"related_evidence": ["ev_fingerprint"],
		},
		{
			"id": "s_julia_elevator_admission",
			"person_id": "p_julia",
			"text": "Fine, I was there briefly.",
			"day_given": 1,
			"related_evidence": ["ev_elevator_log"],
		},
		{
			"id": "s_julia_shoe_silence",
			"person_id": "p_julia",
			"text": "...",
			"day_given": 1,
			"related_evidence": ["ev_shoe_print"],
		},
		{
			"id": "s_julia_journal_confession",
			"person_id": "p_julia",
			"text": "He was going to ruin everything. I had no choice.",
			"day_given": 1,
			"related_evidence": ["ev_journal"],
		},
	],
	"events": [],
	"locations": [
		{"id": "loc_apartment", "name": "Apartment", "searchable": true, "evidence_pool": []},
		{"id": "loc_office", "name": "Office", "searchable": true, "evidence_pool": []},
		{"id": "loc_parking", "name": "Parking Lot", "searchable": true, "evidence_pool": []},
		{"id": "loc_hallway", "name": "Hallway", "searchable": true, "evidence_pool": []},
	],
	"event_triggers": [],
	"interrogation_topics": [
		{
			"id": "topic_mark_evening",
			"person_id": "p_mark",
			"topic_name": "Evening whereabouts",
			"trigger_conditions": [],
			"statements": ["s_mark_left_early"],
			"required_evidence": [],
		},
		{
			"id": "topic_julia_whereabouts",
			"person_id": "p_julia",
			"topic_name": "Night of the incident",
			"trigger_conditions": [],
			"statements": ["s_julia_was_away"],
			"required_evidence": [],
		},
	],
	"actions": [],
	"insights": [],
	"interrogation_triggers": [
		{
			"id": "trig_mark_camera",
			"person_id": "p_mark",
			"evidence_id": "ev_parking_camera",
			"requires_statement_id": "s_mark_left_early",
			"impact_level": "MAJOR",
			"reaction_type": "DENIAL",
			"dialogue": "That camera must be wrong!",
			"new_statement_id": "s_mark_admission_time",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_mark_financial",
			"person_id": "p_mark",
			"evidence_id": "ev_financial",
			"requires_statement_id": "",
			"impact_level": "MAJOR",
			"reaction_type": "ADMISSION",
			"dialogue": "Fine, I moved some money.",
			"new_statement_id": "s_mark_embezzlement",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_mark_safe",
			"person_id": "p_mark",
			"evidence_id": "ev_safe",
			"requires_statement_id": "s_mark_embezzlement",
			"impact_level": "BREAKPOINT",
			"reaction_type": "PANIC",
			"dialogue": "I did not think you would find the safe.",
			"new_statement_id": "s_mark_safe_panic",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_julia_fingerprint",
			"person_id": "p_julia",
			"evidence_id": "ev_fingerprint",
			"requires_statement_id": "s_julia_was_away",
			"impact_level": "MINOR",
			"reaction_type": "DENIAL",
			"dialogue": "Those prints could be from weeks ago.",
			"new_statement_id": "s_julia_deflection_fingerprint",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_julia_elevator",
			"person_id": "p_julia",
			"evidence_id": "ev_elevator_log",
			"requires_statement_id": "s_julia_was_away",
			"impact_level": "MAJOR",
			"reaction_type": "ADMISSION",
			"dialogue": "Fine, I was there briefly.",
			"new_statement_id": "s_julia_elevator_admission",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_julia_shoe",
			"person_id": "p_julia",
			"evidence_id": "ev_shoe_print",
			"requires_statement_id": "",
			"impact_level": "MAJOR",
			"reaction_type": "SILENCE",
			"dialogue": "...",
			"new_statement_id": "s_julia_shoe_silence",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_julia_journal",
			"person_id": "p_julia",
			"evidence_id": "ev_journal",
			"requires_statement_id": "",
			"impact_level": "BREAKPOINT",
			"reaction_type": "PARTIAL_CONFESSION",
			"dialogue": "He was going to ruin everything.",
			"new_statement_id": "s_julia_journal_confession",
			"unlocks": [],
			"pressure_points": 2,
		},
	],
}


# --- Setup / Teardown --- #

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
	InterrogationManager.reset()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Scenario 1: Mark Bennett — 3 Triggers in Sequence
# =========================================================================

func test_mark_interrogation_three_triggers() -> void:
	# Discover all evidence needed
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_financial")
	GameManager.discover_evidence("ev_safe")

	# Start interrogation with Mark
	var started: bool = InterrogationManager.start_interrogation("p_mark")
	assert_true(started, "Interrogation should start")

	# --- Phase 1: Open Conversation ---
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.OPEN_CONVERSATION)

	# Discuss evening whereabouts → hear "I left at 19:30"
	var topic_result: Dictionary = InterrogationManager.discuss_topic("topic_mark_evening")
	assert_has(topic_result.get("statements", []), "s_mark_left_early")
	assert_has(InterrogationManager.get_heard_statements(), "s_mark_left_early")

	# --- Phase 2: Evidence Confrontation ---
	InterrogationManager.advance_phase()
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.EVIDENCE_CONFRONTATION)

	# Trigger 1: Present parking camera (prereq s_mark_left_early met)
	var result1: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_true(result1.get("triggered", false), "Camera trigger should fire")
	assert_eq(result1["trigger_id"], "trig_mark_camera")
	# Aggressive personality: DENIAL → ANGER
	assert_eq(result1["reaction_type"], Enums.ReactionType.ANGER,
		"Aggressive Mark should react with ANGER instead of DENIAL")
	assert_false(result1.get("weakened", true), "Should not be weakened")
	assert_eq(result1["pressure_added"], 1)
	assert_eq(InterrogationManager.get_current_pressure(), 1)
	assert_has(InterrogationManager.get_heard_statements(), "s_mark_admission_time")

	# Trigger 2: Present financial records (no prereq)
	var result2: Dictionary = InterrogationManager.present_evidence("ev_financial")
	assert_true(result2.get("triggered", false), "Financial trigger should fire")
	assert_eq(result2["trigger_id"], "trig_mark_financial")
	assert_eq(result2["reaction_type"], Enums.ReactionType.ADMISSION)
	assert_eq(result2["pressure_added"], 1)
	assert_eq(InterrogationManager.get_current_pressure(), 2)
	assert_has(InterrogationManager.get_heard_statements(), "s_mark_embezzlement")

	# --- Phase 3: Psychological Pressure ---
	InterrogationManager.advance_phase()
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.PSYCHOLOGICAL_PRESSURE)

	# Trigger 3: Present safe (prereq s_mark_embezzlement met from trigger 2)
	watch_signals(InterrogationManager)
	var result3: Dictionary = InterrogationManager.present_evidence("ev_safe")
	assert_true(result3.get("triggered", false), "Safe trigger should fire")
	assert_eq(result3["trigger_id"], "trig_mark_safe")
	assert_eq(result3["reaction_type"], Enums.ReactionType.PANIC)
	assert_eq(result3["pressure_added"], 1)
	assert_eq(InterrogationManager.get_current_pressure(), 3)

	# Break moment! Pressure 3 = threshold 3
	assert_true(result3.get("break_moment", false), "Break moment should trigger")
	assert_signal_emitted_with_parameters(
		InterrogationManager, "break_moment_reached", ["p_mark"]
	)
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.BREAK_MOMENT)

	# End session and verify persistence
	InterrogationManager.end_interrogation()
	assert_true(InterrogationManager.has_break_moment("p_mark"))
	assert_eq(InterrogationManager.get_pressure_for_person("p_mark"), 3)
	var fired: Array = InterrogationManager.get_fired_triggers_for_person("p_mark")
	assert_eq(fired.size(), 3, "All three triggers should be recorded as fired")


# =========================================================================
# Scenario 2: Julia Ross — Reaching Break Point at Threshold 5
# =========================================================================

func test_julia_interrogation_reaching_break_point() -> void:
	# Discover all evidence
	GameManager.discover_evidence("ev_fingerprint")
	GameManager.discover_evidence("ev_elevator_log")
	GameManager.discover_evidence("ev_shoe_print")
	GameManager.discover_evidence("ev_journal")

	# Start interrogation with Julia
	var started: bool = InterrogationManager.start_interrogation("p_julia")
	assert_true(started)

	# --- Phase 1: Open Conversation ---
	# Discuss whereabouts → hear "I was out of town"
	InterrogationManager.discuss_topic("topic_julia_whereabouts")
	assert_has(InterrogationManager.get_heard_statements(), "s_julia_was_away")

	# --- Phase 2: Evidence Confrontation ---
	InterrogationManager.advance_phase()

	# Trigger 1: Fingerprint (MINOR, prereq met)
	# Julia is MANIPULATIVE → MINOR triggers produce DEFLECTION
	var r1: Dictionary = InterrogationManager.present_evidence("ev_fingerprint")
	assert_true(r1.get("triggered", false))
	assert_eq(r1["reaction_type"], Enums.ReactionType.DEFLECTION,
		"Manipulative Julia should convert MINOR to DEFLECTION")
	# Note: MANIPULATIVE doesn't affect pressure for MINOR (only CALM does)
	assert_eq(r1["pressure_added"], 1)
	assert_eq(InterrogationManager.get_current_pressure(), 1)

	# Trigger 2: Elevator log (MAJOR, prereq met)
	var r2: Dictionary = InterrogationManager.present_evidence("ev_elevator_log")
	assert_true(r2.get("triggered", false))
	assert_eq(r2["reaction_type"], Enums.ReactionType.ADMISSION)
	assert_eq(r2["pressure_added"], 1)
	assert_eq(InterrogationManager.get_current_pressure(), 2)

	# --- Phase 3: Psychological Pressure ---
	InterrogationManager.advance_phase()

	# Trigger 3: Shoe print (MAJOR, no prereq)
	var r3: Dictionary = InterrogationManager.present_evidence("ev_shoe_print")
	assert_true(r3.get("triggered", false))
	assert_eq(r3["reaction_type"], Enums.ReactionType.SILENCE)
	assert_eq(r3["pressure_added"], 1)
	assert_eq(InterrogationManager.get_current_pressure(), 3)

	# Not at break point yet (threshold is 5)
	assert_false(InterrogationManager.has_break_moment("p_julia"),
		"Should not have break moment yet (3 < 5)")

	# Trigger 4: Journal (BREAKPOINT, no prereq, +2 pressure)
	watch_signals(InterrogationManager)
	var r4: Dictionary = InterrogationManager.present_evidence("ev_journal")
	assert_true(r4.get("triggered", false))
	assert_eq(r4["reaction_type"], Enums.ReactionType.PARTIAL_CONFESSION)
	assert_eq(r4["pressure_added"], 2)
	assert_eq(InterrogationManager.get_current_pressure(), 5)

	# Break moment! Pressure 5 = threshold 5
	assert_true(r4.get("break_moment", false), "Break moment should trigger")
	assert_signal_emitted_with_parameters(
		InterrogationManager, "break_moment_reached", ["p_julia"]
	)
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.BREAK_MOMENT)
	assert_true(InterrogationManager.has_break_moment("p_julia"))

	# End and verify
	InterrogationManager.end_interrogation()
	assert_eq(InterrogationManager.get_pressure_for_person("p_julia"), 5)
	var fired: Array = InterrogationManager.get_fired_triggers_for_person("p_julia")
	assert_eq(fired.size(), 4, "All four triggers should be recorded")
	assert_has(fired, "trig_julia_fingerprint")
	assert_has(fired, "trig_julia_elevator")
	assert_has(fired, "trig_julia_shoe")
	assert_has(fired, "trig_julia_journal")

	# Verify all statements heard
	var heard: Array[String] = InterrogationManager.get_heard_statements()
	assert_has(heard, "s_julia_was_away")
	assert_has(heard, "s_julia_deflection_fingerprint")
	assert_has(heard, "s_julia_elevator_admission")
	assert_has(heard, "s_julia_shoe_silence")
	assert_has(heard, "s_julia_journal_confession")
