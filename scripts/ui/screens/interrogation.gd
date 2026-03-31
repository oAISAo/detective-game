## Interrogation.gd
## Evidence-driven interrogation screen.
## On entering, the interrogation is immediately active:
## dialogue, statements, topics, and evidence are all available.
## Receives person_id via ScreenManager.navigation_data.
extends Control


## Noir accent color for focused elements.
const FOCUS_ACCENT_COLOR := Color(0.85, 0.65, 0.3, 1.0)
## Focused button background.
const FOCUS_BG_COLOR := Color(0.22, 0.2, 0.16, 0.95)
## Focused button border.
const FOCUS_BORDER_COLOR := Color(0.85, 0.65, 0.3, 0.8)


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
		return

	if not InterrogationManager.start_interrogation(_person_id):
		push_error("[Interrogation] Failed to start interrogation with %s" % _person_id)
		return

	_setup_ui()


func _exit_tree() -> void:
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
	match phase:
		Enums.InterrogationPhase.STATEMENT_INTAKE:
			phase_label.text = "Statement Intake"
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
		current_focus_label.text = "No focus selected — pick a statement or topic"
		current_focus_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		return

	current_focus_label.add_theme_color_override("font_color", FOCUS_ACCENT_COLOR)
	var focus_type: String = focus.get("type", "")
	var focus_id: String = focus.get("id", "")
	if focus_type == "statement":
		var stmt: StatementData = CaseManager.get_statement(focus_id)
		current_focus_label.text = "► Challenging: \"%s\"" % (stmt.text if stmt else focus_id)
	elif focus_type == "topic":
		var topic: InterrogationTopicData = CaseManager.get_interrogation_topic(focus_id)
		current_focus_label.text = "► Topic: %s" % (topic.topic_name if topic else focus_id)
	else:
		current_focus_label.text = "No focus selected — pick a statement or topic"
		current_focus_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))


func _show_dialogue(text: String) -> void:
	dialogue_label.text = text


## Applies a strong visual style to a focused button (accent border + warm background).
func _apply_focus_style(btn: Button) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = FOCUS_BG_COLOR
	style.border_color = FOCUS_BORDER_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", FOCUS_ACCENT_COLOR)
	btn.add_theme_color_override("font_pressed_color", FOCUS_ACCENT_COLOR)


# =========================================================================
# List Population
# =========================================================================

func _populate_topics() -> void:
	for child: Node in topic_list.get_children():
		child.queue_free()

	var topics: Array[InterrogationTopicData] = InterrogationManager.get_available_topics()
	if topics.is_empty():
		var empty: Label = Label.new()
		empty.text = "No topics available."
		empty.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		topic_list.add_child(empty)
		return

	var current_focus: Dictionary = InterrogationManager.get_current_focus()
	for topic: InterrogationTopicData in topics:
		var is_focused: bool = (
			current_focus.get("type", "") == "topic"
			and current_focus.get("id", "") == topic.id
		)
		var btn: Button = Button.new()
		btn.text = ("► " + topic.topic_name) if is_focused else topic.topic_name
		btn.toggle_mode = true
		btn.button_pressed = is_focused
		if is_focused:
			_apply_focus_style(btn)
		btn.pressed.connect(_on_topic_pressed.bind(topic.id))
		topic_list.add_child(btn)


func _populate_evidence() -> void:
	for child: Node in evidence_list.get_children():
		child.queue_free()

	_selected_evidence_id = ""

	var discovered: Array[String] = GameManager.discovered_evidence
	if discovered.is_empty():
		var empty: Label = Label.new()
		empty.text = "No evidence collected."
		empty.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		evidence_list.add_child(empty)
		return

	for ev_id: String in discovered:
		var ev: EvidenceData = CaseManager.get_evidence(ev_id)
		var btn: Button = Button.new()
		btn.text = ev.name if ev else ev_id
		btn.toggle_mode = true
		btn.pressed.connect(_on_evidence_selected.bind(ev_id))
		evidence_list.add_child(btn)


func _populate_statements() -> void:
	for child: Node in statement_list.get_children():
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
		empty.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
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

		var btn: Button = Button.new()
		btn.toggle_mode = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var prefix: String = ""
		if is_focused:
			prefix = "► "
		elif stmt_id in contradicted_ids:
			prefix = "⚠ "

		btn.text = prefix + stmt.text
		btn.button_pressed = is_focused
		if is_focused:
			_apply_focus_style(btn)
		btn.pressed.connect(_on_statement_pressed.bind(stmt_id))
		statement_list.add_child(btn)


