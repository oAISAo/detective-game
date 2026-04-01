## BoardConnectionDrawer.gd
## Draws connection lines between board nodes.
## Phase 8: Separated from DetectiveBoard to keep classes focused.
extends Control


## Color for the connection lines.
const LINE_COLOR: Color = Color(0.85, 0.82, 0.75, 0.8)

## Width of the connection lines.
const LINE_WIDTH: float = 2.0

## Font size for connection note labels.
const NOTE_FONT_SIZE: int = 12

## Color for connection note text.
const NOTE_COLOR: Color = Color(0.7, 0.68, 0.65)

## Reference to the node layer for finding node positions.
var node_layer: Control = null


func _draw() -> void:
	if node_layer == null:
		return

	# Build a lookup dictionary once per draw call instead of scanning per endpoint
	var node_map: Dictionary = _build_node_map()

	for conn: Dictionary in BoardManager.get_all_connections():
		_draw_connection(conn, node_map)


## Builds a dictionary mapping board_node_id → Control for O(1) lookup.
func _build_node_map() -> Dictionary:
	var result: Dictionary = {}
	for child: Node in node_layer.get_children():
		if child is Control and child.has_meta("board_node_id"):
			result[child.get_meta("board_node_id")] = child
	return result


## Draws a single connection line with an optional note label.
func _draw_connection(conn: Dictionary, node_map: Dictionary) -> void:
	var from_ctrl: Control = node_map.get(conn.get("from", ""))
	var to_ctrl: Control = node_map.get(conn.get("to", ""))

	if from_ctrl == null or to_ctrl == null:
		return

	var from_center: Vector2 = from_ctrl.position + from_ctrl.size / 2.0
	var to_center: Vector2 = to_ctrl.position + to_ctrl.size / 2.0

	draw_line(from_center, to_center, LINE_COLOR, LINE_WIDTH, true)

	var note_text: String = conn.get("note", "")
	if not note_text.is_empty():
		var mid: Vector2 = (from_center + to_center) / 2.0
		var font: Font = ThemeDB.fallback_font
		draw_string(font, mid, note_text, HORIZONTAL_ALIGNMENT_CENTER, -1, NOTE_FONT_SIZE, NOTE_COLOR)
