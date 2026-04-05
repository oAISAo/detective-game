## LocationInvestigation.gd
## Screen for investigating a specific location.
## Shows location info, interactive objects, tools, and investigation progress.
## Receives location_id via ScreenManager.navigation_data.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var completion_label: Label = %CompletionLabel
@onready var object_list: VBoxContainer = %ObjectList
@onready var tool_panel: VBoxContainer = %ToolPanel
@onready var detail_panel: VBoxContainer = %DetailPanel
@onready var detail_title: Label = %DetailTitle
@onready var detail_description: RichTextLabel = %DetailDescription
@onready var detail_state: Label = %DetailState
@onready var detail_actions: VBoxContainer = %DetailActions
@onready var back_button: Button = %BackButton

## The location being investigated.
var _location: LocationData = null

## The currently selected object ID.
var _selected_object_id: String = ""

## Whether this is a full investigation (can perform actions) or quick visit.
var _full_investigation: bool = true


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	var nav_data: Dictionary = ScreenManager.navigation_data
	var location_id: String = nav_data.get("location_id", "")
	_full_investigation = nav_data.get("full_investigation", true)

	if location_id.is_empty():
		push_error("[LocationInvestigation] No location_id in navigation data.")
		_show_error_state("No location selected.")
		return

	_location = CaseManager.get_location(location_id)
	if _location == null:
		push_error("[LocationInvestigation] Location not found: %s" % location_id)
		_show_error_state("Location '%s' could not be found." % location_id)
		return

	_setup_ui()


func _show_error_state(message: String) -> void:
	title_label.text = "Location Not Found"
	description_label.text = message
	completion_label.text = ""
	object_list.visible = false
	tool_panel.visible = false
	detail_panel.visible = false


## Builds the initial UI layout.
func _setup_ui() -> void:
	title_label.text = _location.name
	description_label.text = _location.description if not _location.description.is_empty() else "No description."

	_update_completion()
	_populate_objects()
	_populate_tools()
	_clear_detail()


## Updates the completion indicator.
func _update_completion() -> void:
	var completion: Dictionary = LocationInvestigationManager.get_location_completion(_location.id)
	completion_label.text = "%d/%d clues found" % [completion["found"], completion["total"]]


## Populates the object list for this location.
func _populate_objects() -> void:
	for child: Node in object_list.get_children():
		object_list.remove_child(child)
		child.queue_free()

	if _location.investigable_objects.is_empty():
		var empty: Label = Label.new()
		empty.text = "Nothing to investigate here."
		empty.add_theme_color_override("font_color", UIColors.MUTED)
		object_list.add_child(empty)
		return

	for obj: InvestigableObjectData in _location.investigable_objects:
		var btn: Button = Button.new()
		var state_marker: String = _get_state_marker(obj.id)
		btn.text = "%s %s" % [state_marker, obj.name]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_object_selected.bind(obj.id))
		object_list.add_child(btn)


## Populates the tool panel with available tools.
func _populate_tools() -> void:
	for child: Node in tool_panel.get_children():
		if child is Button:
			tool_panel.remove_child(child)
			child.queue_free()

	var tools: Array[String] = ToolManager.get_available_tools()
	for tool_id: String in tools:
		var btn: Button = Button.new()
		btn.text = "🔧 %s" % ToolManager.get_tool_name(tool_id)
		btn.pressed.connect(_on_tool_selected.bind(tool_id))
		btn.disabled = _selected_object_id.is_empty() or not _full_investigation
		tool_panel.add_child(btn)


## Gets the state marker symbol for an object.
func _get_state_marker(object_id: String) -> String:
	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(_location.id, object_id)
	match state:
		Enums.InvestigationState.NOT_INSPECTED:
			return "🟡"
		Enums.InvestigationState.PARTIALLY_EXAMINED:
			return "🔵"
		Enums.InvestigationState.FULLY_EXAMINED:
			return "⚪"
	return "🟡"


## Handles object selection from the list.
func _on_object_selected(object_id: String) -> void:
	_selected_object_id = object_id
	_show_object_detail(object_id)
	_update_tool_buttons()


## Shows detail panel for a selected object.
func _show_object_detail(object_id: String) -> void:
	var obj: InvestigableObjectData = _find_object(object_id)
	if obj == null:
		return

	detail_panel.visible = true
	detail_title.text = obj.name
	detail_description.text = obj.description if not obj.description.is_empty() else "No details available."

	var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(_location.id, object_id)

	match state:
		Enums.InvestigationState.NOT_INSPECTED:
			detail_state.text = "Status: Not inspected"
			detail_state.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
		Enums.InvestigationState.PARTIALLY_EXAMINED:
			detail_state.text = "Status: Partially examined"
			detail_state.add_theme_color_override("font_color", Color(0.3, 0.5, 0.9))
		Enums.InvestigationState.FULLY_EXAMINED:
			detail_state.text = "Status: Fully examined"
			detail_state.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	_populate_action_buttons(obj)
	_populate_discovered_clues(obj)


## Populates action buttons for the selected object.
func _populate_action_buttons(obj: InvestigableObjectData) -> void:
	for child: Node in detail_actions.get_children():
		detail_actions.remove_child(child)
		child.queue_free()

	if not _full_investigation:
		var label: Label = Label.new()
		label.text = "Quick visit — view only."
		label.add_theme_color_override("font_color", UIColors.MUTED)
		detail_actions.add_child(label)
		return

	# Visual inspection / Examine button
	var has_visual: bool = "visual_inspection" in obj.available_actions
	var has_examine: bool = "examine_device" in obj.available_actions
	if has_visual or has_examine:
		var inspect_btn: Button = Button.new()
		inspect_btn.text = "🔍 Examine" if has_examine else "👁 Visual Inspection"

		var already_done: bool = false
		var actions: Array = LocationInvestigationManager.get_performed_actions(_location.id, obj.id)
		already_done = "visual_inspection" in actions

		if already_done:
			inspect_btn.text += " (done)"
			inspect_btn.disabled = true
		inspect_btn.pressed.connect(_on_inspect_pressed.bind(obj.id))
		detail_actions.add_child(inspect_btn)



