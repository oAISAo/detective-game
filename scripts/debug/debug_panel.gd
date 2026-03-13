## DebugPanel.gd
## In-game debug panel toggled with F1.
## Shows game state information and provides debug actions.
## Only functional in debug builds.
extends CanvasLayer


## Reference to the panel container.
@onready var panel: PanelContainer = $Panel
@onready var content_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/ContentLabel
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/HeaderBar/CloseButton


var _is_visible: bool = false


func _ready() -> void:
	layer = 100  # Always on top
	panel.visible = false
	close_button.pressed.connect(_toggle)
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
	text += "  Remaining: %d\n\n" % remaining_mandatory.size()

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
	var all_evidence: Array[Dictionary] = CaseManager.get_all_evidence()
	for ev: Dictionary in all_evidence:
		GameManager.discover_evidence(ev.get("id", ""))
	_refresh()
	print("[Debug] Unlocked all evidence (%d items)." % all_evidence.size())


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
