## test_sarah_klein_interrogation.gd
## Scenario tests for Sarah Klein's interrogation using the real riverside_apartment case data.
## Validates the complete interrogation loop: statements, topics, triggers,
## pressure, break sequence, and persistence.
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


## Helper: start Sarah's interrogation (starts in INTERROGATION phase).
func _start_sarah() -> void:
	InterrogationManager.start_interrogation("p_sarah")


## Helper: get topic IDs as an array of strings.
func _get_topic_ids() -> Array[String]:
	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	var ids: Array[String] = []
	for t: InterrogationTopicData in topics:
		ids.append(t.id)
	return ids


# =========================================================================
# Test 1: Session initializes correctly
# =========================================================================

func test_session_initializes_correctly() -> void:
	_start_sarah()

	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION,
		"Should start directly in INTERROGATION phase")

	var dialogue: String = InterrogationManager.get_initial_dialogue()
	assert_true(dialogue.length() > 0, "Initial dialogue should not be empty")
	assert_true(dialogue.find("I already told them") >= 0,
		"Initial dialogue should contain opening line")

	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_eq(stmts.size(), 1, "Should have 1 initial statement")
	assert_has(stmts, "stmt_sarah_initial", "Should include initial statement")

	assert_eq(InterrogationManager.get_current_pressure(), 0,
		"Pressure should start at 0")


# =========================================================================
# Test 2: Base topics appear correctly
# =========================================================================

func test_base_topics_appear_on_start() -> void:
	_start_sarah()

	var topic_ids: Array[String] = _get_topic_ids()

	assert_has(topic_ids, "topic_sarah_what_heard", "Should have 'What did you hear?' topic")
	assert_has(topic_ids, "topic_sarah_why_not_look", "Should have 'Why didn't you look?' topic")
	assert_has(topic_ids, "topic_sarah_argue_often", "Should have 'Did Daniel argue often?' topic")
	assert_does_not_have(topic_ids, "topic_sarah_why_hide",
		"Unlockable topic should not appear at start")
	assert_does_not_have(topic_ids, "topic_sarah_footsteps",
		"Unlockable topic should not appear at start")
	assert_does_not_have(topic_ids, "topic_sarah_after_break",
		"Break-unlocked topic should not appear at start")
	assert_does_not_have(topic_ids, "topic_sarah_hallway",
		"Legacy 'What Sarah Saw' topic should not appear")


# =========================================================================
# Test 3: Topic questioning adds expected statements
# =========================================================================

func test_what_heard_topic_adds_statement() -> void:
	_start_sarah()

	var result: Dictionary = InterrogationManager.discuss_topic("topic_sarah_what_heard")
	assert_true(result.get("dialogue", "").find("shouting") >= 0,
		"Dialogue should mention shouting")
	assert_has(result.get("statements", []), "stmt_sarah_heard_argument",
		"Should produce heard-argument statement")

	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_sarah_heard_argument")


func test_why_not_look_topic_adds_statement() -> void:
	_start_sarah()

	var result: Dictionary = InterrogationManager.discuss_topic("topic_sarah_why_not_look")
	assert_true(result.get("dialogue", "").find("involved") >= 0,
		"Dialogue should mention not getting involved")
	assert_has(result.get("statements", []), "stmt_sarah_didnt_look",
		"Should produce didn't-look statement")


func test_argue_often_topic_adds_statement() -> void:
	_start_sarah()

	var result: Dictionary = InterrogationManager.discuss_topic("topic_sarah_argue_often")
	assert_true(result.get("dialogue", "").find("different") >= 0,
		"Dialogue should mention that night felt different")
	assert_has(result.get("statements", []), "stmt_sarah_not_unusual",
		"Should produce not-unusual statement")


# =========================================================================
# Test 4: Wrong evidence does not fire
# =========================================================================

func test_wrong_evidence_does_not_fire() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_knife")

	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	var result: Dictionary = InterrogationManager.present_evidence("ev_knife")
	assert_false(result.get("triggered", false),
		"Wrong evidence should not trigger")


# =========================================================================
# Test 5: Correct evidence with wrong focus does not fire
# =========================================================================

func test_correct_evidence_wrong_focus_does_not_fire() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")

	# Need a statement that is NOT stmt_sarah_initial as focus
	InterrogationManager.discuss_topic("topic_sarah_what_heard")
	InterrogationManager.select_focus("statement", "stmt_sarah_heard_argument")
	var result: Dictionary = InterrogationManager.present_evidence("ev_hallway_camera")
	assert_false(result.get("triggered", false),
		"Hallway camera should not trigger against wrong statement")


