## test_board_manager.gd
## Unit tests for the BoardManager (Detective Board System).
## Phase 8: Tests node CRUD, connection CRUD, serialization, and queries.
extends GutTest


# --- Setup / Teardown --- #

func before_each() -> void:
	BoardManager.reset()


# =========================================================================
# Node Creation
# =========================================================================

func test_add_node_returns_data() -> void:
	var node: Dictionary = BoardManager.add_node("evidence", "ev_knife", 100.0, 200.0)
	assert_false(node.is_empty(), "Should return node data")
	assert_eq(node["type"], "evidence")
	assert_eq(node["ref_id"], "ev_knife")
	assert_eq(node["x"], 100.0)
	assert_eq(node["y"], 200.0)
	assert_eq(node["note"], "")
	assert_true(node["id"].begins_with("node_"), "ID should start with node_")


func test_add_node_with_note() -> void:
	var node: Dictionary = BoardManager.add_node("person", "p_julia", 50.0, 50.0, "Prime suspect")
	assert_eq(node["note"], "Prime suspect")


func test_add_node_invalid_type_returns_empty() -> void:
	var node: Dictionary = BoardManager.add_node("invalid_type", "ref1", 100.0, 100.0)
	assert_true(node.is_empty(), "Invalid type should return empty")
	assert_push_error("[BoardManager] Invalid node type: invalid_type")


func test_add_node_increments_count() -> void:
	BoardManager.add_node("evidence", "ev_1", 10.0, 10.0)
	BoardManager.add_node("person", "p_1", 20.0, 20.0)
	BoardManager.add_node("event", "e_1", 30.0, 30.0)
	assert_eq(BoardManager.get_node_count(), 3)


func test_add_node_generates_unique_ids() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	assert_ne(n1["id"], n2["id"], "Same ref_id should produce different node IDs")


func test_add_node_emits_signal() -> void:
	watch_signals(BoardManager)
	BoardManager.add_node("evidence", "ev_1", 100.0, 100.0)
	assert_signal_emitted(BoardManager, "node_added")


func test_duplicate_nodes_allowed_for_same_reference() -> void:
	BoardManager.add_node("evidence", "ev_knife", 100.0, 100.0)
	BoardManager.add_node("evidence", "ev_knife", 300.0, 300.0)
	assert_eq(BoardManager.get_node_count(), 2, "Should allow duplicate nodes for same ref")


func test_add_node_clamps_position() -> void:
	var node: Dictionary = BoardManager.add_node("evidence", "ev_1", -50.0, 5000.0)
	assert_eq(node["x"], 0.0, "X should be clamped to 0")
	assert_eq(node["y"], BoardManager.BOARD_HEIGHT, "Y should be clamped to board height")


