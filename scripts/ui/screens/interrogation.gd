## Interrogation.gd
## Screen for interrogating a suspect.
## Shows suspect portrait, dialogue area, statement log with contradiction
## markers, evidence inventory, and interrogation controls.
## Receives person_id via ScreenManager.navigation_data.
extends Control


@onready var suspect_name_label: Label = %SuspectNameLabel
@onready var phase_label: Label = %PhaseLabel
@onready var pressure_label: Label = %PressureLabel
@onready var dialogue_label: RichTextLabel = %DialogueLabel
@onready var statement_list: VBoxContainer = %StatementList
@onready var evidence_list: VBoxContainer = %EvidenceList
@onready var topic_list: VBoxContainer = %TopicList
@onready var present_button: Button = %PresentButton
@onready var advance_phase_button: Button = %AdvancePhaseButton
@onready var end_session_button: Button = %EndSessionButton
@onready var back_button: Button = %BackButton

## The ID of the suspect being interrogated.
var _person_id: String = ""

## The currently selected evidence ID for presentation.
var _selected_evidence_id: String = ""


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	present_button.pressed.connect(_on_present_pressed)
	advance_phase_button.pressed.connect(_on_advance_phase_pressed)
	end_session_button.pressed.connect(_on_end_session_pressed)

	# Connect to InterrogationManager signals
	InterrogationManager.phase_changed.connect(_on_phase_changed)
	InterrogationManager.trigger_fired.connect(_on_trigger_fired)
	InterrogationManager.statement_recorded.connect(_on_statement_recorded)
	InterrogationManager.pressure_changed.connect(_on_pressure_changed)
	InterrogationManager.break_moment_reached.connect(_on_break_moment)

	var nav_data: Dictionary = ScreenManager.navigation_data
	_person_id = nav_data.get("person_id", "")

	if _person_id.is_empty():
		push_error("[Interrogation] No person_id in navigation data.")
		return

	# Start the interrogation session
	if not InterrogationManager.start_interrogation(_person_id):
		push_error("[Interrogation] Failed to start interrogation with %s" % _person_id)
		return

	_setup_ui()


func _exit_tree() -> void:
	# Disconnect signals to avoid errors after leaving screen
	if InterrogationManager.phase_changed.is_connected(_on_phase_changed):
		InterrogationManager.phase_changed.disconnect(_on_phase_changed)
	if InterrogationManager.trigger_fired.is_connected(_on_trigger_fired):
		InterrogationManager.trigger_fired.disconnect(_on_trigger_fired)
	if InterrogationManager.statement_recorded.is_connected(_on_statement_recorded):
		InterrogationManager.statement_recorded.disconnect(_on_statement_recorded)
	if InterrogationManager.pressure_changed.is_connected(_on_pressure_changed):
		InterrogationManager.pressure_changed.disconnect(_on_pressure_changed)
	if InterrogationManager.break_moment_reached.is_connected(_on_break_moment):
		InterrogationManager.break_moment_reached.disconnect(_on_break_moment)


## Builds the initial UI layout.
func _setup_ui() -> void:
	var person: PersonData = CaseManager.get_person(_person_id)
	suspect_name_label.text = person.name if person else _person_id

	_update_phase_display()
	_update_pressure_display()
	_populate_topics()
	_populate_evidence()
	_populate_statements()
	_update_button_states()
	_show_dialogue("Interrogation with %s has begun." % suspect_name_label.text)


## Updates the phase indicator.
func _update_phase_display() -> void:
	var phase: Enums.InterrogationPhase = InterrogationManager.get_current_phase()
	match phase:
		Enums.InterrogationPhase.OPEN_CONVERSATION:
			phase_label.text = "Phase: Open Conversation"
		Enums.InterrogationPhase.EVIDENCE_CONFRONTATION:
			phase_label.text = "Phase: Evidence Confrontation"
		Enums.InterrogationPhase.PSYCHOLOGICAL_PRESSURE:
			phase_label.text = "Phase: Psychological Pressure"
		Enums.InterrogationPhase.BREAK_MOMENT:
			phase_label.text = "Phase: Break Moment"
		_:
			phase_label.text = "Phase: —"


## Updates the pressure indicator.
func _update_pressure_display() -> void:
	var person: PersonData = CaseManager.get_person(_person_id)
	var threshold: int = person.pressure_threshold if person else 0
	var current: int = InterrogationManager.get_current_pressure()
	pressure_label.text = "Pressure: %d / %d" % [current, threshold]


## Shows dialogue text in the dialogue area.
func _show_dialogue(text: String) -> void:
	dialogue_label.text = text