# =========================================================================
# Test 6: Hallway camera trigger fires correctly
# =========================================================================

func test_hallway_camera_trigger_fires_correctly() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")

	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	var result: Dictionary = InterrogationManager.present_evidence("ev_hallway_camera")

	assert_true(result.get("triggered", false), "Should trigger")
	assert_eq(result.get("pressure_added", 0), 1, "Should add 1 pressure point")
	assert_true(result.get("dialogue", "").find("woman's voice") >= 0,
		"Dialogue should mention woman's voice")

	# Check new statement
	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_sarah_confronted",
		"Confronted statement should be recorded")

	# Check pressure
	assert_eq(InterrogationManager.get_current_pressure(), 1,
		"Pressure should be 1 after camera trigger")

	# Check topic_sarah_why_hide unlocked
	var topic_ids: Array[String] = _get_topic_ids()
	assert_has(topic_ids, "topic_sarah_why_hide",
		"'Why didn't you say that earlier?' topic should be unlocked")


# =========================================================================
# Test 7: Shoe print trigger fires correctly (requires stmt_sarah_confronted)
# =========================================================================

func test_shoe_print_trigger_fires_correctly() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	# First fire camera trigger to produce stmt_sarah_confronted
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	InterrogationManager.present_evidence("ev_hallway_camera")
	assert_eq(InterrogationManager.get_current_pressure(), 1)

	# Now fire shoe print against stmt_sarah_confronted
	InterrogationManager.select_focus("statement", "stmt_sarah_confronted")
	var result: Dictionary = InterrogationManager.present_evidence("ev_shoe_print")

	assert_true(result.get("triggered", false), "Should trigger")
	assert_eq(result.get("pressure_added", 0), 1, "Should add 1 pressure point")
	assert_true(result.get("dialogue", "").find("footsteps") >= 0,
		"Dialogue should mention footsteps")

	# Check new statement
	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_sarah_footsteps",
		"Footsteps statement should be recorded")

	# Check total pressure
	assert_eq(InterrogationManager.get_current_pressure(), 2,
		"Pressure should be 2 after both triggers")

	# Check topic_sarah_footsteps unlocked
	var topic_ids: Array[String] = _get_topic_ids()
	assert_has(topic_ids, "topic_sarah_footsteps",
		"'What did it sound like?' topic should be unlocked")


# =========================================================================
# Test 8: Shoe print blocked before stmt_sarah_confronted
# =========================================================================

func test_shoe_print_blocked_before_confronted() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_shoe_print")

	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	var result: Dictionary = InterrogationManager.present_evidence("ev_shoe_print")
	assert_false(result.get("triggered", false),
		"Shoe print should NOT fire before stmt_sarah_confronted")
	assert_eq(result.get("reason", ""), "prerequisite_not_met",
		"Should report prerequisite_not_met")


# =========================================================================
# Test 9: Pressure increments correctly
# =========================================================================

func test_pressure_increments_correctly() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	assert_eq(InterrogationManager.get_current_pressure(), 0, "Should start at 0")

	# Trigger 1: +1
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	InterrogationManager.present_evidence("ev_hallway_camera")
	assert_eq(InterrogationManager.get_current_pressure(), 1, "Should be 1 after camera")

	# Trigger 2: +1
	InterrogationManager.select_focus("statement", "stmt_sarah_confronted")
	InterrogationManager.present_evidence("ev_shoe_print")
	assert_eq(InterrogationManager.get_current_pressure(), 2, "Should be 2 after shoe print")


# =========================================================================
# Test 10: Apply Pressure only enables at threshold (2)
# =========================================================================

func test_apply_pressure_only_enables_at_threshold() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	# 0 pressure — disabled
	assert_false(InterrogationManager.can_apply_pressure(),
		"Should not be able to apply pressure at 0")

	# 1 pressure — still disabled
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	InterrogationManager.present_evidence("ev_hallway_camera")
	assert_eq(InterrogationManager.get_current_pressure(), 1)
	assert_false(InterrogationManager.can_apply_pressure(),
		"Should not be able to apply pressure at 1/2")

	# 2 pressure — enabled
	InterrogationManager.select_focus("statement", "stmt_sarah_confronted")
	InterrogationManager.present_evidence("ev_shoe_print")
	assert_eq(InterrogationManager.get_current_pressure(), 2)
	assert_true(InterrogationManager.can_apply_pressure(),
		"Should be able to apply pressure at 2/2")


