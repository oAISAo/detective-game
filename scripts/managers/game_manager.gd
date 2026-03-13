## GameManager.gd
## Global game state controller. Manages the current investigation state,
## day progression, action economy, and acts as the central hub for
## cross-system communication via signals.
extends Node


# --- Signals --- #

## Emitted when the current day changes.
signal day_changed(new_day: int)

## Emitted when the time slot changes.
signal time_slot_changed(new_slot: Enums.TimeSlot)

## Emitted when the number of remaining actions changes.
signal actions_remaining_changed(remaining: int)

## Emitted when new evidence is discovered.
signal evidence_discovered(evidence_id: String)

## Emitted when a new insight is created.
signal insight_discovered(insight_id: String)

## Emitted when a location is visited for the first time.
signal location_visited(location_id: String)

## Emitted when an interrogation is completed.
@warning_ignore("unused_signal")
signal interrogation_completed(person_id: String)

## Emitted when a mandatory action is completed.
signal mandatory_action_completed(action_id: String)

## Emitted when the game state is reset (new game).
signal game_reset


# --- Constants --- #

## Number of days in the investigation.
const TOTAL_DAYS: int = 4

## Number of major actions the player gets per day.
const ACTIONS_PER_DAY: int = 2

## Maximum number of hints per case.
const MAX_HINTS_PER_CASE: int = 3

## Maximum interrogations per suspect per day.
const MAX_INTERROGATIONS_PER_DAY: int = 1


# --- Game State --- #

## The current investigation day (1-4).
var current_day: int = 1

## The current time slot within the day.
var current_time_slot: Enums.TimeSlot = Enums.TimeSlot.MORNING

## How many major actions the player has left today.
var actions_remaining: int = ACTIONS_PER_DAY

## IDs of all evidence the player has discovered.
var discovered_evidence: Array[String] = []

## IDs of all insights the player has created.
var discovered_insights: Array[String] = []

## IDs of all locations the player has visited.
var visited_locations: Array[String] = []

## Tracks completed interrogations: { person_id: [trigger_ids_fired] }
var completed_interrogations: Dictionary = {}

## Tracks how many times each suspect was interrogated today: { person_id: count }
var interrogation_counts_today: Dictionary = {}

## Active lab requests awaiting results.
var active_lab_requests: Array = []

## Active surveillance operations.
var active_surveillance: Array = []

## IDs of mandatory actions required before day can advance.
var mandatory_actions_required: Array[String] = []

## IDs of mandatory actions the player has completed.
var mandatory_actions_completed: Array[String] = []

## IDs of warrants the player has obtained.
var warrants_obtained: Array[String] = []

## The player's detective board state (serialized separately).
var player_board_state: Dictionary = {}

## The player's timeline data (serialized separately).
var player_timeline: Array = []

## The player's theories (serialized separately).
var player_theories: Array = []

## Chronological log of all player actions.
var investigation_log: Array[Dictionary] = []

## How many hints the player has used this case.
var hints_used: int = 0

## Whether the game is currently running.
var game_active: bool = false


# --- Lifecycle --- #

func _ready() -> void:
	print("[GameManager] Initialized.")


## Starts a new investigation, resetting all state.
func new_game() -> void:
	current_day = 1
	current_time_slot = Enums.TimeSlot.MORNING
	actions_remaining = ACTIONS_PER_DAY
	discovered_evidence.clear()
	discovered_insights.clear()
	visited_locations.clear()
	completed_interrogations.clear()
	interrogation_counts_today.clear()
	active_lab_requests.clear()
	active_surveillance.clear()
	mandatory_actions_required.clear()
	mandatory_actions_completed.clear()
	warrants_obtained.clear()
	player_board_state.clear()
	player_timeline.clear()
	player_theories.clear()
	investigation_log.clear()
	hints_used = 0
	game_active = true
	game_reset.emit()
	print("[GameManager] New game started.")


# --- Evidence --- #