func _update_button_states() -> void:
	var phase: Enums.InterrogationPhase = InterrogationManager.get_current_phase()
	var focus: Dictionary = InterrogationManager.get_current_focus()
	var in_intake: bool = phase == Enums.InterrogationPhase.STATEMENT_INTAKE

	# Present Evidence: not allowed during statement intake
	var can_present: bool = InterrogationManager.is_active() and not in_intake
	present_button.disabled = not can_present or focus.is_empty() or _selected_evidence_id.is_empty()

	# Apply Pressure: not allowed during statement intake
	apply_pressure_button.visible = InterrogationManager.is_active()
	var can_pressure: bool = InterrogationManager.can_apply_pressure() and not in_intake
	apply_pressure_button.disabled = not can_pressure
	if not can_pressure and InterrogationManager.is_active():
		if in_intake:
			apply_pressure_button.tooltip_text = "Proceed to questioning first"
		else:
			apply_pressure_button.tooltip_text = "Need more contradictions to apply pressure"
	else:
		apply_pressure_button.tooltip_text = ""

	end_session_button.disabled = not InterrogationManager.is_active()

	# Show/hide the "Proceed to Questioning" button
	_update_proceed_button(in_intake)


## Shows or hides the "Proceed to Questioning" button for statement intake phase.
func _update_proceed_button(in_intake: bool) -> void:
	var parent: Node = dialogue_label.get_parent()
	var existing: Node = parent.get_node_or_null("ProceedButton")
	if in_intake and existing == null:
		var btn: Button = Button.new()
		btn.name = "ProceedButton"
		btn.text = "Proceed to Questioning ►"
		btn.pressed.connect(_on_proceed_pressed)
		parent.add_child(btn)
	elif not in_intake and existing != null:
		existing.queue_free()


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

func _on_proceed_pressed() -> void:
	InterrogationManager.advance_to_interrogation()
	_show_dialogue("You begin questioning %s." % suspect_name_label.text)


func _on_statement_pressed(statement_id: String) -> void:
	var current_focus: Dictionary = InterrogationManager.get_current_focus()
	if current_focus.get("type", "") == "statement" and current_focus.get("id", "") == statement_id:
		InterrogationManager.clear_focus()
	else:
		InterrogationManager.select_focus("statement", statement_id)


func _on_topic_pressed(topic_id: String) -> void:
	# If topic has unheard statements, discuss first to produce them
	var topic: InterrogationTopicData = CaseManager.get_interrogation_topic(topic_id)
	if topic and not topic.statements.is_empty():
		var session_stmts: Array[String] = InterrogationManager.get_session_statements()
		var has_unheard: bool = false
		for stmt_id: String in topic.statements:
			if stmt_id not in session_stmts:
				has_unheard = true
				break
		if has_unheard:
			var result: Dictionary = InterrogationManager.discuss_topic(topic_id)
			if not result.is_empty():
				var dialogue_text: String = result.get("dialogue", "")
				if dialogue_text.is_empty():
					var stmts: Array = result.get("statements", [])
					if not stmts.is_empty():
						var stmt: StatementData = CaseManager.get_statement(stmts[0])
						if stmt:
							dialogue_text = stmt.text
				if not dialogue_text.is_empty():
					_show_dialogue(dialogue_text)
				_populate_statements()

	# Toggle topic as current focus
	var current_focus: Dictionary = InterrogationManager.get_current_focus()
	if current_focus.get("type", "") == "topic" and current_focus.get("id", "") == topic_id:
		InterrogationManager.clear_focus()
	else:
		InterrogationManager.select_focus("topic", topic_id)


func _on_evidence_selected(evidence_id: String) -> void:
	_selected_evidence_id = evidence_id
	for child: Node in evidence_list.get_children():
		if child is Button:
			var btn: Button = child as Button
			btn.button_pressed = false
	for child: Node in evidence_list.get_children():
		if child is Button:
			var btn: Button = child as Button
			var ev: EvidenceData = CaseManager.get_evidence(evidence_id)
			if ev and btn.text == ev.name:
				btn.button_pressed = true
				break
	_update_button_states()


func _on_present_pressed() -> void:
	if _selected_evidence_id.is_empty():
		return

	var result: Dictionary = InterrogationManager.present_evidence(_selected_evidence_id)
	if result.get("triggered", false):
		pass  # trigger_fired signal handles dialogue
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
			if dialogue.is_empty():
				dialogue = "The suspect breaks down under pressure."
			_show_dialogue("[BREAK] %s" % dialogue)
		else:
			if dialogue.is_empty():
				dialogue = "You apply pressure. The suspect is visibly shaken."
			_show_dialogue(dialogue)
	else:
		var required: int = result.get("required", 1)
		var current: int = result.get("current", 0)
		_show_dialogue("Not enough contradictions to apply pressure (%d/%d)." % [current, required])


func _on_end_session_pressed() -> void:
	InterrogationManager.end_interrogation()
	ScreenManager.navigate_back()


func _on_back_pressed() -> void:
	if InterrogationManager.is_active():
		InterrogationManager.end_interrogation()
	ScreenManager.navigate_back()
