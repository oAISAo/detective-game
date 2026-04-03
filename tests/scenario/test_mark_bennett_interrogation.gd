## test_mark_bennett_interrogation.gd
## Scenario tests for Mark Bennett's interrogation using the real riverside_apartment case data.
## Validates the complete interrogation loop: statements, topics, triggers,
## pressure, break sequence, contradiction history, and rejection feedback.
extends GutTest


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case_folder("riverside_apartment")
	InterrogationManager.reset()


func after_each() -> void:
	if InterrogationManager.is_active():
		InterrogationManager.end_interrogation()
	CaseManager.unload_case()


## Start interrogation (now starts directly in INTERROGATION phase).
func _start_and_advance() -> void:
	InterrogationManager.start_interrogation("p_mark")


# =========================================================================
# Test 1: Initial dialogue creates the correct statement entries
# =========================================================================

func test_initial_dialogue_creates_correct_statements() -> void:
	InterrogationManager.start_interrogation("p_mark")

	var dialogue: String = InterrogationManager.get_initial_dialogue()
	assert_true(dialogue.length() > 0, "Initial dialogue should not be empty")
	assert_true(dialogue.find("I already told the police") >= 0,
		"Initial dialogue should contain opening line")

	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_eq(stmts.size(), 3, "Should have 3 initial statements")
	assert_has(stmts, "stmt_mark_visit", "Should include visit statement")
	assert_has(stmts, "stmt_mark_argument", "Should include argument statement")
	assert_has(stmts, "stmt_mark_departure_time", "Should include departure time statement")


# =========================================================================
# Test 2: Base topics appear on interrogation start
# =========================================================================

func test_base_topics_appear_on_start() -> void:
	_start_and_advance()

	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var topic_ids: Array[String] = []
	for t: InterrogationTopicData in topics:
		topic_ids.append(t.id)

	assert_has(topic_ids, "topic_reason_for_visit", "Should have reason for visit topic")
	assert_has(topic_ids, "topic_departure_time", "Should have departure time topic")
	assert_has(topic_ids, "topic_relationship", "Should have relationship topic")
	assert_does_not_have(topic_ids, "topic_why_lie_about_time",
		"Unlockable topic should not appear at start")
	assert_does_not_have(topic_ids, "topic_missing_money",
		"Unlockable topic should not appear at start")
	assert_does_not_have(topic_ids, "topic_who_else_knew",
		"Break-unlocked topic should not appear at start")


# =========================================================================
# Test 3: Current Focus updates correctly
# =========================================================================

func test_focus_updates_correctly_statement() -> void:
	_start_and_advance()

	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	var focus: Dictionary = InterrogationManager.get_current_focus()
	assert_eq(focus.get("type", ""), "statement")
	assert_eq(focus.get("id", ""), "stmt_mark_departure_time")


func test_focus_updates_correctly_topic() -> void:
	_start_and_advance()

	InterrogationManager.select_focus("topic", "topic_departure_time")
	var focus: Dictionary = InterrogationManager.get_current_focus()
	assert_eq(focus.get("type", ""), "topic")
	assert_eq(focus.get("id", ""), "topic_departure_time")


# =========================================================================
# Test 4: E14 only works against departure-related focus
# =========================================================================

func test_parking_camera_only_works_against_departure_focus() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	# Wrong focus: visit statement
	InterrogationManager.select_focus("statement", "stmt_mark_visit")
	var result: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_false(result.get("triggered", false),
		"Parking camera should not trigger against visit statement")

	# Wrong focus: argument statement
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	result = InterrogationManager.present_evidence("ev_parking_camera")
	assert_false(result.get("triggered", false),
		"Parking camera should not trigger against argument statement")

	# Wrong focus: relationship topic
	InterrogationManager.select_focus("topic", "topic_relationship")
	result = InterrogationManager.present_evidence("ev_parking_camera")
	assert_false(result.get("triggered", false),
		"Parking camera should not trigger against relationship topic")

	# Correct focus: departure time statement
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	result = InterrogationManager.present_evidence("ev_parking_camera")
	assert_true(result.get("triggered", false),
		"Parking camera should trigger against departure time statement")


func test_parking_camera_works_against_departure_topic() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	InterrogationManager.select_focus("topic", "topic_departure_time")
	var result: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_true(result.get("triggered", false),
		"Parking camera should trigger against departure time topic")


func test_parking_camera_works_against_reinforced_statement() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	# First discuss the departure topic to produce the reinforced statement
	InterrogationManager.discuss_topic("topic_departure_time")

	InterrogationManager.select_focus("statement", "stmt_mark_departure_reinforced")
	var result: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_true(result.get("triggered", false),
		"Parking camera should trigger against reinforced departure statement")


