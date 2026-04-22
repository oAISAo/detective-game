## test_location_investigation_manager.gd
## Unit tests for the LocationInvestigationManager autoload singleton.
## Phase 6: Verify object investigation, state transitions, tool usage,
## location visits, completion tracking, and serialization.
extends GutTest


## Path to the test case JSON file.
const TEST_CASE_FILE: String = "test_location_inv.json"

## Test case data with locations, investigable objects, and evidence.
var _test_case_data: Dictionary = {
	"id": "case_loc_inv_test",
	"title": "Location Investigation Test Case",
	"description": "Test for Phase 6 location investigation.",
	"start_day": 1,
	"end_day": 4,
	"persons": [
		{
			"id": "p_victim",
			"name": "Daniel Whitfield",
			"role": "VICTIM",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 0,
		},
	],
	"evidence": [
		{
			"id": "ev_prints",
			"name": "Fingerprints on Glass",
			"description": "Latent fingerprints found on a wine glass.",
			"type": "FORENSIC",
			"discovery_method": "TOOL",
			"location_found": "loc_apt",
			"related_persons": [],
			"tags": ["fingerprint"],
			"weight": 0.8,
			"importance_level": "CRITICAL",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_note",
			"name": "Handwritten Note",
			"description": "A note found on the desk.",
			"type": "DOCUMENT",
			"location_found": "loc_apt",
			"related_persons": [],
			"tags": ["note"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
			"legal_categories": [],
		},
		{
			"id": "ev_stain",
			"name": "Chemical Stain",
			"description": "A chemical residue found on the counter.",
			"type": "FORENSIC",
			"discovery_method": "TOOL",
			"location_found": "loc_apt",
			"related_persons": [],
			"tags": ["chemical"],
			"weight": 0.7,
			"importance_level": "CRITICAL",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_camera",
			"name": "Security Camera Footage",
			"description": "Footage from the hallway camera.",
			"type": "RECORDING",
			"location_found": "loc_hallway",
			"related_persons": [],
			"tags": ["video"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
			"legal_categories": ["PRESENCE"],
		},
	],
	"statements": [],
	"events": [],
	"locations": [
		{
			"id": "loc_apt",
			"name": "Victim's Apartment",
			"description": "A small apartment where the victim lived.",
			"searchable": true,
			"investigable_objects": [
				{
					"id": "obj_glass",
					"name": "Wine Glass",
					"description": "A wine glass on the kitchen counter.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": ["fingerprint_powder"],
					"evidence_results": ["ev_prints"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_desk",
					"name": "Writing Desk",
					"description": "A cluttered desk in the living room.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["ev_note"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_counter",
					"name": "Kitchen Counter",
					"description": "A large stone counter with various stains.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": ["chemical_test"],
					"evidence_results": ["ev_stain"],
					"investigation_state": "NOT_INSPECTED",
				},
			],
			"evidence_pool": ["ev_prints", "ev_note", "ev_stain"],
		},
		{
			"id": "loc_hallway",
			"name": "Building Hallway",
			"description": "The corridor outside the apartment.",
			"searchable": true,
			"investigable_objects": [
				{
					"id": "obj_camera",
					"name": "Security Camera",
					"description": "A camera mounted on the ceiling.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["ev_camera"],
					"investigation_state": "NOT_INSPECTED",
				},
			],
			"evidence_pool": ["ev_camera"],
		},
	],
	"event_triggers": [],
	"interrogation_topics": [],
	"actions": [],
	"insights": [],
}

var _loc_inv_mgr: Node = null
var _tool_mgr: Node = null


# --- Setup / Teardown --- #

func before_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	var dir: DirAccess = DirAccess.open("res://data/cases")
	if dir == null:
		DirAccess.make_dir_recursive_absolute("res://data/cases")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_test_case_data, "\t"))
	file.close()


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case(TEST_CASE_FILE)
	_loc_inv_mgr = get_node_or_null("/root/LocationInvestigationManager")
	_tool_mgr = get_node_or_null("/root/ToolManager")
	if _loc_inv_mgr:
		_loc_inv_mgr.reset()
	if _tool_mgr:
		_tool_mgr.reset()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


# --- Location Visit Tests --- #

func test_first_visit_is_free() -> void:
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY)
	var result: Dictionary = _loc_inv_mgr.start_investigation("loc_apt")
	assert_true(result.get("success", false), "First visit should succeed")
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY, "Location entry should be free")
	assert_true(GameManager.has_visited_location("loc_apt"))