## Populates the list of available topics.
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

	for topic: InterrogationTopicData in topics:
		var btn: Button = Button.new()
		btn.text = topic.topic_name
		btn.pressed.connect(_on_topic_pressed.bind(topic.id))
		topic_list.add_child(btn)


## Populates the evidence inventory with discovered evidence.
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


## Populates the statement log with contradiction markers.
func _populate_statements() -> void:
	for child: Node in statement_list.get_children():
		child.queue_free()

	var heard: Array[String] = InterrogationManager.get_heard_statements()
	var contradictions: Array[Dictionary] = InterrogationManager.get_contradicted_statements()
	var contradicted_ids: Array[String] = []
	for c: Dictionary in contradictions:
		contradicted_ids.append(c.get("statement_id", ""))

	if heard.is_empty():
		var empty: Label = Label.new()
		empty.text = "No statements recorded yet."
		empty.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		statement_list.add_child(empty)
		return

	for stmt_id: String in heard:
		var stmt: StatementData = CaseManager.get_statement(stmt_id)
		if stmt == null:
			continue

		var label: RichTextLabel = RichTextLabel.new()
		label.fit_content = true
		label.bbcode_enabled = true
		label.custom_minimum_size.y = 30

		if stmt_id in contradicted_ids:
			label.text = "[color=yellow]⚠[/color] %s" % stmt.text
		else:
			label.text = stmt.text

		statement_list.add_child(label)


## Updates button enabled/disabled states based on current phase.
func _update_button_states() -> void:
	var phase: Enums.InterrogationPhase = InterrogationManager.get_current_phase()
	var can_present: bool = phase == Enums.InterrogationPhase.EVIDENCE_CONFRONTATION \
		or phase == Enums.InterrogationPhase.PSYCHOLOGICAL_PRESSURE
	present_button.disabled = not can_present or _selected_evidence_id.is_empty()

	var can_advance: bool = phase == Enums.InterrogationPhase.OPEN_CONVERSATION \
		or phase == Enums.InterrogationPhase.EVIDENCE_CONFRONTATION
	advance_phase_button.disabled = not can_advance

	end_session_button.disabled = not InterrogationManager.is_active()


# --- Signal Handlers --- #

func _on_phase_changed(_new_phase: Enums.InterrogationPhase) -> void:
	_update_phase_display()
	_update_button_states()
	_populate_topics()


func _on_trigger_fired(_trigger_id: String, result: Dictionary) -> void:
	var reaction: int = result.get("reaction_type", Enums.ReactionType.DENIAL)
	var dialogue_text: String = result.get("dialogue", "")
	var reaction_name: String = EnumHelper.enum_to_string(Enums.ReactionType, reaction)

	_show_dialogue("[%s] %s" % [reaction_name, dialogue_text])
	_populate_statements()
	_populate_evidence()

	if result.get("break_moment", false):
		_show_dialogue("[BREAK MOMENT] %s" % dialogue_text)


func _on_statement_recorded(_statement_id: String) -> void:
	_populate_statements()


func _on_pressure_changed(_person_id: String, _current: int, _threshold: int) -> void:
	_update_pressure_display()


func _on_break_moment(_person_id: String) -> void:
	_update_phase_display()
	_update_button_states()


# --- User Actions --- #

func _on_topic_pressed(topic_id: String) -> void:
	var result: Dictionary = InterrogationManager.discuss_topic(topic_id)
	if result.is_empty():
		return

	var stmts: Array = result.get("statements", [])
	if not stmts.is_empty():
		var stmt: StatementData = CaseManager.get_statement(stmts[0])
		if stmt:
			_show_dialogue(stmt.text)
	_populate_topics()
	_populate_statements()


func _on_evidence_selected(evidence_id: String) -> void:
	_selected_evidence_id = evidence_id
	# Deselect other evidence buttons
	for child: Node in evidence_list.get_children():
		if child is Button:
			var btn: Button = child as Button
			btn.button_pressed = false
	# Re-select this one
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
		# Trigger fired - UI updates happen via signal handlers
		pass
	else:
		_show_dialogue("This evidence doesn't seem relevant to %s." % suspect_name_label.text)

	_selected_evidence_id = ""
	_update_button_states()


func _on_advance_phase_pressed() -> void:
	InterrogationManager.advance_phase()


func _on_end_session_pressed() -> void:
	InterrogationManager.end_interrogation()
	ScreenManager.go_back()


func _on_back_pressed() -> void:
	if InterrogationManager.is_active():
		InterrogationManager.end_interrogation()
	ScreenManager.go_back()
