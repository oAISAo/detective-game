## DaySystem.gd
## Manages the investigation day cycle, morning briefings, and night processing.
## Orchestrates the flow: Morning (narrative) → Afternoon (action) → Evening (action) → Night (processing).
## Phase 2: Core day lifecycle with delayed-action processing and end-of-investigation pressure.
extends Node


# --- Signals --- #

## Emitted when the morning briefing content is ready.
signal morning_briefing_ready(briefing_items: Array[String])

## Emitted when night processing begins.
signal night_processing_started

## Emitted when night processing is complete and the new day is ready.
signal night_processing_completed(new_day: int)

## Emitted when a lab request completes during night processing.
signal lab_result_ready(lab_request_id: String, output_evidence_id: String)

## Emitted when surveillance produces results during night processing.
signal surveillance_result(surveillance_id: String, result_event_ids: Array[String])

## Emitted when the investigation reaches its final day.
signal final_day_warning

## Emitted when all investigation days are exhausted.
signal investigation_time_expired

## Emitted when the player cannot advance the day because mandatory actions remain.
signal day_advance_blocked(remaining_actions: Array[String])


# --- State --- #

## Whether morning briefing has been acknowledged for the current day.
var _morning_briefing_shown: bool = false

## Tracks which triggers have already fired (by ID) so they don't repeat.
var _fired_triggers: Array[String] = []


# --- Lifecycle --- #

func _ready() -> void:
	print("[DaySystem] Initialized.")


# --- Morning Phase --- #

## Processes the morning phase for the current day.
## Collects lab results, surveillance results, and trigger-based events,
## then emits the morning briefing signal.
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

	# 3. Evaluate day-start triggers from case data
	var trigger_events: Array[String] = _evaluate_day_start_triggers()
	briefing.append_array(trigger_events)

	# 4. Check for final day warning
	if GameManager.current_day == GameManager.TOTAL_DAYS:
		briefing.append("FINAL DAY — This is your last chance to complete the investigation.")
		final_day_warning.emit()

	_morning_briefing_shown = true
	morning_briefing_ready.emit(briefing)
	return briefing


## Returns whether the morning briefing has been shown for the current day.
func is_morning_briefing_shown() -> bool:
	return _morning_briefing_shown


# --- Day Advancement --- #

## Attempts to end the current day and advance to Night processing.
## Returns true if successful, false if blocked by mandatory actions or other conditions.
func try_end_day() -> bool:
	# Check mandatory actions
	if not GameManager.all_mandatory_actions_completed():
		var remaining: Array[String] = GameManager.get_remaining_mandatory_actions()
		day_advance_blocked.emit(remaining)
		return false

	# Process night
	_process_night()
	return true


## Forces day advancement (for debug use). Skips mandatory action checks.
func force_advance_day() -> void:
	_process_night()


# --- Night Processing --- #

## Processes the Night phase: advances timers, evaluates triggers, and transitions to the next day.
func _process_night() -> void:
	night_processing_started.emit()

	# 1. Advance lab request timers
	_advance_lab_timers()

	# 2. Advance surveillance timers (deactivate expired ones)
	_advance_surveillance_timers()

	# 3. Evaluate TIMED triggers for the next day
	_evaluate_timed_triggers()

	# 4. Log the day end
	GameManager._log_action("Day %d ended — Night processing complete." % GameManager.current_day)

	# 5. Check if investigation is over
	if GameManager.current_day >= GameManager.TOTAL_DAYS:
		investigation_time_expired.emit()
		night_processing_completed.emit(GameManager.current_day)
		return

	# 6. Advance to next day
	GameManager.current_day += 1
	GameManager.current_time_slot = Enums.TimeSlot.MORNING
	GameManager.actions_remaining = GameManager.ACTIONS_PER_DAY
	GameManager.interrogation_counts_today.clear()
	_morning_briefing_shown = false

	GameManager.day_changed.emit(GameManager.current_day)
	GameManager.time_slot_changed.emit(GameManager.current_time_slot)
	GameManager.actions_remaining_changed.emit(GameManager.actions_remaining)
	GameManager._log_action("Day %d begins." % GameManager.current_day)

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
		else:
			remaining.append(req)

	GameManager.active_lab_requests = remaining
	return completed


## Advances lab request timers (called during Night processing — no completions here,
## just ensures the state is ready for the next morning check).
func _advance_lab_timers() -> void:
	# Lab requests complete during morning processing, not night.
	# This method is a hook for future timer-based processing.
	pass