# =========================================================================
# Test 5: E14 creates contradiction and pressure correctly
# =========================================================================

func test_parking_camera_creates_contradiction_and_pressure() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	var result: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")

	assert_true(result.get("triggered", false), "Should trigger")
	assert_eq(result.get("pressure_added", 0), 1, "Should add 1 pressure point")
	assert_true(result.get("dialogue", "").find("20:40") >= 0,
		"Dialogue should mention the corrected time")

	# Check contradiction was logged
	var contradictions: Array[Dictionary] = InterrogationManager.get_session_contradictions()
	assert_eq(contradictions.size(), 1, "Should have 1 contradiction")
	assert_eq(contradictions[0].get("statement_id", ""), "stmt_mark_departure_time")
	assert_eq(contradictions[0].get("evidence_id", ""), "ev_parking_camera")

	# Check new statement was recorded
	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_mark_corrected_departure",
		"Corrected departure statement should be recorded")

	# Check pressure level
	assert_eq(InterrogationManager.get_current_pressure(), 1,
		"Pressure should be 1 after first trigger")


# =========================================================================
# Test 6: topic_why_lie_about_time unlocks correctly
# =========================================================================

func test_why_lie_topic_unlocks_after_first_contradiction() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	# Before trigger, topic should not be available
	var topics_before: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids_before: Array[String] = []
	for t: InterrogationTopicData in topics_before:
		ids_before.append(t.id)
	assert_does_not_have(ids_before, "topic_why_lie_about_time",
		"Why-lie topic should not be available before trigger")

	# Fire parking camera trigger
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")

	# After trigger, topic should be available
	var topics_after: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids_after: Array[String] = []
	for t: InterrogationTopicData in topics_after:
		ids_after.append(t.id)
	assert_has(ids_after, "topic_why_lie_about_time",
		"Why-lie topic should be available after first trigger")


# =========================================================================
# Test 7: E11 only works against valid focus
# =========================================================================

func test_bank_transfer_only_works_against_valid_focus() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_bank_transfer")

	# Wrong focus: departure time
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	var result: Dictionary = InterrogationManager.present_evidence("ev_bank_transfer")
	assert_false(result.get("triggered", false),
		"Bank transfer should not trigger against departure statement")

	# Wrong focus: visit statement
	InterrogationManager.select_focus("statement", "stmt_mark_visit")
	result = InterrogationManager.present_evidence("ev_bank_transfer")
	assert_false(result.get("triggered", false),
		"Bank transfer should not trigger against visit statement")

	# Correct focus: argument statement
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	result = InterrogationManager.present_evidence("ev_bank_transfer")
	assert_true(result.get("triggered", false),
		"Bank transfer should trigger against argument statement")


func test_bank_transfer_works_against_relationship_topic() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_bank_transfer")

	InterrogationManager.select_focus("topic", "topic_relationship")
	var result: Dictionary = InterrogationManager.present_evidence("ev_bank_transfer")
	assert_true(result.get("triggered", false),
		"Bank transfer should trigger against relationship topic")


func test_bank_transfer_works_against_why_lie_topic() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# First unlock topic_why_lie_about_time
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")

	InterrogationManager.select_focus("topic", "topic_why_lie_about_time")
	var result: Dictionary = InterrogationManager.present_evidence("ev_bank_transfer")
	assert_true(result.get("triggered", false),
		"Bank transfer should trigger against why-lie topic")


# =========================================================================
# Test 8: E11 increases pressure and unlocks topic_missing_money
# =========================================================================

func test_bank_transfer_increases_pressure_and_unlocks_missing_money() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_bank_transfer")

	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	var result: Dictionary = InterrogationManager.present_evidence("ev_bank_transfer")

	assert_true(result.get("triggered", false), "Should trigger")
	assert_eq(result.get("pressure_added", 0), 1, "Should add 1 pressure point")

	# Check new statement
	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_mark_denies_financial",
		"Financial denial statement should be recorded")

	# Check topic_missing_money is now available
	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var topic_ids: Array[String] = []
	for t: InterrogationTopicData in topics:
		topic_ids.append(t.id)
	assert_has(topic_ids, "topic_missing_money",
		"Missing money topic should be unlocked")


# =========================================================================
# Test 9: Apply Pressure is blocked below threshold
# =========================================================================

func test_apply_pressure_blocked_with_no_pressure() -> void:
	_start_and_advance()

	assert_false(InterrogationManager.can_apply_pressure(),
		"Should not be able to apply pressure with 0 pressure")

	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_false(result.get("success", true), "Apply pressure should fail")
	assert_eq(result.get("reason", ""), "insufficient_pressure")


# =========================================================================
# Test 10: Apply Pressure fails with only 1 pressure (gate is 2)
# =========================================================================

