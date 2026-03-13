## LocationMap.gd
## Map of investigation locations — allows the player to select where to go.
## Phase 4A: Shell screen — full map interaction in later phases.
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

	for loc: Resource in locations:
		var btn: Button = Button.new()
		btn.text = loc.name if loc.get("name") else "Unknown Location"
		location_list.add_child(btn)


## Navigates back to the previous screen.
func _on_back_pressed() -> void:
	ScreenManager.navigate_back()