func test_all_three_node_types_valid() -> void:
	var n1: Dictionary = BoardManager.add_node("person", "p1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("evidence", "e1", 0.0, 0.0)
	var n3: Dictionary = BoardManager.add_node("event", "ev1", 0.0, 0.0)
	assert_false(n1.is_empty())
	assert_false(n2.is_empty())
	assert_false(n3.is_empty())


# =========================================================================
# Node Retrieval
# =========================================================================

func test_get_node_returns_correct_data() -> void:
	var node: Dictionary = BoardManager.add_node("evidence", "ev_1", 100.0, 200.0)
	var retrieved: Dictionary = BoardManager.get_board_node(node["id"])
	assert_eq(retrieved["ref_id"], "ev_1")


func test_get_node_nonexistent_returns_empty() -> void:
	var retrieved: Dictionary = BoardManager.get_board_node("nonexistent")
	assert_true(retrieved.is_empty())


func test_get_all_nodes() -> void:
	BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	BoardManager.add_node("person", "p_1", 0.0, 0.0)
	var all_nodes: Array[Dictionary] = BoardManager.get_all_nodes()
	assert_eq(all_nodes.size(), 2)


func test_get_nodes_by_type() -> void:
	BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	BoardManager.add_node("evidence", "ev_2", 0.0, 0.0)
	BoardManager.add_node("person", "p_1", 0.0, 0.0)
	var evidence_nodes: Array[Dictionary] = BoardManager.get_nodes_by_type("evidence")
	assert_eq(evidence_nodes.size(), 2)
	var person_nodes: Array[Dictionary] = BoardManager.get_nodes_by_type("person")
	assert_eq(person_nodes.size(), 1)


# =========================================================================
# Node Modification
# =========================================================================

func test_move_node_updates_position() -> void:
	var node: Dictionary = BoardManager.add_node("evidence", "ev_1", 100.0, 100.0)
	var moved: bool = BoardManager.move_node(node["id"], 500.0, 600.0)
	assert_true(moved)
	var updated: Dictionary = BoardManager.get_board_node(node["id"])
	assert_eq(updated["x"], 500.0)
	assert_eq(updated["y"], 600.0)


func test_move_node_emits_signal() -> void:
	var node: Dictionary = BoardManager.add_node("evidence", "ev_1", 100.0, 100.0)
	watch_signals(BoardManager)
	BoardManager.move_node(node["id"], 200.0, 300.0)
	assert_signal_emitted(BoardManager, "node_moved")


func test_move_node_nonexistent_returns_false() -> void:
	var moved: bool = BoardManager.move_node("nonexistent", 0.0, 0.0)
	assert_false(moved)
	assert_push_warning("[BoardManager]")


func test_move_node_clamps_position() -> void:
	var node: Dictionary = BoardManager.add_node("evidence", "ev_1", 100.0, 100.0)
	BoardManager.move_node(node["id"], -100.0, 99999.0)
	var updated: Dictionary = BoardManager.get_board_node(node["id"])
	assert_eq(updated["x"], 0.0)
	assert_eq(updated["y"], BoardManager.BOARD_HEIGHT)


func test_set_node_note() -> void:
	var node: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var result: bool = BoardManager.set_node_note(node["id"], "Important clue")
	assert_true(result)
	assert_eq(BoardManager.get_board_node(node["id"])["note"], "Important clue")


func test_set_node_note_emits_signal() -> void:
	var node: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	watch_signals(BoardManager)
	BoardManager.set_node_note(node["id"], "Note")
	assert_signal_emitted(BoardManager, "node_note_changed")


func test_set_node_note_nonexistent_returns_false() -> void:
	var result: bool = BoardManager.set_node_note("nonexistent", "Note")
	assert_false(result)
	assert_push_warning("[BoardManager]")


# =========================================================================
# Node Removal
# =========================================================================

func test_remove_node() -> void:
	var node: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var removed: bool = BoardManager.remove_node(node["id"])
	assert_true(removed)
	assert_eq(BoardManager.get_node_count(), 0)


func test_remove_node_emits_signal() -> void:
	var node: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	watch_signals(BoardManager)
	BoardManager.remove_node(node["id"])
	assert_signal_emitted(BoardManager, "node_removed")


func test_remove_node_nonexistent_returns_false() -> void:
	var removed: bool = BoardManager.remove_node("nonexistent")
	assert_false(removed)
	assert_push_warning("[BoardManager]")


func test_remove_node_removes_associated_connections() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var n3: Dictionary = BoardManager.add_node("event", "e_1", 200.0, 0.0)
	BoardManager.add_connection(n1["id"], n2["id"], "linked")
	BoardManager.add_connection(n2["id"], n3["id"], "also linked")
	assert_eq(BoardManager.get_connection_count(), 2)

	# Removing n2 should remove both connections
	BoardManager.remove_node(n2["id"])
	assert_eq(BoardManager.get_connection_count(), 0)
	assert_eq(BoardManager.get_node_count(), 2)


# =========================================================================
# Connection Creation
# =========================================================================

func test_add_connection_returns_data() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var conn: Dictionary = BoardManager.add_connection(n1["id"], n2["id"], "fingerprint match")
	assert_false(conn.is_empty())
	assert_eq(conn["from"], n1["id"])
	assert_eq(conn["to"], n2["id"])
	assert_eq(conn["note"], "fingerprint match")
	assert_true(conn["id"].begins_with("conn_"))


func test_add_connection_without_note() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var conn: Dictionary = BoardManager.add_connection(n1["id"], n2["id"])
	assert_eq(conn["note"], "")


func test_add_connection_emits_signal() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	watch_signals(BoardManager)
	BoardManager.add_connection(n1["id"], n2["id"])
	assert_signal_emitted(BoardManager, "connection_added")


func test_add_connection_invalid_source_returns_empty() -> void:
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var conn: Dictionary = BoardManager.add_connection("nonexistent", n2["id"])
	assert_true(conn.is_empty())
	assert_push_error("[BoardManager] Source node not found: nonexistent")


func test_add_connection_invalid_target_returns_empty() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var conn: Dictionary = BoardManager.add_connection(n1["id"], "nonexistent")
	assert_true(conn.is_empty())
	assert_push_error("[BoardManager] Target node not found: nonexistent")


func test_add_connection_self_loop_returns_empty() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var conn: Dictionary = BoardManager.add_connection(n1["id"], n1["id"])
	assert_true(conn.is_empty())
	assert_push_warning("[BoardManager]")


# =========================================================================
# Connection Retrieval
# =========================================================================

func test_get_connection_returns_data() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var conn: Dictionary = BoardManager.add_connection(n1["id"], n2["id"], "match")
	var retrieved: Dictionary = BoardManager.get_connection(conn["id"])
	assert_eq(retrieved["note"], "match")


func test_get_all_connections() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var n3: Dictionary = BoardManager.add_node("event", "e_1", 200.0, 0.0)
	BoardManager.add_connection(n1["id"], n2["id"])
	BoardManager.add_connection(n2["id"], n3["id"])
	var all_conns: Array[Dictionary] = BoardManager.get_all_connections()
	assert_eq(all_conns.size(), 2)


func test_get_connections_for_node() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var n3: Dictionary = BoardManager.add_node("event", "e_1", 200.0, 0.0)
	BoardManager.add_connection(n1["id"], n2["id"])
	BoardManager.add_connection(n2["id"], n3["id"])

	# n2 is involved in both connections
	var n2_conns: Array[Dictionary] = BoardManager.get_connections_for_node(n2["id"])
	assert_eq(n2_conns.size(), 2, "n2 should have 2 connections")

	# n1 is only in 1
	var n1_conns: Array[Dictionary] = BoardManager.get_connections_for_node(n1["id"])
	assert_eq(n1_conns.size(), 1)


# =========================================================================
# Connection Modification
# =========================================================================

func test_set_connection_note() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var conn: Dictionary = BoardManager.add_connection(n1["id"], n2["id"])
	var result: bool = BoardManager.set_connection_note(conn["id"], "updated note")
	assert_true(result)
	assert_eq(BoardManager.get_connection(conn["id"])["note"], "updated note")


func test_set_connection_note_emits_signal() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var conn: Dictionary = BoardManager.add_connection(n1["id"], n2["id"])
	watch_signals(BoardManager)
	BoardManager.set_connection_note(conn["id"], "note")
	assert_signal_emitted(BoardManager, "connection_note_changed")


func test_set_connection_note_nonexistent_returns_false() -> void:
	var result: bool = BoardManager.set_connection_note("nonexistent", "note")
	assert_false(result)
	assert_push_warning("[BoardManager]")


# =========================================================================
# Connection Removal
# =========================================================================

func test_remove_connection() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var conn: Dictionary = BoardManager.add_connection(n1["id"], n2["id"])
	var removed: bool = BoardManager.remove_connection(conn["id"])
	assert_true(removed)
	assert_eq(BoardManager.get_connection_count(), 0)


func test_remove_connection_emits_signal() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var conn: Dictionary = BoardManager.add_connection(n1["id"], n2["id"])
	watch_signals(BoardManager)
	BoardManager.remove_connection(conn["id"])
	assert_signal_emitted(BoardManager, "connection_removed")


func test_remove_connection_nonexistent_returns_false() -> void:
	var removed: bool = BoardManager.remove_connection("nonexistent")
	assert_false(removed)
	assert_push_warning("[BoardManager]")


# =========================================================================
# Board Operations
# =========================================================================

func test_clear_board() -> void:
	BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	BoardManager.add_node("person", "p_1", 100.0, 0.0)
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_2", 200.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_2", 300.0, 0.0)
	BoardManager.add_connection(n1["id"], n2["id"])

	BoardManager.clear_board()
	assert_eq(BoardManager.get_node_count(), 0)
	assert_eq(BoardManager.get_connection_count(), 0)


