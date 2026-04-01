## DaySystem.gd
## Manages the investigation day cycle as an explicit state machine.
## State flow: MORNING → DAYTIME → NIGHT → (next day) MORNING → ...
##
## Morning: Informational only — briefing, lab results, surveillance results, story events.
##          Automatically transitions to Daytime after processing.
## Daytime: Player performs actions (4 per day). Transitions to Night only when
##          the player presses "End Day". Running out of actions does NOT auto-end the day.
## Night:   Processes queued systems (lab, surveillance, timed triggers).
##          Automatically transitions to next day's Morning.
extends BaseSubsystem


# --- Signals --- #

## Emitted when the morning briefing content is ready.
signal morning_briefing_ready(briefing_items: Array[String])

## Emitted when night processing begins.
signal night_processing_started

## Emitted when night processing is complete and the new day is ready.
signal night_processing_completed(new_day: int)

## Emitted when a lab request completes during morning processing.
signal lab_result_ready(lab_request_id: String, output_evidence_id: String)

## Emitted when surveillance produces results during morning processing.
signal surveillance_result(surveillance_id: String, result_event_ids: Array[String])

## Emitted when the investigation reaches its final day.
signal final_day_warning

## Emitted when all investigation days are exhausted.
signal investigation_time_expired

## Emitted when the player cannot advance the day because mandatory actions remain.
signal day_advance_blocked(remaining_actions: Array[String])

## Emitted when the phase transitions (Morning, Daytime, Night).
signal phase_transitioned(new_phase: Enums.DayPhase)


# --- State --- #

## Whether morning briefing has been processed for the current day.
var _morning_briefing_shown: bool = false

## Tracks fired trigger IDs for the legacy fallback (prevents re-firing).
var _legacy_fired_triggers: Array[String] = []


# --- Lifecycle --- #

func _ready() -> void:
	super()


# --- Phase Transitions --- #

## Processes the morning phase and automatically transitions to Daytime.
## Call this at the start of each day.
func process_morning() -> Array[String]:
	var briefing: Array[String] = []

	# 1. Process completed lab requests
	var completed_labs: Array[Dictionary] = _process_lab_completions()
	for lab_info: Dictionary in completed_labs:
		briefing.append("Lab result ready: %s" % lab_info.get("analysis_type", "unknown"))
		lab_result_ready.emit(lab_info.get("id", ""), lab_info.get("output_evidence_id", ""))

	# 2. Check surveillance results
	var surv_results: Array[Dictionary] = _check_surveillance_results()
	for surv_info: Dictionary in surv_results:
		var event_ids: Array[String] = []
		event_ids.assign(surv_info.get("result_events", []))
		briefing.append("Surveillance update: %s" % surv_info.get("target_person", "unknown"))
		surveillance_result.emit(surv_info.get("id", ""), event_ids)

	# 3. Evaluate day-start triggers via EventSystem
	var event_sys: Node = get_node_or_null("/root/EventSystem")
	if event_sys and event_sys.has_method("evaluate_day_start_triggers"):
		var trigger_events: Array[String] = []
		trigger_events.assign(event_sys.call("evaluate_day_start_triggers"))
		briefing.append_array(trigger_events)
	else:
		var trigger_events: Array[String] = _evaluate_day_start_triggers()
		briefing.append_array(trigger_events)

	# 4. Check for final day warning
	if GameManager.current_day == GameManager.get_total_days():
		briefing.append("FINAL DAY — This is your last chance to complete the investigation.")
		final_day_warning.emit()

	_morning_briefing_shown = true
	morning_briefing_ready.emit(briefing)

	# 5. Automatically transition to Daytime
	_transition_to_daytime()

	return briefing


## Returns whether the morning briefing has been shown for the current day.
func is_morning_briefing_shown() -> bool:
	return _morning_briefing_shown


## Ends the day early (player pressed "End Day") or when actions reach 0.
## Transitions to Night phase, processes night systems, then advances to next Morning.
## Returns true if successful, false if blocked by mandatory actions.
func try_end_day() -> bool:
	# Check mandatory actions
	if not GameManager.all_mandatory_actions_completed():
		var remaining: Array[String] = GameManager.get_remaining_mandatory_actions()
		day_advance_blocked.emit(remaining)
		return false

	_process_night()
	return true


## Forces day advancement (for debug use). Skips mandatory action checks.
func force_advance_day() -> void:
	_process_night()


# --- Internal Transitions --- #

## Transitions from Morning to Daytime.
func _transition_to_daytime() -> void:
	GameManager.set_phase(Enums.DayPhase.DAYTIME)
	GameManager.reset_actions()
	phase_transitioned.emit(Enums.DayPhase.DAYTIME)


