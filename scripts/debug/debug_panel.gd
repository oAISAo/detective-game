## DebugPanel.gd
## In-game debug panel toggled with F1.
## Shows game state information and provides debug actions.
## Only functional in debug builds.
extends CanvasLayer


## Reference to the panel container.
@onready var panel: PanelContainer = $Panel
@onready var content_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/ContentLabel
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/HeaderBar/CloseButton
@onready var evidence_id_input: LineEdit = $Panel/MarginContainer/VBoxContainer/ActionsContainer/EvidenceIdInput
@onready var unlock_evidence_button: Button = $Panel/MarginContainer/VBoxContainer/ActionsContainer/UnlockEvidenceButton
@onready var unlock_all_button: Button = $Panel/MarginContainer/VBoxContainer/ActionsContainer/UnlockAllButton
@onready var export_state_button: Button = $Panel/MarginContainer/VBoxContainer/ActionsContainer/ExportStateButton
@onready var advance_day_button: Button = $Panel/MarginContainer/VBoxContainer/DayActionsContainer/AdvanceDayButton
@onready var set_morning_button: Button = $Panel/MarginContainer/VBoxContainer/DayActionsContainer/SetMorningButton
@onready var set_afternoon_button: Button = $Panel/MarginContainer/VBoxContainer/DayActionsContainer/SetAfternoonButton
@onready var set_evening_button: Button = $Panel/MarginContainer/VBoxContainer/DayActionsContainer/SetEveningButton
@onready var process_night_button: Button = $Panel/MarginContainer/VBoxContainer/DayActionsContainer/ProcessNightButton
@onready var complete_mandatory_button: Button = $Panel/MarginContainer/VBoxContainer/DayActionsContainer/CompleteMandatoryButton
@onready var day_spin_box: SpinBox = $Panel/MarginContainer/VBoxContainer/DayActionsContainer/DaySelectContainer/DaySpinBox
@onready var goto_day_button: Button = $Panel/MarginContainer/VBoxContainer/DayActionsContainer/DaySelectContainer/GotoDayButton

# Phase 3: Event & dialogue debug controls
@onready var trigger_id_input: LineEdit = $Panel/MarginContainer/VBoxContainer/EventActionsContainer/TriggerIdInput
@onready var fire_trigger_button: Button = $Panel/MarginContainer/VBoxContainer/EventActionsContainer/FireTriggerButton
@onready var eval_conditional_button: Button = $Panel/MarginContainer/VBoxContainer/EventActionsContainer/EvalConditionalButton
@onready var clear_notifications_button: Button = $Panel/MarginContainer/VBoxContainer/EventActionsContainer/ClearNotificationsButton
@onready var skip_dialogue_button: Button = $Panel/MarginContainer/VBoxContainer/EventActionsContainer/SkipDialogueButton


var _is_visible: bool = false


