## DetectiveBoard.gd
## Interactive cork-board for pinning evidence, persons, and events.
## Phase 8: Pannable canvas with draggable nodes and connection drawing.
extends Control


# --- Node References --- #

@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var board_viewport: Control = %BoardViewport
@onready var board_canvas: Control = %BoardCanvas
@onready var connection_layer: Control = %ConnectionLayer
@onready var node_layer: Control = %NodeLayer
@onready var clear_button: Button = %ClearButton
@onready var node_count_label: Label = %NodeCountLabel


# --- Constants --- #

## Size of board node cards.
const NODE_WIDTH: float = 160.0
const NODE_HEIGHT: float = 80.0

## Colors for different node types.
const TYPE_COLORS: Dictionary = {
	"person": Color(0.75, 0.38, 0.38),
	"evidence": Color(0.38, 0.58, 0.75),
	"event": Color(0.55, 0.75, 0.38),
}

## Connection line color.
const CONNECTION_COLOR: Color = Color(0.85, 0.82, 0.75, 0.8)

## Connection line width.
const CONNECTION_WIDTH: float = 2.0


# --- State --- #

## Whether the board is currently being panned.
var _panning: bool = false

## Last mouse position during pan.
var _pan_start: Vector2 = Vector2.ZERO

## Currently dragged node element (null if not dragging).
var _dragged_node: Control = null

## Drag offset within the node.
var _drag_offset: Vector2 = Vector2.ZERO

## Connection drawing state: source node_id when drawing a connection.
var _connection_source_id: String = ""

## Map of node_id → Control for quick lookup.
var _node_controls: Dictionary = {}


# --- Lifecycle --- #

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	clear_button.pressed.connect(_on_clear_pressed)

	# Wire connection drawer to node layer for position lookups
	connection_layer.node_layer = node_layer

	BoardManager.node_added.connect(_on_node_added)
	BoardManager.node_removed.connect(_on_node_removed)
	BoardManager.connection_added.connect(_on_connection_added)
	BoardManager.connection_removed.connect(_on_connection_removed)
	BoardManager.board_cleared.connect(_on_board_cleared)
	BoardManager.state_loaded.connect(_rebuild_board)

	_rebuild_board()


func _exit_tree() -> void:
	UIHelper.safe_disconnect(BoardManager.node_added, _on_node_added)
	UIHelper.safe_disconnect(BoardManager.node_removed, _on_node_removed)
	UIHelper.safe_disconnect(BoardManager.connection_added, _on_connection_added)
	UIHelper.safe_disconnect(BoardManager.connection_removed, _on_connection_removed)
	UIHelper.safe_disconnect(BoardManager.board_cleared, _on_board_cleared)
	UIHelper.safe_disconnect(BoardManager.state_loaded, _rebuild_board)


# --- Input Handling --- #

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _panning:
		_handle_pan_motion(event as InputEventMouseMotion)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_MIDDLE or \
		(event.button_index == MOUSE_BUTTON_LEFT and event.alt_pressed):
		# Middle-click or Alt+Left-click starts panning
		_panning = event.pressed
		_pan_start = event.position
		accept_event()
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Right-click cancels connection drawing
		_connection_source_id = ""
		accept_event()


func _handle_pan_motion(event: InputEventMouseMotion) -> void:
	var delta: Vector2 = event.position - _pan_start
	_pan_start = event.position
	board_canvas.position += delta
	_clamp_canvas_position()
	accept_event()


## Clamps the canvas so it doesn't drift entirely off-screen.
func _clamp_canvas_position() -> void:
	var viewport_size: Vector2 = board_viewport.size
	var min_pos: Vector2 = viewport_size - Vector2(BoardManager.BOARD_WIDTH, BoardManager.BOARD_HEIGHT)
	board_canvas.position.x = clampf(board_canvas.position.x, min_pos.x, 0.0)
	board_canvas.position.y = clampf(board_canvas.position.y, min_pos.y, 0.0)


# --- Board Rebuild --- #

## Rebuilds the entire board UI from BoardManager data.
func _rebuild_board() -> void:
	_clear_ui()

	for node_data: Dictionary in BoardManager.get_all_nodes():
		_create_node_control(node_data)

	_redraw_connections()
	_update_count_label()


## Clears all UI elements from the board.
func _clear_ui() -> void:
	for child: Node in node_layer.get_children():
		node_layer.remove_child(child)
		child.queue_free()
	_node_controls.clear()
	connection_layer.queue_redraw()


# --- Node UI Creation --- #

## Creates a visual Control for a board node.
func _create_node_control(node_data: Dictionary) -> void:
	var node_id: String = node_data["id"]
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(NODE_WIDTH, NODE_HEIGHT)
	panel.position = Vector2(node_data["x"], node_data["y"])
	panel.set_meta("board_node_id", node_id)

	_apply_node_style(panel, node_data["type"])

	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)

	var type_label: Label = Label.new()
	type_label.text = _get_display_name(node_data)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(type_label)

	var type_badge: Label = Label.new()
	type_badge.text = "[%s]" % node_data["type"].to_upper()
	type_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_badge.add_theme_font_size_override("font_size", 12)
	type_badge.add_theme_color_override("font_color", UIColors.HEADER)
	vbox.add_child(type_badge)

	if not node_data.get("note", "").is_empty():
		var note_label: Label = Label.new()
		note_label.text = "📝 %s" % node_data["note"]
		note_label.add_theme_font_size_override("font_size", 12)
		note_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(note_label)

	panel.gui_input.connect(_on_node_gui_input.bind(node_id))

	node_layer.add_child(panel)
	_node_controls[node_id] = panel


