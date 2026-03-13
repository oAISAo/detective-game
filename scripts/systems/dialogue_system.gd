## DialogueSystem.gd
## Lightweight dialogue display system for investigation narrative.
## Handles character portrait + text + continue flow.
## Phase 3: Simple queue-based dialogue — NOT branching dialogue trees.
## Used for chief communications, technician updates, morning briefings.
extends Node


# --- Signals --- #

## Emitted when a new dialogue sequence starts.
signal dialogue_started(dialogue_id: String)

## Emitted when the current dialogue line advances.
signal dialogue_advanced(current_index: int, total_lines: int)

## Emitted when a dialogue line is displayed.
signal dialogue_line_displayed(speaker: String, text: String, portrait_id: String)

## Emitted when the current dialogue sequence ends.
signal dialogue_ended(dialogue_id: String)

## Emitted when the dialogue queue is empty after completing a sequence.
signal all_dialogues_completed


# --- State --- #

## Queue of dialogue sequences waiting to be shown.
## Each entry: { "id": String, "source_trigger": String, "lines": Array[Dictionary] }
## Each line: { "speaker": String, "text": String, "portrait": String }
var _dialogue_queue: Array[Dictionary] = []

## The currently active dialogue sequence (null if none).
var _current_dialogue: Dictionary = {}

## Index of the current line within the active dialogue.
var _current_line_index: int = -1

## Whether a dialogue is currently being displayed.
var _is_active: bool = false

## History of shown dialogues for save/debug.
var _dialogue_history: Array[String] = []


# --- Lifecycle --- #

func _ready() -> void:
	print("[DialogueSystem] Initialized.")


# --- Public API --- #

## Queues a dialogue for display.
## dialogue_key: An identifier used to look up or describe the dialogue.
## source_trigger: The trigger ID that initiated this dialogue (for tracking).
## lines: Array of dialogue line dictionaries.
##   Each line: { "speaker": "Name", "text": "Dialogue text", "portrait": "portrait_id" }
func queue_dialogue(dialogue_key: String, source_trigger: String = "", lines: Array[Dictionary] = []) -> void:
	var entry: Dictionary = {
		"id": dialogue_key,
		"source_trigger": source_trigger,
		"lines": lines.duplicate(true),
	}
	_dialogue_queue.append(entry)

	# Auto-start if no dialogue is active
	if not _is_active:
		_start_next_dialogue()


## Queues a simple single-line dialogue (convenience).
func queue_simple(speaker: String, text: String, portrait: String = "", dialogue_id: String = "") -> void:
	var did: String = dialogue_id if not dialogue_id.is_empty() else "simple_%d" % Time.get_ticks_msec()
	var lines: Array[Dictionary] = [{"speaker": speaker, "text": text, "portrait": portrait}]
	queue_dialogue(did, "", lines)


## Queues a morning briefing as a dialogue sequence.
func queue_briefing(briefing_items: Array[String], day: int) -> void:
	if briefing_items.is_empty():
		return

	var lines: Array[Dictionary] = []
	lines.append({
		"speaker": "Chief",
		"text": "Good morning, detective. Here's your briefing for Day %d." % day,
		"portrait": "chief",
	})

	for item: String in briefing_items:
		lines.append({
			"speaker": "Chief",
			"text": item,
			"portrait": "chief",
		})

	queue_dialogue("morning_briefing_day_%d" % day, "", lines)


## Advances to the next line in the current dialogue.
## Returns true if there was a next line, false if the dialogue ended.
func advance() -> bool:
	if not _is_active:
		return false

	_current_line_index += 1

	var lines: Array = _current_dialogue.get("lines", [])
	if _current_line_index >= lines.size():
		# Dialogue sequence complete
		_end_current_dialogue()
		return false

	var line: Dictionary = lines[_current_line_index] as Dictionary
	dialogue_line_displayed.emit(
		line.get("speaker", ""),
		line.get("text", ""),
		line.get("portrait", ""),
	)
	dialogue_advanced.emit(_current_line_index, lines.size())
	return true


## Skips the current dialogue entirely and moves to the next in queue.
func skip_current() -> void:
	if _is_active:
		_end_current_dialogue()


## Returns whether a dialogue is currently active.
func is_active() -> bool:
	return _is_active


## Returns the current dialogue info, or empty dict if none.
func get_current_dialogue() -> Dictionary:
	return _current_dialogue


## Returns the current line data, or empty dict.
func get_current_line() -> Dictionary:
	if not _is_active:
		return {}
	var lines: Array = _current_dialogue.get("lines", [])
	if _current_line_index < 0 or _current_line_index >= lines.size():
		return {}
	return lines[_current_line_index] as Dictionary


## Returns how many dialogues are queued (excluding the current one).
func get_queue_size() -> int:
	return _dialogue_queue.size()


## Returns the dialogue history (IDs of completed dialogues).
func get_dialogue_history() -> Array[String]:
	return _dialogue_history.duplicate()


## Returns whether a specific dialogue has been shown.
func has_shown_dialogue(dialogue_id: String) -> bool:
	return dialogue_id in _dialogue_history


## Clears the dialogue queue and ends any active dialogue.
func clear_queue() -> void:
	_dialogue_queue.clear()
	if _is_active:
		var did: String = _current_dialogue.get("id", "")
		_is_active = false
		_current_dialogue = {}
		_current_line_index = -1
		dialogue_ended.emit(did)


# --- Internal --- #

## Starts the next dialogue in the queue.
func _start_next_dialogue() -> void:
	if _dialogue_queue.is_empty():
		all_dialogues_completed.emit()
		return

	_current_dialogue = _dialogue_queue.pop_front()
	_current_line_index = -1
	_is_active = true

	var did: String = _current_dialogue.get("id", "")
	dialogue_started.emit(did)

	# Auto-advance to first line
	advance()


## Ends the current dialogue and starts the next one if available.
func _end_current_dialogue() -> void:
	var did: String = _current_dialogue.get("id", "")
	_dialogue_history.append(did)
	_is_active = false
	_current_dialogue = {}
	_current_line_index = -1
	dialogue_ended.emit(did)

	# Auto-start next dialogue if queue is not empty
	if not _dialogue_queue.is_empty():
		_start_next_dialogue()
	else:
		all_dialogues_completed.emit()


# --- Serialization --- #

## Returns state for save/load.
func serialize() -> Dictionary:
	return {
		"dialogue_history": _dialogue_history.duplicate(),
		"dialogue_queue": _dialogue_queue.duplicate(true),
	}


## Restores state from saved data.
func deserialize(data: Dictionary) -> void:
	_dialogue_history.assign(data.get("dialogue_history", []))
	_dialogue_queue.assign(data.get("dialogue_queue", []))
	_is_active = false
	_current_dialogue = {}
	_current_line_index = -1


## Resets all DialogueSystem state for a new game.
func reset() -> void:
	_dialogue_queue.clear()
	_dialogue_history.clear()
	_is_active = false
	_current_dialogue = {}
	_current_line_index = -1
