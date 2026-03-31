## test_dialogue_system.gd
## Unit tests for the DialogueSystem singleton.
## Phase 3: Queue management, dialogue flow, signals, history, serialization.
extends GutTest


# --- Helpers --- #

func _reset_state() -> void:
	DialogueSystem.reset()


func _make_lines(count: int) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for i: int in range(count):
		lines.append({
			"speaker": "Speaker %d" % i,
			"text": "Line %d text" % i,
			"portrait": "portrait_%d" % i,
		})
	return lines


# --- Setup --- #

func before_each() -> void:
	_reset_state()


# --- Initialization --- #

func test_initial_state() -> void:
	assert_false(DialogueSystem.is_active(), "Should not be active initially")
	assert_eq(DialogueSystem.get_queue_size(), 0, "Queue should be empty initially")
	assert_eq(DialogueSystem.get_dialogue_history().size(), 0, "History should be empty initially")
	assert_eq(DialogueSystem.get_current_dialogue().size(), 0, "No current dialogue initially")
	assert_eq(DialogueSystem.get_current_line().size(), 0, "No current line initially")


func test_reset_clears_all() -> void:
	var lines: Array[Dictionary] = _make_lines(2)
	DialogueSystem.queue_dialogue("test_01", "", lines)
	DialogueSystem.reset()
	assert_false(DialogueSystem.is_active(), "Reset should deactivate")
	assert_eq(DialogueSystem.get_queue_size(), 0, "Reset should clear queue")
	assert_eq(DialogueSystem.get_dialogue_history().size(), 0, "Reset should clear history")


# --- Queue Dialogue --- #

func test_queue_dialogue_starts_immediately() -> void:
	var lines: Array[Dictionary] = _make_lines(2)
	DialogueSystem.queue_dialogue("test_01", "trig_01", lines)
	assert_true(DialogueSystem.is_active(), "Should auto-start the dialogue")


func test_queue_dialogue_emits_started_signal() -> void:
	watch_signals(DialogueSystem)
	var lines: Array[Dictionary] = _make_lines(2)
	DialogueSystem.queue_dialogue("test_01", "", lines)
	assert_signal_emitted(DialogueSystem, "dialogue_started")


func test_queue_dialogue_shows_first_line() -> void:
	var lines: Array[Dictionary] = _make_lines(3)
	DialogueSystem.queue_dialogue("test_01", "", lines)
	var current: Dictionary = DialogueSystem.get_current_line()
	assert_eq(current.get("speaker", ""), "Speaker 0")
	assert_eq(current.get("text", ""), "Line 0 text")


func test_queue_multiple_dialogues() -> void:
	var lines1: Array[Dictionary] = _make_lines(1)
	var lines2: Array[Dictionary] = _make_lines(1)
	DialogueSystem.queue_dialogue("test_01", "", lines1)
	DialogueSystem.queue_dialogue("test_02", "", lines2)
	# First dialogue is active, second is queued
	assert_true(DialogueSystem.is_active())
	assert_eq(DialogueSystem.get_queue_size(), 1, "Second dialogue should be in queue")


# --- Advance --- #

func test_advance_to_next_line() -> void:
	var lines: Array[Dictionary] = _make_lines(3)
	DialogueSystem.queue_dialogue("test_01", "", lines)
	# Currently on line 0
	assert_eq(DialogueSystem.get_current_line().get("text", ""), "Line 0 text")

	# Advance to line 1
	var has_next: bool = DialogueSystem.advance()
	assert_true(has_next, "Should have a next line")
	assert_eq(DialogueSystem.get_current_line().get("text", ""), "Line 1 text")

	# Advance to line 2
	has_next = DialogueSystem.advance()
	assert_true(has_next, "Should have a next line")
	assert_eq(DialogueSystem.get_current_line().get("text", ""), "Line 2 text")

	# Advance past end
	has_next = DialogueSystem.advance()
	assert_false(has_next, "No more lines")
	assert_false(DialogueSystem.is_active(), "Should be deactivated after last line")