## Applies visual styling based on node type.
func _apply_node_style(panel: PanelContainer, type: String) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = TYPE_COLORS.get(type, Color(0.5, 0.5, 0.5))
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)


## Returns a display name for a board node by looking up the reference.
func _get_display_name(node_data: Dictionary) -> String:
	var ref_id: String = node_data.get("ref_id", "")
	var type: String = node_data.get("type", "")

	match type:
		"person":
			var person: PersonData = CaseManager.get_person(ref_id)
			return person.name if person else ref_id
		"evidence":
			var ev: EvidenceData = CaseManager.get_evidence(ref_id)
			return ev.name if ev else ref_id
		"event":
			var evt: EventData = CaseManager.get_event(ref_id)
			return evt.title if evt else ref_id

	return ref_id


# --- Node Interaction --- #

## Handles input on a node card: drag, click, right-click for notes.
func _on_node_gui_input(event: InputEvent, node_id: String) -> void:
	if event is InputEventMouseButton:
		_handle_node_mouse_button(event as InputEventMouseButton, node_id)
	elif event is InputEventMouseMotion and _dragged_node != null:
		_handle_node_drag(event as InputEventMouseMotion)


func _handle_node_mouse_button(event: InputEventMouseButton, node_id: String) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.shift_pressed:
				_start_connection(node_id)
			else:
				_start_drag(node_id, event.position)
		else:
			_end_drag(node_id)
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_prompt_node_note(node_id)


func _start_drag(node_id: String, local_pos: Vector2) -> void:
	if node_id not in _node_controls:
		return
	_dragged_node = _node_controls[node_id]
	_drag_offset = local_pos


func _handle_node_drag(event: InputEventMouseMotion) -> void:
	if _dragged_node == null:
		return
	_dragged_node.position += event.relative
	# Clamp within board bounds
	_dragged_node.position.x = clampf(_dragged_node.position.x, 0.0,
		BoardManager.BOARD_WIDTH - NODE_WIDTH)
	_dragged_node.position.y = clampf(_dragged_node.position.y, 0.0,
		BoardManager.BOARD_HEIGHT - NODE_HEIGHT)
	_redraw_connections()


func _end_drag(node_id: String) -> void:
	if _dragged_node == null:
		# Check if this is a connection target
		if not _connection_source_id.is_empty() and _connection_source_id != node_id:
			BoardManager.add_connection(_connection_source_id, node_id)
			_connection_source_id = ""
		return

	# Persist new position
	BoardManager.move_node(node_id, _dragged_node.position.x, _dragged_node.position.y)
	_dragged_node = null


## Starts drawing a connection from this node.
func _start_connection(node_id: String) -> void:
	if _connection_source_id.is_empty():
		_connection_source_id = node_id
	elif _connection_source_id != node_id:
		BoardManager.add_connection(_connection_source_id, node_id)
		_connection_source_id = ""
	else:
		_connection_source_id = ""


## Prompts the player to add a note to a node.
func _prompt_node_note(node_id: String) -> void:
	var current_note: String = BoardManager.get_board_node(node_id).get("note", "")
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Edit Note"

	var line_edit: LineEdit = LineEdit.new()
	line_edit.text = current_note
	line_edit.placeholder_text = "Enter note..."
	dialog.add_child(line_edit)

	dialog.confirmed.connect(func() -> void:
		BoardManager.set_node_note(node_id, line_edit.text)
		_rebuild_board()
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())

	add_child(dialog)
	dialog.popup_centered(Vector2i(300, 100))


# --- Connection Drawing --- #

## Redraws all connection lines.
func _redraw_connections() -> void:
	connection_layer.queue_redraw()


# --- Signal Handlers --- #

func _on_node_added(_node_data: Dictionary) -> void:
	_rebuild_board()


func _on_node_removed(_node_id: String) -> void:
	_rebuild_board()


func _on_connection_added(_conn_data: Dictionary) -> void:
	_redraw_connections()


func _on_connection_removed(_conn_id: String) -> void:
	_redraw_connections()


func _on_board_cleared() -> void:
	_rebuild_board()


func _on_back_pressed() -> void:
	ScreenManager.navigate_back()


func _on_clear_pressed() -> void:
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.dialog_text = "Clear all nodes and connections from the board?"
	dialog.confirmed.connect(func() -> void:
		BoardManager.clear_board()
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()


func _update_count_label() -> void:
	node_count_label.text = "%d nodes · %d connections" % [
		BoardManager.get_node_count(), BoardManager.get_connection_count()
	]