# =========================================================================
# Test 11: Apply Pressure only works once
# =========================================================================

func test_apply_pressure_only_works_once() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	# Build pressure to 2
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	InterrogationManager.present_evidence("ev_hallway_camera")
	InterrogationManager.select_focus("statement", "stmt_sarah_confronted")
	InterrogationManager.present_evidence("ev_shoe_print")

	# First apply — should succeed
	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(result.get("success", false), "First apply should succeed")
	assert_true(result.get("break_moment", false), "Should trigger break")

	# Second apply — should fail
	assert_false(InterrogationManager.can_apply_pressure(),
		"Should not be able to apply pressure after break")
	var second: Dictionary = InterrogationManager.apply_pressure()
	assert_false(second.get("success", true), "Second apply should fail")
	assert_eq(second.get("reason", ""), "already_used", "Should report already_used")


# =========================================================================
# Test 12: Break state adds the correct witness statement
# =========================================================================

func test_break_adds_witness_statement() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	# Build pressure and break
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	InterrogationManager.present_evidence("ev_hallway_camera")
	InterrogationManager.select_focus("statement", "stmt_sarah_confronted")
	InterrogationManager.present_evidence("ev_shoe_print")

	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(result.get("break_moment", false), "Should trigger break")

	# Check break dialogue
	assert_true(result.get("dialogue", "").find("I was scared") >= 0,
		"Break dialogue should start with fear admission")
	assert_true(result.get("dialogue", "").find("woman leaving") >= 0,
		"Break dialogue should mention seeing a woman")

	# Check break statement
	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_sarah_saw_woman",
		"Break should produce saw-woman statement")

	# Check break moment is recorded
	assert_true(InterrogationManager.has_break_moment("p_sarah"),
		"Break moment should be recorded for Sarah")

	# Check post-break topic unlocked
	var topic_ids: Array[String] = _get_topic_ids()
	assert_has(topic_ids, "topic_sarah_after_break",
		"'Can you describe her?' topic should be unlocked after break")


# =========================================================================
# Test 13: Repeated valid evidence does not duplicate
# =========================================================================

func test_repeated_evidence_does_not_duplicate() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")

	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	var r1: Dictionary = InterrogationManager.present_evidence("ev_hallway_camera")
	assert_true(r1.get("triggered", false), "First presentation should trigger")

	# Present same evidence again
	var r2: Dictionary = InterrogationManager.present_evidence("ev_hallway_camera")
	assert_false(r2.get("triggered", false), "Second presentation should not trigger")
	assert_true(r2.get("already_fired", false), "Should report already_fired")


# =========================================================================
# Test 14: Sarah session state persists across save/load
# =========================================================================

func test_save_load_preserves_sarah_progress() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	# Build up progress
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	InterrogationManager.present_evidence("ev_hallway_camera")
	InterrogationManager.select_focus("statement", "stmt_sarah_confronted")
	InterrogationManager.present_evidence("ev_shoe_print")
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

	# Verify persistent state survived
	assert_true(InterrogationManager.has_break_moment("p_sarah"),
		"Break moment should survive save/load")
	assert_eq(InterrogationManager.get_pressure_for_person("p_sarah"), 2,
		"Accumulated pressure should survive save/load")

	var fired: Array = InterrogationManager.get_fired_triggers_for_person("p_sarah")
	assert_true(fired.size() >= 2,
		"Fired triggers should survive save/load")

	var heard: Array[String] = InterrogationManager.get_heard_statements()
	assert_has(heard, "stmt_sarah_initial",
		"Initial statement should survive save/load")
	assert_has(heard, "stmt_sarah_confronted",
		"Confronted statement should survive save/load")
	assert_has(heard, "stmt_sarah_footsteps",
		"Footsteps statement should survive save/load")
	assert_has(heard, "stmt_sarah_saw_woman",
		"Break-produced statement should survive save/load")


# =========================================================================
# Test 15: Full Sarah interrogation end-to-end
# =========================================================================