func test_advance_emits_dialogue_advanced() -> void:
	var lines: Array[Dictionary] = _make_lines(2)
	DialogueSystem.queue_dialogue("test_01", "", lines)
	watch_signals(DialogueSystem)
	DialogueSystem.advance()
	assert_signal_emitted(DialogueSystem, "dialogue_advanced")


func test_advance_emits_dialogue_line_displayed() -> void:
	var lines: Array[Dictionary] = _make_lines(2)
	watch_signals(DialogueSystem)
	DialogueSystem.queue_dialogue("test_01", "", lines)
	assert_signal_emitted(DialogueSystem, "dialogue_line_displayed")


func test_advance_when_not_active_returns_false() -> void:
	assert_false(DialogueSystem.advance(), "Should return false when not active")


# --- Dialogue End --- #

func test_dialogue_ended_signal() -> void:
	var lines: Array[Dictionary] = _make_lines(1)
	DialogueSystem.queue_dialogue("test_01", "", lines)
	watch_signals(DialogueSystem)
	# Advance past the only line
	DialogueSystem.advance()
	assert_signal_emitted(DialogueSystem, "dialogue_ended")


func test_dialogue_ended_adds_to_history() -> void:
	var lines: Array[Dictionary] = _make_lines(1)
	DialogueSystem.queue_dialogue("test_01", "", lines)
	# Advance past the only line
	DialogueSystem.advance()
	assert_true(DialogueSystem.has_shown_dialogue("test_01"))


func test_dialogue_chain_auto_starts_next() -> void:
	var lines1: Array[Dictionary] = _make_lines(1)
	var lines2: Array[Dictionary] = _make_lines(1)
	DialogueSystem.queue_dialogue("first", "", lines1)
	DialogueSystem.queue_dialogue("second", "", lines2)

	# Finish first dialogue
	DialogueSystem.advance()

	# Second should auto-start
	assert_true(DialogueSystem.is_active(), "Second dialogue should auto-start")
	assert_eq(DialogueSystem.get_current_dialogue().get("id", ""), "second")


func test_all_dialogues_completed_signal() -> void:
	var lines: Array[Dictionary] = _make_lines(1)
	DialogueSystem.queue_dialogue("only", "", lines)
	watch_signals(DialogueSystem)
	DialogueSystem.advance()
	assert_signal_emitted(DialogueSystem, "all_dialogues_completed")


# --- Skip Current --- #

func test_skip_current_ends_dialogue() -> void:
	var lines: Array[Dictionary] = _make_lines(5)
	DialogueSystem.queue_dialogue("test_01", "", lines)
	DialogueSystem.skip_current()
	assert_true(DialogueSystem.has_shown_dialogue("test_01"))


func test_skip_current_starts_next_in_queue() -> void:
	var lines: Array[Dictionary] = _make_lines(3)
	DialogueSystem.queue_dialogue("first", "", lines)
	DialogueSystem.queue_dialogue("second", "", _make_lines(1))
	DialogueSystem.skip_current()
	assert_true(DialogueSystem.is_active())
	assert_eq(DialogueSystem.get_current_dialogue().get("id", ""), "second")


func test_skip_when_not_active() -> void:
	# Should not crash
	DialogueSystem.skip_current()
	assert_false(DialogueSystem.is_active())


# --- Queue Simple --- #

func test_queue_simple_single_line() -> void:
	DialogueSystem.queue_simple("Chief", "Hello detective.", "chief", "simple_test")
	assert_true(DialogueSystem.is_active())
	var line: Dictionary = DialogueSystem.get_current_line()
	assert_eq(line.get("speaker", ""), "Chief")
	assert_eq(line.get("text", ""), "Hello detective.")
	assert_eq(line.get("portrait", ""), "chief")


# --- Queue Briefing --- #