func _ready() -> void:
	layer = 100  # Always on top
	panel.visible = false
	close_button.pressed.connect(_toggle)
	unlock_evidence_button.pressed.connect(_on_unlock_evidence_pressed)
	unlock_all_button.pressed.connect(_on_unlock_all_pressed)
	export_state_button.pressed.connect(_on_export_state_pressed)
	evidence_id_input.text_submitted.connect(_on_evidence_id_submitted)

	# Phase 2: Day/action debug controls
	advance_day_button.pressed.connect(_on_advance_day_pressed)
	set_morning_button.pressed.connect(func() -> void: debug_set_phase(Enums.DayPhase.MORNING))
	set_afternoon_button.pressed.connect(func() -> void: debug_set_phase(Enums.DayPhase.DAYTIME))
	set_evening_button.pressed.connect(func() -> void: debug_set_phase(Enums.DayPhase.NIGHT))
	process_night_button.pressed.connect(_on_process_night_pressed)
	complete_mandatory_button.pressed.connect(_on_complete_mandatory_pressed)
	day_spin_box.min_value = 1
	day_spin_box.max_value = GameManager.TOTAL_DAYS
	day_spin_box.value = 1
	goto_day_button.pressed.connect(_on_goto_day_pressed)

	# Phase 3: Event & dialogue debug controls
	fire_trigger_button.pressed.connect(_on_fire_trigger_pressed)
	eval_conditional_button.pressed.connect(_on_eval_conditional_pressed)
	clear_notifications_button.pressed.connect(_on_clear_notifications_pressed)
	skip_dialogue_button.pressed.connect(_on_skip_dialogue_pressed)
	trigger_id_input.text_submitted.connect(_on_trigger_id_submitted)

	print("[DebugPanel] Ready. Press F1 to toggle.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_panel"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	_is_visible = not _is_visible
	panel.visible = _is_visible
	if _is_visible:
		_refresh()


func _refresh() -> void:
	var text: String = ""
	text += "[b]═══ DEBUG PANEL ═══[/b]\n\n"

	# Game State
	text += "[b]Game State[/b]\n"
	text += "  Day: %d / %d\n" % [GameManager.current_day, GameManager.TOTAL_DAYS]
	text += "  Phase: %s\n" % GameManager.get_phase_display()
	text += "  Actions Remaining: %d / %d\n" % [GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY]
	text += "  Game Active: %s\n\n" % str(GameManager.game_active)

	# Evidence
	text += "[b]Evidence[/b]\n"
	text += "  Discovered: %d items\n" % GameManager.discovered_evidence.size()
	for ev_id: String in GameManager.discovered_evidence:
		text += "    ✓ %s\n" % ev_id
	text += "\n"

	# Evidence Checklist (compact)
	var all_ev: Array[EvidenceData] = CaseManager.get_all_evidence()
	if not all_ev.is_empty():
		text += "[b]Evidence Checklist[/b]\n  "
		var items: PackedStringArray = PackedStringArray()
		for ev: EvidenceData in all_ev:
			var found: bool = GameManager.has_evidence(ev.id)
			items.append("%s %s" % ["✓" if found else "✗", ev.id])
		text += "  ".join(items) + "\n\n"

	# Insights
	text += "[b]Insights[/b]\n"
	text += "  Discovered: %d\n\n" % GameManager.discovered_insights.size()

	# Locations
	text += "[b]Locations Visited[/b]\n"
	text += "  Count: %d\n" % GameManager.visited_locations.size()
	for loc_id: String in GameManager.visited_locations:
		text += "    ✓ %s\n" % loc_id
	text += "\n"

	# Hints
	text += "[b]Hints[/b]\n"
	text += "  Used: %d / %d\n\n" % [GameManager.hints_used, GameManager.MAX_HINTS_PER_CASE]

	# Mandatory Actions
	var remaining_mandatory: Array[String] = GameManager.get_remaining_mandatory_actions()
	text += "[b]Mandatory Actions[/b]\n"
	text += "  Required: %d\n" % GameManager.mandatory_actions_required.size()
	text += "  Completed: %d\n" % GameManager.mandatory_actions_completed.size()
	text += "  Remaining: %d\n" % remaining_mandatory.size()
	for m_id: String in remaining_mandatory:
		text += "    ✗ %s\n" % m_id
	text += "\n"

	# Lab Requests
	text += "[b]Lab Requests[/b]\n"
	text += "  Active: %d\n" % GameManager.active_lab_requests.size()
	for req in GameManager.active_lab_requests:
		var r: Dictionary = req as Dictionary
		text += "    ⏳ %s → Day %s\n" % [r.get("id", "?"), str(r.get("completion_day", "?"))]
	text += "\n"

	# Surveillance
	text += "[b]Surveillance[/b]\n"
	text += "  Active: %d\n" % GameManager.active_surveillance.size()
	for surv in GameManager.active_surveillance:
		var s: Dictionary = surv as Dictionary
		text += "    👁 %s (%s days)\n" % [s.get("target_person", "?"), str(s.get("active_days", "?"))]
	text += "\n"

	# Action System
	text += "[b]Action System[/b]\n"
	text += "  Total Executed: %d\n" % ActionSystem.executed_actions.size()
	text += "  Today: %d\n\n" % ActionSystem.actions_executed_today.size()

	# Warrants
	text += "[b]Warrants[/b]\n"
	text += "  Obtained: %d\n" % GameManager.warrants_obtained.size()
	for w_id: String in GameManager.warrants_obtained:
		text += "    ✓ %s\n" % w_id
	text += "\n"

	# Notifications
	text += "[b]Notifications[/b]\n"
	text += "  Active: %d\n" % NotificationManager.get_all().size()
	text += "  Unread: %d\n\n" % NotificationManager.get_unread_count()

	# Event System
	text += "[b]Event System[/b]\n"
	text += "  Fired Triggers: %d\n" % EventSystem.get_fired_triggers().size()
	for t_id: String in EventSystem.get_fired_triggers():
		text += "    ✓ %s\n" % t_id
	text += "  Pending Morning Actions: %d\n" % EventSystem.get_pending_morning_actions().size()
	text += "  Trigger History: %d entries\n\n" % EventSystem.get_trigger_history().size()

	# Dialogue System
	text += "[b]Dialogue System[/b]\n"
	text += "  Active: %s\n" % str(DialogueSystem.is_active())
	text += "  Queue Size: %d\n" % DialogueSystem.get_queue_size()
	text += "  History: %d dialogues\n" % DialogueSystem.get_dialogue_history().size()
	if DialogueSystem.is_active():
		var current_line: Dictionary = DialogueSystem.get_current_line()
		text += "  Current Speaker: %s\n" % current_line.get("speaker", "?")
	text += "\n"

	# Interrogation System
	text += "[b]Interrogation System[/b]\n"
	var interr_mgr: Node = get_node_or_null("/root/InterrogationManager")
	if interr_mgr:
		text += "  Active: %s\n" % str(interr_mgr.is_active())
		if interr_mgr.is_active():
			text += "  Suspect: %s\n" % interr_mgr.get_current_person_id()
			text += "  Phase: %s\n" % str(interr_mgr.get_current_phase())
			text += "  Pressure: %d\n" % interr_mgr.get_current_pressure()
		var heard: Array = interr_mgr.get_heard_statements()
		text += "  Heard Statements: %d\n" % heard.size()
		# Show fired triggers per person
		var suspects: Array[PersonData] = CaseManager.get_suspects()
		for suspect: PersonData in suspects:
			var fired: Array = interr_mgr.get_fired_triggers_for_person(suspect.id)
			var pressure: int = interr_mgr.get_pressure_for_person(suspect.id)
			var broken: bool = interr_mgr.has_break_moment(suspect.id)
			text += "  %s: %d triggers fired, pressure=%d%s\n" % [
				suspect.name, fired.size(), pressure,
				" [BROKEN]" if broken else ""
			]
	else:
		text += "  Not available.\n"
	text += "\n"

	# Detective Board
	text += "[b]Detective Board[/b]\n"
	var board_mgr: Node = get_node_or_null("/root/BoardManager")
	if board_mgr:
		text += "  Nodes: %d\n" % board_mgr.get_node_count()
		text += "  Connections: %d\n" % board_mgr.get_connection_count()
		var person_nodes: Array = board_mgr.get_nodes_by_type("person")
		var evidence_nodes: Array = board_mgr.get_nodes_by_type("evidence")
		var event_nodes: Array = board_mgr.get_nodes_by_type("event")
		text += "  Person nodes: %d\n" % person_nodes.size()
		text += "  Evidence nodes: %d\n" % evidence_nodes.size()
		text += "  Event nodes: %d\n" % event_nodes.size()
	else:
		text += "  Not available.\n"
	text += "\n"

	# Timeline
	text += "[b]Timeline[/b]\n"
	var tl_mgr: Node = get_node_or_null("/root/TimelineManager")
	if tl_mgr:
		text += "  Entries: %d\n" % tl_mgr.get_entry_count()
		text += "  Hypotheses: %d\n" % tl_mgr.get_hypothesis_count()
		text += "  Has content: %s\n" % str(tl_mgr.has_content())
	else:
		text += "  Not available.\n"
	text += "\n"

	# Theory Builder
	text += "[b]Theory Builder[/b]\n"
	var th_mgr: Node = get_node_or_null("/root/TheoryManager")
	if th_mgr:
		text += "  Theories: %d\n" % th_mgr.get_theory_count()
		text += "  Has content: %s\n" % str(th_mgr.has_content())
		for t: Dictionary in th_mgr.get_all_theories():
			var complete_str: String = "✓" if th_mgr.is_complete(t["id"]) else "…"
			text += "  [%s] %s (suspect: %s)\n" % [complete_str, t["name"], t.get("suspect_id", "")]
	else:
		text += "  Not available.\n"
	text += "\n"

	# Lab Manager
	text += "[b]Lab Manager[/b]\n"
	var lab_mgr: Node = get_node_or_null("/root/LabManager")
	if lab_mgr:
		var pending: Array = lab_mgr.get_pending_requests()
		var completed: Array = lab_mgr.get_completed_requests()
		text += "  Pending: %d  Completed: %d\n" % [pending.size(), completed.size()]
		for req: Dictionary in pending:
			text += "  [⏳] %s → %s (day %d)\n" % [req.get("input_evidence_id", ""), req.get("output_evidence_id", ""), req.get("completion_day", 0)]
	else:
		text += "  Not available.\n"
	text += "\n"

	# Surveillance Manager
	text += "[b]Surveillance Manager[/b]\n"
	var surv_mgr: Node = get_node_or_null("/root/SurveillanceManager")
	if surv_mgr:
		var active: Array = surv_mgr.get_active_operations()
		text += "  Active: %d\n" % active.size()
		for op: Dictionary in active:
			text += "  [👁] %s (expires day %d)\n" % [op.get("target_person", ""), op.get("expiry_day", 0)]
	else:
		text += "  Not available.\n"
	text += "\n"

	# Warrant Manager
	text += "[b]Warrant Manager[/b]\n"
	var w_mgr: Node = get_node_or_null("/root/WarrantManager")
	if w_mgr:
		var approved: Array = w_mgr.get_approved_warrants()
		var denied: Array = w_mgr.get_denied_warrants()
		var arrested: Array = w_mgr.get_arrested_suspects()
		text += "  Approved: %d  Denied: %d  Arrested: %d\n" % [approved.size(), denied.size(), arrested.size()]
	else:
		text += "  Not available.\n"
	text += "\n"

	# Case
	text += "[b]Case[/b]\n"
	text += "  Loaded: %s\n\n" % str(CaseManager.case_loaded_flag)

	# Conclusion System
	text += "[b]Conclusion System[/b]\n"
	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	if concl_mgr:
		text += "  Has Report: %s\n" % str(concl_mgr.has_report())
		text += "  Evaluated: %s\n" % str(concl_mgr.is_evaluated())
		if concl_mgr.is_evaluated():
			text += "  Score: %.1f%%\n" % (concl_mgr.get_confidence_score() * 100.0)
			text += "  Level: %s\n" % str(concl_mgr.get_confidence_level())
			text += "  Dialogue: %s\n" % concl_mgr.get_prosecutor_dialogue()
		var choice: String = concl_mgr.get_player_choice()
		if not choice.is_empty():
			text += "  Choice: %s\n" % choice
			text += "  Outcome: %s\n" % concl_mgr.get_outcome_name()
	else:
		text += "  Not available.\n"

	content_label.text = text


# --- Debug Actions --- #

## Unlocks a specific evidence item by ID.
func debug_unlock_evidence(evidence_id: String) -> void:
	GameManager.discover_evidence(evidence_id)
	_refresh()
	print("[Debug] Unlocked evidence: %s" % evidence_id)


## Unlocks all evidence from the current case.
func debug_unlock_all_evidence() -> void:
	var all_evidence: Array[EvidenceData] = CaseManager.get_all_evidence()
	for ev: EvidenceData in all_evidence:
		GameManager.discover_evidence(ev.id)
	_refresh()
	print("[Debug] Unlocked all evidence (%d items)." % all_evidence.size())


## Prints the full game state to the console.
func debug_print_state() -> void:
	var state: Dictionary = GameManager.serialize()
	print("[Debug] === FULL GAME STATE ===")
	for key: String in state:
		print("  %s: %s" % [key, str(state[key])])
	print("[Debug] === END STATE ===")


# --- UI Callbacks --- #

func _on_unlock_evidence_pressed() -> void:
	var ev_id: String = evidence_id_input.text.strip_edges()
	if ev_id.is_empty():
		return
	debug_unlock_evidence(ev_id)
	evidence_id_input.text = ""


func _on_evidence_id_submitted(ev_id: String) -> void:
	if ev_id.strip_edges().is_empty():
		return
	debug_unlock_evidence(ev_id.strip_edges())
	evidence_id_input.text = ""


func _on_unlock_all_pressed() -> void:
	debug_unlock_all_evidence()


func _on_export_state_pressed() -> void:
	debug_export_state()


func _on_advance_day_pressed() -> void:
	DaySystem.force_advance_day()
	_refresh()
	print("[Debug] Forced day advance.")


func _on_process_night_pressed() -> void:
	DaySystem.force_advance_day()
	_refresh()
	print("[Debug] Night processing triggered.")


func _on_complete_mandatory_pressed() -> void:
	debug_complete_mandatory_actions()


func _on_goto_day_pressed() -> void:
	var target_day: int = int(day_spin_box.value)
	debug_set_day(target_day)


## Advances to the specified day.
func debug_set_day(day: int) -> void:
	GameManager.current_day = clampi(day, 1, GameManager.TOTAL_DAYS)
	GameManager.current_phase = Enums.DayPhase.MORNING
	GameManager.actions_remaining = GameManager.ACTIONS_PER_DAY
	GameManager.day_changed.emit(GameManager.current_day)
	GameManager.phase_changed.emit(GameManager.current_phase)
	_refresh()
	print("[Debug] Set day to %d." % day)


## Sets the current day phase.
func debug_set_phase(phase: Enums.DayPhase) -> void:
	GameManager.current_phase = phase
	GameManager.phase_changed.emit(phase)
	_refresh()
	print("[Debug] Set phase to %s." % GameManager.get_phase_display())


## Completes all mandatory actions.
func debug_complete_mandatory_actions() -> void:
	for action_id: String in GameManager.mandatory_actions_required:
		GameManager.complete_mandatory_action(action_id)
	_refresh()
	print("[Debug] All mandatory actions completed.")


## Exports the full game state to the console as JSON.
func debug_export_state() -> void:
	var state: Dictionary = GameManager.serialize()
	var json_string: String = JSON.stringify(state, "\t")
	print("[Debug] Game State Export:")
	print(json_string)


# --- Phase 3: Event & Dialogue Debug Actions --- #

func _on_fire_trigger_pressed() -> void:
	var t_id: String = trigger_id_input.text.strip_edges()
	if t_id.is_empty():
		return
	var success: bool = EventSystem.force_trigger(t_id)
	if success:
		print("[Debug] Force-fired trigger: %s" % t_id)
	else:
		print("[Debug] Failed to fire trigger: %s (not found or already fired)" % t_id)
	trigger_id_input.text = ""
	_refresh()


func _on_trigger_id_submitted(t_id: String) -> void:
	if t_id.strip_edges().is_empty():
		return
	var success: bool = EventSystem.force_trigger(t_id.strip_edges())
	if success:
		print("[Debug] Force-fired trigger: %s" % t_id.strip_edges())
	else:
		print("[Debug] Failed to fire trigger: %s" % t_id.strip_edges())
	trigger_id_input.text = ""
	_refresh()


func _on_eval_conditional_pressed() -> void:
	EventSystem.evaluate_conditional_triggers()
	_refresh()
	print("[Debug] Evaluated conditional triggers.")


func _on_clear_notifications_pressed() -> void:
	NotificationManager.clear_all()
	_refresh()
	print("[Debug] All notifications cleared.")


func _on_skip_dialogue_pressed() -> void:
	DialogueSystem.skip_current()
	_refresh()
	print("[Debug] Current dialogue skipped.")


# --- Phase 7: Interrogation Debug Actions --- #

## Resets interrogation state for a specific suspect.
func debug_reset_interrogation(person_id: String) -> void:
	var interr_mgr: Node = get_node_or_null("/root/InterrogationManager")
	if interr_mgr == null:
		print("[Debug] InterrogationManager not available.")
		return
	# Clear fired triggers and pressure for this person
	interr_mgr._fired_triggers.erase(person_id)
	interr_mgr._accumulated_pressure.erase(person_id)
	interr_mgr._break_moments.erase(person_id)
	_refresh()
	print("[Debug] Reset interrogation state for %s." % person_id)


## Sets pressure points manually for a suspect.
func debug_set_pressure(person_id: String, pressure: int) -> void:
	var interr_mgr: Node = get_node_or_null("/root/InterrogationManager")
	if interr_mgr == null:
		print("[Debug] InterrogationManager not available.")
		return
	interr_mgr._accumulated_pressure[person_id] = pressure
	if interr_mgr.is_active() and interr_mgr.get_current_person_id() == person_id:
		interr_mgr._current_pressure = pressure
	_refresh()
	print("[Debug] Set pressure for %s to %d." % [person_id, pressure])


## Lists all interrogation triggers and their status.
func debug_list_triggers() -> void:
	var triggers: Array[InterrogationTriggerData] = CaseManager.get_all_interrogation_triggers()
	var interr_mgr: Node = get_node_or_null("/root/InterrogationManager")
	print("[Debug] === INTERROGATION TRIGGERS ===")
	for trigger: InterrogationTriggerData in triggers:
		var fired: bool = false
		if interr_mgr:
			var person_fired: Array = interr_mgr.get_fired_triggers_for_person(trigger.person_id)
			fired = trigger.id in person_fired
		var status: String = "FIRED" if fired else "AVAILABLE"
		print("  [%s] %s → %s (evidence: %s, impact: %s)" % [
			status, trigger.id, trigger.person_id,
			trigger.evidence_id,
			EnumHelper.enum_to_string(Enums.ImpactLevel, trigger.impact_level)
		])
	print("[Debug] === END TRIGGERS ===")


# --- Phase 8: Detective Board Debug Actions --- #

## Clears the entire detective board.
func debug_clear_board() -> void:
	var board_mgr: Node = get_node_or_null("/root/BoardManager")
	if board_mgr == null:
		print("[Debug] BoardManager not available.")
		return
	board_mgr.clear_board()
	_refresh()
	print("[Debug] Board cleared.")


## Auto-populates the board with all discovered evidence and suspects.
func debug_populate_board() -> void:
	var board_mgr: Node = get_node_or_null("/root/BoardManager")
	if board_mgr == null:
		print("[Debug] BoardManager not available.")
		return

	var offset_x: float = 100.0
	var offset_y: float = 100.0
	var col: int = 0

	# Add all discovered evidence
	for ev_id: String in GameManager.discovered_evidence:
		board_mgr.add_node("evidence", ev_id, offset_x + col * 200.0, offset_y)
		col += 1
		if col >= 8:
			col = 0
			offset_y += 120.0

	# Add all suspects
	offset_y += 150.0
	col = 0
	var suspects: Array[PersonData] = CaseManager.get_suspects()
	for suspect: PersonData in suspects:
		board_mgr.add_node("person", suspect.id, offset_x + col * 200.0, offset_y)
		col += 1

	_refresh()
	print("[Debug] Board populated with %d evidence + %d suspects." % [
		GameManager.discovered_evidence.size(), suspects.size()
	])


# --- Phase 9: Timeline Debug Actions --- #

## Clears the entire timeline.
func debug_clear_timeline() -> void:
	var tl_mgr: Node = get_node_or_null("/root/TimelineManager")
	if tl_mgr == null:
		print("[Debug] TimelineManager not available.")
		return
	tl_mgr.clear_timeline()
	_refresh()
	print("[Debug] Timeline cleared.")


## Places all case events on the timeline at their defined times.
func debug_populate_timeline() -> void:
	var tl_mgr: Node = get_node_or_null("/root/TimelineManager")
	if tl_mgr == null:
		print("[Debug] TimelineManager not available.")
		return

	var events: Array[EventData] = CaseManager.get_all_events()
	var count: int = 0
	for event: EventData in events:
		var time_min: int = TimelineManager.parse_time_string(event.time)
		tl_mgr.place_event(event.id, time_min, event.day)
		count += 1

	_refresh()
	print("[Debug] Placed %d events on timeline." % count)


# --- Phase 10: Theory Builder Debug Actions --- #

## Clears all theories.
func debug_reset_theories() -> void:
	var th_mgr: Node = get_node_or_null("/root/TheoryManager")
	if th_mgr == null:
		print("[Debug] TheoryManager not available.")
		return
	th_mgr.clear_theories()
	_refresh()
	print("[Debug] All theories cleared.")


## Completes all pending lab requests instantly.
func debug_complete_all_labs() -> void:
	var lab_mgr: Node = get_node_or_null("/root/LabManager")
	if lab_mgr == null:
		print("[Debug] LabManager not available.")
		return
	var results: Array = lab_mgr.complete_all_instantly()
	_refresh()
	print("[Debug] Completed %d lab requests instantly." % results.size())


## Completes all active surveillance instantly.
func debug_complete_all_surveillance() -> void:
	var surv_mgr: Node = get_node_or_null("/root/SurveillanceManager")
	if surv_mgr == null:
		print("[Debug] SurveillanceManager not available.")
		return
	var results: Array = surv_mgr.complete_all_instantly()
	_refresh()
	print("[Debug] Completed %d surveillance operations instantly." % results.size())


## Grants a warrant of the given type for the given target with all evidence.
func debug_grant_warrant(warrant_type: int, target: String) -> void:
	var w_mgr: Node = get_node_or_null("/root/WarrantManager")
	if w_mgr == null:
		print("[Debug] WarrantManager not available.")
		return
	var all_ids: Array[String] = []
	for ev: EvidenceData in CaseManager.get_all_evidence():
		all_ids.append(ev.id)
	var result: Dictionary = w_mgr.request_warrant(warrant_type, target, all_ids)
	_refresh()
	if result.get("approved", false):
		print("[Debug] Warrant granted: %s for %s" % [result.get("warrant_id", ""), target])
	else:
		print("[Debug] Warrant denied: %s" % result.get("feedback", ""))


## Creates a sample theory with the first suspect.
func debug_create_sample_theory() -> void:
	var th_mgr: Node = get_node_or_null("/root/TheoryManager")
	if th_mgr == null:
		print("[Debug] TheoryManager not available.")
		return

	var theory: Dictionary = th_mgr.create_theory("Debug Theory")
	var suspects: Array[PersonData] = CaseManager.get_suspects()
	if not suspects.is_empty():
		th_mgr.set_suspect(theory["id"], suspects[0].id)
	th_mgr.set_motive(theory["id"], "Debug motive")
	th_mgr.set_method(theory["id"], "Debug weapon")
	th_mgr.set_time(theory["id"], 1260, 1)  # 21:00 Day 1

	_refresh()
	print("[Debug] Sample theory created: %s" % theory["id"])


# --- Phase 12: Conclusion Debug Actions --- #

## Submits a debug case report using the first theory data.
func debug_submit_report() -> void:
	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	if concl_mgr == null:
		print("[Debug] ConclusionManager not available.")
		return

	var th_mgr: Node = get_node_or_null("/root/TheoryManager")
	if th_mgr == null:
		print("[Debug] TheoryManager not available.")
		return

	var theories: Array[Dictionary] = th_mgr.get_all_theories()
	if theories.is_empty():
		print("[Debug] No theories to build report from.")
		return

	var t: Dictionary = theories[0]
	var report: Dictionary = {
		"suspect": {"answer": t.get("suspect_id", ""), "evidence": []},
		"motive": {"answer": t.get("motive", ""), "evidence": []},
		"weapon": {"answer": t.get("method", ""), "evidence": []},
		"time": {"answer": "%d %d" % [t.get("time_minutes", 0), t.get("time_day", 1)], "evidence": []},
		"access": {"answer": "Unknown", "evidence": []},
	}

	var success: bool = concl_mgr.submit_report(report)
	_refresh()
	if success:
		print("[Debug] Report submitted. Score: %.1f%%" % (concl_mgr.get_confidence_score() * 100.0))
	else:
		print("[Debug] Failed to submit report.")


## Forces a specific case outcome.
func debug_force_outcome(outcome: Enums.CaseOutcome) -> void:
	var concl_mgr: Node = get_node_or_null("/root/ConclusionManager")
	if concl_mgr == null:
		print("[Debug] ConclusionManager not available.")
		return
	concl_mgr._outcome = outcome
	concl_mgr._evaluated = true
	_refresh()
	print("[Debug] Forced outcome: %s" % concl_mgr.get_outcome_name())
