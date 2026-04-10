## LocationMap.gd
## Map of investigation locations — uses LocationCard components
## with cinematic photo-card tiles in a flow grid layout.
extends Control


const LocationCardScene: PackedScene = preload("res://scenes/ui/components/location_card.tscn")

@onready var location_grid: HFlowContainer = %LocationGrid


func _ready() -> void:
	_populate_locations()


## Populates location cards from CaseManager data.
func _populate_locations() -> void:
	for child: Node in location_grid.get_children():
		location_grid.remove_child(child)
		child.queue_free()

	var locations: Array[LocationData] = CaseManager.get_all_locations()
	if locations.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No locations available."
		empty_label.add_theme_color_override("font_color", UIColors.MUTED)
		location_grid.add_child(empty_label)
		return

	# Filter to only show unlocked locations
	var unlocked: Array[LocationData] = []
	for loc: LocationData in locations:
		if GameManager.is_location_unlocked(loc.id):
			unlocked.append(loc)

	if unlocked.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No locations available yet."
		empty_label.add_theme_color_override("font_color", UIColors.MUTED)
		location_grid.add_child(empty_label)
		return

	for loc: LocationData in unlocked:
		var card: LocationCard = LocationCardScene.instantiate()
		location_grid.add_child(card)
		card.setup(loc)
		card.card_pressed.connect(_on_location_pressed)


## Handles a location card press.
func _on_location_pressed(location_id: String) -> void:
	if not GameManager.has_actions_remaining():
		NotificationManager.notify(
			"No Actions",
			"You have no actions remaining today. Use 'End Day' to proceed."
		)
		return

	_navigate_to_location(location_id, true)


## Navigates to the location investigation screen.
func _navigate_to_location(location_id: String, full_investigation: bool) -> void:
	var success: bool = LocationInvestigationManager.start_investigation(location_id, full_investigation)
	if not success:
		return

	ScreenManager.navigate_to("location_investigation", {
		"location_id": location_id,
		"full_investigation": full_investigation,
	})