func test_queue_briefing_creates_dialogue() -> void:
	var items: Array[String] = ["Lab results ready.", "New suspect identified."]
	DialogueSystem.queue_briefing(items, 2)
	assert_true(DialogueSystem.is_active())
	# First line is the greeting
	var line: Dictionary = DialogueSystem.get_current_line()
	assert_eq(line.get("speaker", ""), "Chief")
	assert_true("Day 2" in line.get("text", ""), "Should mention the day")


func test_queue_briefing_includes_all_items() -> void:
	var items: Array[String] = ["Item 1", "Item 2", "Item 3"]
	DialogueSystem.queue_briefing(items, 1)
	# Greeting + 3 items = 4 lines
	var dialogue: Dictionary = DialogueSystem.get_current_dialogue()
	var lines: Array = dialogue.get("lines", [])
	assert_eq(lines.size(), 4, "Should have greeting + 3 items")


func test_queue_briefing_empty_items_no_dialogue() -> void:
	var items: Array[String] = []
	DialogueSystem.queue_briefing(items, 1)
	assert_false(DialogueSystem.is_active(), "Empty briefing should not create dialogue")


# --- has_shown_dialogue --- #

func test_has_shown_dialogue() -> void:
	assert_false(DialogueSystem.has_shown_dialogue("test_01"))
	var lines: Array[Dictionary] = _make_lines(1)
	DialogueSystem.queue_dialogue("test_01", "", lines)
	DialogueSystem.advance()  # Complete dialogue
	assert_true(DialogueSystem.has_shown_dialogue("test_01"))


# --- Clear Queue --- #

func test_clear_queue_stops_everything() -> void:
	DialogueSystem.queue_dialogue("d1", "", _make_lines(3))
	DialogueSystem.queue_dialogue("d2", "", _make_lines(2))
	DialogueSystem.clear_queue()
	assert_false(DialogueSystem.is_active())
	assert_eq(DialogueSystem.get_queue_size(), 0)


func test_clear_queue_emits_ended() -> void:
	DialogueSystem.queue_dialogue("d1", "", _make_lines(3))
	watch_signals(DialogueSystem)
	DialogueSystem.clear_queue()
	assert_signal_emitted(DialogueSystem, "dialogue_ended")


# --- Serialization --- #

func test_serialize_returns_dictionary() -> void:
	var data: Dictionary = DialogueSystem.serialize()
	assert_has(data, "dialogue_history", "Should contain dialogue_history")
	assert_has(data, "dialogue_queue", "Should contain dialogue_queue")


func test_deserialize_restores_history() -> void:
	# Manually set history
	DialogueSystem._dialogue_history.append("test_01")
	DialogueSystem._dialogue_history.append("test_02")
	var data: Dictionary = DialogueSystem.serialize()

	DialogueSystem.reset()
	DialogueSystem.deserialize(data)
	assert_eq(DialogueSystem.get_dialogue_history().size(), 2)
	assert_true(DialogueSystem.has_shown_dialogue("test_01"))
	assert_true(DialogueSystem.has_shown_dialogue("test_02"))


func test_serialize_round_trip() -> void:
	DialogueSystem._dialogue_history.append("hist_a")
	DialogueSystem._dialogue_queue.append({"id": "queued", "lines": []})
	var original: Dictionary = DialogueSystem.serialize()

	DialogueSystem.reset()
	DialogueSystem.deserialize(original)
	var restored: Dictionary = DialogueSystem.serialize()

	assert_eq(restored["dialogue_history"].size(), original["dialogue_history"].size())
	assert_eq(restored["dialogue_queue"].size(), original["dialogue_queue"].size())


# --- Morning Briefing Queue --- #

func test_morning_briefing_can_be_queued() -> void:
	DialogueSystem.reset()
	var items: Array[String] = ["Lab results ready", "New suspect available"]
	DialogueSystem.queue_briefing(items, 1)
	assert_true(DialogueSystem.is_active(),
		"DialogueSystem should be active after queuing briefing")
	DialogueSystem.reset()
