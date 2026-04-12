## LocationMap.gd
## Map of investigation locations — uses LocationCard components
## with cinematic photo-card tiles in a flow grid layout.
extends Control


const LocationCardScene: PackedScene = preload("res://scenes/ui/components/location_card.tscn")

@onready var location_grid: HFlowContainer = %LocationGrid

var _refresh_queued: bool = false


func _ready() -> void:
	_connect_refresh_signals()
	_populate_locations()


func _exit_tree() -> void:
	_disconnect_refresh_signals()


## Populates location cards from CaseManager data.
func _populate_locations() -> void:
	for child: Node in location_grid.get_children():
		location_grid.remove_child(child)
		child.queue_free()

	var locations: Array[LocationData] = CaseManager.get_all_locations()
	if locations.is_empty():
		_add_empty_state_message("No locations available.")
		return

	# Filter to only show unlocked locations
	var unlocked: Array[LocationData] = []
	for loc: LocationData in locations:
		if GameManager.is_location_unlocked(loc.id):
			unlocked.append(loc)

	if unlocked.is_empty():
		_add_empty_state_message("No locations available yet.")
		return

	for loc: LocationData in unlocked:
		var card: LocationCard = LocationCardScene.instantiate()
		location_grid.add_child(card)
		card.setup(loc)
		card.card_pressed.connect(_on_location_pressed)


## Adds a consistent empty-state message to the map grid.
func _add_empty_state_message(message: String) -> void:
	var empty_label: Label = Label.new()
	empty_label.text = message
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
	empty_label.add_theme_font_size_override("font_size", UIFonts.SIZE_BODY)
	location_grid.add_child(empty_label)


## Handles a location card press.
func _on_location_pressed(location_id: String) -> void:
	_navigate_to_location(location_id)


## Navigates to the location investigation screen.
func _navigate_to_location(location_id: String) -> void:
	var result: Dictionary = LocationInvestigationManager.start_map_investigation(location_id)
	if not result.get("success", false):
		_show_start_failure_message(result)
		return

	ScreenManager.navigate_to("location_investigation", {
		"location_id": location_id,
	})


## Displays a player-facing reason when investigation start fails.
func _show_start_failure_message(result: Dictionary) -> void:
	var error_message: String = str(result.get("error_message", "Unable to visit this location right now."))
	NotificationManager.notify("Cannot Visit Location", error_message)


## Subscribes to state-change signals so map cards stay fresh while the screen is open.
func _connect_refresh_signals() -> void:
	_bind_refresh_signal(GameManager.location_unlocked)
	_bind_refresh_signal(GameManager.location_visited)
	_bind_refresh_signal(GameManager.evidence_discovered)
	_bind_refresh_signal(GameManager.evidence_upgraded)
	_bind_refresh_signal(GameManager.game_reset)
	_bind_refresh_signal(LocationInvestigationManager.object_state_changed)
	_bind_refresh_signal(LocationInvestigationManager.location_completed)
	_bind_refresh_signal(LocationInvestigationManager.state_loaded)
	_bind_refresh_signal(LabManager.lab_submitted)
	_bind_refresh_signal(LabManager.lab_completed)


## Unsubscribes from state-change signals when this screen leaves the tree.
func _disconnect_refresh_signals() -> void:
	_unbind_refresh_signal(GameManager.location_unlocked)
	_unbind_refresh_signal(GameManager.location_visited)
	_unbind_refresh_signal(GameManager.evidence_discovered)
	_unbind_refresh_signal(GameManager.evidence_upgraded)
	_unbind_refresh_signal(GameManager.game_reset)
	_unbind_refresh_signal(LocationInvestigationManager.object_state_changed)
	_unbind_refresh_signal(LocationInvestigationManager.location_completed)
	_unbind_refresh_signal(LocationInvestigationManager.state_loaded)
	_unbind_refresh_signal(LabManager.lab_submitted)
	_unbind_refresh_signal(LabManager.lab_completed)


## Connects one signal to runtime map refresh if not already connected.
func _bind_refresh_signal(signal_ref: Signal) -> void:
	if not signal_ref.is_connected(_on_runtime_state_changed):
		signal_ref.connect(_on_runtime_state_changed)


## Disconnects one signal from runtime map refresh if connected.
func _unbind_refresh_signal(signal_ref: Signal) -> void:
	UIHelper.safe_disconnect(signal_ref, _on_runtime_state_changed)


## Schedules a deferred refresh so multiple same-frame state changes coalesce.
func _on_runtime_state_changed(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_refresh_map")


## Refreshes map cards after deferred scheduling.
func _refresh_map() -> void:
	_refresh_queued = false
	if not is_inside_tree():
		return
	_populate_locations()
