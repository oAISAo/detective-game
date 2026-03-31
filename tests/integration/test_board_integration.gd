## test_board_integration.gd
## Integration tests for the Detective Board System.
## Phase 8: Tests evidence-to-board pipeline and save/load persistence.
extends GutTest


const TEST_CASE_FILE: String = "test_case_board_integ.json"

var _test_case_data: Dictionary = {
	"id": "case_board_integ",
	"title": "Board Integration Case",
	"description": "Test case for board integration.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{
			"id": "p_julia",
			"name": "Julia Ross",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 3,
		},
	],
	"evidence": [
		{
			"id": "ev_glass",
			"name": "Wine Glass",
			"description": "A wine glass with fingerprints.",
			"type": "FORENSIC",
			"location_found": "loc_apt",
			"related_persons": ["p_julia"],
			"weight": 0.8,
			"importance_level": "CRITICAL",
		},
		{
			"id": "ev_letter",
			"name": "Threatening Letter",
			"description": "A threatening letter found at scene.",
			"type": "DOCUMENT",
			"location_found": "loc_apt",
			"related_persons": [],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
		},
	],
	"statements": [],
	"events": [
		{
			"id": "event_arrival",
			"title": "Julia arrives",
			"description": "Julia arrives at the building.",
			"day": 1,
			"time_slot": "DAYTIME",
			"persons_involved": ["p_julia"],
			"evidence_ids": [],
			"certainty_level": "CONFIRMED",
		},
	],
	"locations": [
		{"id": "loc_apt", "name": "Apartment", "searchable": true, "evidence_pool": []},
	],
	"event_triggers": [],
	"interrogation_topics": [],
	"actions": [],
	"insights": [],
	"interrogation_triggers": [],
}


func before_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	DirAccess.make_dir_recursive_absolute("res://data/cases")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_test_case_data, "\t"))
	file.close()


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)
	BoardManager.reset()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Evidence → Board Pipeline
# =========================================================================

func test_send_evidence_to_board_creates_node() -> void:
	GameManager.discover_evidence("ev_glass")
	var node: Dictionary = BoardManager.send_to_board("evidence", "ev_glass")
	assert_false(node.is_empty())
	assert_eq(node["type"], "evidence")
	assert_eq(node["ref_id"], "ev_glass")
	assert_eq(BoardManager.get_node_count(), 1)


func test_send_person_to_board() -> void:
	var node: Dictionary = BoardManager.send_to_board("person", "p_julia")
	assert_eq(node["type"], "person")
	assert_eq(node["ref_id"], "p_julia")


func test_send_event_to_board() -> void:
	var node: Dictionary = BoardManager.send_to_board("event", "event_arrival")
	assert_eq(node["type"], "event")
	assert_eq(node["ref_id"], "event_arrival")


func test_full_pipeline_discover_send_connect_save_load() -> void:
	# 1. Discover evidence
	GameManager.discover_evidence("ev_glass")
	GameManager.discover_evidence("ev_letter")

	# 2. Send to board
	var n_glass: Dictionary = BoardManager.send_to_board("evidence", "ev_glass")
	var n_julia: Dictionary = BoardManager.send_to_board("person", "p_julia")
	var n_letter: Dictionary = BoardManager.send_to_board("evidence", "ev_letter")

	# 3. Add note and connection
	BoardManager.set_node_note(n_glass["id"], "Julia's fingerprints")
	BoardManager.add_connection(n_glass["id"], n_julia["id"], "fingerprint match")
	BoardManager.add_connection(n_letter["id"], n_julia["id"], "handwriting?")

	# 4. Verify state
	assert_eq(BoardManager.get_node_count(), 3)
	assert_eq(BoardManager.get_connection_count(), 2)

	# 5. Serialize via GameManager
	var save_data: Dictionary = GameManager.serialize()
	assert_true(save_data.has("board_manager"))

	# 6. Reset and restore
	GameManager.new_game()
	BoardManager.reset()
	assert_eq(BoardManager.get_node_count(), 0)

	GameManager.deserialize(save_data)
	assert_eq(BoardManager.get_node_count(), 3)
	assert_eq(BoardManager.get_connection_count(), 2)

	# 7. Verify node data preserved
	var glass_node: Dictionary = BoardManager.get_board_node(n_glass["id"])
	assert_eq(glass_node["note"], "Julia's fingerprints")

	# 8. Verify connection data preserved
	var julia_conns: Array[Dictionary] = BoardManager.get_connections_for_node(n_julia["id"])
	assert_eq(julia_conns.size(), 2)


func test_board_state_survives_game_manager_round_trip() -> void:
	BoardManager.add_node("evidence", "ev_glass", 150.5, 250.7, "test note")
	var n1: Dictionary = BoardManager.add_node("person", "p_julia", 400.0, 300.0)
	var n2: Dictionary = BoardManager.get_all_nodes()[0]
	BoardManager.add_connection(n2["id"], n1["id"], "linked")

	var save_data: Dictionary = GameManager.serialize()
	GameManager.new_game()
	GameManager.deserialize(save_data)

	assert_eq(BoardManager.get_node_count(), 2)
	assert_eq(BoardManager.get_connection_count(), 1)
	var nodes: Array[Dictionary] = BoardManager.get_nodes_by_type("evidence")
	assert_eq(nodes[0]["x"], 150.5)
	assert_eq(nodes[0]["note"], "test note")
