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

## Number of days in the investigation.
const TOTAL_DAYS: int = 4

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
	player_board_state.clear()
	player_timeline.clear()
	player_theories.clear()
	investigation_log.clear()
	hints_used = 0
	game_active = true

	# Reset Phase 2 systems if available
	var day_sys: Node = get_node_or_null("/root/DaySystem")
	if day_sys and day_sys.has_method("reset"):
		day_sys.call("reset")
	var action_sys: Node = get_node_or_null("/root/ActionSystem")
	if action_sys and action_sys.has_method("reset"):
		action_sys.call("reset")

	# Reset Phase 3 systems if available
	var event_sys: Node = get_node_or_null("/root/EventSystem")
	if event_sys and event_sys.has_method("reset"):
		event_sys.call("reset")
	var dialogue_sys: Node = get_node_or_null("/root/DialogueSystem")
	if dialogue_sys and dialogue_sys.has_method("reset"):
		dialogue_sys.call("reset")

	# Reset Phase 4 systems if available
	var screen_mgr: Node = get_node_or_null("/root/ScreenManager")
	if screen_mgr and screen_mgr.has_method("reset"):
		screen_mgr.call("reset")

	# Reset Phase 5 systems if available
	var evidence_mgr: Node = get_node_or_null("/root/EvidenceManager")
	if evidence_mgr and evidence_mgr.has_method("reset"):
		evidence_mgr.call("reset")

	# Reset Phase 6 systems if available
	var tool_mgr: Node = get_node_or_null("/root/ToolManager")
	if tool_mgr and tool_mgr.has_method("reset"):
		tool_mgr.call("reset")
	var loc_inv_mgr: Node = get_node_or_null("/root/LocationInvestigationManager")
	if loc_inv_mgr and loc_inv_mgr.has_method("reset"):
		loc_inv_mgr.call("reset")

	# Reset Phase 7 systems if available
	var interr_mgr: Node = get_node_or_null("/root/InterrogationManager")
	if interr_mgr and interr_mgr.has_method("reset"):
		interr_mgr.call("reset")

	# Reset Phase 8 systems if available
	var board_mgr: Node = get_node_or_null("/root/BoardManager")
	if board_mgr and board_mgr.has_method("reset"):
		board_mgr.call("reset")

	# Reset Phase 9 systems if available
	var timeline_mgr: Node = get_node_or_null("/root/TimelineManager")
	if timeline_mgr and timeline_mgr.has_method("reset"):
		timeline_mgr.call("reset")

	# Reset Phase 10 systems if available
	var theory_mgr: Node = get_node_or_null("/root/TheoryManager")
	if theory_mgr and theory_mgr.has_method("reset"):
		theory_mgr.call("reset")

	# Reset Phase 11 systems if available
	var lab_mgr: Node = get_node_or_null("/root/LabManager")
	if lab_mgr and lab_mgr.has_method("reset"):
		lab_mgr.call("reset")
	var surv_mgr: Node = get_node_or_null("/root/SurveillanceManager")
	if surv_mgr and surv_mgr.has_method("reset"):
		surv_mgr.call("reset")
	var warrant_mgr: Node = get_node_or_null("/root/WarrantManager")
	if warrant_mgr and warrant_mgr.has_method("reset"):
		warrant_mgr.call("reset")

	# Reset Phase 12 systems if available
	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	if concl_mgr and concl_mgr.has_method("reset"):
		concl_mgr.call("reset")

	game_reset.emit()
	print("[GameManager] New game started.")


# --- Evidence --- #

## Discovers a piece of evidence by ID. Returns true if newly discovered.
func discover_evidence(evidence_id: String) -> bool:
	if evidence_id in discovered_evidence:
		return false
	discovered_evidence.append(evidence_id)
	evidence_discovered.emit(evidence_id)
	var ev: EvidenceData = CaseManager.get_evidence(evidence_id)
	var ev_name: String = ev.name if ev else evidence_id
	_log_action("Evidence discovered: %s" % ev_name)
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
	_log_action("New insight discovered")
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
	_log_action("New location available: %s" % loc_name)
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
	_log_action("Location visited: %s" % loc_name)
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
	_log_action("Suspect available for questioning: %s" % person_name)
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
	_log_action("Mandatory action completed: %s" % action_id)
	return true


