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
	set_morning_button.pressed.connect(func() -> void: debug_set_time_slot(Enums.TimeSlot.MORNING))
	set_afternoon_button.pressed.connect(func() -> void: debug_set_time_slot(Enums.TimeSlot.AFTERNOON))
	set_evening_button.pressed.connect(func() -> void: debug_set_time_slot(Enums.TimeSlot.EVENING))
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
	text += "  Time Slot: %s\n" % GameManager.get_time_slot_display()
	text += "  Actions Remaining: %d / %d\n" % [GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY]
	text += "  Game Active: %s\n\n" % str(GameManager.game_active)

	# Evidence
	text += "[b]Evidence[/b]\n"
	text += "  Discovered: %d items\n" % GameManager.discovered_evidence.size()
	for ev_id: String in GameManager.discovered_evidence:
		text += "    ✓ %s\n" % ev_id
	text += "\n"

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

	# Case
	text += "[b]Case[/b]\n"
	text += "  Loaded: %s\n" % str(CaseManager.case_loaded_flag)

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
	GameManager.current_time_slot = Enums.TimeSlot.MORNING
	GameManager.actions_remaining = GameManager.ACTIONS_PER_DAY
	GameManager.day_changed.emit(GameManager.current_day)
	GameManager.time_slot_changed.emit(GameManager.current_time_slot)
	_refresh()
	print("[Debug] Set day to %d." % day)


## Sets the current time slot.
func debug_set_time_slot(slot: Enums.TimeSlot) -> void:
	GameManager.current_time_slot = slot
	GameManager.time_slot_changed.emit(slot)
	_refresh()
	print("[Debug] Set time slot to %s." % GameManager.get_time_slot_display())


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