func test_clear_board_emits_signal() -> void:
	watch_signals(BoardManager)
	BoardManager.clear_board()
	assert_signal_emitted(BoardManager, "board_cleared")


func test_has_content_false_when_empty() -> void:
	assert_false(BoardManager.has_content())


func test_has_content_true_when_nodes_exist() -> void:
	BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	assert_true(BoardManager.has_content())


func test_send_to_board() -> void:
	var node: Dictionary = BoardManager.send_to_board("evidence", "ev_test")
	assert_false(node.is_empty())
	assert_eq(node["type"], "evidence")
	assert_eq(node["ref_id"], "ev_test")
	# First node placed at INBOX_ORIGIN
	assert_eq(node["x"], BoardManager.INBOX_ORIGIN.x)
	assert_eq(node["y"], BoardManager.INBOX_ORIGIN.y)


func test_send_to_board_staggers_positions() -> void:
	BoardManager.clear_board()
	var node1: Dictionary = BoardManager.send_to_board("evidence", "ev_1")
	var node2: Dictionary = BoardManager.send_to_board("person", "p_1")
	assert_ne(node1["x"], node2["x"], "Nodes should be placed at different positions")


# =========================================================================
# Inbox Zone
# =========================================================================

func test_send_to_board_second_node_offset_by_col_stride() -> void:
	var n1: Dictionary = BoardManager.send_to_board("evidence", "ev_1")
	var n2: Dictionary = BoardManager.send_to_board("evidence", "ev_2")
	assert_eq(n2["x"], n1["x"] + BoardManager.INBOX_COL_STRIDE,
		"Second node should be one INBOX_COL_STRIDE to the right.")
	assert_eq(n2["y"], n1["y"], "Second node should share the same row as the first.")