func test_full_sarah_interrogation_end_to_end() -> void:
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	# --- Step 1: Start interrogation ---
	var started: bool = InterrogationManager.start_interrogation("p_sarah")
	assert_true(started, "Interrogation should start")
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION)

	# Check initial state
	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_eq(stmts.size(), 1, "Should have 1 initial statement")
	assert_has(stmts, "stmt_sarah_initial")

	# --- Step 2: Discuss base topics ---
	var r_heard: Dictionary = InterrogationManager.discuss_topic("topic_sarah_what_heard")
	assert_has(r_heard.get("statements", []), "stmt_sarah_heard_argument")

	var r_look: Dictionary = InterrogationManager.discuss_topic("topic_sarah_why_not_look")
	assert_has(r_look.get("statements", []), "stmt_sarah_didnt_look")

	var r_often: Dictionary = InterrogationManager.discuss_topic("topic_sarah_argue_often")
	assert_has(r_often.get("statements", []), "stmt_sarah_not_unusual")

	# --- Step 3: Present hallway camera against initial statement ---
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	var r1: Dictionary = InterrogationManager.present_evidence("ev_hallway_camera")
	assert_true(r1.get("triggered", false), "Camera trigger should fire")
	assert_eq(InterrogationManager.get_current_pressure(), 1)
	assert_has(InterrogationManager.get_session_statements(), "stmt_sarah_confronted")

	# Check topic_sarah_why_hide unlocked
	var topic_ids: Array[String] = _get_topic_ids()
	assert_has(topic_ids, "topic_sarah_why_hide")

	# --- Step 4: Present shoe print against confronted statement ---
	InterrogationManager.select_focus("statement", "stmt_sarah_confronted")
	var r2: Dictionary = InterrogationManager.present_evidence("ev_shoe_print")
	assert_true(r2.get("triggered", false), "Shoe print trigger should fire")
	assert_eq(InterrogationManager.get_current_pressure(), 2)
	assert_has(InterrogationManager.get_session_statements(), "stmt_sarah_footsteps")

	# Check topic_sarah_footsteps unlocked
	topic_ids = _get_topic_ids()
	assert_has(topic_ids, "topic_sarah_footsteps")

	# --- Step 5: Apply pressure → break ---
	assert_true(InterrogationManager.can_apply_pressure(),
		"Should be able to apply pressure at 2/2")
	var break_result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(break_result.get("success", false))
	assert_true(break_result.get("break_moment", false), "Should break at pressure 2")
	assert_has(InterrogationManager.get_session_statements(), "stmt_sarah_saw_woman")

	# Check post-break topic
	topic_ids = _get_topic_ids()
	assert_has(topic_ids, "topic_sarah_after_break")

	# --- Step 6: Discuss post-break topic ---
	var after_result: Dictionary = InterrogationManager.discuss_topic("topic_sarah_after_break")
	assert_true(after_result.get("dialogue", "").find("Dark hair") >= 0,
		"After-break topic should mention physical description")

	# --- Step 7: Phase should be INTERROGATION after break ---
	assert_eq(InterrogationManager.get_current_phase(),
		Enums.InterrogationPhase.INTERROGATION,
		"Phase should return to INTERROGATION after break")

	# --- Step 8: Apply pressure again should fail ---
	assert_false(InterrogationManager.can_apply_pressure())
	var second: Dictionary = InterrogationManager.apply_pressure()
	assert_false(second.get("success", true))

	# --- Step 9: End interrogation ---
	InterrogationManager.end_interrogation()
	assert_false(InterrogationManager.is_active())
	assert_true(InterrogationManager.has_break_moment("p_sarah"))
	assert_eq(InterrogationManager.get_pressure_for_person("p_sarah"), 2)


# =========================================================================
# Test 16: Insufficient pressure returns correct result
# =========================================================================

func test_apply_pressure_blocked_with_no_pressure() -> void:
	_start_sarah()

	assert_false(InterrogationManager.can_apply_pressure(),
		"Should not be able to apply pressure with 0 pressure")

	var result: Dictionary = InterrogationManager.apply_pressure()
	assert_false(result.get("success", true), "Apply pressure should fail")
	assert_eq(result.get("reason", ""), "insufficient_pressure")


# =========================================================================
# Test 17: Rejection text comes from Sarah's pool
# =========================================================================

