## BoardManager.gd
## Manages the detective board data: nodes and connections.
## Handles node placement, connection drawing, notes, and persistence.
## Phase 8: Pure data layer — no UI dependency.
extends BaseSubsystem


# --- Signals --- #

signal node_added(node_data: Dictionary)
signal node_removed(node_id: String)
signal node_moved(node_id: String, new_x: float, new_y: float)
signal node_note_changed(node_id: String, note: String)
signal connection_added(connection_data: Dictionary)
signal connection_removed(connection_id: String)
signal connection_note_changed(connection_id: String, note: String)
signal board_cleared
signal state_loaded


# --- Constants --- #

## Valid node types for the board.
const VALID_NODE_TYPES: Array[String] = ["person", "evidence", "event"]

## Default board dimensions (large but finite).
const BOARD_WIDTH: float = 3840.0
const BOARD_HEIGHT: float = 2160.0

## Inbox zone — where newly sent items auto-place before the player arranges them.
## Origin is near the top-left corner of the canvas (visible on first open).
const INBOX_ORIGIN: Vector2 = Vector2(40.0, 40.0)
## Horizontal distance between inbox columns (NODE_WIDTH≈160 + 20px gap).
const INBOX_COL_STRIDE: float = 180.0
## Vertical distance between inbox rows (NODE_HEIGHT≈80 + 20px gap).
const INBOX_ROW_STRIDE: float = 100.0
## Number of columns before wrapping to the next row.
const INBOX_COLS: int = 5


# --- State --- #

## All board nodes: { node_id: {id, type, ref_id, x, y, note} }
var _nodes: Dictionary = {}

## All board connections: { conn_id: {id, from, to, note} }
var _connections: Dictionary = {}

## Counter for generating unique node IDs.
var _next_node_id: int = 1

## Counter for generating unique connection IDs.
var _next_connection_id: int = 1

## Tracks how many items have been sent via send_to_board() so inbox
## staggering is independent of manual add_node() calls and node removals.
var _inbox_cursor: int = 0


# --- Lifecycle --- #

func _ready() -> void:
	super()


# --- Node Management --- #

## Adds a new node to the board. Returns the created node data dictionary.
func add_node(type: String, ref_id: String, x: float, y: float, note: String = "") -> Dictionary:
	if type not in VALID_NODE_TYPES:
		push_error("[BoardManager] Invalid node type: %s" % type)
		return {}

	var clamped_x: float = clampf(x, 0.0, BOARD_WIDTH)
	var clamped_y: float = clampf(y, 0.0, BOARD_HEIGHT)

	var node_id: String = "node_%d" % _next_node_id
	_next_node_id += 1

	var node_data: Dictionary = {
		"id": node_id,
		"type": type,
		"ref_id": ref_id,
		"x": clamped_x,
		"y": clamped_y,
		"note": note,
	}

	_nodes[node_id] = node_data
	node_added.emit(node_data)
	return node_data


## Removes a node and all its connections from the board.
func remove_node(node_id: String) -> bool:
	if node_id not in _nodes:
		push_warning("[BoardManager] Node not found: %s" % node_id)
		return false

	# Remove all connections involving this node
	var conns_to_remove: Array[String] = []
	for conn_id: String in _connections:
		var conn: Dictionary = _connections[conn_id]
		if conn["from"] == node_id or conn["to"] == node_id:
			conns_to_remove.append(conn_id)

	for conn_id: String in conns_to_remove:
		_connections.erase(conn_id)
		connection_removed.emit(conn_id)

	_nodes.erase(node_id)
	node_removed.emit(node_id)
	return true


## Moves a node to a new position. Returns true on success.
func move_node(node_id: String, new_x: float, new_y: float) -> bool:
	if node_id not in _nodes:
		push_warning("[BoardManager] Node not found: %s" % node_id)
		return false

	var clamped_x: float = clampf(new_x, 0.0, BOARD_WIDTH)
	var clamped_y: float = clampf(new_y, 0.0, BOARD_HEIGHT)
	_nodes[node_id]["x"] = clamped_x
	_nodes[node_id]["y"] = clamped_y
	node_moved.emit(node_id, clamped_x, clamped_y)
	return true


## Sets or updates the note on a node.
func set_node_note(node_id: String, note: String) -> bool:
	if node_id not in _nodes:
		push_warning("[BoardManager] Node not found: %s" % node_id)
		return false

	_nodes[node_id]["note"] = note
	node_note_changed.emit(node_id, note)
	return true


## Returns a specific board node's data, or an empty dictionary if not found.
func get_board_node(node_id: String) -> Dictionary:
	return _nodes.get(node_id, {})


## Returns all board nodes as an array of dictionaries.
func get_all_nodes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node_id: String in _nodes:
		result.append(_nodes[node_id])
	return result


