## LocationInvestigation.gd
## Screen for investigating a specific location.
## 3-column layout: left (objects), center (scene image), right (detail).
## Receives location_id via ScreenManager.navigation_data.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var completion_label: Label = %CompletionLabel
@onready var object_list: VBoxContainer = %ObjectList
@onready var scene_image: TextureRect = %SceneImage
@onready var detail_panel: VBoxContainer = %DetailPanel
@onready var _placeholder_state: VBoxContainer = %PlaceholderState
@onready var _target_state: VBoxContainer = %TargetState
@onready var detail_title: Label = %DetailTitle
@onready var detail_description: Label = %DetailDescription
@onready var detail_state: Label = %DetailState
@onready var detail_actions: VBoxContainer = %DetailActions
@onready var action_list: VBoxContainer = %ActionList
@onready var back_button: Button = %BackButton
@onready var _left_panel: PanelContainer = $MarginContainer/VBoxContainer/MainColumns/LeftPanel
@onready var _center_panel: PanelContainer = $MarginContainer/VBoxContainer/MainColumns/CenterPanel
@onready var _right_panel: PanelContainer = $MarginContainer/VBoxContainer/MainColumns/RightPanel

## The location being investigated.
var _location: LocationData = null

## The currently selected object ID.
var _selected_object_id: String = ""

## Stored callable for signal cleanup.
var _back_pressed_cb: Callable

const ACTION_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/components/action_button.tscn")
const CLUES_SECTION_SCENE: PackedScene = preload("res://scenes/ui/components/clues_section.tscn")
const INSPECT_ACTION_COST: int = 1
const _PANEL_BORDER_WIDTH: int = 2
const _PANEL_BORDER_COLOR: Color = Color(0.7, 0.68, 0.65, 0.45)
const _PANEL_CORNER_RADIUS: int = 14
const _OBJECT_LIST_TOP_PADDING: int = 6
const _DETAIL_SECTION_SPACING: int = 18
const _HANDWRITING_FONT_PATH: String = "res://assets/fonts/Caveat-Regular.ttf"
var _handwriting_font: Font = null


func _ready() -> void:
	_back_pressed_cb = _on_back_pressed
	UIHelper.apply_back_button_icon(back_button, "Back")
	back_button.pressed.connect(_back_pressed_cb)
	_apply_panel_styles()
	_apply_scene_image_clip()
	_handwriting_font = _load_handwriting_font()

	var nav_data: Dictionary = ScreenManager.navigation_data
	var location_id: String = nav_data.get("location_id", "")

	if location_id.is_empty():
		push_error("[LocationInvestigation] No location_id in navigation data.")
		_show_error_state()
		return

	_location = CaseManager.get_location(location_id)
	if _location == null:
		push_error("[LocationInvestigation] Location not found: %s" % location_id)
		_show_error_state()
		return

	_setup_ui()


func _exit_tree() -> void:
	UIHelper.safe_disconnect(back_button.pressed, _back_pressed_cb)


func _show_error_state() -> void:
	title_label.text = "Location Not Found"
	completion_label.text = ""
	object_list.visible = false
	_placeholder_state.visible = false
	_target_state.visible = false


## Builds the initial UI layout.
func _setup_ui() -> void:
	title_label.text = _location.name

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
	UIHelper.clear_children(object_list)

	if _location.investigable_objects.is_empty():
		var empty: Label = Label.new()
		empty.text = "Nothing to investigate here."
		empty.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		object_list.add_child(empty)
		return

	# Top spacer so first item's selection shadow is visible
	var spacer: Control = Control.new()
	spacer.custom_minimum_size.y = _OBJECT_LIST_TOP_PADDING
	object_list.add_child(spacer)

	for obj: InvestigableObjectData in _location.investigable_objects:
		var btn: Button = Button.new()
		UIHelper.apply_list_button_style(btn, obj.id == _selected_object_id, HORIZONTAL_ALIGNMENT_LEFT)
		btn.pressed.connect(_on_object_selected.bind(obj.id))
		btn.text = "• %s" % [obj.name]

		object_list.add_child(btn)