## Returns the list of mandatory actions not yet completed.
func get_remaining_mandatory_actions() -> Array[String]:
	var remaining: Array[String] = []
	for action_id: String in mandatory_actions_required:
		if action_id not in mandatory_actions_completed:
			remaining.append(action_id)
	return remaining


# --- Day Phase --- #

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
func _log_action(description: String) -> void:
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
	_log_action("Hint used (%d/%d)." % [hints_used, MAX_HINTS_PER_CASE])
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

	# Include Phase 2 system state if available
	var day_sys: Node = get_node_or_null("/root/DaySystem")
	if day_sys and day_sys.has_method("serialize"):
		data["day_system"] = day_sys.call("serialize")
	var action_sys: Node = get_node_or_null("/root/ActionSystem")
	if action_sys and action_sys.has_method("serialize"):
		data["action_system"] = action_sys.call("serialize")

	# Include Phase 3 system state if available
	var event_sys: Node = get_node_or_null("/root/EventSystem")
	if event_sys and event_sys.has_method("serialize"):
		data["event_system"] = event_sys.call("serialize")

	# Include Phase 5 system state if available
	var evidence_mgr: Node = get_node_or_null("/root/EvidenceManager")
	if evidence_mgr and evidence_mgr.has_method("serialize"):
		data["evidence_manager"] = evidence_mgr.call("serialize")

	# Include Phase 6 system state if available
	var tool_mgr: Node = get_node_or_null("/root/ToolManager")
	if tool_mgr and tool_mgr.has_method("serialize"):
		data["tool_manager"] = tool_mgr.call("serialize")
	var loc_inv_mgr: Node = get_node_or_null("/root/LocationInvestigationManager")
	if loc_inv_mgr and loc_inv_mgr.has_method("serialize"):
		data["location_investigation_manager"] = loc_inv_mgr.call("serialize")

	# Include Phase 7 system state if available
	var interr_mgr: Node = get_node_or_null("/root/InterrogationManager")
	if interr_mgr and interr_mgr.has_method("serialize"):
		data["interrogation_manager"] = interr_mgr.call("serialize")

	# Include Phase 8 system state if available
	var board_mgr: Node = get_node_or_null("/root/BoardManager")
	if board_mgr and board_mgr.has_method("serialize"):
		data["board_manager"] = board_mgr.call("serialize")

	# Include Phase 9 system state if available
	var timeline_mgr: Node = get_node_or_null("/root/TimelineManager")
	if timeline_mgr and timeline_mgr.has_method("serialize"):
		data["timeline_manager"] = timeline_mgr.call("serialize")

	# Include Phase 10 system state if available
	var theory_mgr: Node = get_node_or_null("/root/TheoryManager")
	if theory_mgr and theory_mgr.has_method("serialize"):
		data["theory_manager"] = theory_mgr.call("serialize")

	# Include Phase 11 system state if available
	var lab_mgr: Node = get_node_or_null("/root/LabManager")
	if lab_mgr and lab_mgr.has_method("serialize"):
		data["lab_manager"] = lab_mgr.call("serialize")
	var surv_mgr: Node = get_node_or_null("/root/SurveillanceManager")
	if surv_mgr and surv_mgr.has_method("serialize"):
		data["surveillance_manager"] = surv_mgr.call("serialize")
	var warrant_mgr: Node = get_node_or_null("/root/WarrantManager")
	if warrant_mgr and warrant_mgr.has_method("serialize"):
		data["warrant_manager"] = warrant_mgr.call("serialize")

	# Include Phase 12 system state if available
	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	if concl_mgr and concl_mgr.has_method("serialize"):
		data["conclusion_manager"] = concl_mgr.call("serialize")

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

	# Restore Phase 2 system state if available
	var day_sys: Node = get_node_or_null("/root/DaySystem")
	if day_sys and day_sys.has_method("deserialize") and data.has("day_system"):
		day_sys.call("deserialize", data["day_system"])
	var action_sys: Node = get_node_or_null("/root/ActionSystem")
	if action_sys and action_sys.has_method("deserialize") and data.has("action_system"):
		action_sys.call("deserialize", data["action_system"])

	# Restore Phase 3 system state if available
	var event_sys: Node = get_node_or_null("/root/EventSystem")
	if event_sys and event_sys.has_method("deserialize") and data.has("event_system"):
		event_sys.call("deserialize", data["event_system"])

	# Restore Phase 5 system state if available
	var evidence_mgr: Node = get_node_or_null("/root/EvidenceManager")
	if evidence_mgr and evidence_mgr.has_method("deserialize") and data.has("evidence_manager"):
		evidence_mgr.call("deserialize", data["evidence_manager"])

	# Restore Phase 6 system state if available
	var tool_mgr: Node = get_node_or_null("/root/ToolManager")
	if tool_mgr and tool_mgr.has_method("deserialize") and data.has("tool_manager"):
		tool_mgr.call("deserialize", data["tool_manager"])
	var loc_inv_mgr: Node = get_node_or_null("/root/LocationInvestigationManager")
	if loc_inv_mgr and loc_inv_mgr.has_method("deserialize") and data.has("location_investigation_manager"):
		loc_inv_mgr.call("deserialize", data["location_investigation_manager"])

	# Restore Phase 7 system state if available
	var interr_mgr: Node = get_node_or_null("/root/InterrogationManager")
	if interr_mgr and interr_mgr.has_method("deserialize") and data.has("interrogation_manager"):
		interr_mgr.call("deserialize", data["interrogation_manager"])

	# Restore Phase 8 system state if available
	var board_mgr: Node = get_node_or_null("/root/BoardManager")
	if board_mgr and board_mgr.has_method("deserialize") and data.has("board_manager"):
		board_mgr.call("deserialize", data["board_manager"])

	# Restore Phase 9 system state if available
	var timeline_mgr: Node = get_node_or_null("/root/TimelineManager")
	if timeline_mgr and timeline_mgr.has_method("deserialize") and data.has("timeline_manager"):
		timeline_mgr.call("deserialize", data["timeline_manager"])

	# Restore Phase 10 system state if available
	var theory_mgr: Node = get_node_or_null("/root/TheoryManager")
	if theory_mgr and theory_mgr.has_method("deserialize") and data.has("theory_manager"):
		theory_mgr.call("deserialize", data["theory_manager"])

	# Restore Phase 11 system state if available
	var lab_mgr: Node = get_node_or_null("/root/LabManager")
	if lab_mgr and lab_mgr.has_method("deserialize") and data.has("lab_manager"):
		lab_mgr.call("deserialize", data["lab_manager"])
	var surv_mgr: Node = get_node_or_null("/root/SurveillanceManager")
	if surv_mgr and surv_mgr.has_method("deserialize") and data.has("surveillance_manager"):
		surv_mgr.call("deserialize", data["surveillance_manager"])
	var warrant_mgr: Node = get_node_or_null("/root/WarrantManager")
	if warrant_mgr and warrant_mgr.has_method("deserialize") and data.has("warrant_manager"):
		warrant_mgr.call("deserialize", data["warrant_manager"])

	# Restore Phase 12 system state if available
	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	if concl_mgr and concl_mgr.has_method("deserialize") and data.has("conclusion_manager"):
		concl_mgr.call("deserialize", data["conclusion_manager"])

	# Re-emit core state signals so any listening UI refreshes after load
	day_changed.emit(current_day)
	phase_changed.emit(current_phase)
	actions_remaining_changed.emit(actions_remaining)