func test_apply_pressure_fails_at_one_pressure() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	# Fire first trigger to get 1 pressure
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	assert_eq(InterrogationManager.get_current_pressure(), 1)

	assert_false(InterrogationManager.can_apply_pressure(),
		"Should NOT be able to apply pressure with 1/2 pressure")

	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_false(result.get("success", true),
		"Apply pressure should fail below gate")
	assert_eq(result.get("reason", ""), "insufficient_pressure")


# =========================================================================
# Test 11: Apply Pressure triggers break sequence at threshold 2
# =========================================================================

func test_apply_pressure_triggers_break_at_two_pressure() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# Trigger 1: parking camera → +1 pressure
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	assert_eq(InterrogationManager.get_current_pressure(), 1)

	# Trigger 2: bank transfer → +1 pressure (total 2)
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")
	assert_eq(InterrogationManager.get_current_pressure(), 2)

	# Apply pressure → should trigger break
	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(result.get("success", false), "Apply pressure should succeed")
	assert_true(result.get("break_moment", false), "Should trigger break moment")
	assert_true(result.get("dialogue", "").find("Daniel found out") >= 0,
		"Break dialogue should mention Daniel finding out")

	# Check break effects
	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_mark_deeper_admission",
		"Break should produce deeper admission statement")

	# Check topic_who_else_knew is now available
	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var topic_ids: Array[String] = []
	for t: InterrogationTopicData in topics:
		topic_ids.append(t.id)
	assert_has(topic_ids, "topic_who_else_knew",
		"Who-else-knew topic should be unlocked by break")

	# Verify break moment is recorded
	assert_true(InterrogationManager.has_break_moment("p_mark"),
		"Break moment should be recorded for Mark")


# =========================================================================
# Test 12: Contradiction history is stored correctly
# =========================================================================

func test_contradiction_history_stored_correctly() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# First contradiction
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")

	var contradictions: Array[Dictionary] = InterrogationManager.get_session_contradictions()
	assert_eq(contradictions.size(), 1, "Should have 1 contradiction after first trigger")
	assert_eq(contradictions[0].get("statement_id", ""), "stmt_mark_departure_time")
	assert_eq(contradictions[0].get("evidence_id", ""), "ev_parking_camera")

	# Second contradiction (against statement focus)
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")

	contradictions = InterrogationManager.get_session_contradictions()
	assert_eq(contradictions.size(), 2, "Should have 2 contradictions after second trigger")
	assert_eq(contradictions[1].get("statement_id", ""), "stmt_mark_argument")
	assert_eq(contradictions[1].get("evidence_id", ""), "ev_bank_transfer")


# =========================================================================
# Test 13: Incorrect evidence produces natural rejection feedback
# =========================================================================

func test_incorrect_evidence_produces_rejection_text() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_knife")

	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	var result: Dictionary = InterrogationManager.present_evidence("ev_knife")
	assert_false(result.get("triggered", false), "Wrong evidence should not trigger")

	# The rejection text should come from the session's rejection_texts pool
	var rejection: String = InterrogationManager.get_rejection_text()
	assert_true(rejection.length() > 0, "Rejection text should not be empty")

	# Verify it's one of the defined texts (or a default)
	var expected_rejections: Array[String] = [
		"He barely reacts to that.",
		"That doesn't seem to shake his story.",
		"He dismisses it immediately.",
		"That isn't enough to challenge this point.",
	]
	var default_rejections: Array[String] = [
		"He barely reacts to that.",
		"That doesn't seem to shake his story.",
		"He dismisses it immediately.",
		"She looks at you blankly.",
		"That doesn't get a reaction.",
	]
	var all_valid: Array[String] = []
	all_valid.append_array(expected_rejections)
	all_valid.append_array(default_rejections)
	assert_has(all_valid, rejection, "Rejection should be from valid pool")


# =========================================================================
# Test 14: Full Mark interrogation works end-to-end
# =========================================================================