## Handles object selection from the list.
func _on_object_selected(object_id: String) -> void:
	_selected_object_id = object_id
	_refresh_ui()


## Shows detail panel for a selected object.
func _show_object_detail(object_id: String) -> void:
	var obj: InvestigableObjectData = LocationInvestigationManager.get_object(_location.id, object_id)
	if obj == null:
		return

	_placeholder_state.visible = false
	_target_state.visible = true
	detail_title.text = obj.name
	detail_description.text = obj.description if not obj.description.is_empty() else "No details available."

	var status: Enums.ObjectDisplayStatus = LocationInvestigationManager.get_object_display_status(_location.id, object_id)

	match status:
		Enums.ObjectDisplayStatus.NOT_INSPECTED:
			detail_state.text = "Status: Not inspected"
			detail_state.add_theme_color_override("font_color", UIColors.AMBER)
		Enums.ObjectDisplayStatus.PARTIALLY_EXAMINED:
			detail_state.text = "Status: Partially examined"
			detail_state.add_theme_color_override("font_color", UIColors.BLUE)
		Enums.ObjectDisplayStatus.AWAITING_LAB_RESULTS:
			detail_state.text = "Status: Awaiting lab results"
			detail_state.add_theme_color_override("font_color", UIColors.AMBER)
		Enums.ObjectDisplayStatus.FULLY_PROCESSED:
			detail_state.text = "Status: Fully processed"
			detail_state.add_theme_color_override("font_color", UIColors.TEXT_GREY)

	_populate_action_buttons(obj)
	_populate_discovered_clues(obj)


## Populates action buttons for the selected object.
func _populate_action_buttons(obj: InvestigableObjectData) -> void:
	UIHelper.clear_children(action_list)

	# Visual inspection / Examine button
	var has_visual: bool = LocationInvestigationManager.ACTION_VISUAL_INSPECTION in obj.available_actions
	var has_examine: bool = LocationInvestigationManager.ACTION_EXAMINE_DEVICE in obj.available_actions
	if has_visual or has_examine:
		var inspect_btn: Control = ACTION_BUTTON_SCENE.instantiate() as Control
		if inspect_btn == null:
			push_error("[LocationInvestigation] Failed to instantiate ActionButton scene")
			return

		var inspect_text: String = "Examine" if has_examine else "Visual Inspection"
		inspect_btn.set("action_text", inspect_text)
		inspect_btn.set("action_cost", INSPECT_ACTION_COST)

		var already_done: bool = false
		var actions: Array = LocationInvestigationManager.get_performed_actions(_location.id, obj.id)
		already_done = LocationInvestigationManager.ACTION_VISUAL_INSPECTION in actions

		if already_done:
			inspect_btn.set("action_text", "%s (done)" % inspect_text)
			inspect_btn.set("disabled", true)
		elif not GameManager.has_actions_remaining():
			inspect_btn.set("disabled", true)
			inspect_btn.tooltip_text = "No actions remaining today. End the day to continue."
		inspect_btn.connect("pressed", Callable(self, "_on_inspect_pressed").bind(obj.id))
		action_list.add_child(inspect_btn)


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


## Resets the detail panel to its placeholder state.
func _clear_detail() -> void:
	_placeholder_state.visible = true
	_target_state.visible = false

	UIHelper.clear_children(action_list)
	_remove_clues_section()


## Removes any dynamically added CluesSection from the target state.
func _remove_clues_section() -> void:
	var old_section: Node = _target_state.get_node_or_null("CluesSection")
	if old_section:
		_target_state.remove_child(old_section)
		old_section.queue_free()
	var old_spacer: Node = _target_state.get_node_or_null("CluesSpacer")
	if old_spacer:
		_target_state.remove_child(old_spacer)
		old_spacer.queue_free()