## Discovers a piece of evidence by ID. Returns true if newly discovered.
func discover_evidence(evidence_id: String) -> bool:
	if evidence_id in discovered_evidence:
		return false
	discovered_evidence.append(evidence_id)
	evidence_discovered.emit(evidence_id)
	_log_action("Evidence discovered: %s" % evidence_id)
	return true


## Returns true if the given evidence has been discovered.
func has_evidence(evidence_id: String) -> bool:
	return evidence_id in discovered_evidence


# --- Insights --- #

## Discovers a new insight by ID. Returns true if newly discovered.
func discover_insight(insight_id: String) -> bool:
	if insight_id in discovered_insights:
		return false
	discovered_insights.append(insight_id)
	insight_discovered.emit(insight_id)
	_log_action("Insight discovered: %s" % insight_id)
	return true


# --- Locations --- #

## Marks a location as visited. Returns true if first visit.
func visit_location(location_id: String) -> bool:
	if location_id in visited_locations:
		return false
	visited_locations.append(location_id)
	location_visited.emit(location_id)
	_log_action("Location visited: %s" % location_id)
	return true


## Returns true if the given location has been visited.
func has_visited_location(location_id: String) -> bool:
	return location_id in visited_locations


# --- Actions --- #

## Uses a major action (costs 1 slot). Returns true if action was available.
func use_action() -> bool:
	if actions_remaining <= 0:
		return false
	actions_remaining -= 1
	actions_remaining_changed.emit(actions_remaining)
	return true


## Returns true if the player has actions remaining.
func has_actions_remaining() -> bool:
	return actions_remaining > 0


# --- Mandatory Actions --- #

## Checks if all mandatory actions are completed.
func all_mandatory_actions_completed() -> bool:
	for action_id: String in mandatory_actions_required:
		if action_id not in mandatory_actions_completed:
			return false
	return true


## Completes a mandatory action. Returns true if it was required.
func complete_mandatory_action(action_id: String) -> bool:
	if action_id not in mandatory_actions_required:
		return false
	if action_id in mandatory_actions_completed:
		return false
	mandatory_actions_completed.append(action_id)
	mandatory_action_completed.emit(action_id)
	_log_action("Mandatory action completed: %s" % action_id)
	return true


## Returns the list of mandatory actions not yet completed.
func get_remaining_mandatory_actions() -> Array[String]:
	var remaining: Array[String] = []
	for action_id: String in mandatory_actions_required:
		if action_id not in mandatory_actions_completed:
			remaining.append(action_id)
	return remaining


# --- Day Progression --- #

## Advances the time slot. Returns the new time slot.
func advance_time_slot() -> Enums.TimeSlot:
	match current_time_slot:
		Enums.TimeSlot.MORNING:
			current_time_slot = Enums.TimeSlot.AFTERNOON
		Enums.TimeSlot.AFTERNOON:
			current_time_slot = Enums.TimeSlot.EVENING
		Enums.TimeSlot.EVENING:
			current_time_slot = Enums.TimeSlot.NIGHT
		Enums.TimeSlot.NIGHT:
			# Night triggers day transition
			_advance_day()
			return current_time_slot
	time_slot_changed.emit(current_time_slot)
	return current_time_slot


## Returns a display string for the current time slot.
func get_time_slot_display() -> String:
	match current_time_slot:
		Enums.TimeSlot.MORNING:
			return "Morning"
		Enums.TimeSlot.AFTERNOON:
			return "Afternoon"
		Enums.TimeSlot.EVENING:
			return "Evening"
		Enums.TimeSlot.NIGHT:
			return "Night"
	return "Unknown"


## Advances to the next day. Called internally from night processing.
func _advance_day() -> void:
	if current_day >= TOTAL_DAYS:
		_log_action("Investigation complete — Day %d ended." % current_day)
		# End of investigation handling will be in Phase 12
		return

	current_day += 1
	current_time_slot = Enums.TimeSlot.MORNING
	actions_remaining = ACTIONS_PER_DAY
	interrogation_counts_today.clear()

	day_changed.emit(current_day)
	time_slot_changed.emit(current_time_slot)
	actions_remaining_changed.emit(actions_remaining)
	_log_action("Day %d begins." % current_day)