func test_full_mark_interrogation_end_to_end() -> void:
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")
	GameManager.discover_evidence("ev_hidden_safe")

	# --- Step 1: Start interrogation ---
	var started: bool = InterrogationManager.start_interrogation("p_mark")
	assert_true(started, "Interrogation should start")
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION)

	# Check initial statements
	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_eq(stmts.size(), 3, "Should have 3 initial statements")

	# --- Step 2: Discuss departure topic ---
	var topic_result: Dictionary = InterrogationManager.discuss_topic("topic_departure_time")
	assert_has(topic_result.get("statements", []), "stmt_mark_departure_reinforced",
		"Topic should produce reinforced statement")
	assert_true(topic_result.get("dialogue", "").find("20:30") >= 0,
		"Topic dialogue should mention time")

	# --- Step 4: Present parking camera against departure time ---
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	var r1: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_true(r1.get("triggered", false), "Trigger 1 should fire")
	assert_eq(InterrogationManager.get_current_pressure(), 1)
	assert_has(InterrogationManager.get_session_statements(),
		"stmt_mark_corrected_departure")

	# --- Step 5: Verify sibling dedup — parking camera shouldn't fire again ---
	InterrogationManager.select_focus("statement", "stmt_mark_departure_reinforced")
	var r1b: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_false(r1b.get("triggered", false),
		"Parking camera should be spent after first fire (sibling dedup)")
	assert_true(r1b.get("already_fired", false),
		"Should report already_fired for sibling trigger")

	# --- Step 6: Check why-lie topic unlocked ---
	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var topic_ids: Array[String] = []
	for t: InterrogationTopicData in topics:
		topic_ids.append(t.id)
	assert_has(topic_ids, "topic_why_lie_about_time")

	# --- Step 7: Discuss why-lie topic ---
	var lie_result: Dictionary = InterrogationManager.discuss_topic("topic_why_lie_about_time")
	assert_true(lie_result.get("dialogue", "").find("looks bad") >= 0,
		"Why-lie response should contain key phrase")

	# --- Step 8: Present bank transfer against relationship topic ---
	InterrogationManager.select_focus("topic", "topic_relationship")
	var r2: Dictionary = InterrogationManager.present_evidence("ev_bank_transfer")
	assert_true(r2.get("triggered", false), "Trigger 2 should fire")
	assert_eq(InterrogationManager.get_current_pressure(), 2)
	assert_has(InterrogationManager.get_session_statements(),
		"stmt_mark_denies_financial")

	# --- Step 9: Check missing money topic unlocked ---
	topics = InterrogationManager.get_available_topics()
	topic_ids.clear()
	for t: InterrogationTopicData in topics:
		topic_ids.append(t.id)
	assert_has(topic_ids, "topic_missing_money")

	# --- Step 10: Apply pressure → break ---
	var pressure_result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(pressure_result.get("success", false))
	assert_true(pressure_result.get("break_moment", false), "Should break at pressure 2")
	assert_has(InterrogationManager.get_session_statements(),
		"stmt_mark_deeper_admission")

	# --- Step 11: Verify who-else-knew topic ---
	topics = InterrogationManager.get_available_topics()
	topic_ids.clear()
	for t: InterrogationTopicData in topics:
		topic_ids.append(t.id)
	assert_has(topic_ids, "topic_who_else_knew")

	# --- Step 12: Present hidden safe for final lock ---
	InterrogationManager.select_focus("topic", "topic_missing_money")
	var r3: Dictionary = InterrogationManager.present_evidence("ev_hidden_safe")
	assert_true(r3.get("triggered", false), "Trigger 3 should fire")
	assert_has(InterrogationManager.get_session_statements(),
		"stmt_mark_final_lock")

	# --- Step 13: End interrogation ---
	InterrogationManager.end_interrogation()
	assert_false(InterrogationManager.is_active())

	# Verify final state
	assert_true(InterrogationManager.has_break_moment("p_mark"))
	assert_eq(InterrogationManager.get_pressure_for_person("p_mark"), 2)


# =========================================================================
# Additional: Sibling trigger dedup prevents double-firing
# =========================================================================

func test_sibling_triggers_share_fired_status() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	# Discuss departure topic to get reinforced statement
	InterrogationManager.discuss_topic("topic_departure_time")

	# Fire against departure time statement
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	var r1: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_true(r1.get("triggered", false), "First firing should succeed")

	# Try against reinforced statement — should be blocked by sibling dedup
	InterrogationManager.select_focus("statement", "stmt_mark_departure_reinforced")
	var r2: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_false(r2.get("triggered", false), "Sibling trigger should be blocked")

	# Try against topic — should also be blocked
	InterrogationManager.select_focus("topic", "topic_departure_time")
	var r3: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_false(r3.get("triggered", false), "Topic sibling trigger should be blocked")


# =========================================================================
# Additional: Topic discussion produces correct dialogue
# =========================================================================

func test_topic_discussions_produce_dialogue() -> void:
	_start_and_advance()

	var r1: Dictionary = InterrogationManager.discuss_topic("topic_reason_for_visit")
	assert_true(r1.get("dialogue", "").find("Daniel asked me") >= 0,
		"Reason-for-visit topic should produce correct dialogue")
	assert_has(r1.get("statements", []), "stmt_mark_daniel_requested",
		"Should produce daniel-requested statement")

	var r2: Dictionary = InterrogationManager.discuss_topic("topic_relationship")
	assert_true(r2.get("dialogue", "").find("worked together") >= 0,
		"Relationship topic should produce correct dialogue")