func test_first_visit_with_no_actions_still_succeeds() -> void:
	GameManager.actions_remaining = 0
	var result: Dictionary = _loc_inv_mgr.start_investigation("loc_apt")
	assert_true(result.get("success", false), "Location entry should succeed even when no actions remain")
	assert_true(GameManager.has_visited_location("loc_apt"))


func test_new_location_visit_with_no_actions_still_succeeds() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.leave_location()
	GameManager.actions_remaining = 0
	var result: Dictionary = _loc_inv_mgr.start_investigation("loc_hallway")
	assert_true(result.get("success", false), "New location visit should stay free")
	assert_true(GameManager.has_visited_location("loc_hallway"))


func test_return_visit_is_free() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.leave_location()
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY)
	var result: Dictionary = _loc_inv_mgr.start_investigation("loc_apt")
	assert_true(result.get("success", false))
	assert_eq(GameManager.actions_remaining, GameManager.ACTIONS_PER_DAY, "Return visit should be free")


func test_return_visit_with_no_actions_still_succeeds() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.leave_location()
	GameManager.actions_remaining = 0
	var result: Dictionary = _loc_inv_mgr.start_investigation("loc_apt")
	assert_true(result.get("success", false), "Revisits should remain free")


func test_invalid_location_fails() -> void:
	var result: Dictionary = _loc_inv_mgr.start_investigation("loc_nonexistent")
	assert_false(result.get("success", true))
	assert_push_error("Unknown location: loc_nonexistent")


func test_start_investigation_returns_free_entry_context() -> void:
	GameManager.actions_remaining = 0
	var result: Dictionary = _loc_inv_mgr.start_investigation("loc_apt")
	assert_true(result.get("success", false), "Free entry should succeed with no actions")
	assert_eq(
		result.get("error_code", ""),
		LocationInvestigationManager.START_ERROR_NONE
	)
	assert_eq(
		result.get("error_message", ""),
		""
	)
	assert_true(result.get("is_first_visit", false))


func test_start_investigation_invalid_location_has_structured_error() -> void:
	var result: Dictionary = _loc_inv_mgr.start_investigation("loc_nonexistent")
	assert_push_error("Unknown location: loc_nonexistent")
	assert_false(result.get("success", true))
	assert_eq(
		result.get("error_code", ""),
		LocationInvestigationManager.START_ERROR_UNKNOWN_LOCATION
	)
	assert_eq(
		result.get("error_message", ""),
		LocationInvestigationManager.START_ERROR_MESSAGE_UNKNOWN_LOCATION
	)


func test_investigation_started_signal() -> void:
	watch_signals(_loc_inv_mgr)
	_loc_inv_mgr.start_investigation("loc_apt")
	assert_signal_emitted_with_parameters(
		_loc_inv_mgr, "investigation_started", ["loc_apt", true]
	)


func test_return_visit_signal_shows_not_first() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.leave_location()
	watch_signals(_loc_inv_mgr)
	_loc_inv_mgr.start_investigation("loc_apt")
	assert_signal_emitted_with_parameters(
		_loc_inv_mgr, "investigation_started", ["loc_apt", false]
	)


func test_leave_location() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	assert_true(_loc_inv_mgr.is_at_location())
	_loc_inv_mgr.leave_location()
	assert_false(_loc_inv_mgr.is_at_location())
	assert_eq(_loc_inv_mgr.current_location_id, "")


# --- Object State Tests --- #