# --- Surveillance Processing --- #

## Checks active surveillance and returns results for the current day.
func _check_surveillance_results() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for surv in GameManager.active_surveillance:
		var s: Dictionary = surv as Dictionary
		var installed_day: int = s.get("day_installed", 0)
		var active_days: int = s.get("active_days", 0)
		# Surveillance is active from installed_day to installed_day + active_days - 1
		if GameManager.current_day >= installed_day and GameManager.current_day < installed_day + active_days:
			var result_events: Array = s.get("result_events", [])
			if not result_events.is_empty():
				results.append(s)

	return results


## Removes expired surveillance operations during Night processing.
func _advance_surveillance_timers() -> void:
	var still_active: Array = []

	for surv in GameManager.active_surveillance:
		var s: Dictionary = surv as Dictionary
		var installed_day: int = s.get("day_installed", 0)
		var active_days: int = s.get("active_days", 0)
		# Keep if still active after tonight (next day is current_day + 1)
		if GameManager.current_day + 1 < installed_day + active_days:
			still_active.append(s)

	GameManager.active_surveillance = still_active


# --- Trigger Evaluation --- #

## Evaluates DAY_START triggers for the current day.
func _evaluate_day_start_triggers() -> Array[String]:
	var results: Array[String] = []

	if not CaseManager.case_loaded_flag:
		return results

	var triggers: Array[EventTriggerData] = CaseManager.get_triggers_by_type("DAY_START")
	for trigger: EventTriggerData in triggers:
		if trigger.id in _fired_triggers:
			continue
		if trigger.trigger_day != -1 and trigger.trigger_day != GameManager.current_day:
			continue
		# Check if conditions are met
		if _check_trigger_conditions(trigger.conditions):
			_fired_triggers.append(trigger.id)
			for action_str: String in trigger.actions:
				results.append(action_str)
			GameManager._log_action("Trigger fired: %s" % trigger.id)

	return results


## Evaluates TIMED triggers for the next day (called during Night processing).
func _evaluate_timed_triggers() -> void:
	if not CaseManager.case_loaded_flag:
		return

	var next_day: int = GameManager.current_day + 1
	var triggers: Array[EventTriggerData] = CaseManager.get_triggers_by_type("TIMED")
	for trigger: EventTriggerData in triggers:
		if trigger.id in _fired_triggers:
			continue
		if trigger.trigger_day != next_day:
			continue
		if _check_trigger_conditions(trigger.conditions):
			_fired_triggers.append(trigger.id)
			GameManager._log_action("Timed trigger queued: %s (fires Day %d)" % [trigger.id, next_day])


## Checks whether all conditions in a trigger's condition array are met.
## Condition format: "condition_type:value"
## Supported types: evidence_discovered, location_visited, action_completed, warrant_obtained, day
func _check_trigger_conditions(conditions: Array[String]) -> bool:
	for condition: String in conditions:
		var parts: PackedStringArray = condition.split(":", true, 1)
		if parts.size() < 2:
			# Conditions without a colon are treated as simple flags — skip for now
			continue
		var cond_type: String = parts[0].strip_edges()
		var cond_value: String = parts[1].strip_edges()

		match cond_type:
			"evidence_discovered":
				if not GameManager.has_evidence(cond_value):
					return false
			"location_visited":
				if not GameManager.has_visited_location(cond_value):
					return false
			"action_completed":
				if cond_value not in GameManager.mandatory_actions_completed:
					return false
			"warrant_obtained":
				if cond_value not in GameManager.warrants_obtained:
					return false
			"day":
				if GameManager.current_day != int(cond_value):
					return false
			"lab_complete":
				# Check if a lab request with this ID has already completed
				# (it would have been removed from active_lab_requests)
				var still_active: bool = false
				for req in GameManager.active_lab_requests:
					if (req as Dictionary).get("id", "") == cond_value:
						still_active = true
						break
				if still_active:
					return false

	return true


# --- Serialization --- #

## Returns state for save/load.
func serialize() -> Dictionary:
	return {
		"morning_briefing_shown": _morning_briefing_shown,
		"fired_triggers": _fired_triggers.duplicate(),
	}


## Restores state from saved data.
func deserialize(data: Dictionary) -> void:
	_morning_briefing_shown = data.get("morning_briefing_shown", false)
	_fired_triggers.assign(data.get("fired_triggers", []))


## Resets all DaySystem state for a new game.
func reset() -> void:
	_morning_briefing_shown = false
	_fired_triggers.clear()