# =========================================================================
# Test: Interrogation starts directly in INTERROGATION phase (no button needed)
# =========================================================================

func test_interrogation_auto_starts_in_interrogation_phase() -> void:
	InterrogationManager.start_interrogation("p_mark")
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION,
		"Interrogation should start directly in INTERROGATION phase")

	# Opening dialogue should be available immediately
	var dialogue: String = InterrogationManager.get_initial_dialogue()
	assert_true(dialogue.length() > 0,
		"Opening dialogue should be available at start")

	# Statements should be present immediately
	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_eq(stmts.size(), 3,
		"Initial statements should be visible immediately")

	# Topics should be available immediately
	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	assert_true(topics.size() >= 3,
		"Base topics should be available immediately")


# =========================================================================
# Test: Present Evidence enabling based on focus + evidence
# =========================================================================

func test_present_evidence_requires_focus_and_evidence() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	# Without focus, present evidence should return no_focus
	var result1: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_false(result1.get("triggered", false),
		"Should not trigger without focus")
	assert_eq(result1.get("reason", ""), "no_focus",
		"Should report no_focus reason")

	# With focus but wrong evidence, should not trigger
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	var result2: Dictionary = InterrogationManager.present_evidence("ev_nonexistent")
	assert_false(result2.get("triggered", false),
		"Should not trigger with wrong evidence")

	# With correct focus + correct evidence, should trigger
	var result3: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_true(result3.get("triggered", false),
		"Should trigger with correct focus + evidence")


# =========================================================================
# Test: Apply Pressure from any active phase
# =========================================================================

func test_apply_pressure_works_regardless_of_phase() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# Get 2 pressure points to meet Mark's gate of 2
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")

	# Still in INTERROGATION phase, apply pressure should work
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION)
	assert_true(InterrogationManager.can_apply_pressure(),
		"Should be able to apply pressure in INTERROGATION phase")

	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(result.get("success", false),
		"Apply pressure should succeed from INTERROGATION phase")


# =========================================================================
# Test: Follow-up topic "Why did you lie?" produces a logged statement
# =========================================================================

func test_why_lie_topic_produces_statement() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	# Fire parking camera to unlock why-lie topic and produce prerequisite statement
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")

	# Discuss the why-lie topic
	var result: Dictionary = InterrogationManager.discuss_topic("topic_why_lie_about_time")
	assert_true(result.get("dialogue", "").find("looks bad") >= 0,
		"Should contain why-lie dialogue")
	assert_has(result.get("statements", []), "stmt_mark_lied_to_hide_argument",
		"Why-lie topic should produce lied-to-hide-argument statement")

	# Verify statement is in session
	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_mark_lied_to_hide_argument",
		"Statement should be recorded in session")


# =========================================================================
# Test: Follow-up topic "Missing money" produces a logged statement
# =========================================================================

func test_missing_money_topic_produces_statement() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_bank_transfer")

	# Fire bank transfer to unlock missing money topic
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")

	# Discuss the missing money topic
	var result: Dictionary = InterrogationManager.discuss_topic("topic_missing_money")
	assert_true(result.get("dialogue", "").find("transfers") >= 0,
		"Should contain missing money dialogue")
	assert_has(result.get("statements", []), "stmt_mark_money_admission",
		"Missing money topic should produce money admission statement")

	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_mark_money_admission",
		"Money admission statement should be recorded in session")


# =========================================================================
# Test: Follow-up topic "Who else knew?" produces a logged statement
# =========================================================================

func test_who_else_knew_topic_produces_statement() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# Build up to break to unlock who-else-knew topic
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")
	InterrogationManager.apply_pressure()

	# Discuss who-else-knew topic
	var result: Dictionary = InterrogationManager.discuss_topic("topic_who_else_knew")
	assert_true(result.get("dialogue", "").find("Julia") >= 0,
		"Should mention Julia in dialogue")
	assert_has(result.get("statements", []), "stmt_mark_julia_knew",
		"Who-else-knew topic should produce julia-knew statement")

	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_mark_julia_knew",
		"Julia-knew statement should be recorded in session")


# =========================================================================
# Test: Dialogue-only topic still shows dialogue when clicked
# =========================================================================

func test_dialogue_only_topic_shows_dialogue() -> void:
	_start_and_advance()

	# topic_relationship has no statements, only dialogue
	var result: Dictionary = InterrogationManager.discuss_topic("topic_relationship")
	assert_true(result.get("dialogue", "").find("worked together") >= 0,
		"Dialogue-only topic should return its dialogue text")
	assert_eq(result.get("statements", []).size(), 0,
		"Dialogue-only topic should produce no statements")


