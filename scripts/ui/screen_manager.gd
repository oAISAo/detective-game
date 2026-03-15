## ScreenManager.gd
## Manages screen navigation, transitions, and history for the investigation desk.
## Phase 4A: Provides centralized screen loading, back navigation, and modal management.
## Screens are loaded into the GameRoot's screen_container; modals into modal_layer.
extends Node


# --- Signals --- #

## Emitted when a screen transition begins.
signal screen_changing(from_screen: String, to_screen: String)

## Emitted when a screen has been loaded and added to the tree.
signal screen_changed(screen_id: String)

## Emitted when a modal is opened.
signal modal_opened(modal_id: String)

## Emitted when a modal is closed.
signal modal_closed(modal_id: String)


# --- Constants --- #

## Registry of known screen scene paths, keyed by screen ID.
const SCREEN_SCENES: Dictionary = {
	"desk_hub": "res://scenes/ui/desk_hub.tscn",
	"evidence_archive": "res://scenes/ui/evidence_archive.tscn",
	"detective_board": "res://scenes/ui/detective_board.tscn",
	"timeline_board": "res://scenes/ui/timeline_board.tscn",
	"location_map": "res://scenes/ui/location_map.tscn",
	"investigation_log": "res://scenes/ui/investigation_log.tscn",
	"evidence_detail": "res://scenes/ui/evidence_detail.tscn",
	"location_investigation": "res://scenes/ui/location_investigation.tscn",
	"interrogation": "res://scenes/ui/interrogation.tscn",
	"theory_builder": "res://scenes/ui/theory_builder.tscn",
	"lab_queue": "res://scenes/ui/lab_queue.tscn",
	"surveillance_panel": "res://scenes/ui/surveillance_panel.tscn",
	"warrant_office": "res://scenes/ui/warrant_office.tscn",
}

## Registry of known modal scene paths, keyed by modal ID.
const MODAL_SCENES: Dictionary = {
	"morning_briefing": "res://scenes/ui/morning_briefing.tscn",
	"notification_panel": "res://scenes/ui/notification_panel.tscn",
}


# --- State --- #

## The currently active screen ID (empty string if none).
var current_screen: String = ""

## Navigation history stack for back navigation.
var _nav_history: Array[String] = []

## Cache of loaded screen PackedScenes for faster transitions.
var _scene_cache: Dictionary = {}

## Currently active modal node references: { modal_id: Node }
var _active_modals: Dictionary = {}

## Whether a screen transition is in progress (prevents double-nav).
var _transitioning: bool = false

## Data passed to the next screen during navigation.
var navigation_data: Dictionary = {}


# --- Lifecycle --- #

func _ready() -> void:
	print("[ScreenManager] Initialized.")


# --- Screen Navigation --- #

## Navigates to a screen by its registered ID.
## Pushes the current screen onto the history stack for back navigation.
## Returns true if navigation succeeded.
func navigate_to(screen_id: String, data: Dictionary = {}) -> bool:
	if _transitioning:
		push_warning("[ScreenManager] Navigation blocked — transition in progress.")
		return false

	if screen_id == current_screen:
		return false

	if screen_id not in SCREEN_SCENES:
		push_error("[ScreenManager] Unknown screen: %s" % screen_id)
		return false

	var game_root: Node = _get_game_root()
	if game_root == null:
		push_error("[ScreenManager] GameRoot not found.")
		return false

	_transitioning = true
	var old_screen: String = current_screen

	# Push current to history (if not empty)
	if not current_screen.is_empty():
		_nav_history.append(current_screen)

	navigation_data = data
	screen_changing.emit(old_screen, screen_id)

	# Clear existing screen
	var container: Node = game_root.get_node("ScreenContainer")
	for child: Node in container.get_children():
		child.queue_free()

	# Load and instantiate the new screen
	var scene: PackedScene = _load_scene(screen_id)
	if scene == null:
		_transitioning = false
		push_error("[ScreenManager] Failed to load scene for: %s" % screen_id)
		return false

	var instance: Node = scene.instantiate()
	container.add_child(instance)
	current_screen = screen_id

	_transitioning = false
	screen_changed.emit(screen_id)
	print("[ScreenManager] Navigated to: %s" % screen_id)
	return true