func test_send_to_board_wraps_to_next_row_after_inbox_cols() -> void:
	# Fill exactly one row.
	for i: int in range(BoardManager.INBOX_COLS):
		BoardManager.send_to_board("evidence", "ev_%d" % i)
	# The next node should appear at the start of the second row.
	var overflow: Dictionary = BoardManager.send_to_board("evidence", "ev_overflow")
	assert_eq(overflow["x"], BoardManager.INBOX_ORIGIN.x,
		"Overflow node should wrap to column 0 of the next row.")
	assert_eq(overflow["y"], BoardManager.INBOX_ORIGIN.y + BoardManager.INBOX_ROW_STRIDE,
		"Overflow node should be one INBOX_ROW_STRIDE below the first row.")


func test_send_to_board_cursor_unaffected_by_add_node() -> void:
	# Manually adding a node via add_node() must not shift the inbox cursor.
	BoardManager.add_node("evidence", "ev_manual", 500.0, 500.0)
	var n: Dictionary = BoardManager.send_to_board("evidence", "ev_inbox")
	assert_eq(n["x"], BoardManager.INBOX_ORIGIN.x,
		"Cursor should still be 0 — add_node() must not affect inbox cursor.")


func test_send_to_board_cursor_unaffected_by_remove_node() -> void:
	# send two, remove one — next send must not reuse the removed slot.
	var n1: Dictionary = BoardManager.send_to_board("evidence", "ev_1")
	BoardManager.send_to_board("evidence", "ev_2")
	BoardManager.remove_node(n1["id"])
	# cursor is now 2, so next node goes to column 2
	var n3: Dictionary = BoardManager.send_to_board("evidence", "ev_3")
	assert_eq(n3["x"], BoardManager.INBOX_ORIGIN.x + 2.0 * BoardManager.INBOX_COL_STRIDE,
		"Cursor should not reuse the removed node's slot.")


func test_send_to_board_cursor_resets_on_clear_board() -> void:
	BoardManager.send_to_board("evidence", "ev_1")
	BoardManager.send_to_board("evidence", "ev_2")
	BoardManager.clear_board()
	var n: Dictionary = BoardManager.send_to_board("evidence", "ev_fresh")
	assert_eq(n["x"], BoardManager.INBOX_ORIGIN.x,
		"After clear_board() the cursor must reset to 0.")
	assert_eq(n["y"], BoardManager.INBOX_ORIGIN.y)


