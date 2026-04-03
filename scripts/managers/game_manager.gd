## GameManager.gd
## Global game state controller. Manages the current investigation state,
## day progression, action economy, and acts as the central hub for
## cross-system communication via signals.
extends Node


# --- Signals --- #

## Emitted when the current day changes.
signal day_changed(new_day: int)

## Emitted when the day phase changes.
signal phase_changed(new_phase: Enums.DayPhase)

## Emitted when the number of remaining actions changes.
signal actions_remaining_changed(remaining: int)

## Emitted when new evidence is discovered.
signal evidence_discovered(evidence_id: String)

## Emitted when a new insight is created.
signal insight_discovered(insight_id: String)

## Emitted when a location is visited for the first time.
signal location_visited(location_id: String)

## Emitted when a location is unlocked.
signal location_unlocked(location_id: String)

## Emitted when a suspect becomes available for interrogation.
signal interrogation_unlocked(person_id: String)

## Emitted when an interrogation is completed.
@warning_ignore("unused_signal")
signal interrogation_completed(person_id: String)

## Emitted when a mandatory action is completed.
signal mandatory_action_completed(action_id: String)

## Emitted when the game state is reset (new game).
signal game_reset


# --- Constants --- #

## Number of major actions the player gets per day.
const ACTIONS_PER_DAY: int = 4

## Maximum number of hints per case.
const MAX_HINTS_PER_CASE: int = 3

## Maximum interrogations per suspect per day.
const MAX_INTERROGATIONS_PER_DAY: int = 1


# --- Game State --- #

## The current investigation day (1-4).
var current_day: int = 1

## The current phase within the day (Morning, Daytime, Night).
var current_phase: Enums.DayPhase = Enums.DayPhase.MORNING

## How many major actions the player has left today.
var actions_remaining: int = ACTIONS_PER_DAY

## IDs of all evidence the player has discovered.
var discovered_evidence: Array[String] = []

## IDs of all insights the player has created.
var discovered_insights: Array[String] = []

## IDs of all locations the player has visited.
var visited_locations: Array[String] = []

## IDs of all locations available to the player (unlocked via events).
var unlocked_locations: Array[String] = []

## IDs of suspects available for interrogation (unlocked via events).
var unlocked_interrogations: Array[String] = []

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

## Chronological log of all player actions.
var investigation_log: Array[Dictionary] = []

## How many hints the player has used this case.
var hints_used: int = 0

## Whether the game is currently running.
var game_active: bool = false

## Whether debug mode is active (shows extra status text in UI).
var debug_mode: bool = false

## Registry of subsystems that auto-register for reset/serialize/deserialize.
var _subsystems: Array[Node] = []


# --- Subsystem Registry --- #

## Registers a subsystem so it participates in reset/serialize/deserialize.
func register_subsystem(subsystem: Node) -> void:
	if subsystem not in _subsystems:
		_subsystems.append(subsystem)


## Unregisters a subsystem.
func unregister_subsystem(subsystem: Node) -> void:
	_subsystems.erase(subsystem)


# --- Lifecycle --- #

func _ready() -> void:
	pass


## Starts a new investigation, resetting all state.
func new_game() -> void:
	current_day = get_start_day()
	current_phase = Enums.DayPhase.MORNING
	actions_remaining = ACTIONS_PER_DAY
	discovered_evidence.clear()
	discovered_insights.clear()
	visited_locations.clear()
	unlocked_locations.clear()
	unlocked_interrogations.clear()
	completed_interrogations.clear()
	interrogation_counts_today.clear()
	active_lab_requests.clear()
	active_surveillance.clear()
	mandatory_actions_required.clear()
	mandatory_actions_completed.clear()
	warrants_obtained.clear()
	investigation_log.clear()
	hints_used = 0
	game_active = true
	debug_mode = false

	# Reset all registered subsystems
	for subsystem in _subsystems:
		subsystem.reset()

	game_reset.emit()


