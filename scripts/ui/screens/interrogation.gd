## Interrogation.gd
## Evidence-driven interrogation screen.
## On entering, the interrogation is immediately active:
## dialogue, statements, topics, and evidence are all available.
## Receives person_id via ScreenManager.navigation_data.
extends Control


## Noir accent color for focused elements.
const FOCUS_ACCENT_COLOR := Color(1.0, 0.78, 0.35, 1.0)
## Focused button background.
const FOCUS_BG_COLOR := Color(0.28, 0.24, 0.14, 0.95)
## Focused button border.
const FOCUS_BORDER_COLOR := Color(1.0, 0.78, 0.35, 1.0)
## Selected evidence highlight.
const EVIDENCE_SELECTED_BG := Color(0.18, 0.22, 0.28, 0.95)
const EVIDENCE_SELECTED_BORDER := Color(0.45, 0.7, 1.0, 1.0)
const EVIDENCE_SELECTED_TEXT := Color(0.55, 0.8, 1.0, 1.0)
## Newly-unlocked topic highlight.
const NEW_TOPIC_BG_COLOR := Color(0.18, 0.25, 0.16, 0.95)
const NEW_TOPIC_BORDER_COLOR := Color(0.45, 0.85, 0.35, 1.0)
const NEW_TOPIC_TEXT_COLOR := Color(0.55, 0.9, 0.45, 1.0)
## Contradicted statement style.
const CONTRADICTED_BG_COLOR := Color(0.28, 0.14, 0.1, 0.95)
const CONTRADICTED_BORDER_COLOR := Color(0.9, 0.35, 0.25, 0.8)
## Inline feedback color appended to dialogue.
const INLINE_INFO_COLOR := Color(0.85, 0.65, 0.3, 1.0)


@onready var suspect_name_label: Label = %SuspectNameLabel
@onready var phase_label: Label = %PhaseLabel
@onready var pressure_label: Label = %PressureLabel
@onready var dialogue_label: RichTextLabel = %DialogueLabel
@onready var statement_list: VBoxContainer = %StatementList
@onready var evidence_list: VBoxContainer = %EvidenceList
@onready var topic_list: VBoxContainer = %TopicList
@onready var current_focus_label: Label = %CurrentFocusLabel
@onready var present_button: Button = %PresentButton
@onready var apply_pressure_button: Button = %ApplyPressureButton
@onready var end_session_button: Button = %EndSessionButton
@onready var back_button: Button = %BackButton

var _person_id: String = ""
var _selected_evidence_id: String = ""
## Track newly unlocked topic IDs so we can highlight them in the UI.
var _newly_unlocked_topic_ids: Array[String] = []


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	present_button.pressed.connect(_on_present_pressed)
	apply_pressure_button.pressed.connect(_on_apply_pressure_pressed)
	end_session_button.pressed.connect(_on_end_session_pressed)

	InterrogationManager.phase_changed.connect(_on_phase_changed)
	InterrogationManager.trigger_fired.connect(_on_trigger_fired)
	InterrogationManager.statement_recorded.connect(_on_statement_recorded)
	InterrogationManager.pressure_changed.connect(_on_pressure_changed)
	InterrogationManager.break_moment_reached.connect(_on_break_moment)
	InterrogationManager.focus_changed.connect(_on_focus_changed)
	InterrogationManager.contradiction_logged.connect(_on_contradiction_logged)

	var nav_data: Dictionary = ScreenManager.navigation_data
	_person_id = nav_data.get("person_id", "")

	if _person_id.is_empty():
		push_error("[Interrogation] No person_id in navigation data.")
		_show_error_state("No suspect selected for interrogation.")
		return

	# If a stale session is active (e.g. from previous day), end it first
	if InterrogationManager.is_active():
		InterrogationManager.end_interrogation()

	if not InterrogationManager.start_interrogation(_person_id):
		push_error("[Interrogation] Failed to start interrogation with %s" % _person_id)
		_show_error_state("Could not start interrogation.")
		return

	NotificationManager.suppressed = true
	_setup_ui()


