## LocationInvestigation.gd
## Screen for investigating a specific location.
## 3-column layout: left (objects), center (scene image), right (detail + tools).
## Receives location_id via ScreenManager.navigation_data.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var completion_label: Label = %CompletionLabel
@onready var object_list: VBoxContainer = %ObjectList
@onready var scene_image: TextureRect = %SceneImage
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

	# Load scene image or show fallback placeholder
	if not _location.image.is_empty() and ResourceLoader.exists(_location.image):
		scene_image.texture = load(_location.image)
		scene_image.visible = true
	else:
		scene_image.visible = false
		_build_scene_placeholder()

	_update_completion()
	_populate_objects()
	_populate_tools()
	_clear_detail()


## Updates the completion indicator.
func _update_completion() -> void:
	var completion: Dictionary = LocationInvestigationManager.get_location_completion(_location.id)
	completion_label.text = "%d/%d clues found" % [completion["found"], completion["total"]]


## Populates the object list with status indicators, names, clue counts, and status badges.
## Uses plain Buttons as direct VBoxContainer children — no child controls inside the
## buttons. Adding child controls to Buttons in Godot 4 breaks click detection over
## the text area. All visual info is encoded in the button text string instead.
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
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_object_selected.bind(obj.id))

		# Build button text: [StateMarker] [Name] [(ClueCount)] [Badge]
		var state_marker: String = _get_state_marker(obj.id)
		var parts: PackedStringArray = PackedStringArray()
		parts.append(state_marker)
		parts.append(obj.name)

		var clue_count: int = _get_discovered_clue_count(obj)
		if clue_count > 0:
			parts.append("(%d)" % clue_count)

		var badge_text: String = _get_object_badge(obj)
		if not badge_text.is_empty():
			parts.append("· %s" % badge_text)

		btn.text = " ".join(parts)

		# Highlight selected object
		if obj.id == _selected_object_id:
			btn.add_theme_color_override("font_color", UIColors.ACCENT_CLUE)

		object_list.add_child(btn)


## Returns the badge text for an object based on its derived display status.
func _get_object_badge(obj: InvestigableObjectData) -> String:
	var display_status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(
		_location.id, obj.id
	)
	match display_status:
		Enums.ObjectDisplayStatus.NOT_INSPECTED:
			if not obj.evidence_results.is_empty():
				return "new"
		Enums.ObjectDisplayStatus.PARTIALLY_EXAMINED:
			return "partial"
		Enums.ObjectDisplayStatus.AWAITING_LAB_RESULTS:
			return "pending"
		Enums.ObjectDisplayStatus.FULLY_PROCESSED:
			return "done"
	return ""


## Returns how many clues have been discovered from an object.
func _get_discovered_clue_count(obj: InvestigableObjectData) -> int:
	var count: int = 0
	for ev_id: String in obj.evidence_results:
		if GameManager.has_evidence(ev_id):
			count += 1
		else:
			var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(ev_id)
			if lab_req != null and GameManager.has_evidence(lab_req.output_evidence_id):
				count += 1
	return count


## Populates the tool panel — shows tools with contextual availability info.
## Compatible tools get action buttons; incompatible ones show explanatory text.
func _populate_tools() -> void:
	for child: Node in tool_panel.get_children():
		if child is Button or child is HBoxContainer or child is Label:
			tool_panel.remove_child(child)
			child.queue_free()

	var tools: Array[String] = ToolManager.get_available_tools()

	if _selected_object_id.is_empty():
		var hint: Label = Label.new()
		hint.text = "Select a target to see available tools."
		hint.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
		hint.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tool_panel.add_child(hint)
		return

	var obj: InvestigableObjectData = _find_object(_selected_object_id)

	for tool_id: String in tools:
		var tool_name: String = ToolManager.get_tool_name(tool_id)
		var is_relevant: bool = false
		var reason: String = ""

		if not _full_investigation:
			reason = "View only"
		elif obj and tool_id in obj.tool_requirements:
			is_relevant = true
			# Check if already used
			var actions: Array = LocationInvestigationManager.get_performed_actions(
				_location.id, _selected_object_id
			)
			if "tool:%s" % tool_id in actions:
				reason = "Already used"
				is_relevant = false
		else:
			reason = ToolManager.get_tool_unavailable_hint(tool_id)

		if is_relevant:
			# Usable tool — show action button
			var btn: Button = Button.new()
			btn.text = "🔧 %s" % tool_name
			btn.pressed.connect(_on_tool_selected.bind(tool_id))
			tool_panel.add_child(btn)
		else:
			# Unavailable tool — show name + reason as text
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)

			var name_label: Label = Label.new()
			name_label.text = "🔧 %s" % tool_name
			name_label.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
			name_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
			row.add_child(name_label)

			var reason_label: Label = Label.new()
			reason_label.text = "— %s" % reason
			reason_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
			reason_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
			reason_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(reason_label)

			tool_panel.add_child(row)