func test_rejection_text_from_sarah_pool() -> void:
	_start_sarah()

	var rejection: String = InterrogationManager.get_rejection_text()
	assert_true(rejection.length() > 0, "Rejection text should not be empty")

	var valid_rejections: Array[String] = [
		"Sarah shakes her head. 'I don't know anything about that.'",
		"She looks confused. 'I... I don't understand what you're showing me.'",
		"She wrings her hands. 'That doesn't mean anything to me.'",
		"She avoids your eyes. 'I really can't help you with that.'",
		# Defaults from InterrogationManager
		"That doesn't seem relevant.",
		"That doesn't get a reaction.",
		"They dismiss it immediately.",
		"They barely react to that.",
		"That doesn't seem to shake their story.",
	]
	assert_has(valid_rejections, rejection, "Rejection should be from valid pool")


# =========================================================================
# Test 18: Save/load mid-session preserves unlocked topics
# =========================================================================

func test_save_load_preserves_unlocked_topics() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")

	# Fire camera trigger to unlock topic_sarah_why_hide
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	InterrogationManager.present_evidence("ev_hallway_camera")

	# Verify topic is unlocked pre-save
	var topic_ids: Array[String] = _get_topic_ids()
	assert_has(topic_ids, "topic_sarah_why_hide", "Should be unlocked before save")

	# Serialize mid-session, reset, restore
	var game_data: Dictionary = GameManager.serialize()
	InterrogationManager.reset()
	GameManager.deserialize(game_data)

	# Verify topic is still unlocked after load
	var topic_ids_after: Array[String] = _get_topic_ids()
	assert_has(topic_ids_after, "topic_sarah_why_hide",
		"Unlocked topics should survive save/load")


# =========================================================================
# Test 19: Topics don't leak even when evidence is pre-discovered
# =========================================================================

func test_topics_dont_leak_with_pre_discovered_evidence() -> void:
	# Discover hallway camera BEFORE starting interrogation
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	_start_sarah()

	var topic_ids: Array[String] = _get_topic_ids()

	# Only the 3 base topics should appear
	assert_has(topic_ids, "topic_sarah_what_heard")
	assert_has(topic_ids, "topic_sarah_why_not_look")
	assert_has(topic_ids, "topic_sarah_argue_often")

	# Conditional/unlockable topics must NOT leak
	assert_does_not_have(topic_ids, "topic_sarah_hallway",
		"Legacy topic should not leak even with evidence pre-discovered")
	assert_does_not_have(topic_ids, "topic_sarah_why_hide",
		"Camera-unlock topic should not leak before trigger fires")
	assert_does_not_have(topic_ids, "topic_sarah_footsteps",
		"Shoe-unlock topic should not leak before trigger fires")
	assert_does_not_have(topic_ids, "topic_sarah_after_break",
		"Break-unlock topic should not leak at start")


# =========================================================================
# Test 20: Shoe print on wrong focus returns prerequisite_not_met
# =========================================================================

func test_shoe_print_wrong_focus_returns_prerequisite_not_met() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_shoe_print")

	# Discuss a topic to get a different statement for focus
	InterrogationManager.discuss_topic("topic_sarah_what_heard")
	InterrogationManager.select_focus("statement", "stmt_sarah_heard_argument")

	var result: Dictionary = InterrogationManager.present_evidence("ev_shoe_print")
	assert_false(result.get("triggered", false),
		"Shoe print should not trigger against wrong focus without prerequisite")
	assert_eq(result.get("reason", ""), "prerequisite_not_met",
		"Should return prerequisite_not_met (trigger exists but requires stmt_sarah_confronted)")


# =========================================================================
# Test 21: Shoe print fires via topic focus (gameplay path)
# =========================================================================

func test_shoe_print_fires_via_topic_focus() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	# Step 1: Fire camera trigger to unlock topic_sarah_why_hide
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	InterrogationManager.present_evidence("ev_hallway_camera")
	assert_eq(InterrogationManager.get_current_pressure(), 1)

	# Step 2: Discuss the unlocked topic and set it as focus
	var topic_ids: Array[String] = _get_topic_ids()
	assert_has(topic_ids, "topic_sarah_why_hide")

	InterrogationManager.discuss_topic("topic_sarah_why_hide")
	InterrogationManager.select_focus("topic", "topic_sarah_why_hide")

	# Step 3: Present shoe print against the topic focus
	var result: Dictionary = InterrogationManager.present_evidence("ev_shoe_print")
	assert_true(result.get("triggered", false),
		"Shoe print should trigger when presented against 'Why didn't you say that earlier?' topic")
	assert_eq(result.get("pressure_added", 0), 1, "Should add 1 pressure point")
	assert_true(result.get("dialogue", "").find("footsteps") >= 0,
		"Dialogue should mention footsteps")

	# Check total pressure
	assert_eq(InterrogationManager.get_current_pressure(), 2,
		"Pressure should be 2 after both triggers")

	# Check new statement and topic unlock
	var stmts: Array[String] = InterrogationManager.get_session_statements()
	assert_has(stmts, "stmt_sarah_footsteps")
	topic_ids = _get_topic_ids()
	assert_has(topic_ids, "topic_sarah_footsteps")