## Transitions to Night, processes all night systems, then advances to next Morning.
func _process_night() -> void:
	# Transition to Night phase
	GameManager.set_phase(Enums.DayPhase.NIGHT)
	phase_transitioned.emit(Enums.DayPhase.NIGHT)
	night_processing_started.emit()

	# 1. Advance surveillance timers (deactivate expired ones)
	_advance_surveillance_timers()

	# 3. Evaluate TIMED triggers for the next day via EventSystem
	var event_sys: Node = get_node_or_null("/root/EventSystem")
	if event_sys and event_sys.has_method("evaluate_timed_triggers"):
		event_sys.call("evaluate_timed_triggers", GameManager.current_day + 1)
	else:
		_evaluate_timed_triggers()

	# 4. Log the day end
	GameManager.log_action("Day %d ended — Night processing complete." % GameManager.current_day)

	# 5. Check if investigation is over
	if GameManager.current_day >= GameManager.get_total_days():
		investigation_time_expired.emit()
		night_processing_completed.emit(GameManager.current_day)
		return

	# 6. Advance to next day's Morning
	GameManager.advance_day()
	GameManager.set_phase(Enums.DayPhase.MORNING)
	GameManager.reset_actions()
	_morning_briefing_shown = false

	GameManager.log_action("Day %d begins." % GameManager.current_day)

	# Reset ActionSystem daily tracking
	var action_sys: Node = get_node_or_null("/root/ActionSystem")
	if action_sys and action_sys.has_method("on_new_day"):
		action_sys.call("on_new_day")

	phase_transitioned.emit(Enums.DayPhase.MORNING)
	night_processing_completed.emit(GameManager.current_day)


# --- Lab Processing --- #

## Checks active lab requests and returns any that complete on the current day.
func _process_lab_completions() -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	var remaining: Array = []

	for request in GameManager.active_lab_requests:
		var req: Dictionary = request as Dictionary
		if req.get("completion_day", 0) <= GameManager.current_day:
			completed.append(req)
			# Auto-discover the output evidence
			var output_id: String = req.get("output_evidence_id", "")
			if not output_id.is_empty():
				GameManager.discover_evidence(output_id)
			# Sync authoritative state in LabManager
			var lab_mgr: Node = get_node_or_null("/root/LabManager")
			if lab_mgr and lab_mgr.has_method("_on_lab_result_ready"):
				lab_mgr._on_lab_result_ready(req.get("id", ""), output_id)
		else:
			remaining.append(req)

	GameManager.active_lab_requests = remaining
	return completed


# --- Surveillance Processing --- #

## Checks active surveillance and returns results for the current day.
func _check_surveillance_results() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for surv in GameManager.active_surveillance:
		var s: Dictionary = surv as Dictionary
		var installed_day: int = s.get("day_installed", 0)
		var active_days: int = s.get("active_days", 0)
		if GameManager.current_day >= installed_day and GameManager.current_day < installed_day + active_days:
			var result_events: Array = s.get("result_events", [])
			if not result_events.is_empty():
				results.append(s)

	return results


## Removes expired surveillance operations during Night processing.
func _advance_surveillance_timers() -> void:
	var still_active: Array = []
	var surv_mgr: Node = get_node_or_null("/root/SurveillanceManager")

	for surv in GameManager.active_surveillance:
		var s: Dictionary = surv as Dictionary
		var installed_day: int = s.get("day_installed", 0)
		var active_days: int = s.get("active_days", 0)
		if GameManager.current_day + 1 < installed_day + active_days:
			still_active.append(s)
		else:
			# Sync authoritative state in SurveillanceManager
			var surv_id: String = s.get("id", "")
			if surv_mgr and not surv_id.is_empty() and surv_mgr.has_method("mark_expired"):
				surv_mgr.mark_expired(surv_id)

	GameManager.active_surveillance = still_active


# --- Legacy Trigger Evaluation (fallback when EventSystem is not loaded) --- #

## Evaluates DAY_START triggers for the current day (legacy fallback).
func _evaluate_day_start_triggers() -> Array[String]:
	var results: Array[String] = []

	if not CaseManager.case_loaded_flag:
		return results

	var triggers: Array[EventTriggerData] = CaseManager.get_triggers_by_type("DAY_START")
	for trigger: EventTriggerData in triggers:
		if trigger.id in _legacy_fired_triggers:
			continue
		if trigger.trigger_day != -1 and trigger.trigger_day != GameManager.current_day:
			continue
		_legacy_fired_triggers.append(trigger.id)
		for action_str: String in trigger.actions:
			results.append(action_str)
		GameManager.log_action("Trigger fired (legacy): %s" % trigger.id)

	return results


## Evaluates TIMED triggers for the next day (legacy fallback).
func _evaluate_timed_triggers() -> void:
	if not CaseManager.case_loaded_flag:
		return

	var next_day: int = GameManager.current_day + 1
	var triggers: Array[EventTriggerData] = CaseManager.get_triggers_by_type("TIMED")
	for trigger: EventTriggerData in triggers:
		if trigger.id in _legacy_fired_triggers:
			continue
		if trigger.trigger_day != next_day:
			continue
		_legacy_fired_triggers.append(trigger.id)
		GameManager.log_action("Timed trigger queued (legacy): %s (fires Day %d)" % [trigger.id, next_day])


# --- Serialization --- #

## Returns state for save/load.
func serialize() -> Dictionary:
	return {
		"morning_briefing_shown": _morning_briefing_shown,
		"legacy_fired_triggers": _legacy_fired_triggers.duplicate(),
	}


## Restores state from saved data.
func deserialize(data: Dictionary) -> void:
	_morning_briefing_shown = data.get("morning_briefing_shown", false)
	_legacy_fired_triggers.clear()
	var saved_triggers: Array = data.get("legacy_fired_triggers", [])
	for t in saved_triggers:
		_legacy_fired_triggers.append(str(t))


## Resets all DaySystem state for a new game.
func reset() -> void:
	_morning_briefing_shown = false
	_legacy_fired_triggers.clear()