func test_send_to_board_cursor_serialized_and_restored() -> void:
	BoardManager.send_to_board("evidence", "ev_1")
	BoardManager.send_to_board("evidence", "ev_2")
	var data: Dictionary = BoardManager.serialize()
	assert_true(data.has("inbox_cursor"), "Serialized data must contain inbox_cursor.")
	assert_eq(data["inbox_cursor"], 2)

	BoardManager.reset()
	BoardManager.deserialize(data)
	# Next send must continue from cursor=2, not restart at 0.
	var n: Dictionary = BoardManager.send_to_board("evidence", "ev_3")
	assert_eq(n["x"], BoardManager.INBOX_ORIGIN.x + 2.0 * BoardManager.INBOX_COL_STRIDE,
		"Cursor should resume at 2 after deserialization.")


func test_reset_clears_everything() -> void:
	BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	BoardManager.reset()
	assert_eq(BoardManager.get_node_count(), 0)
	assert_eq(BoardManager.get_connection_count(), 0)
	assert_false(BoardManager.has_content())


# =========================================================================
# Serialization
# =========================================================================

func test_serialize_returns_dictionary() -> void:
	BoardManager.add_node("evidence", "ev_1", 100.0, 200.0, "my note")
	var data: Dictionary = BoardManager.serialize()
	assert_true(data.has("board_nodes"))
	assert_true(data.has("board_connections"))
	assert_true(data.has("next_node_id"))
	assert_true(data.has("next_connection_id"))


func test_serialize_contains_all_nodes() -> void:
	BoardManager.add_node("evidence", "ev_1", 100.0, 200.0)
	BoardManager.add_node("person", "p_1", 300.0, 400.0)
	var data: Dictionary = BoardManager.serialize()
	assert_eq(data["board_nodes"].size(), 2)


func test_serialize_contains_all_connections() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	BoardManager.add_connection(n1["id"], n2["id"], "link")
	var data: Dictionary = BoardManager.serialize()
	assert_eq(data["board_connections"].size(), 1)
	assert_eq(data["board_connections"][0]["note"], "link")


func test_deserialize_restores_nodes() -> void:
	BoardManager.add_node("evidence", "ev_1", 100.0, 200.0, "note1")
	BoardManager.add_node("person", "p_1", 300.0, 400.0)
	var data: Dictionary = BoardManager.serialize()

	BoardManager.reset()
	assert_eq(BoardManager.get_node_count(), 0)

	BoardManager.deserialize(data)
	assert_eq(BoardManager.get_node_count(), 2)


func test_deserialize_restores_connections() -> void:
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 100.0, 0.0)
	BoardManager.add_connection(n1["id"], n2["id"], "fingerprint match")
	var data: Dictionary = BoardManager.serialize()

	BoardManager.reset()
	BoardManager.deserialize(data)

	assert_eq(BoardManager.get_connection_count(), 1)
	var conns: Array[Dictionary] = BoardManager.get_all_connections()
	assert_eq(conns[0]["note"], "fingerprint match")


func test_serialize_round_trip_preserves_node_positions() -> void:
	BoardManager.add_node("evidence", "ev_1", 123.5, 456.7, "test note")
	var data: Dictionary = BoardManager.serialize()

	BoardManager.reset()
	BoardManager.deserialize(data)

	var all_nodes: Array[Dictionary] = BoardManager.get_all_nodes()
	assert_eq(all_nodes.size(), 1)
	assert_eq(all_nodes[0]["x"], 123.5)
	assert_eq(all_nodes[0]["y"], 456.7)
	assert_eq(all_nodes[0]["note"], "test note")


func test_deserialize_restores_id_counters() -> void:
	BoardManager.add_node("evidence", "ev_1", 0.0, 0.0)
	BoardManager.add_node("evidence", "ev_2", 0.0, 0.0)
	var data: Dictionary = BoardManager.serialize()

	BoardManager.reset()
	BoardManager.deserialize(data)

	# Adding a new node should not reuse old IDs
	var new_node: Dictionary = BoardManager.add_node("person", "p_1", 0.0, 0.0)
	assert_eq(new_node["id"], "node_3", "Should continue from next_node_id=3")