## Builds a styled placeholder for the center scene panel when no art exists.
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
	initial.add_theme_font_size_override("font_size", UIFonts.SIZE_PLACEHOLDER_INITIAL)
	initial.add_theme_color_override("font_color", UIColors.TEXT_GREY)
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


## Populates the "Clues found in this area" section below the action buttons.
func _populate_discovered_clues(obj: InvestigableObjectData) -> void:
	_remove_clues_section()

	# Collect discovered evidence for this object
	var found_clues: Array[EvidenceData] = []
	for ev_id: String in obj.evidence_results:
		if LocationInvestigationManager.is_evidence_discovered(ev_id):
			# Resolve the actual evidence (raw or upgraded via lab)
			var ev: EvidenceData = CaseManager.get_evidence(ev_id)
			if ev == null:
				var lab_req: LabRequestData = CaseManager.get_lab_request_for_evidence(ev_id)
				if lab_req != null:
					ev = CaseManager.get_evidence(lab_req.output_evidence_id)
			if ev:
				found_clues.append(ev)

	# Add spacing before clues section
	var spacer: Control = Control.new()
	spacer.name = "CluesSpacer"
	spacer.custom_minimum_size.y = _DETAIL_SECTION_SPACING
	_target_state.add_child(spacer)

	# Instantiate and populate clues section
	var section: CluesSection = CLUES_SECTION_SCENE.instantiate() as CluesSection
	_target_state.add_child(section)
	section.populate(found_clues, _handwriting_font)


## Loads the handwriting font used for polaroid clue labels.
func _load_handwriting_font() -> Font:
	if ResourceLoader.exists(_HANDWRITING_FONT_PATH):
		return load(_HANDWRITING_FONT_PATH) as Font
	push_warning("[LocationInvestigation] Handwriting font not found: %s" % _HANDWRITING_FONT_PATH)
	return null


## Navigates back to location map.
func _on_back_pressed() -> void:
	LocationInvestigationManager.leave_location()
	ScreenManager.navigate_back()


## Applies border and padding overrides to the three main panels.
func _apply_panel_styles() -> void:
	for panel: PanelContainer in [_left_panel, _center_panel, _right_panel]:
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate(true) as StyleBoxFlat
		style.border_width_left = _PANEL_BORDER_WIDTH
		style.border_width_top = _PANEL_BORDER_WIDTH
		style.border_width_right = _PANEL_BORDER_WIDTH
		style.border_width_bottom = _PANEL_BORDER_WIDTH
		style.border_color = _PANEL_BORDER_COLOR
		if panel == _center_panel:
			style.content_margin_left = float(_PANEL_BORDER_WIDTH)
			style.content_margin_top = float(_PANEL_BORDER_WIDTH)
			style.content_margin_right = float(_PANEL_BORDER_WIDTH)
			style.content_margin_bottom = float(_PANEL_BORDER_WIDTH)
		panel.add_theme_stylebox_override("panel", style)


## Clips the center panel's image to the inner rounded shape.
func _apply_scene_image_clip() -> void:
	var center_vbox: VBoxContainer = _center_panel.get_node("CenterVBox") as VBoxContainer

	var inner_radius: int = _PANEL_CORNER_RADIUS - _PANEL_BORDER_WIDTH
	var clip_style := StyleBoxFlat.new()
	clip_style.bg_color = UIColors.BG_SURFACE
	clip_style.corner_radius_top_left = inner_radius
	clip_style.corner_radius_top_right = inner_radius
	clip_style.corner_radius_bottom_left = inner_radius
	clip_style.corner_radius_bottom_right = inner_radius

	var clip_panel := PanelContainer.new()
	clip_panel.name = "CenterClip"
	clip_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_panel.add_theme_stylebox_override("panel", clip_style)
	clip_panel.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW

	_center_panel.remove_child(center_vbox)
	clip_panel.add_child(center_vbox)
	_center_panel.add_child(clip_panel)