# =========================================================================
# Test: Topic discussion emits topic_discussed signal
# =========================================================================

func test_topic_discussed_signal_emitted() -> void:
	_start_and_advance()

	# Use watch_signals for reliable signal detection in GUT
	watch_signals(InterrogationManager)
	InterrogationManager.discuss_topic("topic_reason_for_visit")
	assert_signal_emitted(InterrogationManager, "topic_discussed",
		"topic_discussed signal should be emitted")
	var params: Array = get_signal_parameters(InterrogationManager, "topic_discussed")
	assert_eq(params[0], "topic_reason_for_visit",
		"Signal should carry the discussed topic ID")


# =========================================================================
# Test: Unlocked topics appear immediately in available topics
# =========================================================================

func test_unlocked_topics_appear_immediately() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	# Before trigger
	var topics_before: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids_before: Array[String] = []
	for t: InterrogationTopicData in topics_before:
		ids_before.append(t.id)
	assert_does_not_have(ids_before, "topic_why_lie_about_time")

	# Fire trigger that unlocks topic
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")

	# Immediately after trigger — no phase reset or reopen needed
	var topics_after: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids_after: Array[String] = []
	for t: InterrogationTopicData in topics_after:
		ids_after.append(t.id)
	assert_has(ids_after, "topic_why_lie_about_time",
		"Unlocked topic should appear immediately without any extra steps")


# =========================================================================
# Test: Full Mark Bennett flow with new statement logging
# =========================================================================

func test_full_mark_flow_with_statement_logging() -> void:
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")
	GameManager.discover_evidence("ev_hidden_safe")

	# Start
	InterrogationManager.start_interrogation("p_mark")
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION)

	# Present parking camera
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	var r1: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_true(r1.get("triggered", false))

	# Ask why lie — should produce statement
	var lie_result: Dictionary = InterrogationManager.discuss_topic("topic_why_lie_about_time")
	assert_has(lie_result.get("statements", []), "stmt_mark_lied_to_hide_argument")

	# Present bank transfer
	InterrogationManager.select_focus("topic", "topic_relationship")
	var r2: Dictionary = InterrogationManager.present_evidence("ev_bank_transfer")
	assert_true(r2.get("triggered", false))

	# Ask missing money — should produce statement
	var money_result: Dictionary = InterrogationManager.discuss_topic("topic_missing_money")
	assert_has(money_result.get("statements", []), "stmt_mark_money_admission")

	# Apply pressure → break
	var pressure_result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(pressure_result.get("break_moment", false))

	# Ask who else knew — should produce statement
	var julia_result: Dictionary = InterrogationManager.discuss_topic("topic_who_else_knew")
	assert_has(julia_result.get("statements", []), "stmt_mark_julia_knew")

	# Present hidden safe for final lock
	InterrogationManager.select_focus("topic", "topic_missing_money")
	var r3: Dictionary = InterrogationManager.present_evidence("ev_hidden_safe")
	assert_true(r3.get("triggered", false))
	assert_has(InterrogationManager.get_session_statements(), "stmt_mark_final_lock")

	# Verify all progression statements are in session
	var all_stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(all_stmts, "stmt_mark_lied_to_hide_argument")
	assert_has(all_stmts, "stmt_mark_money_admission")
	assert_has(all_stmts, "stmt_mark_julia_knew")
	assert_has(all_stmts, "stmt_mark_deeper_admission")
	assert_has(all_stmts, "stmt_mark_final_lock")

	InterrogationManager.end_interrogation()


# =========================================================================
# Regression: E24 Hidden Safe is blocked before stmt_mark_deeper_admission
# =========================================================================

func test_e24_hidden_safe_blocked_before_break() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")
	GameManager.discover_evidence("ev_hidden_safe")

	# Build up pressure but do NOT apply it yet
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")
	assert_eq(InterrogationManager.get_current_pressure(), 2)

	# Try to present hidden safe before break — should be blocked
	InterrogationManager.select_focus("topic", "topic_missing_money")
	var result: Dictionary = InterrogationManager.present_evidence("ev_hidden_safe")
	assert_false(result.get("triggered", false),
		"E24 should NOT fire before stmt_mark_deeper_admission is heard")
	assert_eq(result.get("reason", ""), "prerequisite_not_met",
		"Should report prerequisite_not_met")


# =========================================================================
# Regression: E24 works correctly after pressure break
# =========================================================================