# --- Investigation Log --- #

## Adds an entry to the investigation log.
func _log_action(description: String) -> void:
	var entry: Dictionary = {
		"day": current_day,
		"time_slot": current_time_slot,
		"description": description,
		"timestamp": Time.get_unix_time_from_system(),
	}
	investigation_log.append(entry)


## Returns the full investigation log.
func get_investigation_log() -> Array[Dictionary]:
	return investigation_log


# --- Interrogation Tracking --- #

## Records an interrogation for a suspect today. Returns true if allowed.
func record_interrogation(person_id: String) -> bool:
	var count: int = interrogation_counts_today.get(person_id, 0)
	if count >= MAX_INTERROGATIONS_PER_DAY:
		return false
	interrogation_counts_today[person_id] = count + 1
	return true


## Returns true if the suspect can still be interrogated today.
func can_interrogate_today(person_id: String) -> bool:
	var count: int = interrogation_counts_today.get(person_id, 0)
	return count < MAX_INTERROGATIONS_PER_DAY


# --- Hints --- #

## Uses a hint. Returns true if hints remain.
func use_hint() -> bool:
	if hints_used >= MAX_HINTS_PER_CASE:
		return false
	hints_used += 1
	_log_action("Hint used (%d/%d)." % [hints_used, MAX_HINTS_PER_CASE])
	return true


## Returns the number of hints remaining.
func get_hints_remaining() -> int:
	return MAX_HINTS_PER_CASE - hints_used


# --- Serialization --- #

## Returns the full game state as a dictionary for saving.
func serialize() -> Dictionary:
	return {
		"current_day": current_day,
		"current_time_slot": current_time_slot,
		"actions_remaining": actions_remaining,
		"discovered_evidence": discovered_evidence.duplicate(),
		"discovered_insights": discovered_insights.duplicate(),
		"visited_locations": visited_locations.duplicate(),
		"completed_interrogations": completed_interrogations.duplicate(true),
		"interrogation_counts_today": interrogation_counts_today.duplicate(),
		"active_lab_requests": active_lab_requests.duplicate(true),
		"active_surveillance": active_surveillance.duplicate(true),
		"mandatory_actions_required": mandatory_actions_required.duplicate(),
		"mandatory_actions_completed": mandatory_actions_completed.duplicate(),
		"warrants_obtained": warrants_obtained.duplicate(),
		"investigation_log": investigation_log.duplicate(true),
		"hints_used": hints_used,
		"game_active": game_active,
	}


## Restores game state from a saved dictionary.
func deserialize(data: Dictionary) -> void:
	current_day = data.get("current_day", 1)
	current_time_slot = data.get("current_time_slot", Enums.TimeSlot.MORNING) as Enums.TimeSlot
	actions_remaining = data.get("actions_remaining", ACTIONS_PER_DAY)
	discovered_evidence.assign(data.get("discovered_evidence", []))
	discovered_insights.assign(data.get("discovered_insights", []))
	visited_locations.assign(data.get("visited_locations", []))
	completed_interrogations = data.get("completed_interrogations", {})
	interrogation_counts_today = data.get("interrogation_counts_today", {})
	active_lab_requests = data.get("active_lab_requests", [])
	active_surveillance = data.get("active_surveillance", [])
	mandatory_actions_required.assign(data.get("mandatory_actions_required", []))
	mandatory_actions_completed.assign(data.get("mandatory_actions_completed", []))
	warrants_obtained.assign(data.get("warrants_obtained", []))
	investigation_log.assign(data.get("investigation_log", []))
	hints_used = data.get("hints_used", 0)
	game_active = data.get("game_active", false)