func _exit_tree() -> void:
	NotificationManager.suppressed = false
	var signals: Array[Signal] = [
		InterrogationManager.phase_changed,
		InterrogationManager.trigger_fired,
		InterrogationManager.statement_recorded,
		InterrogationManager.pressure_changed,
		InterrogationManager.break_moment_reached,
		InterrogationManager.focus_changed,
		InterrogationManager.contradiction_logged,
	]
	var callbacks: Array[Callable] = [
		_on_phase_changed,
		_on_trigger_fired,
		_on_statement_recorded,
		_on_pressure_changed,
		_on_break_moment,
		_on_focus_changed,
		_on_contradiction_logged,
	]
	for i: int in signals.size():
		if signals[i].is_connected(callbacks[i]):
			signals[i].disconnect(callbacks[i])


func _show_error_state(message: String) -> void:
	suspect_name_label.text = "—"
	phase_label.text = ""
	pressure_label.text = ""
	dialogue_label.text = message
	present_button.disabled = true
	apply_pressure_button.disabled = true
	end_session_button.disabled = true
	statement_list.visible = false
	evidence_list.visible = false
	topic_list.visible = false


func _setup_ui() -> void:
	var person: PersonData = CaseManager.get_person(_person_id)
	suspect_name_label.text = person.name if person else _person_id

	# Show initial dialogue from session data
	var initial: String = InterrogationManager.get_initial_dialogue()
	if initial.is_empty():
		_show_dialogue("Interrogation with %s has begun." % suspect_name_label.text)
	else:
		_show_dialogue(initial)

	_update_phase_display()
	_update_pressure_display()
	_update_focus_display()
	_populate_topics()
	_populate_evidence()
	_populate_statements()
	_update_button_states()


# =========================================================================
# Display Updates
# =========================================================================

func _update_phase_display() -> void:
	var phase: Enums.InterrogationPhase = InterrogationManager.get_current_phase()
	var has_break: bool = InterrogationManager.has_break_moment(_person_id)
	if has_break:
		phase_label.text = "Post-Pressure"
	else:
		match phase:
			Enums.InterrogationPhase.INTERROGATION:
				phase_label.text = "Questioning"
			Enums.InterrogationPhase.PRESSURE:
				phase_label.text = "Confrontation"
			Enums.InterrogationPhase.BREAK_MOMENT:
				phase_label.text = "Breakthrough"
			_:
				phase_label.text = ""


func _update_pressure_display() -> void:
	var person: PersonData = CaseManager.get_person(_person_id)
	var threshold: int = person.pressure_threshold if person else 0
	var current: int = InterrogationManager.get_current_pressure()
	pressure_label.text = "Pressure: %d / %d" % [current, threshold]


func _update_focus_display() -> void:
	var focus: Dictionary = InterrogationManager.get_current_focus()
	if focus.is_empty():
		current_focus_label.text = "No target selected \u2014 select a statement or topic to challenge"
		current_focus_label.add_theme_color_override("font_color", UIColors.MUTED)
		return

	current_focus_label.add_theme_color_override("font_color", FOCUS_ACCENT_COLOR)
	var focus_type: String = focus.get("type", "")
	var focus_id: String = focus.get("id", "")
	if focus_type == "statement":
		var stmt: StatementData = CaseManager.get_statement(focus_id)
		current_focus_label.text = "Current Target Statement: \"%s\"" % (stmt.text if stmt else focus_id)
	elif focus_type == "topic":
		var topic: InterrogationTopicData = CaseManager.get_interrogation_topic(focus_id)
		current_focus_label.text = "Current Target Topic: %s" % (topic.topic_name if topic else focus_id)
	else:
		current_focus_label.text = "No target selected \u2014 select a statement or topic to challenge"
		current_focus_label.add_theme_color_override("font_color", UIColors.MUTED)


func _show_dialogue(text: String) -> void:
	dialogue_label.text = text


## Appends inline feedback below the current dialogue.
func _append_dialogue(text: String) -> void:
	dialogue_label.text += "\n\n" + text


