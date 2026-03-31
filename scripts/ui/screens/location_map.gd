## LocationMap.gd
## Map of investigation locations — allows the player to select where to go.
## Phase 6: Full location interaction with visit/completion indicators.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var location_list: VBoxContainer = %LocationList
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_locations()


## Populates location list from CaseManager data.
func _populate_locations() -> void:
	for child: Node in location_list.get_children():
		child.queue_free()

	var locations: Array[LocationData] = CaseManager.get_all_locations()
	if locations.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No locations available."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		location_list.add_child(empty_label)
		return

	# Filter to only show unlocked locations
	var unlocked: Array[LocationData] = []
	for loc: LocationData in locations:
		if GameManager.is_location_unlocked(loc.id):
			unlocked.append(loc)

	if unlocked.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No locations available yet."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		location_list.add_child(empty_label)
		return

	var loc_inv_mgr: Node = get_node_or_null("/root/LocationInvestigationManager")

	for loc: Resource in unlocked:
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var btn: Button = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var loc_name: String = loc.get("name") if loc.get("name") else "Unknown Location"
		var visited: bool = GameManager.has_visited_location(loc.get("id"))

		# Build label with visit status
		if visited:
			btn.text = "✓ %s" % loc_name
		else:
			btn.text = "  %s" % loc_name

		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_location_pressed.bind(loc.get("id")))
		hbox.add_child(btn)

		# Completion indicator
		if loc_inv_mgr and visited:
			var completion: Dictionary = loc_inv_mgr.get_location_completion(loc.get("id"))
			var comp_label: Label = Label.new()
			comp_label.text = "(%d/%d clues)" % [completion["found"], completion["total"]]
			comp_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.4))
			comp_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hbox.add_child(comp_label)

		location_list.add_child(hbox)


## Handles a location button press.
func _on_location_pressed(location_id: String) -> void:
	var is_first_visit: bool = not GameManager.has_visited_location(location_id)

	if is_first_visit:
		# First visit — costs an action, go straight in
		if not GameManager.has_actions_remaining():
			NotificationManager.notify(
				"No Actions",
				"You have no actions remaining today. Use 'End Day' to proceed."
			)
			return
		_navigate_to_location(location_id, true)
	else:
		# Return visit (full investigation) — also costs an action
		if not GameManager.has_actions_remaining():
			NotificationManager.notify(
				"No Actions",
				"You have no actions remaining today. Use 'End Day' to proceed."
			)
			return
		_navigate_to_location(location_id, true)


## Navigates to the location investigation screen.
func _navigate_to_location(location_id: String, full_investigation: bool) -> void:
	var loc_inv_mgr: Node = get_node_or_null("/root/LocationInvestigationManager")
	if loc_inv_mgr:
		var success: bool = loc_inv_mgr.start_investigation(location_id, full_investigation)
		if not success:
			return

	ScreenManager.navigate_to("location_investigation", {
		"location_id": location_id,
		"full_investigation": full_investigation,
	})


## Navigates back to the previous screen.
func _on_back_pressed() -> void:
	ScreenManager.navigate_back()