# =========================================================================
# Test 22: Full Sarah path via topics (realistic gameplay)
# =========================================================================

func test_full_sarah_path_via_topics() -> void:
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	# Start interrogation
	InterrogationManager.start_interrogation("p_sarah")

	# Step 1: Present camera against initial statement
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	var r1: Dictionary = InterrogationManager.present_evidence("ev_hallway_camera")
	assert_true(r1.get("triggered", false))
	assert_eq(InterrogationManager.get_current_pressure(), 1)

	# Step 2: Select unlocked topic as focus, present shoe print
	InterrogationManager.discuss_topic("topic_sarah_why_hide")
	InterrogationManager.select_focus("topic", "topic_sarah_why_hide")
	var r2: Dictionary = InterrogationManager.present_evidence("ev_shoe_print")
	assert_true(r2.get("triggered", false), "Shoe print should trigger via topic focus")
	assert_eq(InterrogationManager.get_current_pressure(), 2)

	# Step 3: Apply pressure → break
	assert_true(InterrogationManager.can_apply_pressure())
	var break_result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(break_result.get("break_moment", false))
	assert_has(InterrogationManager.get_session_statements(), "stmt_sarah_saw_woman")

	# Step 4: Discuss post-break topic
	var topic_ids: Array[String] = _get_topic_ids()
	assert_has(topic_ids, "topic_sarah_after_break")
	var after: Dictionary = InterrogationManager.discuss_topic("topic_sarah_after_break")
	assert_true(after.get("dialogue", "").find("Dark hair") >= 0)

	InterrogationManager.end_interrogation()


# =========================================================================
# Test 23: Wrong focus returns wrong_focus (not wrong_evidence)
# =========================================================================

func test_correct_evidence_wrong_focus_returns_wrong_focus() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	# Fire camera to get stmt_sarah_confronted
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	InterrogationManager.present_evidence("ev_hallway_camera")

	# Now present shoe print against a wrong focus (stmt_sarah_heard_argument)
	# but with prerequisite met (stmt_sarah_confronted is now heard)
	InterrogationManager.discuss_topic("topic_sarah_what_heard")
	InterrogationManager.select_focus("statement", "stmt_sarah_heard_argument")

	var result: Dictionary = InterrogationManager.present_evidence("ev_shoe_print")
	assert_false(result.get("triggered", false))
	assert_eq(result.get("reason", ""), "wrong_focus",
		"Should return wrong_focus when evidence is correct but focus doesn't match")


# =========================================================================
# Test 24: Break-unlocked topic appears in available topics after break
# =========================================================================

func test_break_unlocked_topic_available_after_break() -> void:
	_start_sarah()
	GameManager.discover_evidence("ev_hallway_camera")
	GameManager.discover_evidence("ev_shoe_print")

	# Fire both triggers to reach pressure 2
	InterrogationManager.select_focus("statement", "stmt_sarah_initial")
	InterrogationManager.present_evidence("ev_hallway_camera")

	InterrogationManager.select_focus("statement", "stmt_sarah_confronted")
	InterrogationManager.present_evidence("ev_shoe_print")

	# Verify topic_sarah_after_break is NOT available before break
	var topic_ids_before: Array[String] = _get_topic_ids()
	assert_does_not_have(topic_ids_before, "topic_sarah_after_break",
		"Break topic should not be available before applying pressure")

	# Apply pressure → break
	var break_result: Dictionary = InterrogationManager.apply_pressure()
	assert_true(break_result.get("break_moment", false))

	# Verify topic_sarah_after_break IS available after break
	var topic_ids_after: Array[String] = _get_topic_ids()
	assert_has(topic_ids_after, "topic_sarah_after_break",
		"'Can you describe her?' topic should be available after break")

	# Verify the break_unlocks data matches what we expect
	var session: InterrogationSessionData = CaseManager.get_interrogation_session("p_sarah")
	assert_has(session.break_unlocks, "topic_sarah_after_break",
		"Session break_unlocks should contain the after-break topic")