## Gets the state marker symbol for an object using derived display status.
func _get_state_marker(object_id: String) -> String:
	var status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(_location.id, object_id)
	match status:
		Enums.ObjectDisplayStatus.NOT_INSPECTED:
			return "🟡"
		Enums.ObjectDisplayStatus.PARTIALLY_EXAMINED:
			return "🔵"
		Enums.ObjectDisplayStatus.AWAITING_LAB_RESULTS:
			return "🟠"
		Enums.ObjectDisplayStatus.FULLY_PROCESSED:
			return "⚪"
	return "🟡"


## Handles object selection from the list.
func _on_object_selected(object_id: String) -> void:
	_selected_object_id = object_id
	_refresh_ui()


## Shows detail panel for a selected object.
func _show_object_detail(object_id: String) -> void:
	var obj: InvestigableObjectData = _find_object(object_id)
	if obj == null:
		return

	detail_panel.visible = true
	detail_title.text = obj.name
	detail_description.text = obj.description if not obj.description.is_empty() else "No details available."

	var status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(_location.id, object_id)

	match status:
		Enums.ObjectDisplayStatus.NOT_INSPECTED:
			detail_state.text = "Status: Not inspected"
			detail_state.add_theme_color_override("font_color", UIColors.ACCENT_CLUE)
		Enums.ObjectDisplayStatus.PARTIALLY_EXAMINED:
			detail_state.text = "Status: Partially examined"
			detail_state.add_theme_color_override("font_color", UIColors.ACCENT_EXAMINED)
		Enums.ObjectDisplayStatus.AWAITING_LAB_RESULTS:
			detail_state.text = "Status: Awaiting lab results"
			detail_state.add_theme_color_override("font_color", UIColors.STATUS_PENDING)
		Enums.ObjectDisplayStatus.FULLY_PROCESSED:
			detail_state.text = "Status: Fully processed"
			detail_state.add_theme_color_override("font_color", UIColors.TEXT_MUTED)

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
	_populate_tools()
	if not _selected_object_id.is_empty():
		_show_object_detail(_selected_object_id)


## Resets the detail panel to its empty/placeholder state.
## The panel stays visible to avoid Godot layout invalidation issues —
## toggling visibility on a VBoxContainer while sibling containers are
## being rebuilt causes child controls (buttons) to end up with stale
## hit rects, making them unresponsive to clicks until a later refresh.
func _clear_detail() -> void:
	detail_title.text = "Select a target"
	detail_state.text = ""
	detail_description.text = "Choose an investigation target from the list to view details and available actions."

	# Clear action buttons
	for child: Node in detail_actions.get_children():
		detail_actions.remove_child(child)
		child.queue_free()

	# Clear clues section
	var existing: Node = detail_panel.get_node_or_null("CluesSection")
	if existing:
		detail_panel.remove_child(existing)
		existing.queue_free()