## Handles visual inspection action.
func _on_inspect_pressed(object_id: String) -> void:
	var discovered: Array[String] = LocationInvestigationManager.inspect_object(_location.id, object_id)
	_show_discovery_feedback(discovered)
	_refresh_ui()


## Handles tool use on selected object.
func _on_tool_selected(tool_id: String) -> void:
	if _selected_object_id.is_empty():
		return

	var discovered: Array[String] = LocationInvestigationManager.use_tool_on_object(
		_location.id, _selected_object_id, tool_id
	)
	_show_discovery_feedback(discovered)
	_refresh_ui()


## Shows feedback when evidence is discovered.
func _show_discovery_feedback(evidence_ids: Array[String]) -> void:
	if evidence_ids.is_empty():
		return

	for ev_id: String in evidence_ids:
		var ev: EvidenceData = CaseManager.get_evidence(ev_id)
		if ev:
			NotificationManager.notify_evidence(ev.name)


## Refreshes the entire UI after state changes.
func _refresh_ui() -> void:
	_update_completion()
	_populate_objects()
	_update_tool_buttons()
	if not _selected_object_id.is_empty():
		_show_object_detail(_selected_object_id)


## Updates tool button enabled states.
func _update_tool_buttons() -> void:
	var obj: InvestigableObjectData = _find_object(_selected_object_id) if not _selected_object_id.is_empty() else null

	for child: Node in tool_panel.get_children():
		if child is Button:
			if obj == null or not _full_investigation:
				child.disabled = true
			else:
				# Enable only compatible tools
				var tool_name: String = child.text.substr(2).strip_edges()
				var compatible: bool = false
				for tool_id: String in ToolManager.get_available_tools():
					if ToolManager.get_tool_name(tool_id) == tool_name:
						compatible = tool_id in obj.tool_requirements
						break
				child.disabled = not compatible


## Clears the detail panel.
func _clear_detail() -> void:
	detail_panel.visible = false


## Finds an investigable object by ID.
func _find_object(object_id: String) -> InvestigableObjectData:
	if _location == null:
		return null
	for obj: InvestigableObjectData in _location.investigable_objects:
		if obj.id == object_id:
			return obj
	return null


## Populates the "Clues found in this area" section for the selected object.
func _populate_discovered_clues(obj: InvestigableObjectData) -> void:
	# Remove previous clues section if any
	var existing: Node = detail_panel.get_node_or_null("CluesSection")
	if existing:
		existing.queue_free()

	# Check which evidence from this object has been discovered (or upgraded)
	var found_clues: Array[Dictionary] = []
	for ev_id: String in obj.evidence_results:
		if GameManager.has_evidence(ev_id):
			var ev: EvidenceData = CaseManager.get_evidence(ev_id)
			found_clues.append({"id": ev_id, "name": ev.name if ev else ev_id})
		else:
			# Check if this raw evidence was upgraded to analyzed
			var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(ev_id)
			if lab_req != null and GameManager.has_evidence(lab_req.output_evidence_id):
				var ev: EvidenceData = CaseManager.get_evidence(lab_req.output_evidence_id)
				found_clues.append({"id": lab_req.output_evidence_id, "name": ev.name if ev else lab_req.output_evidence_id})

	# Compute forensic hint
	var hint_text: String = ""
	var hint_color: Color = Color.WHITE
	if not obj.tool_requirements.is_empty():
		var state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
			_location.id, obj.id
		)
		var has_unfulfilled_tools: bool = false
		for tool_req: String in obj.tool_requirements:
			if not ToolManager.is_valid_tool(tool_req):
				has_unfulfilled_tools = true
				break
		if has_unfulfilled_tools and state == Enums.InvestigationState.PARTIALLY_EXAMINED:
			hint_text = "Further forensic analysis required — submit discovered evidence to the lab."
			hint_color = Color(0.9, 0.7, 0.2)
		elif not has_unfulfilled_tools:
			hint_text = "Tools may reveal more evidence."
			hint_color = UIColors.SECONDARY

	if found_clues.is_empty() and hint_text.is_empty():
		return

	var section: VBoxContainer = VBoxContainer.new()
	section.name = "CluesSection"
	section.add_theme_constant_override("separation", 4)

	if not found_clues.is_empty():
		var header: Label = Label.new()
		header.text = "Clues found in this area:"
		header.add_theme_color_override("font_color", UIColors.HEADER)
		header.add_theme_font_size_override("font_size", 16)
		section.add_child(header)

		for clue: Dictionary in found_clues:
			var clue_label: Label = Label.new()
			clue_label.text = "  - %s" % clue["name"]
			clue_label.add_theme_color_override("font_color", UIColors.SECONDARY)
			clue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			section.add_child(clue_label)

	if not hint_text.is_empty():
		var hint_label: Label = Label.new()
		hint_label.text = hint_text
		hint_label.add_theme_color_override("font_color", hint_color)
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		section.add_child(hint_label)

	detail_panel.add_child(section)
	detail_panel.move_child(section, detail_description.get_index() + 1)


## Navigates back to location map.
func _on_back_pressed() -> void:
	LocationInvestigationManager.leave_location()
	ScreenManager.navigate_back()