## Returns all nodes of a specific type.
func get_nodes_by_type(type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node_id: String in _nodes:
		if _nodes[node_id]["type"] == type:
			result.append(_nodes[node_id])
	return result


## Returns the total number of nodes on the board.
func get_node_count() -> int:
	return _nodes.size()


# --- Connection Management --- #

## Creates a connection between two nodes. Returns the connection data.
func add_connection(from_id: String, to_id: String, note: String = "") -> Dictionary:
	if from_id not in _nodes:
		push_error("[BoardManager] Source node not found: %s" % from_id)
		return {}
	if to_id not in _nodes:
		push_error("[BoardManager] Target node not found: %s" % to_id)
		return {}
	if from_id == to_id:
		push_warning("[BoardManager] Cannot connect node to itself.")
		return {}

	# Check for existing connection between the same pair (either direction)
	for conn: Dictionary in _connections.values():
		if (conn["from"] == from_id and conn["to"] == to_id) or \
			(conn["from"] == to_id and conn["to"] == from_id):
			return conn.duplicate()

	var conn_id: String = "conn_%d" % _next_connection_id
	_next_connection_id += 1

	var conn_data: Dictionary = {
		"id": conn_id,
		"from": from_id,
		"to": to_id,
		"note": note,
	}

	_connections[conn_id] = conn_data
	connection_added.emit(conn_data)
	return conn_data


## Removes a connection by ID.
func remove_connection(connection_id: String) -> bool:
	if connection_id not in _connections:
		push_warning("[BoardManager] Connection not found: %s" % connection_id)
		return false

	_connections.erase(connection_id)
	connection_removed.emit(connection_id)
	return true


## Sets or updates the note on a connection.
func set_connection_note(connection_id: String, note: String) -> bool:
	if connection_id not in _connections:
		push_warning("[BoardManager] Connection not found: %s" % connection_id)
		return false

	_connections[connection_id]["note"] = note
	connection_note_changed.emit(connection_id, note)
	return true


## Returns a specific connection's data, or empty dict if not found.
func get_connection(connection_id: String) -> Dictionary:
	return _connections.get(connection_id, {})


## Returns all connections as an array of dictionaries.
func get_all_connections() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for conn_id: String in _connections:
		result.append(_connections[conn_id])
	return result


## Returns all connections involving a specific node.
func get_connections_for_node(node_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for conn_id: String in _connections:
		var conn: Dictionary = _connections[conn_id]
		if conn["from"] == node_id or conn["to"] == node_id:
			result.append(conn)
	return result


## Returns the total number of connections on the board.
func get_connection_count() -> int:
	return _connections.size()


# --- Convenience --- #

## Sends an item to the board inbox zone. Returns node data.
## Items are staggered in a grid within the inbox zone so they do not
## overlap; the player can then drag them to their preferred position.
func send_to_board(type: String, ref_id: String) -> Dictionary:
	var col: int = _inbox_cursor % INBOX_COLS
	var row: int = _inbox_cursor / INBOX_COLS
	var x: float = INBOX_ORIGIN.x + col * INBOX_COL_STRIDE
	var y: float = INBOX_ORIGIN.y + row * INBOX_ROW_STRIDE
	_inbox_cursor += 1
	return add_node(type, ref_id, x, y)


## Clears all nodes and connections from the board.
func clear_board() -> void:
	_nodes.clear()
	_connections.clear()
	_next_node_id = 1
	_next_connection_id = 1
	_inbox_cursor = 0
	board_cleared.emit()


## Returns true if the board has any content.
func has_content() -> bool:
	return not _nodes.is_empty()


# --- Serialization --- #

## Returns the board state as a dictionary for saving.
func serialize() -> Dictionary:
	var nodes_array: Array[Dictionary] = []
	for node_id: String in _nodes:
		nodes_array.append(_nodes[node_id].duplicate())

	var conns_array: Array[Dictionary] = []
	for conn_id: String in _connections:
		conns_array.append(_connections[conn_id].duplicate())

	return {
		"board_nodes": nodes_array,
		"board_connections": conns_array,
		"next_node_id": _next_node_id,
		"next_connection_id": _next_connection_id,
		"inbox_cursor": _inbox_cursor,
	}


## Restores the board state from a saved dictionary.
func deserialize(data: Dictionary) -> void:
	clear_board()

	var nodes_array: Array = data.get("board_nodes", [])
	for node_dict in nodes_array:
		var nd: Dictionary = node_dict as Dictionary
		var nid: String = nd.get("id", "")
		if not nid.is_empty():
			_nodes[nid] = nd

	var conns_array: Array = data.get("board_connections", [])
	for conn_dict in conns_array:
		var cd: Dictionary = conn_dict as Dictionary
		var cid: String = cd.get("id", "")
		if not cid.is_empty():
			_connections[cid] = cd

	_next_node_id = data.get("next_node_id", _nodes.size() + 1)
	_next_connection_id = data.get("next_connection_id", _connections.size() + 1)
	_inbox_cursor = data.get("inbox_cursor", _nodes.size())
	state_loaded.emit()


## Resets all board state for a new game.
func reset() -> void:
	clear_board()