func test_initial_state_not_inspected() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	var state: Enums.InvestigationState = _loc_inv_mgr.get_object_state("loc_apt", "obj_glass")
	assert_eq(state, Enums.InvestigationState.NOT_INSPECTED)


func test_visual_inspection_changes_state_to_fully_examined() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.inspect_object("loc_apt", "obj_glass")
	var state: Enums.InvestigationState = _loc_inv_mgr.get_object_state("loc_apt", "obj_glass")
	# In the map tab, tool requirements are ignored. Only visual_inspection matters.
	# obj_glass has visual_inspection in available_actions, so after inspection it's FULLY_EXAMINED
	assert_eq(state, Enums.InvestigationState.FULLY_EXAMINED)


func test_full_examination_after_all_actions() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	# obj_desk has only visual_inspection with no tool requirements
	_loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	var state: Enums.InvestigationState = _loc_inv_mgr.get_object_state("loc_apt", "obj_desk")
	assert_eq(state, Enums.InvestigationState.FULLY_EXAMINED)


func test_state_change_signal() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	watch_signals(_loc_inv_mgr)
	_loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	assert_signal_emitted(_loc_inv_mgr, "object_state_changed")


# --- Visual Inspection Tests --- #

func test_inspect_object_discovers_evidence_no_tools() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	var before: int = GameManager.actions_remaining
	# obj_desk has visual_inspection, no tool_requirements, evidence: ev_note
	var discovered: Array[String] = _loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	assert_eq(discovered.size(), 1)
	assert_has(discovered, "ev_note")
	assert_true(GameManager.has_evidence("ev_note"))
	assert_eq(GameManager.actions_remaining, before - 1, "Inspection should spend one action")


func test_inspect_object_with_tool_requirements_discovers_no_visual_evidence() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	var before: int = GameManager.actions_remaining
	# obj_glass has visual_inspection + tool_requirements; evidence is TOOL-method only
	var discovered: Array[String] = _loc_inv_mgr.inspect_object("loc_apt", "obj_glass")
	assert_eq(discovered.size(), 0, "Visual inspection should not discover TOOL-method evidence")
	assert_eq(GameManager.actions_remaining, before - 1, "Inspection should spend one action even when no evidence is found")


func test_inspect_twice_returns_empty() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	var before: int = GameManager.actions_remaining
	_loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	var second: Array[String] = _loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	assert_eq(second.size(), 0, "Second inspection should return nothing")
	assert_eq(GameManager.actions_remaining, before - 1, "Repeated inspection should not spend another action")


func test_inspect_without_actions_returns_empty() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	GameManager.actions_remaining = 0
	var discovered: Array[String] = _loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	assert_eq(discovered.size(), 0)
	assert_false(GameManager.has_evidence("ev_note"), "Inspection should not discover evidence with no actions")
	assert_push_warning("[LocationInvestigationManager] No actions remaining for inspection.")


func test_inspect_emits_evidence_found() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	watch_signals(_loc_inv_mgr)
	_loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	assert_signal_emitted_with_parameters(
		_loc_inv_mgr, "evidence_found", ["ev_note", "obj_desk", "visual_inspection"]
	)


func test_inspect_invalid_object_returns_empty() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	var discovered: Array[String] = _loc_inv_mgr.inspect_object("loc_apt", "obj_nonexistent")
	assert_eq(discovered.size(), 0)
	assert_push_error("Unknown object")



# --- Performed Actions Tests --- #

func test_performed_actions_tracked() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	var actions: Array = _loc_inv_mgr.get_performed_actions("loc_apt", "obj_desk")
	assert_eq(actions.size(), 1)
	assert_has(actions, "visual_inspection")


# --- Location Completion Tests --- #

func test_completion_initially_zero() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	var completion: Dictionary = _loc_inv_mgr.get_location_completion("loc_apt")
	assert_eq(completion["found"], 0)
	assert_eq(completion["total"], 3, "loc_apt has 3 evidence items total")