# --- Evidence --- #

## Discovers a piece of evidence by ID. Returns true if newly discovered.
func discover_evidence(evidence_id: String) -> bool:
	if evidence_id in discovered_evidence:
		return false
	discovered_evidence.append(evidence_id)
	evidence_discovered.emit(evidence_id)
	var ev: EvidenceData = CaseManager.get_evidence(evidence_id)
	var ev_name: String = ev.name if ev else evidence_id
	log_action("Evidence discovered: %s" % ev_name)
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
	log_action("New insight discovered")
	return true


# --- Locations --- #

## Unlocks a location, making it available on the map. Returns true if newly unlocked.
func unlock_location(location_id: String) -> bool:
	if location_id in unlocked_locations:
		return false
	unlocked_locations.append(location_id)
	location_unlocked.emit(location_id)
	var loc: LocationData = CaseManager.get_location(location_id)
	var loc_name: String = loc.name if loc else location_id
	log_action("New location available: %s" % loc_name)
	return true


## Returns true if the given location has been unlocked.
func is_location_unlocked(location_id: String) -> bool:
	return location_id in unlocked_locations


## Marks a location as visited. Returns true if first visit.
func visit_location(location_id: String) -> bool:
	if location_id in visited_locations:
		return false
	visited_locations.append(location_id)
	# Also ensure it's in unlocked list
	if location_id not in unlocked_locations:
		unlocked_locations.append(location_id)
	location_visited.emit(location_id)
	var loc: LocationData = CaseManager.get_location(location_id)
	var loc_name: String = loc.name if loc else location_id
	log_action("Location visited: %s" % loc_name)
	return true


## Returns true if the given location has been visited.
func has_visited_location(location_id: String) -> bool:
	return location_id in visited_locations


# --- Interrogation Unlocking --- #

## Unlocks a suspect for interrogation. Returns true if newly unlocked.
func unlock_interrogation(person_id: String) -> bool:
	if person_id in unlocked_interrogations:
		return false
	unlocked_interrogations.append(person_id)
	interrogation_unlocked.emit(person_id)
	var person: PersonData = CaseManager.get_person(person_id)
	var person_name: String = person.name if person else person_id
	log_action("Suspect available for questioning: %s" % person_name)
	return true


## Returns true if the given suspect is unlocked for interrogation.
func is_interrogation_unlocked(person_id: String) -> bool:
	return person_id in unlocked_interrogations


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
	log_action("Mandatory action completed: %s" % action_id)
	return true


## Returns the list of mandatory actions not yet completed.
func get_remaining_mandatory_actions() -> Array[String]:
	var remaining: Array[String] = []
	for action_id: String in mandatory_actions_required:
		if action_id not in mandatory_actions_completed:
			remaining.append(action_id)
	return remaining


# --- Day Phase --- #

## Returns the first investigation day from CaseData (fallback: 1).
func get_start_day() -> int:
	var cd: CaseData = CaseManager.get_case_data()
	return cd.start_day if cd else 1


## Returns the last investigation day from CaseData (fallback: 4).
func get_total_days() -> int:
	var cd: CaseData = CaseManager.get_case_data()
	return cd.end_day if cd else 4


## Sets the current phase and emits the phase_changed signal.
func set_phase(new_phase: Enums.DayPhase) -> void:
	current_phase = new_phase
	phase_changed.emit(current_phase)


## Resets action points to the daily maximum and emits the signal.
func reset_actions() -> void:
	actions_remaining = ACTIONS_PER_DAY
	actions_remaining_changed.emit(actions_remaining)


## Advances to the next day, clears daily interrogation counts, and emits day_changed.
func advance_day() -> void:
	current_day += 1
	interrogation_counts_today.clear()
	day_changed.emit(current_day)