## Builds a styled placeholder for the center scene panel when no art exists.
## Shows location initial + name in a clean presentation, future-ready for scene images.
func _build_scene_placeholder() -> void:
	var center_vbox: VBoxContainer = scene_image.get_parent() as VBoxContainer
	if center_vbox == null:
		return

	# Remove any previous placeholder
	var old: Node = center_vbox.get_node_or_null("ScenePlaceholder")
	if old:
		center_vbox.remove_child(old)
		old.queue_free()

	var placeholder: VBoxContainer = VBoxContainer.new()
	placeholder.name = "ScenePlaceholder"
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placeholder.alignment = BoxContainer.ALIGNMENT_CENTER

	# Location initial (large, centered)
	var initial: Label = Label.new()
	initial.text = _location.name.substr(0, 1).to_upper() if not _location.name.is_empty() else "?"
	initial.add_theme_font_size_override("font_size", 64)
	initial.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_child(initial)

	# Location name
	var name_label: Label = Label.new()
	name_label.text = _location.name
	name_label.add_theme_font_size_override("font_size", UIFonts.SIZE_BODY)
	name_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placeholder.add_child(name_label)

	# Placeholder notice
	var notice: Label = Label.new()
	notice.text = "Scene preview unavailable"
	notice.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	notice.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_child(notice)

	center_vbox.add_child(placeholder)


## Finds an investigable object by ID.
func _find_object(object_id: String) -> InvestigableObjectData:
	if _location == null:
		return null
	for obj: InvestigableObjectData in _location.investigable_objects:
		if obj.id == object_id:
			return obj
	return null


## Populates the "Clues found in this area" section and investigation messaging
## for the selected object. Always shows the section with appropriate empty/populated state.
func _populate_discovered_clues(obj: InvestigableObjectData) -> void:
	# Remove previous clues section if any — must remove from tree immediately
	# to avoid stale nodes interfering with layout and child indexing.
	var existing: Node = detail_panel.get_node_or_null("CluesSection")
	if existing:
		detail_panel.remove_child(existing)
		existing.queue_free()

	var section: VBoxContainer = VBoxContainer.new()
	section.name = "CluesSection"
	section.add_theme_constant_override("separation", 4)

	# Investigation state message — always shown
	var display_status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(_location.id, obj.id)
	var hint_text: String = LocationInvestigationManager.get_object_status_hint(_location.id, obj.id)
	var hint_color: Color = UIColors.SECONDARY
	match display_status:
		Enums.ObjectDisplayStatus.NOT_INSPECTED:
			hint_color = UIColors.TEXT_MUTED
		Enums.ObjectDisplayStatus.PARTIALLY_EXAMINED:
			hint_color = UIColors.ACCENT_CLUE
		Enums.ObjectDisplayStatus.AWAITING_LAB_RESULTS:
			hint_color = UIColors.STATUS_PROCESSING
		Enums.ObjectDisplayStatus.FULLY_PROCESSED:
			hint_color = UIColors.ACCENT_PROCESSED

	# Also show tool hint if tools are applicable and not yet done
	if not obj.tool_requirements.is_empty():
		var base_state: Enums.InvestigationState = LocationInvestigationManager.get_object_state(
			_location.id, obj.id
		)
		if base_state == Enums.InvestigationState.PARTIALLY_EXAMINED:
			if hint_text.is_empty() or not hint_text.contains("lab"):
				hint_text = "Forensic tools may reveal additional evidence."
				hint_color = UIColors.SECONDARY

	if not hint_text.is_empty():
		var hint_label: Label = Label.new()
		hint_label.text = hint_text
		hint_label.add_theme_color_override("font_color", hint_color)
		hint_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		section.add_child(hint_label)

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

	# Clues found header
	var header: Label = Label.new()
	header.text = "CLUES FOUND HERE"
	header.theme_type_variation = &"MetadataLabel"
	header.add_theme_color_override("font_color", UIColors.HEADER)
	header.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	section.add_child(header)

	if found_clues.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No evidence recovered from this target yet."
		empty_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
		empty_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		section.add_child(empty_label)
	else:
		for clue: Dictionary in found_clues:
			var clue_label: Label = Label.new()
			clue_label.text = "  - %s" % clue["name"]
			clue_label.add_theme_color_override("font_color", UIColors.SECONDARY)
			clue_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
			clue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			section.add_child(clue_label)

	detail_panel.add_child(section)
	detail_panel.move_child(section, detail_description.get_index() + 1)


## Navigates back to location map.
func _on_back_pressed() -> void:
	LocationInvestigationManager.leave_location()
	ScreenManager.navigate_back()
