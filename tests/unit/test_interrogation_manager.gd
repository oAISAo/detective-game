## test_interrogation_manager.gd
## Unit tests for the InterrogationManager autoload singleton.
## Tests: Session lifecycle, focus selection, evidence presentation with focus,
## apply pressure gating, phase flow, personality modifiers, contradiction
## logging, daily limits, statement collection, contradiction detection,
## session data, rejection texts, topic availability, serialization.
extends GutTest


## Path to a test case JSON file for interrogation tests.
const TEST_CASE_FILE: String = "test_case_interrogation.json"

## Comprehensive test case data with suspects, triggers, and statements.
var _test_case_data: Dictionary = {
	"id": "case_interr_test",
	"title": "Interrogation Test Case",
	"description": "Test case for interrogation system.",
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
			"id": "p_sarah",
			"name": "Sarah Klein",
			"role": "SUSPECT",
			"personality_traits": ["ANXIOUS"],
			"relationships": [],
			"pressure_threshold": 2,
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
			"id": "p_lucas",
			"name": "Lucas Weber",
			"role": "SUSPECT",
			"personality_traits": ["CALM"],
			"relationships": [],
			"pressure_threshold": 2,
		},
	],
	"evidence": [
		{
			"id": "ev_parking_camera",
			"name": "Parking Camera Footage",
			"description": "Security footage from parking lot.",
			"type": "RECORDING",
			"location_found": "loc_parking",
			"related_persons": ["p_mark"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_financial",
			"name": "Financial Records",
			"description": "Irregular financial transactions.",
			"type": "FINANCIAL",
			"location_found": "loc_office",
			"related_persons": ["p_mark"],
			"weight": 0.7,
			"importance_level": "CRITICAL",
		},
		{
			"id": "ev_safe",
			"name": "Office Safe Contents",
			"description": "Documents from the office safe.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": ["p_mark"],
			"weight": 0.8,
			"importance_level": "CRITICAL",
		},
		{
			"id": "ev_hallway_camera",
			"name": "Hallway Camera",
			"description": "Hallway security camera footage.",
			"type": "RECORDING",
			"location_found": "loc_hallway",
			"related_persons": ["p_sarah"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_shoe_print",
			"name": "Shoe Print",
			"description": "Shoe print found at the scene.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": ["p_sarah", "p_julia"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
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
			"id": "ev_journal",
			"name": "Victim's Journal",
			"description": "Personal journal of the victim.",
			"type": "DOCUMENT",
			"location_found": "loc_apartment",
			"related_persons": ["p_julia"],
			"weight": 0.9,
			"importance_level": "CRITICAL",
		},
		{
			"id": "ev_maintenance",
			"name": "Maintenance Logs",
			"description": "Building maintenance records.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": ["p_lucas"],
			"weight": 0.4,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_key_access",
			"name": "Key Access Records",
			"description": "Electronic key card access logs.",
			"type": "DIGITAL",
			"location_found": "loc_office",
			"related_persons": ["p_lucas"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_unlocked_clue",
			"name": "Unlocked Clue",
			"description": "Evidence unlocked by a trigger.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": [],
			"weight": 0.3,
			"importance_level": "OPTIONAL",
		},
		{
			"id": "ev_no_trigger",
			"name": "Irrelevant Document",
			"description": "A document with no trigger.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": [],
			"weight": 0.1,
			"importance_level": "OPTIONAL",
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
			"text": "Alright, maybe it was closer to 20:40.",
			"day_given": 1,
			"related_evidence": ["ev_parking_camera"],
		},
		{
			"id": "s_mark_financial_denial",
			"person_id": "p_mark",
			"text": "I know nothing about those transactions.",
			"day_given": 1,
			"related_evidence": ["ev_financial"],
			"contradicting_evidence": ["ev_financial"],
		},
		{
			"id": "s_mark_embezzlement",
			"person_id": "p_mark",
			"text": "I admit I moved some money around.",
			"day_given": 1,
			"related_evidence": ["ev_financial"],
		},
		{
			"id": "s_mark_safe_panic",
			"person_id": "p_mark",
			"text": "I... I didn't think you would find the safe.",
			"day_given": 1,
			"related_evidence": ["ev_safe"],
		},
		{
			"id": "s_sarah_was_home",
			"person_id": "p_sarah",
			"text": "I was at home the whole evening.",
			"day_given": 1,
			"related_evidence": [],
			"contradicting_evidence": ["ev_hallway_camera"],
		},
		{
			"id": "s_sarah_hallway_panic",
			"person_id": "p_sarah",
			"text": "OK I was in the building but I did not go upstairs!",
			"day_given": 1,
			"related_evidence": ["ev_hallway_camera"],
		},
		{
			"id": "s_sarah_heard_voice",
			"person_id": "p_sarah",
			"text": "I heard a female voice from the apartment.",
			"day_given": 1,
			"related_evidence": [],
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
			"text": "Fine, I was there briefly, but I left quickly.",
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
		{
			"id": "s_lucas_denial",
			"person_id": "p_lucas",
			"text": "I just do maintenance. I had no reason to be there.",
			"day_given": 1,
			"related_evidence": [],
		},
		{
			"id": "s_lucas_key_admission",
			"person_id": "p_lucas",
			"text": "I used the key to check a reported leak.",
			"day_given": 1,
			"related_evidence": ["ev_key_access"],
		},
	],
	"events": [],
	"locations": [
		{
			"id": "loc_apartment",
			"name": "Victim's Apartment",
			"searchable": true,
			"evidence_pool": [],
		},
		{
			"id": "loc_office",
			"name": "Victim's Office",
			"searchable": true,
			"evidence_pool": [],
		},
		{
			"id": "loc_parking",
			"name": "Parking Lot",
			"searchable": true,
			"evidence_pool": [],
		},
		{
			"id": "loc_hallway",
			"name": "Hallway",
			"searchable": true,
			"evidence_pool": [],
		},
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
			"id": "topic_mark_finances",
			"person_id": "p_mark",
			"topic_name": "Financial dealings",
			"trigger_conditions": ["evidence:ev_financial"],
			"statements": ["s_mark_financial_denial"],
			"required_evidence": ["ev_financial"],
		},
		{
			"id": "topic_sarah_alibi",
			"person_id": "p_sarah",
			"topic_name": "Evening alibi",
			"trigger_conditions": [],
			"statements": ["s_sarah_was_home"],
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
		{
			"id": "topic_julia_locked",
			"person_id": "p_julia",
			"topic_name": "Elevator usage",
			"trigger_conditions": ["evidence:ev_elevator_log"],
			"statements": [],
			"required_evidence": ["ev_elevator_log"],
			"requires_statement_id": "s_julia_was_away",
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
			"target_statement_id": "s_mark_left_early",
			"target_topic_id": "",
			"impact_level": "MAJOR",
			"reaction_type": "DENIAL",
			"dialogue": "That camera must be wrong. I left at 19:30!",
			"new_statement_id": "s_mark_admission_time",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_mark_financial",
			"person_id": "p_mark",
			"evidence_id": "ev_financial",
			"requires_statement_id": "",
			"target_statement_id": "",
			"target_topic_id": "",
			"impact_level": "MAJOR",
			"reaction_type": "ADMISSION",
			"dialogue": "Fine, I moved some money. But it has nothing to do with this.",
			"new_statement_id": "s_mark_embezzlement",
			"unlocks": ["ev_unlocked_clue"],
			"pressure_points": 1,
		},
		{
			"id": "trig_mark_safe",
			"person_id": "p_mark",
			"evidence_id": "ev_safe",
			"requires_statement_id": "s_mark_embezzlement",
			"target_statement_id": "s_mark_embezzlement",
			"target_topic_id": "",
			"impact_level": "BREAKPOINT",
			"reaction_type": "PANIC",
			"dialogue": "I... I didn't think you would find the safe.",
			"new_statement_id": "s_mark_safe_panic",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_sarah_hallway",
			"person_id": "p_sarah",
			"evidence_id": "ev_hallway_camera",
			"requires_statement_id": "s_sarah_was_home",
			"target_statement_id": "s_sarah_was_home",
			"target_topic_id": "",
			"impact_level": "MAJOR",
			"reaction_type": "SILENCE",
			"dialogue": "...",
			"new_statement_id": "s_sarah_hallway_panic",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_sarah_shoe",
			"person_id": "p_sarah",
			"evidence_id": "ev_shoe_print",
			"requires_statement_id": "",
			"target_statement_id": "",
			"target_topic_id": "",
			"impact_level": "MAJOR",
			"reaction_type": "ADMISSION",
			"dialogue": "I heard a female voice from upstairs.",
			"new_statement_id": "s_sarah_heard_voice",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_julia_fingerprint",
			"person_id": "p_julia",
			"evidence_id": "ev_fingerprint",
			"requires_statement_id": "s_julia_was_away",
			"target_statement_id": "s_julia_was_away",
			"target_topic_id": "",
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
			"target_statement_id": "s_julia_was_away",
			"target_topic_id": "",
			"impact_level": "MAJOR",
			"reaction_type": "ADMISSION",
			"dialogue": "Fine, I was there briefly, but I left quickly.",
			"new_statement_id": "s_julia_elevator_admission",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_julia_shoe",
			"person_id": "p_julia",
			"evidence_id": "ev_shoe_print",
			"requires_statement_id": "",
			"target_statement_id": "",
			"target_topic_id": "",
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
			"target_statement_id": "",
			"target_topic_id": "",
			"impact_level": "BREAKPOINT",
			"reaction_type": "PARTIAL_CONFESSION",
			"dialogue": "He was going to ruin everything. I had no choice.",
			"new_statement_id": "s_julia_journal_confession",
			"unlocks": [],
			"pressure_points": 2,
		},
		{
			"id": "trig_lucas_maintenance",
			"person_id": "p_lucas",
			"evidence_id": "ev_maintenance",
			"requires_statement_id": "",
			"target_statement_id": "",
			"target_topic_id": "",
			"impact_level": "MINOR",
			"reaction_type": "DENIAL",
			"dialogue": "I do regular checks. That is my job.",
			"new_statement_id": "s_lucas_denial",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_lucas_key",
			"person_id": "p_lucas",
			"evidence_id": "ev_key_access",
			"requires_statement_id": "",
			"target_statement_id": "",
			"target_topic_id": "",
			"impact_level": "MAJOR",
			"reaction_type": "ADMISSION",
			"dialogue": "I used the key to check a reported leak.",
			"new_statement_id": "s_lucas_key_admission",
			"unlocks": [],
			"pressure_points": 1,
		},
		{
			"id": "trig_mark_deflection",
			"person_id": "p_mark",
			"evidence_id": "ev_no_trigger",
			"requires_statement_id": "",
			"target_statement_id": "",
			"target_topic_id": "",
			"impact_level": "MINOR",
			"reaction_type": "DEFLECTION",
			"dialogue": "You should really talk to Julia about this.",
			"new_statement_id": "",
			"unlocks": [],
			"pressure_points": 0,
			"deflection_target_id": "p_julia",
		},
	],
	"interrogation_sessions": [
		{
			"person_id": "p_mark",
			"initial_dialogue": "Mark sits down and crosses his arms.",
			"initial_statement_ids": ["s_mark_left_early"],
			"base_topic_ids": ["topic_mark_evening"],
			"pressure_gate": 2,
			"rejection_texts": [
				"Mark shakes his head.",
				"That doesn't concern me.",
			],
		},
		{
			"person_id": "p_sarah",
			"initial_dialogue": "Sarah fidgets nervously.",
			"initial_statement_ids": ["s_sarah_was_home"],
			"base_topic_ids": ["topic_sarah_alibi"],
			"pressure_gate": 1,
			"rejection_texts": [
				"Sarah looks confused.",
			],
		},
		{
			"person_id": "p_julia",
			"initial_dialogue": "Julia crosses her arms defiantly.",
			"initial_statement_ids": ["s_julia_was_away"],
			"base_topic_ids": ["topic_julia_whereabouts"],
			"pressure_gate": 2,
			"rejection_texts": [
				"Julia dismisses it.",
			],
		},
		{
			"person_id": "p_lucas",
			"initial_dialogue": "Lucas leans back casually.",
			"initial_statement_ids": [],
			"base_topic_ids": [],
			"pressure_gate": 1,
			"rejection_texts": [],
		},
	],
}


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
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)
	InterrogationManager.reset()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# --- Helpers --- #

## Starts an interrogation with a suspect after discovering needed evidence.
func _start_with(person_id: String, evidence_ids: Array[String] = []) -> void:
	for ev_id: String in evidence_ids:
		GameManager.discover_evidence(ev_id)
	InterrogationManager.start_interrogation(person_id)


## Starts interrogation, advances to INTERROGATION phase, and sets a focus.
func _start_interrogation_with_focus(
	person_id: String,
	evidence_ids: Array[String],
	focus_type: String,
	focus_id: String,
) -> void:
	_start_with(person_id, evidence_ids)
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus(focus_type, focus_id)


# =========================================================================
# Session Lifecycle
# =========================================================================

func test_start_interrogation_succeeds() -> void:
	var result: bool = InterrogationManager.start_interrogation("p_mark")
	assert_true(result, "Should start interrogation successfully")
	assert_true(InterrogationManager.is_active(), "Should be active after start")
	assert_eq(InterrogationManager.get_current_person_id(), "p_mark")


func test_start_interrogation_sets_interrogation_phase() -> void:
	InterrogationManager.start_interrogation("p_mark")
	assert_eq(
		InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION,
		"Should start directly in interrogation phase"
	)


func test_start_interrogation_emits_signals() -> void:
	watch_signals(InterrogationManager)
	InterrogationManager.start_interrogation("p_mark")
	assert_signal_emitted_with_parameters(InterrogationManager, "interrogation_started", ["p_mark"])
	assert_signal_emitted_with_parameters(
		InterrogationManager, "phase_changed", [Enums.InterrogationPhase.INTERROGATION]
	)


func test_start_interrogation_records_initial_statements() -> void:
	InterrogationManager.start_interrogation("p_mark")
	var heard: Array[String] = InterrogationManager.get_heard_statements()
	assert_has(heard, "s_mark_left_early",
		"Should auto-record initial statements from session data")


func test_start_interrogation_fails_when_already_active() -> void:
	InterrogationManager.start_interrogation("p_mark")
	var result: bool = InterrogationManager.start_interrogation("p_sarah")
	assert_false(result, "Should fail when already interrogating")
	assert_eq(InterrogationManager.get_current_person_id(), "p_mark", "Should still be with Mark")


func test_start_interrogation_fails_for_invalid_person() -> void:
	var result: bool = InterrogationManager.start_interrogation("nonexistent")
	assert_false(result, "Should fail for invalid person ID")
	assert_false(InterrogationManager.is_active())
	assert_push_error("[InterrogationManager] Person not found: nonexistent")


func test_end_interrogation() -> void:
	InterrogationManager.start_interrogation("p_mark")
	InterrogationManager.end_interrogation()
	assert_false(InterrogationManager.is_active(), "Should not be active after end")
	assert_eq(InterrogationManager.get_current_person_id(), "", "Person should be cleared")


func test_end_interrogation_emits_signals() -> void:
	InterrogationManager.start_interrogation("p_mark")
	watch_signals(InterrogationManager)
	InterrogationManager.end_interrogation()
	assert_signal_emitted_with_parameters(InterrogationManager, "interrogation_ended", ["p_mark"])


# =========================================================================
# Daily Limit
# =========================================================================

func test_daily_limit_enforced() -> void:
	InterrogationManager.start_interrogation("p_mark")
	InterrogationManager.end_interrogation()
	var result: bool = InterrogationManager.start_interrogation("p_mark")
	assert_false(result, "Should not allow second interrogation of same suspect today")


func test_daily_limit_allows_different_suspect() -> void:
	InterrogationManager.start_interrogation("p_mark")
	InterrogationManager.end_interrogation()
	var result: bool = InterrogationManager.start_interrogation("p_sarah")
	assert_true(result, "Should allow interrogating different suspect same day")


# =========================================================================
# Phase Flow — advance_to_interrogation()
# =========================================================================

func test_advance_to_interrogation_is_noop_when_already_interrogating() -> void:
	InterrogationManager.start_interrogation("p_mark")
	var new_phase: Enums.InterrogationPhase = InterrogationManager.advance_to_interrogation()
	assert_eq(new_phase, Enums.InterrogationPhase.INTERROGATION,
		"Should stay in INTERROGATION when already there")


func test_advance_to_interrogation_does_not_emit_when_already_interrogating() -> void:
	InterrogationManager.start_interrogation("p_mark")
	watch_signals(InterrogationManager)
	InterrogationManager.advance_to_interrogation()
	assert_signal_not_emitted(
		InterrogationManager, "phase_changed"
	)


func test_advance_to_interrogation_fails_from_wrong_phase() -> void:
	InterrogationManager.start_interrogation("p_mark")
	InterrogationManager.advance_to_interrogation()  # → INTERROGATION
	var phase: Enums.InterrogationPhase = InterrogationManager.advance_to_interrogation()
	assert_eq(phase, Enums.InterrogationPhase.INTERROGATION,
		"Should stay in current phase when already past STATEMENT_INTAKE")


# =========================================================================
# Focus Selection
# =========================================================================

func test_select_focus_statement() -> void:
	InterrogationManager.start_interrogation("p_mark")
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	var focus: Dictionary = InterrogationManager.get_current_focus()
	assert_eq(focus.get("type", ""), "statement")
	assert_eq(focus.get("id", ""), "s_mark_left_early")


func test_select_focus_topic() -> void:
	InterrogationManager.start_interrogation("p_mark")
	InterrogationManager.select_focus("topic", "topic_mark_evening")
	var focus: Dictionary = InterrogationManager.get_current_focus()
	assert_eq(focus.get("type", ""), "topic")
	assert_eq(focus.get("id", ""), "topic_mark_evening")


func test_select_focus_emits_signal() -> void:
	InterrogationManager.start_interrogation("p_mark")
	watch_signals(InterrogationManager)
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	assert_signal_emitted(InterrogationManager, "focus_changed")


func test_clear_focus() -> void:
	InterrogationManager.start_interrogation("p_mark")
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	InterrogationManager.clear_focus()
	assert_true(InterrogationManager.get_current_focus().is_empty(),
		"Focus should be empty after clearing")


func test_select_focus_invalid_type_errors() -> void:
	InterrogationManager.start_interrogation("p_mark")
	InterrogationManager.select_focus("invalid", "some_id")
	assert_push_error("[InterrogationManager] Invalid focus type: invalid")


# =========================================================================
# Evidence Presentation — Focus Required
# =========================================================================

func test_present_evidence_without_focus_returns_no_focus() -> void:
	_start_with("p_mark", ["ev_financial"])
	InterrogationManager.advance_to_interrogation()
	var result: Dictionary = InterrogationManager.present_evidence("ev_financial")
	assert_false(result.get("triggered", true))
	assert_eq(result.get("reason", ""), "no_focus",
		"Should require focus to be set before presenting evidence")


func test_present_evidence_matching_trigger_fires() -> void:
	_start_with("p_mark", ["ev_financial"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	var result: Dictionary = InterrogationManager.present_evidence("ev_financial")
	assert_true(result.get("triggered", false), "Trigger should fire for matching evidence")
	assert_eq(result.get("trigger_id", ""), "trig_mark_financial")


func test_present_evidence_no_match_returns_not_triggered() -> void:
	_start_with("p_mark", ["ev_hallway_camera"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	var result: Dictionary = InterrogationManager.present_evidence("ev_hallway_camera")
	assert_false(result.get("triggered", true), "Should not trigger for non-matching evidence")


func test_present_evidence_already_fired_returns_not_triggered() -> void:
	_start_with("p_mark", ["ev_financial"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	InterrogationManager.present_evidence("ev_financial")
	var result: Dictionary = InterrogationManager.present_evidence("ev_financial")
	assert_false(result.get("triggered", true), "Already-fired trigger should not fire again")
	assert_true(result.get("already_fired", false))


func test_present_evidence_records_new_statement() -> void:
	_start_with("p_mark", ["ev_financial"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	InterrogationManager.present_evidence("ev_financial")
	var heard: Array[String] = InterrogationManager.get_heard_statements()
	assert_has(heard, "s_mark_embezzlement", "New statement should be recorded")


func test_present_evidence_unlocks_evidence() -> void:
	_start_with("p_mark", ["ev_financial"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	InterrogationManager.present_evidence("ev_financial")
	assert_true(GameManager.has_evidence("ev_unlocked_clue"), "Unlocked evidence should be discovered")


func test_present_evidence_emits_trigger_fired() -> void:
	_start_with("p_mark", ["ev_financial"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	watch_signals(InterrogationManager)
	InterrogationManager.present_evidence("ev_financial")
	assert_signal_emitted(InterrogationManager, "trigger_fired")


func test_present_evidence_emits_statement_recorded() -> void:
	_start_with("p_mark", ["ev_financial"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	watch_signals(InterrogationManager)
	InterrogationManager.present_evidence("ev_financial")
	assert_signal_emitted_with_parameters(
		InterrogationManager, "statement_recorded", ["s_mark_embezzlement"]
	)


# =========================================================================
# requires_statement_id — Prerequisite Gating
# =========================================================================

func test_requires_statement_weakens_when_not_heard() -> void:
	# trig_mark_camera requires s_mark_left_early heard; session auto-records it,
	# but we need a fresh session without auto-record. Use lucas who has no initial stmts,
	# then test with a mark trigger that requires a statement not yet heard.
	# Actually mark auto-records s_mark_left_early — so prerequisite IS met.
	# Instead, test with safe trigger which requires s_mark_embezzlement (NOT auto-heard).
	_start_with("p_mark", ["ev_safe"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_embezzlement")
	var result: Dictionary = InterrogationManager.present_evidence("ev_safe")
	assert_true(result.get("triggered", false), "Should still fire")
	assert_true(result.get("weakened", false), "Should be weakened without prerequisite")
	assert_eq(result.get("impact_level", -1), Enums.ImpactLevel.MAJOR,
		"BREAKPOINT → MAJOR when weakened")


func test_requires_statement_full_strength_when_heard() -> void:
	_start_with("p_mark", ["ev_financial", "ev_safe"])
	InterrogationManager.advance_to_interrogation()
	# Fire financial trigger first to hear s_mark_embezzlement (prereq for safe)
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	InterrogationManager.present_evidence("ev_financial")
	# Now present safe evidence with embezzlement as focus (prereq now met)
	InterrogationManager.select_focus("statement", "s_mark_embezzlement")
	var result: Dictionary = InterrogationManager.present_evidence("ev_safe")
	assert_true(result.get("triggered", false))
	assert_false(result.get("weakened", false), "Should not be weakened when prerequisite met")
	assert_eq(result.get("impact_level", -1), Enums.ImpactLevel.BREAKPOINT)


func test_requires_statement_pressure_halved_when_weakened() -> void:
	# trig_mark_safe has pressure_points=1 and requires s_mark_embezzlement;
	# without hearing it, weakened → 1/2=0
	_start_with("p_mark", ["ev_safe"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_embezzlement")
	var result: Dictionary = InterrogationManager.present_evidence("ev_safe")
	assert_eq(result.get("pressure_added", -1), 0,
		"Pressure should be halved (1/2=0 floor) when weakened")


# =========================================================================
# Pressure System
# =========================================================================

func test_pressure_accumulates() -> void:
	_start_with("p_mark", ["ev_financial", "ev_parking_camera"])
	InterrogationManager.advance_to_interrogation()

	# Present financial evidence (no prereq needed, trig_mark_financial) +1
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	InterrogationManager.present_evidence("ev_financial")

	# s_mark_left_early is auto-recorded (prereq for camera trigger), so full strength +1
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	InterrogationManager.present_evidence("ev_parking_camera")

	assert_eq(InterrogationManager.get_current_pressure(), 2, "Pressure should be 2")


func test_pressure_emits_signal() -> void:
	_start_with("p_mark", ["ev_financial"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	watch_signals(InterrogationManager)
	InterrogationManager.present_evidence("ev_financial")
	assert_signal_emitted(InterrogationManager, "pressure_changed")


func test_break_moment_at_threshold() -> void:
	# Mark threshold=3. Fire 3 triggers to reach it.
	_start_with("p_mark", ["ev_financial", "ev_parking_camera", "ev_safe"])
	InterrogationManager.advance_to_interrogation()

	# s_mark_left_early is auto-heard. Present camera → +1
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	InterrogationManager.present_evidence("ev_parking_camera")  # +1 → pressure=1

	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	InterrogationManager.present_evidence("ev_financial")       # +1 → pressure=2

	# s_mark_embezzlement heard from trigger. Now safe trigger prereq met.
	InterrogationManager.select_focus("statement", "s_mark_embezzlement")
	InterrogationManager.present_evidence("ev_safe")            # +1 → pressure=3 = threshold

	# Break triggers via apply_pressure, not during evidence
	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(result.get("break_moment", false),
		"Break moment should be reached at threshold")
	assert_true(InterrogationManager.has_break_moment("p_mark"),
		"Break moment should be recorded")


func test_break_moment_emits_signal() -> void:
	_start_with("p_mark", ["ev_financial", "ev_parking_camera", "ev_safe"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	InterrogationManager.present_evidence("ev_financial")
	InterrogationManager.select_focus("statement", "s_mark_embezzlement")
	InterrogationManager.present_evidence("ev_safe")
	watch_signals(InterrogationManager)
	InterrogationManager.apply_pressure()
	assert_signal_emitted_with_parameters(InterrogationManager, "break_moment_reached", ["p_mark"])


func test_break_moment_changes_phase() -> void:
	_start_with("p_mark", ["ev_financial", "ev_parking_camera", "ev_safe"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	InterrogationManager.present_evidence("ev_financial")
	InterrogationManager.select_focus("statement", "s_mark_embezzlement")
	InterrogationManager.present_evidence("ev_safe")
	InterrogationManager.apply_pressure()
	assert_eq(InterrogationManager.get_current_phase(), Enums.InterrogationPhase.BREAK_MOMENT)


func test_break_moment_persists_across_sessions() -> void:
	_start_with("p_mark", ["ev_financial", "ev_parking_camera", "ev_safe"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	InterrogationManager.present_evidence("ev_financial")
	InterrogationManager.select_focus("statement", "s_mark_embezzlement")
	InterrogationManager.present_evidence("ev_safe")
	InterrogationManager.apply_pressure()
	InterrogationManager.end_interrogation()
	assert_true(InterrogationManager.has_break_moment("p_mark"),
		"Break moment should persist after session ends")


# =========================================================================
# Personality Traits
# =========================================================================

func test_personality_aggressive_denial_becomes_anger() -> void:
	# Mark is AGGRESSIVE. trig_mark_camera has DENIAL reaction.
	# s_mark_left_early auto-heard (prereq met), DENIAL → ANGER
	_start_with("p_mark", ["ev_parking_camera"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	var result: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_eq(result.get("reaction_type", -1), Enums.ReactionType.ANGER,
		"Aggressive personality should convert DENIAL to ANGER")


func test_personality_anxious_silence_becomes_panic() -> void:
	# Sarah is ANXIOUS. trig_sarah_hallway has SILENCE reaction.
	# s_sarah_was_home auto-heard from session (prereq met).
	_start_with("p_sarah", ["ev_hallway_camera"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_sarah_was_home")
	var result: Dictionary = InterrogationManager.present_evidence("ev_hallway_camera")
	assert_eq(result.get("reaction_type", -1), Enums.ReactionType.PANIC,
		"Anxious personality should convert SILENCE to PANIC")


func test_personality_manipulative_minor_becomes_deflection() -> void:
	# Julia is MANIPULATIVE. trig_julia_fingerprint is MINOR impact, DENIAL reaction.
	# s_julia_was_away auto-heard (prereq met). MINOR + MANIPULATIVE → DEFLECTION
	_start_with("p_julia", ["ev_fingerprint"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_julia_was_away")
	var result: Dictionary = InterrogationManager.present_evidence("ev_fingerprint")
	assert_eq(result.get("reaction_type", -1), Enums.ReactionType.DEFLECTION,
		"Manipulative personality should convert MINOR triggers to DEFLECTION")


func test_personality_calm_minor_no_pressure() -> void:
	# Lucas is CALM. trig_lucas_maintenance is MINOR impact with 1 pressure_point.
	# Lucas has no auto-heard initial statements, but trigger has no prereq.
	_start_with("p_lucas", ["ev_maintenance"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_lucas_denial")
	var result: Dictionary = InterrogationManager.present_evidence("ev_maintenance")
	assert_eq(result.get("pressure_added", -1), 0,
		"Calm personality should suppress pressure from MINOR triggers")


# =========================================================================
# Deflection Reaction
# =========================================================================

func test_deflection_references_target() -> void:
	_start_with("p_mark", ["ev_no_trigger"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	var result: Dictionary = InterrogationManager.present_evidence("ev_no_trigger")
	assert_true(result.get("triggered", false))
	assert_eq(result.get("deflection_target_id", ""), "p_julia",
		"Deflection should reference target suspect")


# =========================================================================
# Topic Discussion
# =========================================================================

func test_discuss_topic_produces_statements() -> void:
	InterrogationManager.start_interrogation("p_mark")
	var result: Dictionary = InterrogationManager.discuss_topic("topic_mark_evening")
	var stmts: Array = result.get("statements", [])
	# s_mark_left_early is auto-recorded by session data, so discuss_topic
	# should still return it but it may already be in heard_statements.
	assert_eq(stmts.size(), 1)
	assert_eq(stmts[0], "s_mark_left_early")


func test_discuss_topic_records_heard_statements() -> void:
	InterrogationManager.start_interrogation("p_mark")
	InterrogationManager.discuss_topic("topic_mark_evening")
	assert_has(InterrogationManager.get_heard_statements(), "s_mark_left_early")


func test_discuss_topic_wrong_person_fails() -> void:
	InterrogationManager.start_interrogation("p_mark")
	var result: Dictionary = InterrogationManager.discuss_topic("topic_sarah_alibi")
	assert_eq(result.size(), 0, "Should return empty for wrong person's topic")
	assert_push_error("[InterrogationManager] Topic topic_sarah_alibi does not belong to p_mark")


# =========================================================================
# Topic Availability
# =========================================================================

func test_available_topics_includes_base_topics() -> void:
	InterrogationManager.start_interrogation("p_mark")
	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids: Array[String] = []
	for t: InterrogationTopicData in topics:
		ids.append(t.id)
	assert_has(ids, "topic_mark_evening", "Base topic from session should be available")
	assert_does_not_have(ids, "topic_mark_finances", "Conditional topic should not be available yet")


func test_available_topics_with_evidence_condition() -> void:
	GameManager.discover_evidence("ev_financial")
	InterrogationManager.start_interrogation("p_mark")
	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids: Array[String] = []
	for t: InterrogationTopicData in topics:
		ids.append(t.id)
	assert_has(ids, "topic_mark_finances", "Topic with evidence condition met should be available")


func test_available_topics_requires_statement() -> void:
	GameManager.discover_evidence("ev_elevator_log")
	InterrogationManager.start_interrogation("p_julia")
	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids: Array[String] = []
	for t: InterrogationTopicData in topics:
		ids.append(t.id)
	# s_julia_was_away is auto-recorded from session, so topic_julia_locked prereq IS met.
	# But topic_julia_locked also requires ev_elevator_log which we discovered above.
	assert_has(ids, "topic_julia_locked",
		"Topic should be available when statement auto-heard and evidence discovered")


# =========================================================================
# Contradiction Detection
# =========================================================================

func test_contradicted_statements_with_evidence() -> void:
	GameManager.discover_evidence("ev_parking_camera")
	InterrogationManager.start_interrogation("p_mark")
	# s_mark_left_early auto-heard from session data → contradicts ev_parking_camera
	var contradicted: Array[Dictionary] = InterrogationManager.get_contradicted_statements()
	assert_eq(contradicted.size(), 1, "Should find one contradicted statement")
	assert_eq(contradicted[0].get("statement_id", ""), "s_mark_left_early")


func test_contradicted_statements_without_evidence() -> void:
	# No contradicting evidence discovered
	InterrogationManager.start_interrogation("p_mark")
	# s_mark_left_early heard but no ev_parking_camera discovered
	var contradicted: Array[Dictionary] = InterrogationManager.get_contradicted_statements()
	assert_eq(contradicted.size(), 0, "No contradictions without relevant evidence")


# =========================================================================
# Contradiction Logging via Focus
# =========================================================================

func test_contradiction_logged_on_focused_evidence() -> void:
	_start_with("p_mark", ["ev_parking_camera"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	watch_signals(InterrogationManager)
	InterrogationManager.present_evidence("ev_parking_camera")
	assert_signal_emitted(InterrogationManager, "contradiction_logged")
	var contras: Array[Dictionary] = InterrogationManager.get_session_contradictions()
	assert_eq(contras.size(), 1)
	assert_eq(contras[0].get("statement_id", ""), "s_mark_left_early")
	assert_eq(contras[0].get("evidence_id", ""), "ev_parking_camera")


func test_contradiction_not_duplicated() -> void:
	_start_with("p_sarah", ["ev_hallway_camera", "ev_shoe_print"])
	InterrogationManager.advance_to_interrogation()
	# Present hallway camera against same focus twice (second time already_fired)
	InterrogationManager.select_focus("statement", "s_sarah_was_home")
	InterrogationManager.present_evidence("ev_hallway_camera")
	InterrogationManager.present_evidence("ev_hallway_camera")  # already fired
	var contras: Array[Dictionary] = InterrogationManager.get_session_contradictions()
	assert_eq(contras.size(), 1, "Should not duplicate contradictions")


# =========================================================================
# Apply Pressure — Contradiction Gating
# =========================================================================

func test_apply_pressure_fails_without_enough_contradictions() -> void:
	# Mark's pressure_gate is 2
	_start_with("p_mark", ["ev_parking_camera"])
	InterrogationManager.advance_to_interrogation()
	# Only 1 contradiction
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	InterrogationManager.present_evidence("ev_parking_camera")
	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_false(result.get("success", true))
	assert_eq(result.get("reason", ""), "insufficient_contradictions")


func test_can_apply_pressure_returns_false_below_gate() -> void:
	_start_with("p_mark", ["ev_parking_camera"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	InterrogationManager.present_evidence("ev_parking_camera")  # 1 contradiction
	assert_false(InterrogationManager.can_apply_pressure(),
		"Should not be able to apply pressure with < gate contradictions")


func test_apply_pressure_succeeds_at_gate() -> void:
	# Mark gate is 2, need 2 contradictions
	_start_with("p_mark", ["ev_parking_camera", "ev_financial"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_mark_left_early")
	InterrogationManager.present_evidence("ev_parking_camera")  # contradiction 1
	InterrogationManager.select_focus("statement", "s_mark_financial_denial")
	InterrogationManager.present_evidence("ev_financial")  # contradiction 2
	assert_true(InterrogationManager.can_apply_pressure())
	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(result.get("success", false))
	assert_eq(InterrogationManager.get_current_phase(), Enums.InterrogationPhase.PRESSURE)


func test_apply_pressure_with_sarah_lower_gate() -> void:
	# Sarah gate is 1
	_start_with("p_sarah", ["ev_hallway_camera"])
	InterrogationManager.advance_to_interrogation()
	InterrogationManager.select_focus("statement", "s_sarah_was_home")
	InterrogationManager.present_evidence("ev_hallway_camera")  # 1 contradiction
	assert_true(InterrogationManager.can_apply_pressure())
	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(result.get("success", false))


# =========================================================================
# Session Data — Initial Dialogue & Rejection Text
# =========================================================================

func test_initial_dialogue_returned() -> void:
	InterrogationManager.start_interrogation("p_mark")
	var dialogue: String = InterrogationManager.get_initial_dialogue()
	assert_eq(dialogue, "Mark sits down and crosses his arms.")


func test_rejection_text_returned() -> void:
	InterrogationManager.start_interrogation("p_mark")
	var text: String = InterrogationManager.get_rejection_text()
	assert_true(
		text == "Mark shakes his head." or text == "That doesn't concern me.",
		"Should return one of Mark's rejection texts"
	)


func test_rejection_text_fallback_for_empty() -> void:
	# Lucas has empty rejection_texts
	InterrogationManager.start_interrogation("p_lucas")
	var text: String = InterrogationManager.get_rejection_text()
	assert_true(not text.is_empty(), "Should return a default rejection text")


# =========================================================================
# InterrogationTriggerData Resource
# =========================================================================

func test_trigger_data_from_dict() -> void:
	var data: Dictionary = {
		"id": "test_trig",
		"person_id": "p_test",
		"evidence_id": "ev_test",
		"requires_statement_id": "s_test",
		"target_statement_id": "s_test",
		"target_topic_id": "",
		"impact_level": "BREAKPOINT",
		"reaction_type": "REVELATION",
		"dialogue": "I reveal everything.",
		"new_statement_id": "s_new",
		"unlocks": ["ev_unlock"],
		"pressure_points": 2,
		"deflection_target_id": "p_other",
	}
	var trigger: InterrogationTriggerData = InterrogationTriggerData.from_dict(data)
	assert_eq(trigger.id, "test_trig")
	assert_eq(trigger.person_id, "p_test")
	assert_eq(trigger.evidence_id, "ev_test")
	assert_eq(trigger.requires_statement_id, "s_test")
	assert_eq(trigger.target_statement_id, "s_test")
	assert_eq(trigger.target_topic_id, "")
	assert_eq(trigger.impact_level, Enums.ImpactLevel.BREAKPOINT)
	assert_eq(trigger.reaction_type, Enums.ReactionType.REVELATION)
	assert_eq(trigger.dialogue, "I reveal everything.")
	assert_eq(trigger.new_statement_id, "s_new")
	assert_eq(trigger.unlocks.size(), 1)
	assert_eq(trigger.pressure_points, 2)
	assert_eq(trigger.deflection_target_id, "p_other")


func test_trigger_data_validate_valid() -> void:
	var trigger: InterrogationTriggerData = InterrogationTriggerData.from_dict({
		"id": "t1", "person_id": "p1", "evidence_id": "e1", "dialogue": "text",
		"target_statement_id": "s1",
	})
	assert_eq(trigger.validate().size(), 0, "Valid trigger should have no errors")


func test_trigger_data_validate_missing_fields() -> void:
	var trigger: InterrogationTriggerData = InterrogationTriggerData.from_dict({})
	var errors: Array[String] = trigger.validate()
	assert_true(errors.size() >= 3, "Should have validation errors for missing fields")


func test_trigger_data_validate_deflection_without_target() -> void:
	var trigger: InterrogationTriggerData = InterrogationTriggerData.from_dict({
		"id": "t1", "person_id": "p1", "evidence_id": "e1", "dialogue": "text",
		"target_statement_id": "s1",
		"reaction_type": "DEFLECTION",
	})
	var errors: Array[String] = trigger.validate()
	assert_true(errors.size() > 0, "DEFLECTION without deflection_target_id should produce error")


func test_trigger_data_to_dict_roundtrip() -> void:
	var original: Dictionary = {
		"id": "rt_trig", "person_id": "p_rt", "evidence_id": "ev_rt",
		"impact_level": "MAJOR", "reaction_type": "ANGER",
		"dialogue": "Test roundtrip", "pressure_points": 1,
	}
	var trigger: InterrogationTriggerData = InterrogationTriggerData.from_dict(original)
	var exported: Dictionary = trigger.to_dict()
	assert_eq(exported["id"], "rt_trig")
	assert_eq(exported["impact_level"], "MAJOR")
	assert_eq(exported["reaction_type"], "ANGER")


# =========================================================================
# CaseManager Integration — Trigger Queries
# =========================================================================

func test_case_manager_get_interrogation_trigger() -> void:
	var trigger: InterrogationTriggerData = CaseManager.get_interrogation_trigger("trig_mark_camera")
	assert_not_null(trigger, "Should find trigger by ID")
	assert_eq(trigger.person_id, "p_mark")


func test_case_manager_get_triggers_for_person() -> void:
	var triggers: Array[InterrogationTriggerData] = CaseManager.get_interrogation_triggers_for_person("p_mark")
	# Mark has 4 triggers: camera, financial, safe, deflection
	assert_eq(triggers.size(), 4, "Mark should have 4 triggers")


func test_case_manager_get_trigger_by_evidence() -> void:
	var trigger: InterrogationTriggerData = CaseManager.get_trigger_by_evidence("p_mark", "ev_parking_camera")
	assert_not_null(trigger, "Should find trigger by evidence")
	assert_eq(trigger.id, "trig_mark_camera")


func test_case_manager_get_trigger_by_evidence_no_match() -> void:
	var trigger: InterrogationTriggerData = CaseManager.get_trigger_by_evidence("p_mark", "ev_fingerprint")
	assert_null(trigger, "Should return null for non-matching evidence")


func test_case_manager_get_all_interrogation_triggers() -> void:
	var all_triggers: Array[InterrogationTriggerData] = CaseManager.get_all_interrogation_triggers()
	assert_eq(all_triggers.size(), 12, "Should have 12 total triggers")
