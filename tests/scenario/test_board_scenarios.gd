## test_board_scenarios.gd
## Scenario tests for the Detective Board System.
## Phase 8: Tests boards with 20+ nodes and complex connection networks.
extends GutTest


func before_each() -> void:
	BoardManager.reset()


# =========================================================================
# Scenario 1: Board with 20+ Nodes and Connections
# =========================================================================

func test_large_board_serialize_deserialize() -> void:
	# Add 25 nodes: 10 evidence, 10 persons, 5 events
	var node_ids: Array[String] = []

	for i: int in range(10):
		var node: Dictionary = BoardManager.add_node(
			"evidence", "ev_%d" % i,
			float(i * 150), float((i % 5) * 120)
		)
		node_ids.append(node["id"])

	for i: int in range(10):
		var node: Dictionary = BoardManager.add_node(
			"person", "p_%d" % i,
			float(i * 150), float(600 + (i % 5) * 120)
		)
		node_ids.append(node["id"])

	for i: int in range(5):
		var node: Dictionary = BoardManager.add_node(
			"event", "event_%d" % i,
			float(i * 200), 1200.0
		)
		node_ids.append(node["id"])

	assert_eq(BoardManager.get_node_count(), 25)

	# Add 15 connections linking evidence to persons
	for i: int in range(10):
		BoardManager.add_connection(
			node_ids[i], node_ids[10 + i],
			"connection_%d" % i
		)

	# Link events to some persons
	for i: int in range(5):
		BoardManager.add_connection(
			node_ids[20 + i], node_ids[10 + i],
			"event_link_%d" % i
		)

	assert_eq(BoardManager.get_connection_count(), 15)

	# Add notes to some nodes
	BoardManager.set_node_note(node_ids[0], "Critical evidence")
	BoardManager.set_node_note(node_ids[10], "Prime suspect")
	BoardManager.set_node_note(node_ids[20], "Key event")

	# Serialize
	var data: Dictionary = BoardManager.serialize()
	assert_eq(data["board_nodes"].size(), 25)
	assert_eq(data["board_connections"].size(), 15)

	# Reset and deserialize
	BoardManager.reset()
	assert_eq(BoardManager.get_node_count(), 0)
	assert_eq(BoardManager.get_connection_count(), 0)

	BoardManager.deserialize(data)
	assert_eq(BoardManager.get_node_count(), 25)
	assert_eq(BoardManager.get_connection_count(), 15)

	# Verify type counts
	assert_eq(BoardManager.get_nodes_by_type("evidence").size(), 10)
	assert_eq(BoardManager.get_nodes_by_type("person").size(), 10)
	assert_eq(BoardManager.get_nodes_by_type("event").size(), 5)

	# Verify notes preserved
	assert_eq(BoardManager.get_board_node(node_ids[0])["note"], "Critical evidence")
	assert_eq(BoardManager.get_board_node(node_ids[10])["note"], "Prime suspect")

	# Verify connections preserved with notes
	var person0_conns: Array[Dictionary] = BoardManager.get_connections_for_node(node_ids[10])
	assert_true(person0_conns.size() >= 2, "Person 0 should have evidence + event connections")


# =========================================================================
# Scenario 2: Node Operations After Deserialize
# =========================================================================

func test_operations_after_deserialize_use_correct_ids() -> void:
	# Build initial board
	var n1: Dictionary = BoardManager.add_node("evidence", "ev_1", 100.0, 100.0)
	var n2: Dictionary = BoardManager.add_node("person", "p_1", 200.0, 200.0)
	BoardManager.add_connection(n1["id"], n2["id"], "link")

	# Serialize and restore
	var data: Dictionary = BoardManager.serialize()
	BoardManager.reset()
	BoardManager.deserialize(data)

	# Add new nodes — IDs should not collide
	var n3: Dictionary = BoardManager.add_node("event", "e_1", 300.0, 300.0)
	assert_ne(n3["id"], n1["id"])
	assert_ne(n3["id"], n2["id"])

	# New connections should work with both old and new nodes
	var conn: Dictionary = BoardManager.add_connection(n2["id"], n3["id"], "new link")
	assert_false(conn.is_empty())
	assert_eq(BoardManager.get_connection_count(), 2)

	# Remove old node — should clean up its connections
	BoardManager.remove_node(n1["id"])
	assert_eq(BoardManager.get_node_count(), 2)
	assert_eq(BoardManager.get_connection_count(), 1, "Removing n1 should remove its connection")