## Applies a strong visual style to a focused button (accent border + warm background).
func _apply_focus_style(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = FOCUS_BG_COLOR
	style.border_color = FOCUS_BORDER_COLOR
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_color_override("font_color", FOCUS_ACCENT_COLOR)
	btn.add_theme_color_override("font_pressed_color", FOCUS_ACCENT_COLOR)
	btn.add_theme_color_override("font_hover_color", FOCUS_ACCENT_COLOR)


## Applies a selected style to evidence buttons.
func _apply_evidence_selected_style(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = EVIDENCE_SELECTED_BG
	style.border_color = EVIDENCE_SELECTED_BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_color_override("font_color", EVIDENCE_SELECTED_TEXT)
	btn.add_theme_color_override("font_pressed_color", EVIDENCE_SELECTED_TEXT)
	btn.add_theme_color_override("font_hover_color", EVIDENCE_SELECTED_TEXT)


## Applies a highlight style to a newly unlocked topic button.
func _apply_new_topic_style(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = NEW_TOPIC_BG_COLOR
	style.border_color = NEW_TOPIC_BORDER_COLOR
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_color_override("font_color", NEW_TOPIC_TEXT_COLOR)
	btn.add_theme_color_override("font_pressed_color", NEW_TOPIC_TEXT_COLOR)
	btn.add_theme_color_override("font_hover_color", NEW_TOPIC_TEXT_COLOR)


## Applies a subtle warning style to a contradicted statement button.
func _apply_contradicted_style(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = CONTRADICTED_BG_COLOR
	style.border_color = CONTRADICTED_BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)


# =========================================================================
# List Population
# =========================================================================

func _populate_topics() -> void:
	for child: Node in topic_list.get_children():
		topic_list.remove_child(child)
		child.queue_free()

	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	if topics.is_empty():
		var empty: Label = Label.new()
		empty.text = "No topics available."
		empty.add_theme_color_override("font_color", UIColors.MUTED)
		topic_list.add_child(empty)
		return

	var current_focus: Dictionary = InterrogationManager.get_current_focus()
	for topic: InterrogationTopicData in topics:
		var is_focused: bool = (
			current_focus.get("type", "") == "topic"
			and current_focus.get("id", "") == topic.id
		)
		var is_new: bool = topic.id in _newly_unlocked_topic_ids
		var btn: Button = Button.new()
		var prefix: String = ""
		if is_focused:
			prefix = "\u25ba "
		elif is_new:
			prefix = "\u2605 "
		btn.text = prefix + topic.topic_name
		btn.toggle_mode = true
		btn.button_pressed = is_focused
		if is_focused:
			_apply_focus_style(btn)
		elif is_new:
			_apply_new_topic_style(btn)
		btn.pressed.connect(_on_topic_pressed.bind(topic.id))
		topic_list.add_child(btn)


func _populate_evidence() -> void:
	for child: Node in evidence_list.get_children():
		evidence_list.remove_child(child)
		child.queue_free()

	var discovered: Array[String] = GameManager.discovered_evidence
	if discovered.is_empty():
		var empty: Label = Label.new()
		empty.text = "No evidence collected."
		empty.add_theme_color_override("font_color", UIColors.MUTED)
		evidence_list.add_child(empty)
		return

	for ev_id: String in discovered:
		var ev: EvidenceData = CaseManager.get_evidence(ev_id)
		var is_selected: bool = ev_id == _selected_evidence_id
		var btn: Button = Button.new()
		var prefix: String = "\u25c6 " if is_selected else ""
		btn.text = prefix + (ev.name if ev else ev_id)
		btn.toggle_mode = true
		btn.button_pressed = is_selected
		btn.set_meta("evidence_id", ev_id)
		if is_selected:
			_apply_evidence_selected_style(btn)
		btn.pressed.connect(_on_evidence_selected.bind(ev_id))
		evidence_list.add_child(btn)


func _populate_statements() -> void:
	for child: Node in statement_list.get_children():
		statement_list.remove_child(child)
		child.queue_free()

	var session_stmts: Array[String] = InterrogationManager.get_session_statements()
	var contradictions: Array[Dictionary] = InterrogationManager.get_session_contradictions()
	var contradicted_ids: Array[String] = []
	for c: Dictionary in contradictions:
		contradicted_ids.append(c.get("statement_id", ""))

	var current_focus: Dictionary = InterrogationManager.get_current_focus()

	if session_stmts.is_empty():
		var empty: Label = Label.new()
		empty.text = "No statements recorded yet."
		empty.add_theme_color_override("font_color", UIColors.MUTED)
		statement_list.add_child(empty)
		return

	for stmt_id: String in session_stmts:
		var stmt: StatementData = CaseManager.get_statement(stmt_id)
		if stmt == null:
			continue

		var is_focused: bool = (
			current_focus.get("type", "") == "statement"
			and current_focus.get("id", "") == stmt_id
		)
		var is_contradicted: bool = stmt_id in contradicted_ids

		var btn: Button = Button.new()
		btn.toggle_mode = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var prefix: String = ""
		if is_focused:
			prefix = "\u25ba "
		elif is_contradicted:
			prefix = "\u26a0 CONTRADICTED: "

		btn.text = prefix + stmt.text
		btn.button_pressed = is_focused
		if is_focused:
			_apply_focus_style(btn)
		elif is_contradicted:
			_apply_contradicted_style(btn)
		btn.pressed.connect(_on_statement_pressed.bind(stmt_id))
		statement_list.add_child(btn)


func _update_button_states() -> void:
	var focus: Dictionary = InterrogationManager.get_current_focus()

	# Present Evidence: requires active session, a focus, and selected evidence
	var can_present: bool = InterrogationManager.is_active()
	present_button.disabled = not can_present or focus.is_empty() or _selected_evidence_id.is_empty()
	if can_present and focus.is_empty():
		present_button.tooltip_text = "Select a statement or topic to target first"
	elif can_present and _selected_evidence_id.is_empty():
		present_button.tooltip_text = "Select evidence to present"
	else:
		present_button.tooltip_text = ""

	# Apply Pressure: visible always, disabled until threshold met and not already used
	apply_pressure_button.visible = InterrogationManager.is_active()
	var can_pressure: bool = InterrogationManager.can_apply_pressure()
	apply_pressure_button.disabled = not can_pressure
	if not can_pressure and InterrogationManager.is_active():
		if InterrogationManager.has_break_moment(_person_id):
			apply_pressure_button.tooltip_text = "Pressure already applied"
		else:
			var current: int = InterrogationManager.get_current_pressure()
			var session: InterrogationSessionData = CaseManager.get_interrogation_session(_person_id)
			var gate: int = session.pressure_gate if session else 1
			apply_pressure_button.tooltip_text = "Need more pressure (%d/%d)" % [current, gate]
	else:
		apply_pressure_button.tooltip_text = ""

	end_session_button.disabled = not InterrogationManager.is_active()


# =========================================================================
# Signal Handlers
# =========================================================================

func _on_phase_changed(_new_phase: Enums.InterrogationPhase) -> void:
	_update_phase_display()
	_update_button_states()
	_populate_topics()
	_populate_statements()


func _on_trigger_fired(_trigger_id: String, result: Dictionary) -> void:
	var dialogue_text: String = result.get("dialogue", "")
	if dialogue_text.is_empty():
		dialogue_text = "..."

	_show_dialogue(dialogue_text)

	# Build inline status feedback appended to dialogue
	var status_parts: Array[String] = []

	var pressure_added: int = result.get("pressure_added", 0)
	if pressure_added > 0:
		status_parts.append("Pressure increased (+%d)" % pressure_added)

	var new_stmt_id: String = result.get("new_statement_id", "")
	if not new_stmt_id.is_empty():
		status_parts.append("New statement recorded")

	var unlocks: Array = result.get("unlocks", [])
	for unlock_id: String in unlocks:
		if unlock_id.begins_with("topic_"):
			_newly_unlocked_topic_ids.append(unlock_id)
			var topic: InterrogationTopicData = CaseManager.get_interrogation_topic(unlock_id)
			var topic_name: String = topic.topic_name if topic else unlock_id
			status_parts.append("New topic: %s" % topic_name)

	if not status_parts.is_empty() and GameManager.debug_mode:
		_append_dialogue("[%s]" % " | ".join(status_parts))

	_populate_statements()
	_populate_topics()
	_populate_evidence()
	_update_button_states()


func _on_statement_recorded(_statement_id: String) -> void:
	_populate_statements()


func _on_pressure_changed(_person_id: String, _current: int, _threshold: int) -> void:
	_update_pressure_display()
	_update_button_states()


func _on_break_moment(_person_id: String) -> void:
	_update_phase_display()
	_update_button_states()
	_populate_topics()
	_populate_statements()


func _on_focus_changed(_focus: Dictionary) -> void:
	_update_focus_display()
	_update_button_states()
	_populate_statements()
	_populate_topics()


func _on_contradiction_logged(_statement_id: String, _evidence_id: String) -> void:
	_populate_statements()
	_update_button_states()


# =========================================================================
# User Actions
# =========================================================================

func _on_statement_pressed(statement_id: String) -> void:
	var current_focus: Dictionary = InterrogationManager.get_current_focus()
	if current_focus.get("type", "") == "statement" and current_focus.get("id", "") == statement_id:
		InterrogationManager.clear_focus()
	else:
		InterrogationManager.select_focus("statement", statement_id)


func _on_topic_pressed(topic_id: String) -> void:
	var topic: InterrogationTopicData = CaseManager.get_interrogation_topic(topic_id)
	if topic == null:
		return

	# Clear "new" highlight once clicked
	_newly_unlocked_topic_ids.erase(topic_id)

	# Always discuss the topic to produce statements and get dialogue
	var result: Dictionary = InterrogationManager.discuss_topic(topic_id)
	if not result.is_empty():
		var dialogue_text: String = result.get("dialogue", "")
		if dialogue_text.is_empty():
			var stmts: Array = result.get("statements", [])
			if not stmts.is_empty():
				var stmt: StatementData = CaseManager.get_statement(stmts[0])
				if stmt:
					dialogue_text = stmt.text
		if dialogue_text.is_empty() and not topic.dialogue.is_empty():
			dialogue_text = topic.dialogue
		if not dialogue_text.is_empty():
			_show_dialogue(dialogue_text)
		_populate_statements()
		_populate_topics()
	elif not topic.dialogue.is_empty():
		_show_dialogue(topic.dialogue)

	# Toggle topic as current focus
	var current_focus: Dictionary = InterrogationManager.get_current_focus()
	if current_focus.get("type", "") == "topic" and current_focus.get("id", "") == topic_id:
		InterrogationManager.clear_focus()
	else:
		InterrogationManager.select_focus("topic", topic_id)


func _on_evidence_selected(evidence_id: String) -> void:
	# Toggle: deselect if already selected
	if _selected_evidence_id == evidence_id:
		_selected_evidence_id = ""
	else:
		_selected_evidence_id = evidence_id
	_populate_evidence()
	_update_button_states()


func _on_present_pressed() -> void:
	if _selected_evidence_id.is_empty():
		return

	var result: Dictionary = InterrogationManager.present_evidence(_selected_evidence_id)
	if result.get("triggered", false):
		pass  # trigger_fired signal handles dialogue and inline feedback
	elif result.get("already_fired", false):
		var already_texts: Array[String] = [
			"They already addressed that.",
			"You've already challenged that point.",
			"That contradiction has already been resolved.",
		]
		_show_dialogue(already_texts[randi() % already_texts.size()])
	else:
		var reason: String = result.get("reason", "")
		if reason == "wrong_focus":
			_show_dialogue("That evidence might be relevant, but not to this particular point. Try a different approach.")
		elif reason == "prerequisite_not_met":
			_show_dialogue("You sense this could be useful, but you need to build up to it first.")
		else:
			var rejection: String = InterrogationManager.get_rejection_text()
			_show_dialogue(rejection)

	_selected_evidence_id = ""
	_populate_evidence()
	_update_button_states()


func _on_apply_pressure_pressed() -> void:
	var result: Dictionary = InterrogationManager.apply_pressure()
	if result.get("success", false):
		var dialogue: String = result.get("dialogue", "")
		if result.get("break_moment", false):
			# Mark break-unlocked topics as new for green highlighting
			var session: InterrogationSessionData = CaseManager.get_interrogation_session(
				InterrogationManager.get_current_person_id()
			)
			if session:
				for unlock_id: String in session.break_unlocks:
					if unlock_id.begins_with("topic_") and unlock_id not in _newly_unlocked_topic_ids:
						_newly_unlocked_topic_ids.append(unlock_id)
			if dialogue.is_empty():
				dialogue = "The suspect breaks down under pressure."
			_show_dialogue("[BREAK] %s" % dialogue)
			_populate_topics()
			_populate_statements()
		else:
			if dialogue.is_empty():
				dialogue = "You apply pressure. The suspect is visibly shaken."
			_show_dialogue(dialogue)
		_update_button_states()
		_update_phase_display()
	else:
		var reason: String = result.get("reason", "")
		if reason == "already_used":
			_show_dialogue("You've already pressed this suspect to their limit.")
		else:
			var required: int = result.get("required", 1)
			var current: int = result.get("current", 0)
			_show_dialogue("Not enough pressure to confront the suspect (%d/%d)." % [current, required])


func _on_end_session_pressed() -> void:
	InterrogationManager.end_interrogation()
	ScreenManager.navigate_back()


func _on_back_pressed() -> void:
	if InterrogationManager.is_active():
		InterrogationManager.end_interrogation()
	ScreenManager.navigate_back()