func test_completion_increases_with_discovery() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	var completion: Dictionary = _loc_inv_mgr.get_location_completion("loc_apt")
	assert_eq(completion["found"], 1)
	assert_eq(completion["total"], 3)


func test_is_location_complete_false_when_partial() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	assert_false(_loc_inv_mgr.is_location_complete("loc_apt"))


func test_completion_invalid_location() -> void:
	var completion: Dictionary = _loc_inv_mgr.get_location_completion("nonexistent")
	assert_eq(completion["found"], 0)
	assert_eq(completion["total"], 0)


func test_location_card_status_not_visited_is_new() -> void:
	var status: int = _loc_inv_mgr.get_location_card_status("loc_apt")
	assert_eq(status, LocationInvestigationManager.MapCardStatus.NEW)
	assert_eq(
		_loc_inv_mgr.get_location_status("loc_apt"),
		LocationInvestigationManager.LOCATION_STATUS_NEW
	)


func test_location_card_status_active_visit_is_open() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.leave_location()
	var status: int = _loc_inv_mgr.get_location_card_status("loc_apt")
	assert_eq(status, LocationInvestigationManager.MapCardStatus.OPEN)
	assert_eq(
		_loc_inv_mgr.get_location_status("loc_apt"),
		LocationInvestigationManager.LOCATION_STATUS_OPEN
	)


func test_examined_object_count() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	var counts: Dictionary = _loc_inv_mgr.get_examined_object_count("loc_apt")
	assert_eq(counts["examined"], 1)
	assert_eq(counts["total"], 3)


# --- Debug Tools Tests --- #

func test_debug_examine_all() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.debug_examine_all("loc_apt")
	assert_eq(
		_loc_inv_mgr.get_object_state("loc_apt", "obj_glass"),
		Enums.InvestigationState.FULLY_EXAMINED
	)
	assert_eq(
		_loc_inv_mgr.get_object_state("loc_apt", "obj_desk"),
		Enums.InvestigationState.FULLY_EXAMINED
	)
	assert_true(GameManager.has_evidence("ev_prints"))
	assert_true(GameManager.has_evidence("ev_note"))
	assert_true(GameManager.has_evidence("ev_stain"))


func test_debug_reveal_evidence() -> void:
	_loc_inv_mgr.debug_reveal_all_evidence("loc_apt")
	assert_true(GameManager.has_evidence("ev_prints"))
	assert_true(GameManager.has_evidence("ev_note"))
	assert_true(GameManager.has_evidence("ev_stain"))


# --- Serialization Tests --- #

func test_serialize_captures_state() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	var data: Dictionary = _loc_inv_mgr.serialize()
	assert_true(data.has("object_states"))
	assert_true(data.has("performed_actions"))
	assert_true(data.has("current_location_id"))
	assert_eq(data["current_location_id"], "loc_apt")


func test_deserialize_restores_state() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	var saved: Dictionary = _loc_inv_mgr.serialize()
	_loc_inv_mgr.reset()
	assert_eq(_loc_inv_mgr.current_location_id, "")
	_loc_inv_mgr.deserialize(saved)
	assert_eq(_loc_inv_mgr.current_location_id, "loc_apt")
	assert_eq(
		_loc_inv_mgr.get_object_state("loc_apt", "obj_desk"),
		Enums.InvestigationState.FULLY_EXAMINED
	)


func test_reset_clears_state() -> void:
	_loc_inv_mgr.start_investigation("loc_apt")
	_loc_inv_mgr.inspect_object("loc_apt", "obj_desk")
	_loc_inv_mgr.reset()
	assert_eq(_loc_inv_mgr.current_location_id, "")
	# After reset, state should be NOT_INSPECTED (will re-initialize)
	_loc_inv_mgr.start_investigation("loc_apt")
	assert_eq(
		_loc_inv_mgr.get_object_state("loc_apt", "obj_desk"),
		Enums.InvestigationState.NOT_INSPECTED
	)