func test_e24_hidden_safe_works_after_break() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")
	GameManager.discover_evidence("ev_hidden_safe")

	# Build pressure and break
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")
	var break_result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(break_result.get("break_moment", false), "Break should occur")
	assert_has(InterrogationManager.get_session_statements(),
		"stmt_mark_deeper_admission", "Break should produce deeper admission")

	# Now E24 should work (prerequisite met)
	InterrogationManager.select_focus("topic", "topic_missing_money")
	var result: Dictionary = InterrogationManager.present_evidence("ev_hidden_safe")
	assert_true(result.get("triggered", false),
		"E24 should fire after break (stmt_mark_deeper_admission heard)")
	assert_has(InterrogationManager.get_session_statements(),
		"stmt_mark_final_lock", "Should produce final lock statement")


# =========================================================================
# Regression: Apply Pressure enables at exactly pressure_gate
# =========================================================================

func test_apply_pressure_enables_at_exact_gate() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# 0 pressure — should be disabled
	assert_false(InterrogationManager.can_apply_pressure(),
		"Should not be enabled at 0 pressure")

	# 1 pressure — still below gate of 2
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	assert_eq(InterrogationManager.get_current_pressure(), 1)
	assert_false(InterrogationManager.can_apply_pressure(),
		"Should not be enabled at 1/2 pressure")

	# 2 pressure — exactly at gate
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")
	assert_eq(InterrogationManager.get_current_pressure(), 2)
	assert_true(InterrogationManager.can_apply_pressure(),
		"Should be enabled at exactly 2/2 pressure (gate reached)")


# =========================================================================
# Regression: Pressure break unlocks topic_who_else_knew
# =========================================================================

func test_pressure_break_unlocks_who_else_knew() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# Verify topic_who_else_knew is NOT available before break
	var topics_before: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids_before: Array[String] = []
	for t: InterrogationTopicData in topics_before:
		ids_before.append(t.id)
	assert_does_not_have(ids_before, "topic_who_else_knew",
		"Who-else-knew should NOT be available before break")

	# Build pressure and break
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")
	var break_result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(break_result.get("break_moment", false), "Break should occur")

	# Verify topic_who_else_knew is now available immediately
	var topics_after: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids_after: Array[String] = []
	for t: InterrogationTopicData in topics_after:
		ids_after.append(t.id)
	assert_has(ids_after, "topic_who_else_knew",
		"Who-else-knew should be unlocked by pressure break")


# =========================================================================
# Test: Apply Pressure blocked after break with real case data
# =========================================================================

func test_apply_pressure_blocked_after_break() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# Build pressure and break
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")
	var break_result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(break_result.get("break_moment", false), "Break should occur")

	# Second apply should fail
	assert_false(InterrogationManager.can_apply_pressure(),
		"Should NOT be able to apply pressure after break")
	var second_result: Dictionary = InterrogationManager.apply_pressure()
	assert_false(second_result.get("success", true),
		"Second apply pressure should fail")
	assert_eq(second_result.get("reason", ""), "already_used",
		"Should report already_used")


# =========================================================================
# Test: Phase returns to INTERROGATION after break
# =========================================================================

func test_phase_returns_to_interrogation_after_break() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")
	InterrogationManager.apply_pressure()

	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION,
		"Phase should return to INTERROGATION after break so player can continue")


# =========================================================================
# Test: Who Else Knew topic is discussable and produces dialogue
# =========================================================================

func test_who_else_knew_topic_is_discussable_after_break() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# Build up to break
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")
	InterrogationManager.apply_pressure()

	# Check topic appears
	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var topic_ids: Array[String] = []
	for t: InterrogationTopicData in topics:
		topic_ids.append(t.id)
	assert_has(topic_ids, "topic_who_else_knew",
		"Who-else-knew topic must appear after break")

	# Discuss it — should produce dialogue and statement
	var result: Dictionary = InterrogationManager.discuss_topic("topic_who_else_knew")
	assert_false(result.is_empty(), "Discussion result must not be empty")
	assert_true(result.get("dialogue", "").find("Julia") >= 0,
		"Dialogue should mention Julia")
	assert_has(result.get("statements", []), "stmt_mark_julia_knew",
		"Should produce julia-knew statement")

	# Can still set focus and present evidence after break
	InterrogationManager.select_focus("topic", "topic_who_else_knew")
	var focus: Dictionary = InterrogationManager.get_current_focus()
	assert_eq(focus.get("type", ""), "topic",
		"Should be able to set focus after break")


# =========================================================================
# UI State: Present Evidence button logic
# =========================================================================

func test_present_evidence_disabled_without_focus() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	# Without focus — evidence alone is not enough
	var result: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_false(result.get("triggered", false),
		"Cannot present without focus")
	assert_eq(result.get("reason", ""), "no_focus")


func test_present_evidence_enabled_with_focus_and_evidence() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	var result: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_true(result.get("triggered", false),
		"Should trigger with valid focus + evidence")


# =========================================================================
# UI State: Apply Pressure disabled before, enabled after threshold
# =========================================================================