## Returns a display string for the current phase.
func get_phase_display() -> String:
	match current_phase:
		Enums.DayPhase.MORNING:
			return "Morning"
		Enums.DayPhase.DAYTIME:
			return "Daytime"
		Enums.DayPhase.NIGHT:
			return "Night"
	return "Unknown"


## Returns true if the current phase is Daytime (the only phase allowing actions).
func is_daytime() -> bool:
	return current_phase == Enums.DayPhase.DAYTIME


# --- Investigation Log --- #

## Adds an entry to the investigation log.
func log_action(description: String) -> void:
	var entry: Dictionary = {
		"day": current_day,
		"phase": current_phase,
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
	log_action("Hint used (%d/%d)." % [hints_used, MAX_HINTS_PER_CASE])
	return true


## Returns the number of hints remaining.
func get_hints_remaining() -> int:
	return MAX_HINTS_PER_CASE - hints_used


# --- Serialization --- #

## Returns the full game state as a dictionary for saving.
func serialize() -> Dictionary:
	# Record which case is loaded so deserialize can restore it
	var case_data: CaseData = CaseManager.get_case_data()
	var case_id: String = case_data.id if case_data else ""

	var data: Dictionary = {
		"case_id": case_id,
		"current_day": current_day,
		"current_phase": current_phase,
		"actions_remaining": actions_remaining,
		"discovered_evidence": discovered_evidence.duplicate(),
		"discovered_insights": discovered_insights.duplicate(),
		"visited_locations": visited_locations.duplicate(),
		"unlocked_locations": unlocked_locations.duplicate(),
		"unlocked_interrogations": unlocked_interrogations.duplicate(),
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

	# Serialize all registered subsystems
	for subsystem in _subsystems:
		var result: Dictionary = subsystem.serialize()
		if not result.is_empty():
			data[subsystem.name.to_snake_case()] = result

	return data


## Restores game state from a saved dictionary.
func deserialize(data: Dictionary) -> void:
	# Restore the case data first — all other managers depend on it
	var saved_case_id: String = data.get("case_id", "")
	if not saved_case_id.is_empty():
		var current_case: CaseData = CaseManager.get_case_data()
		if current_case == null or current_case.id != saved_case_id:
			CaseManager.unload_case()
			if not CaseManager.load_case_folder(saved_case_id):
				push_error("[GameManager] Failed to load case '%s' from save." % saved_case_id)
				return

	current_day = data.get("current_day", 1)
	current_phase = data.get("current_phase", Enums.DayPhase.MORNING) as Enums.DayPhase
	actions_remaining = data.get("actions_remaining", ACTIONS_PER_DAY)
	discovered_evidence.assign(data.get("discovered_evidence", []))
	discovered_insights.assign(data.get("discovered_insights", []))
	visited_locations.assign(data.get("visited_locations", []))
	unlocked_locations.assign(data.get("unlocked_locations", []))
	unlocked_interrogations.assign(data.get("unlocked_interrogations", []))
	completed_interrogations = data.get("completed_interrogations", {}).duplicate(true)
	interrogation_counts_today = data.get("interrogation_counts_today", {}).duplicate(true)
	active_lab_requests = data.get("active_lab_requests", []).duplicate(true)
	active_surveillance = data.get("active_surveillance", []).duplicate(true)
	mandatory_actions_required.assign(data.get("mandatory_actions_required", []))
	mandatory_actions_completed.assign(data.get("mandatory_actions_completed", []))
	warrants_obtained.assign(data.get("warrants_obtained", []))
	investigation_log.assign(data.get("investigation_log", []))
	hints_used = data.get("hints_used", 0)
	game_active = data.get("game_active", false)

	# Restore all registered subsystems
	for subsystem in _subsystems:
		var key: String = subsystem.name.to_snake_case()
		if data.has(key):
			subsystem.deserialize(data[key])

	# Re-emit core state signals so any listening UI refreshes after load
	day_changed.emit(current_day)
	phase_changed.emit(current_phase)
	actions_remaining_changed.emit(actions_remaining)
