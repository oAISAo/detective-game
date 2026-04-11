## LocationInvestigation.gd
## Screen for investigating a specific location.
## 3-column layout: left (objects), center (scene image), right (detail).
## Receives location_id via ScreenManager.navigation_data.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var completion_label: Label = %CompletionLabel
@onready var object_list: VBoxContainer = %ObjectList
@onready var scene_image: TextureRect = %SceneImage
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

const ACTION_BUTTON_COST_SUFFIX: String = " · 1 Action"


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	var nav_data: Dictionary = ScreenManager.navigation_data
	var location_id: String = nav_data.get("location_id", "")

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
	_clear_detail()


## Updates the completion indicator.
func _update_completion() -> void:
	var completion: Dictionary = LocationInvestigationManager.get_location_completion(_location.id)
	completion_label.text = "Evidence: %d / %d" % [completion["found"], completion["total"]]


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

		# Build button text: [StateMarker] [Name]
		var state_marker: String = _get_state_marker(obj.id)
		btn.text = "%s %s" % [state_marker, obj.name]

		# Highlight selected object
		if obj.id == _selected_object_id:
			btn.add_theme_color_override("font_color", UIColors.ACCENT_CLUE)

		object_list.add_child(btn)

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

	# Visual inspection / Examine button
	var has_visual: bool = "visual_inspection" in obj.available_actions
	var has_examine: bool = "examine_device" in obj.available_actions
	if has_visual or has_examine:
		var inspect_btn: Button = Button.new()
		var base_text: String = "🔍 Examine" if has_examine else "👁 Visual Inspection"
		inspect_btn.text = "%s%s" % [base_text, ACTION_BUTTON_COST_SUFFIX]

		var already_done: bool = false
		var actions: Array = LocationInvestigationManager.get_performed_actions(_location.id, obj.id)
		already_done = "visual_inspection" in actions

		if already_done:
			inspect_btn.text += " (done)"
			inspect_btn.disabled = true
		elif not GameManager.has_actions_remaining():
			inspect_btn.disabled = true
			inspect_btn.tooltip_text = "No actions remaining today. End the day to continue."
		inspect_btn.pressed.connect(_on_inspect_pressed.bind(obj.id))
		detail_actions.add_child(inspect_btn)


## Handles visual inspection action.
func _on_inspect_pressed(object_id: String) -> void:
	var actions_before: int = GameManager.actions_remaining
	var discovered: Array[String] = LocationInvestigationManager.inspect_object(_location.id, object_id)
	if discovered.is_empty() and actions_before == GameManager.actions_remaining and not GameManager.has_actions_remaining():
		NotificationManager.notify("No Actions", LocationInvestigationManager.INVESTIGATION_ERROR_MESSAGE_NO_ACTIONS)
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