func test_apply_pressure_disabled_then_enabled() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# 0 pressure
	assert_false(InterrogationManager.can_apply_pressure(),
		"Disabled at 0 pressure")

	# 1 pressure (below gate of 2)
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	assert_false(InterrogationManager.can_apply_pressure(),
		"Disabled at 1/2 pressure")

	# 2 pressure (at gate)
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")
	assert_true(InterrogationManager.can_apply_pressure(),
		"Enabled at 2/2 pressure")

	# After using it
	InterrogationManager.apply_pressure()
	assert_false(InterrogationManager.can_apply_pressure(),
		"Disabled after use")


# =========================================================================
# Persistence: Save/load round-trip preserves Mark interrogation progress
# =========================================================================

func test_save_load_preserves_mark_progress() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# Build up some progress
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")
	InterrogationManager.select_focus("statement", "stmt_mark_argument")
	InterrogationManager.present_evidence("ev_bank_transfer")
	InterrogationManager.apply_pressure()

	# End interrogation to save persistent state
	InterrogationManager.end_interrogation()

	# Serialize full game state
	var game_data: Dictionary = GameManager.serialize()

	# Reset everything
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case_folder("riverside_apartment")
	InterrogationManager.reset()

	# Deserialize
	GameManager.deserialize(game_data)

	# Verify persistent interrogation state survived
	assert_true(InterrogationManager.has_break_moment("p_mark"),
		"Break moment should survive save/load")
	assert_eq(InterrogationManager.get_pressure_for_person("p_mark"), 2,
		"Accumulated pressure should survive save/load")

	var fired: Array = InterrogationManager.get_fired_triggers_for_person("p_mark")
	assert_true(fired.size() >= 2,
		"Fired triggers should survive save/load")

	var heard: Array[String] = InterrogationManager.get_heard_statements()
	assert_has(heard, "stmt_mark_corrected_departure",
		"Heard statements should survive save/load")
	assert_has(heard, "stmt_mark_denies_financial",
		"Heard statements should survive save/load")
	assert_has(heard, "stmt_mark_deeper_admission",
		"Break-produced statement should survive save/load")


func test_save_load_preserves_mid_session_fired_evidence() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")
	GameManager.discover_evidence("ev_bank_transfer")

	# Present evidence — builds session state
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")

	# Serialize mid-session
	var game_data: Dictionary = GameManager.serialize()

	# Reset + restore
	InterrogationManager.reset()
	GameManager.deserialize(game_data)

	# Verify the session was restored and evidence is marked as used
	assert_true(InterrogationManager.is_active(),
		"Mid-session interrogation should be restored")
	assert_eq(InterrogationManager.get_current_person_id(), "p_mark")

	# Presenting the same evidence again should return already_fired
	InterrogationManager.select_focus("statement", "stmt_mark_departure_reinforced")
	var result: Dictionary = InterrogationManager.present_evidence("ev_parking_camera")
	assert_false(result.get("triggered", true),
		"Evidence should be spent after save/load")
	assert_true(result.get("already_fired", false),
		"Should report already_fired for evidence used before save")


func test_save_load_preserves_contradiction_markers() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")

	# Serialize mid-session
	var game_data: Dictionary = GameManager.serialize()
	InterrogationManager.reset()
	GameManager.deserialize(game_data)

	# Check contradictions survived
	var contras: Array[Dictionary] = InterrogationManager.get_session_contradictions()
	assert_eq(contras.size(), 1,
		"Contradiction markers should survive save/load")
	assert_eq(contras[0].get("statement_id", ""), "stmt_mark_departure_time")
	assert_eq(contras[0].get("evidence_id", ""), "ev_parking_camera")


func test_save_load_preserves_unlocked_topics() -> void:
	_start_and_advance()
	GameManager.discover_evidence("ev_parking_camera")

	# Fire trigger that unlocks topic_why_lie_about_time
	InterrogationManager.select_focus("statement", "stmt_mark_departure_time")
	InterrogationManager.present_evidence("ev_parking_camera")

	# Verify topic is unlocked pre-save
	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids: Array[String] = []
	for t: InterrogationTopicData in topics:
		ids.append(t.id)
	assert_has(ids, "topic_why_lie_about_time", "Should be unlocked before save")

	# Serialize mid-session, reset, restore
	var game_data: Dictionary = GameManager.serialize()
	InterrogationManager.reset()
	GameManager.deserialize(game_data)

	# Verify topic is still unlocked after load
	var topics_after: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids_after: Array[String] = []
	for t: InterrogationTopicData in topics_after:
		ids_after.append(t.id)
	assert_has(ids_after, "topic_why_lie_about_time",
		"Unlocked topics should survive save/load")