## Navigates back to the previous screen in history.
## Returns true if back navigation succeeded.
func navigate_back() -> bool:
	if _nav_history.is_empty():
		return false

	var prev_screen: String = _nav_history.pop_back()

	# Navigate without pushing to history again
	if _transitioning:
		return false

	if prev_screen not in SCREEN_SCENES:
		return false

	var game_root: Node = _get_game_root()
	if game_root == null:
		return false

	_transitioning = true
	var old_screen: String = current_screen

	navigation_data = {}
	screen_changing.emit(old_screen, prev_screen)

	var container: Node = game_root.get_node("ScreenContainer")
	for child: Node in container.get_children():
		child.queue_free()

	var scene: PackedScene = _load_scene(prev_screen)
	if scene == null:
		_transitioning = false
		return false

	var instance: Node = scene.instantiate()
	container.add_child(instance)
	current_screen = prev_screen

	_transitioning = false
	screen_changed.emit(prev_screen)
	print("[ScreenManager] Navigated back to: %s" % prev_screen)
	return true


## Returns the full navigation history.
func get_nav_history() -> Array[String]:
	return _nav_history.duplicate()


## Returns true if back navigation is possible.
func can_go_back() -> bool:
	return not _nav_history.is_empty()


## Clears navigation history.
func clear_history() -> void:
	_nav_history.clear()


# --- Modal Management --- #

## Opens a modal by its registered ID.
## Returns the instantiated modal node, or null on failure.
func open_modal(modal_id: String) -> Node:
	if modal_id in _active_modals:
		push_warning("[ScreenManager] Modal already open: %s" % modal_id)
		return _active_modals[modal_id]

	var scene_path: String = MODAL_SCENES.get(modal_id, "")
	if scene_path.is_empty():
		push_error("[ScreenManager] Unknown modal: %s" % modal_id)
		return null

	var game_root: Node = _get_game_root()
	if game_root == null:
		return null

	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("[ScreenManager] Failed to load modal scene: %s" % scene_path)
		return null

	var instance: Node = scene.instantiate()
	var modal_layer: Node = game_root.get_node("ModalLayer")
	modal_layer.add_child(instance)
	_active_modals[modal_id] = instance

	# Connect tree_exiting to auto-clean on queue_free
	instance.tree_exiting.connect(_on_modal_exiting.bind(modal_id))

	modal_opened.emit(modal_id)
	print("[ScreenManager] Modal opened: %s" % modal_id)
	return instance


## Closes a specific modal by its ID.
func close_modal(modal_id: String) -> void:
	if modal_id not in _active_modals:
		return

	var modal_node: Node = _active_modals[modal_id]
	_active_modals.erase(modal_id)
	if is_instance_valid(modal_node):
		modal_node.queue_free()
	modal_closed.emit(modal_id)
	print("[ScreenManager] Modal closed: %s" % modal_id)


## Closes all open modals.
func close_all_modals() -> void:
	for modal_id: String in _active_modals.keys():
		close_modal(modal_id)


## Returns whether a modal is currently open.
func is_modal_open(modal_id: String) -> bool:
	return modal_id in _active_modals


## Returns the list of currently open modal IDs.
func get_open_modals() -> Array[String]:
	var result: Array[String] = []
	for key: String in _active_modals:
		result.append(key)
	return result


# --- Internal --- #

## Gets the GameRoot node from the scene tree.
func _get_game_root() -> Node:
	var root: Window = get_tree().root if get_tree() else null
	if root == null:
		return null
	return root.get_node_or_null("GameRoot")


## Loads a scene, using cache if available.
func _load_scene(screen_id: String) -> PackedScene:
	if screen_id in _scene_cache:
		return _scene_cache[screen_id]

	var path: String = SCREEN_SCENES.get(screen_id, "")
	if path.is_empty():
		return null

	var scene: PackedScene = load(path) as PackedScene
	if scene:
		_scene_cache[screen_id] = scene
	return scene


## Called when a modal node exits the tree (cleanup reference).
func _on_modal_exiting(modal_id: String) -> void:
	_active_modals.erase(modal_id)


# --- Reset --- #

## Resets navigation state for a new game.
func reset() -> void:
	current_screen = ""
	_nav_history.clear()
	_scene_cache.clear()
	_active_modals.clear()
	_transitioning = false
	navigation_data = {}
