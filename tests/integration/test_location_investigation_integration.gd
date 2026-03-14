## test_location_investigation_integration.gd
## Integration tests for the Phase 6 location investigation system.
## Verifies LocationInvestigationManager, ToolManager, GameManager, CaseManager,
## and EvidenceManager working together for the full evidence discovery flow.
extends GutTest


## Test case file for location investigation integration.
const TEST_CASE_FILE: String = "test_loc_inv_integration.json"

## Comprehensive test case with 5 locations and ~20 investigable objects
## matching the Phase 6 prototype specification.
var _test_case_data: Dictionary = {
	"id": "case_loc_integration",
	"title": "Location Investigation Integration Test",
	"description": "Full prototype test with 5 locations.",
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
		{
			"id": "p_julia",
			"name": "Julia Ross",
			"role": "SUSPECT",
			"personality_traits": ["MANIPULATIVE"],
			"relationships": [{"person_b": "p_victim", "type": "SPOUSE"}],
			"pressure_threshold": 5,
		},
		{
			"id": "p_mark",
			"name": "Mark Bennett",
			"role": "SUSPECT",
			"personality_traits": ["ANXIOUS"],
			"relationships": [{"person_b": "p_victim", "type": "COWORKER"}],
			"pressure_threshold": 3,
		},
	],
	"evidence": [
		# Victim's Apartment evidence (E1-E6)
		{
			"id": "E1",
			"name": "Fingerprints on Wine Glass",
			"description": "Julia's prints on the wine glass.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": ["p_julia"],
			"tags": ["fingerprint"],
			"weight": 0.8,
			"importance_level": "CRITICAL",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "E2",
			"name": "Bloodstain on Kitchen Counter",
			"description": "Small drops of blood on the counter.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": [],
			"tags": ["blood"],
			"weight": 0.9,
			"importance_level": "CRITICAL",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "E3",
			"name": "Threatening Letter",
			"description": "Anonymous threatening letter found on desk.",
			"type": "DOCUMENT",
			"location_found": "loc_apartment",
			"related_persons": ["p_victim"],
			"tags": ["letter"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
			"legal_categories": [],
		},
		{
			"id": "E4",
			"name": "Victim's Laptop",
			"description": "Laptop with browsing history.",
			"type": "DIGITAL",
			"location_found": "loc_apartment",
			"related_persons": ["p_victim"],
			"tags": ["digital"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
			"legal_categories": [],
		},
		{
			"id": "E5",
			"name": "Prescription Medication",
			"description": "Sleeping pills found in the bathroom.",
			"type": "OBJECT",
			"location_found": "loc_apartment",
			"related_persons": ["p_victim"],
			"tags": ["medication"],
			"weight": 0.4,
			"importance_level": "OPTIONAL",
			"legal_categories": [],
		},
		{
			"id": "E6",
			"name": "Hidden Key",
			"description": "Key hidden under the doormat.",
			"type": "OBJECT",
			"location_found": "loc_apartment",
			"related_persons": [],
			"tags": ["key"],
			"weight": 0.3,
			"importance_level": "SUPPORTING",
			"legal_categories": ["OPPORTUNITY"],
		},
		# Building Hallway evidence
		{
			"id": "E15",
			"name": "Hallway CCTV Footage",
			"description": "Security footage from the hallway.",
			"type": "RECORDING",
			"location_found": "loc_hallway",
			"related_persons": ["p_julia"],
			"tags": ["video"],
			"weight": 0.7,
			"importance_level": "CRITICAL",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "E16",
			"name": "Muddy Footprints",
			"description": "Boot prints in the hallway.",
			"type": "FORENSIC",
			"location_found": "loc_hallway",
			"related_persons": [],
			"tags": ["footprint"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "E20",
			"name": "Elevator Maintenance Log",
			"description": "Log showing elevator usage timestamps.",
			"type": "DOCUMENT",
			"location_found": "loc_hallway",
			"related_persons": [],
			"tags": ["log"],
			"weight": 0.4,
			"importance_level": "OPTIONAL",
			"legal_categories": [],
		},
		# Parking Lot evidence
		{
			"id": "E14",
			"name": "Parking Camera Footage",
			"description": "Camera showing car arrivals.",
			"type": "RECORDING",
			"location_found": "loc_parking",
			"related_persons": ["p_mark"],
			"tags": ["video", "parking"],
			"weight": 0.6,
			"importance_level": "CRITICAL",
			"legal_categories": ["PRESENCE"],
		},
		# Neighbor's Apartment evidence
		{
			"id": "E17",
			"name": "Neighbor's Statement Recording",
			"description": "Audio recording of neighbor interview.",
			"type": "RECORDING",
			"location_found": "loc_neighbor",
			"related_persons": [],
			"tags": ["audio"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
			"legal_categories": [],
		},
		{
			"id": "E18",
			"name": "Peephole Photo",
			"description": "Photo taken through the neighbor's peephole.",
			"type": "PHOTO",
			"location_found": "loc_neighbor",
			"related_persons": ["p_julia"],
			"tags": ["photo"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
			"legal_categories": ["PRESENCE"],
		},
		# Victim's Office evidence
		{
			"id": "E10",
			"name": "Financial Records",
			"description": "Irregular financial transactions.",
			"type": "FINANCIAL",
			"location_found": "loc_office",
			"related_persons": ["p_mark", "p_victim"],
			"tags": ["financial"],
			"weight": 0.7,
			"importance_level": "CRITICAL",
			"legal_categories": ["MOTIVE"],
		},
		{
			"id": "E12",
			"name": "Office Computer Logs",
			"description": "Access logs from the victim's office computer.",
			"type": "DIGITAL",
			"location_found": "loc_office",
			"related_persons": ["p_victim"],
			"tags": ["digital"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
			"legal_categories": [],
		},
		{
			"id": "E24",
			"name": "Shredded Documents",
			"description": "Partially shredded confidential documents.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": ["p_mark"],
			"tags": ["document", "shredded"],
			"weight": 0.8,
			"importance_level": "CRITICAL",
			"legal_categories": ["MOTIVE"],
		},
		{
			"id": "E25",
			"name": "UV-Revealed Note",
			"description": "Hidden message revealed under UV light.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": ["p_victim"],
			"tags": ["hidden", "uv"],
			"weight": 0.9,
			"importance_level": "CRITICAL",
			"legal_categories": ["CONNECTION"],
		},
	],
	"statements": [],
	"events": [],
	"locations": [
		{
			"id": "loc_apartment",
			"name": "Victim's Apartment",
			"description": "A well-furnished apartment on the 3rd floor.",
			"searchable": true,
			"investigable_objects": [
				{
					"id": "obj_wine_glass",
					"name": "Wine Glass",
					"description": "A wine glass on the kitchen counter with visible residue.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": ["fingerprint_powder"],
					"evidence_results": ["E1"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_kitchen_counter",
					"name": "Kitchen Counter",
					"description": "A marble counter with several stains.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": ["chemical_test"],
					"evidence_results": ["E2"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_desk",
					"name": "Writing Desk",
					"description": "A cluttered desk in the study.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E3"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_laptop",
					"name": "Victim's Laptop",
					"description": "An open laptop on the bedside table.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E4"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_bathroom_cabinet",
					"name": "Bathroom Cabinet",
					"description": "A medicine cabinet in the bathroom.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E5"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_doormat",
					"name": "Doormat",
					"description": "The doormat at the entrance.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E6"],
					"investigation_state": "NOT_INSPECTED",
				},
			],
			"evidence_pool": ["E1", "E2", "E3", "E4", "E5", "E6"],
		},
		{
			"id": "loc_hallway",
			"name": "Building Hallway",
			"description": "The corridor outside the victim's apartment.",
			"searchable": true,
			"investigable_objects": [
				{
					"id": "obj_security_camera",
					"name": "Security Camera",
					"description": "A ceiling-mounted camera near the elevator.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E15"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_hallway_floor",
					"name": "Hallway Floor",
					"description": "Tiled floor near the apartment entrance.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": ["uv_light"],
					"evidence_results": ["E16"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_elevator_panel",
					"name": "Elevator Control Panel",
					"description": "The elevator's internal control and log system.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E20"],
					"investigation_state": "NOT_INSPECTED",
				},
			],
			"evidence_pool": ["E15", "E16", "E20"],
		},
		{
			"id": "loc_parking",
			"name": "Parking Lot",
			"description": "Underground parking beneath the building.",
			"searchable": true,
			"investigable_objects": [
				{
					"id": "obj_parking_camera",
					"name": "Parking Camera",
					"description": "Security camera monitoring the parking entrance.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E14"],
					"investigation_state": "NOT_INSPECTED",
				},
			],
			"evidence_pool": ["E14"],
		},
		{
			"id": "loc_neighbor",
			"name": "Neighbor's Apartment",
			"description": "Mrs. Henderson's apartment, directly across the hall.",
			"searchable": true,
			"investigable_objects": [
				{
					"id": "obj_neighbor_door",
					"name": "Neighbor's Front Door",
					"description": "A door with a peephole facing the victim's apartment.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E17"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_peephole",
					"name": "Peephole Camera",
					"description": "A small camera installed behind the peephole.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E18"],
					"investigation_state": "NOT_INSPECTED",
				},
			],
			"evidence_pool": ["E17", "E18"],
		},
		{
			"id": "loc_office",
			"name": "Victim's Office",
			"description": "The victim's workspace at FinTech Solutions.",
			"searchable": true,
			"investigable_objects": [
				{
					"id": "obj_filing_cabinet",
					"name": "Filing Cabinet",
					"description": "A locked filing cabinet containing financial records.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E10"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_office_computer",
					"name": "Office Computer",
					"description": "The victim's work computer.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E12"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_shredder",
					"name": "Paper Shredder",
					"description": "A shredder with partially shredded documents.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": [],
					"evidence_results": ["E24"],
					"investigation_state": "NOT_INSPECTED",
				},
				{
					"id": "obj_desk_surface",
					"name": "Desk Surface",
					"description": "The wooden desk surface with faint markings.",
					"available_actions": ["visual_inspection"],
					"tool_requirements": ["uv_light"],
					"evidence_results": ["E25"],
					"investigation_state": "NOT_INSPECTED",
				},
			],
			"evidence_pool": ["E10", "E12", "E24", "E25"],
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


# --- Full Evidence Discovery Flow --- #

func test_visit_examine_discover_flow() -> void:
	# Arrive at location
	var result: bool = _loc_inv_mgr.start_investigation("loc_apartment")
	assert_true(result, "Should start investigation")

	# See objects — check they exist
	var location: LocationData = CaseManager.get_location("loc_apartment")
	assert_eq(location.investigable_objects.size(), 6, "Should have 6 objects")

	# Select and inspect an object (desk — no tools needed)
	var discovered: Array[String] = _loc_inv_mgr.inspect_object("loc_apartment", "obj_desk")
	assert_eq(discovered.size(), 1, "Should discover E3")
	assert_has(discovered, "E3")

	# Verify evidence appears in GameManager
	assert_true(GameManager.has_evidence("E3"))


func test_tool_reveals_hidden_evidence() -> void:
	_loc_inv_mgr.start_investigation("loc_apartment")

	# Visual inspection of wine glass — has tool requirement, no evidence from visual
	var visual: Array[String] = _loc_inv_mgr.inspect_object("loc_apartment", "obj_wine_glass")
	assert_eq(visual.size(), 0, "Tool-required evidence not revealed by visual")
	assert_false(GameManager.has_evidence("E1"))

	# Use fingerprint powder on wine glass
	var tool_result: Array[String] = _loc_inv_mgr.use_tool_on_object(
		"loc_apartment", "obj_wine_glass", "fingerprint_powder"
	)
	assert_eq(tool_result.size(), 1, "Tool should reveal E1")
	assert_has(tool_result, "E1")
	assert_true(GameManager.has_evidence("E1"))


func test_full_apartment_investigation_yields_all_evidence() -> void:
	_loc_inv_mgr.start_investigation("loc_apartment")

	# 1. Wine glass — tool-dependent evidence
	_loc_inv_mgr.use_tool_on_object("loc_apartment", "obj_wine_glass", "fingerprint_powder")
	assert_true(GameManager.has_evidence("E1"))

	# 2. Kitchen counter — tool-dependent evidence
	_loc_inv_mgr.use_tool_on_object("loc_apartment", "obj_kitchen_counter", "chemical_test")
	assert_true(GameManager.has_evidence("E2"))

	# 3. Desk — visual inspection
	_loc_inv_mgr.inspect_object("loc_apartment", "obj_desk")
	assert_true(GameManager.has_evidence("E3"))

	# 4. Laptop — visual inspection
	_loc_inv_mgr.inspect_object("loc_apartment", "obj_laptop")
	assert_true(GameManager.has_evidence("E4"))

	# 5. Bathroom cabinet — visual inspection
	_loc_inv_mgr.inspect_object("loc_apartment", "obj_bathroom_cabinet")
	assert_true(GameManager.has_evidence("E5"))

	# 6. Doormat — visual inspection
	_loc_inv_mgr.inspect_object("loc_apartment", "obj_doormat")
	assert_true(GameManager.has_evidence("E6"))

	# Verify completion
	assert_true(_loc_inv_mgr.is_location_complete("loc_apartment"))
	var completion: Dictionary = _loc_inv_mgr.get_location_completion("loc_apartment")
	assert_eq(completion["found"], 6)
	assert_eq(completion["total"], 6)


func test_all_evidence_discoverable_across_locations() -> void:
	var all_evidence: Array[String] = [
		"E1", "E2", "E3", "E4", "E5", "E6",
		"E15", "E16", "E20",
		"E14",
		"E17", "E18",
		"E10", "E12", "E24", "E25",
	]

	# Visit and investigate all 5 locations
	# Location 1: Victim's Apartment
	_loc_inv_mgr.start_investigation("loc_apartment")
	_loc_inv_mgr.use_tool_on_object("loc_apartment", "obj_wine_glass", "fingerprint_powder")
	_loc_inv_mgr.use_tool_on_object("loc_apartment", "obj_kitchen_counter", "chemical_test")
	_loc_inv_mgr.inspect_object("loc_apartment", "obj_desk")
	_loc_inv_mgr.inspect_object("loc_apartment", "obj_laptop")
	_loc_inv_mgr.inspect_object("loc_apartment", "obj_bathroom_cabinet")
	_loc_inv_mgr.inspect_object("loc_apartment", "obj_doormat")
	_loc_inv_mgr.leave_location()

	# Location 2: Building Hallway
	_loc_inv_mgr.start_investigation("loc_hallway")
	_loc_inv_mgr.inspect_object("loc_hallway", "obj_security_camera")
	_loc_inv_mgr.use_tool_on_object("loc_hallway", "obj_hallway_floor", "uv_light")
	_loc_inv_mgr.inspect_object("loc_hallway", "obj_elevator_panel")
	_loc_inv_mgr.leave_location()

	# Need more actions — advance day
	GameManager.advance_time_slot()  # MORNING -> AFTERNOON
	GameManager.advance_time_slot()  # AFTERNOON -> EVENING
	GameManager.advance_time_slot()  # EVENING -> NIGHT
	GameManager.advance_time_slot()  # NIGHT -> next day MORNING
	# New day = new actions

	# Location 3: Parking Lot
	_loc_inv_mgr.start_investigation("loc_parking")
	_loc_inv_mgr.inspect_object("loc_parking", "obj_parking_camera")
	_loc_inv_mgr.leave_location()

	# Location 4: Neighbor's Apartment
	_loc_inv_mgr.start_investigation("loc_neighbor")
	_loc_inv_mgr.inspect_object("loc_neighbor", "obj_neighbor_door")
	_loc_inv_mgr.inspect_object("loc_neighbor", "obj_peephole")
	_loc_inv_mgr.leave_location()

	# Need more actions — advance another day
	GameManager.advance_time_slot()  # MORNING -> AFTERNOON
	GameManager.advance_time_slot()  # AFTERNOON -> EVENING
	GameManager.advance_time_slot()  # EVENING -> NIGHT
	GameManager.advance_time_slot()  # NIGHT -> next day MORNING

	# Location 5: Victim's Office
	_loc_inv_mgr.start_investigation("loc_office")
	_loc_inv_mgr.inspect_object("loc_office", "obj_filing_cabinet")
	_loc_inv_mgr.inspect_object("loc_office", "obj_office_computer")
	_loc_inv_mgr.inspect_object("loc_office", "obj_shredder")
	_loc_inv_mgr.use_tool_on_object("loc_office", "obj_desk_surface", "uv_light")
	_loc_inv_mgr.leave_location()

	# Verify ALL 16 evidence items discovered
	for ev_id: String in all_evidence:
		assert_true(GameManager.has_evidence(ev_id), "Should have discovered %s" % ev_id)


func test_visit_costs_action_economy() -> void:
	# Day 1: 2 actions
	assert_eq(GameManager.actions_remaining, 2)

	_loc_inv_mgr.start_investigation("loc_apartment")
	assert_eq(GameManager.actions_remaining, 1, "1st visit costs 1 action")
	_loc_inv_mgr.leave_location()

	_loc_inv_mgr.start_investigation("loc_hallway")
	assert_eq(GameManager.actions_remaining, 0, "2nd visit costs 1 action")
	_loc_inv_mgr.leave_location()

	# Cannot visit another location
	var result: bool = _loc_inv_mgr.start_investigation("loc_parking")
	assert_false(result, "Should fail — no actions")


func test_quick_revisit_is_free() -> void:
	_loc_inv_mgr.start_investigation("loc_apartment")
	_loc_inv_mgr.leave_location()
	assert_eq(GameManager.actions_remaining, 1)

	# Quick revisit should be free
	var result: bool = _loc_inv_mgr.start_investigation("loc_apartment", false)
	assert_true(result, "Quick revisit should succeed")
	assert_eq(GameManager.actions_remaining, 1, "Quick revisit should be free")


func test_multi_location_state_persistence() -> void:
	# Visit apartment and inspect desk
	_loc_inv_mgr.start_investigation("loc_apartment")
	_loc_inv_mgr.inspect_object("loc_apartment", "obj_desk")
	_loc_inv_mgr.leave_location()

	# Visit hallway and inspect camera
	_loc_inv_mgr.start_investigation("loc_hallway")
	_loc_inv_mgr.inspect_object("loc_hallway", "obj_security_camera")
	_loc_inv_mgr.leave_location()

	# Check both states persisted
	assert_eq(
		_loc_inv_mgr.get_object_state("loc_apartment", "obj_desk"),
		Enums.InvestigationState.FULLY_EXAMINED,
	)
	assert_eq(
		_loc_inv_mgr.get_object_state("loc_hallway", "obj_security_camera"),
		Enums.InvestigationState.FULLY_EXAMINED,
	)

	# Apartment desk still uninspected objects
	assert_eq(
		_loc_inv_mgr.get_object_state("loc_apartment", "obj_wine_glass"),
		Enums.InvestigationState.NOT_INSPECTED,
	)


func test_serialize_and_restore_across_locations() -> void:
	# Do some investigation
	_loc_inv_mgr.start_investigation("loc_apartment")
	_loc_inv_mgr.inspect_object("loc_apartment", "obj_desk")
	_loc_inv_mgr.use_tool_on_object("loc_apartment", "obj_wine_glass", "fingerprint_powder")
	_loc_inv_mgr.leave_location()

	# Serialize everything
	var gm_data: Dictionary = GameManager.serialize()

	# Reset everything
	GameManager.new_game()

	# Restore
	GameManager.deserialize(gm_data)

	# Check state is restored
	assert_true(GameManager.has_evidence("E3"), "Desk evidence should be restored")
	assert_true(GameManager.has_evidence("E1"), "Fingerprint evidence should be restored")

	# Check LocationInvestigationManager state restored
	assert_eq(
		_loc_inv_mgr.get_object_state("loc_apartment", "obj_desk"),
		Enums.InvestigationState.FULLY_EXAMINED,
	)


func test_screen_manager_knows_location_investigation() -> void:
	assert_true(
		ScreenManager.SCREEN_SCENES.has("location_investigation"),
		"ScreenManager should have location_investigation registered"
	)


func test_screen_manager_has_ten_screens() -> void:
	assert_eq(
		ScreenManager.SCREEN_SCENES.size(), 10,
		"Should have 10 screens (9 from Phase 9 + theory_builder)"
	)


func test_autoloads_accessible() -> void:
	var tool_mgr: Node = get_node_or_null("/root/ToolManager")
	var loc_inv_mgr: Node = get_node_or_null("/root/LocationInvestigationManager")
	assert_not_null(tool_mgr, "ToolManager autoload should be accessible")
	assert_not_null(loc_inv_mgr, "LocationInvestigationManager autoload should be accessible")


func test_five_locations_loaded() -> void:
	var locations: Array[LocationData] = CaseManager.get_all_locations()
	assert_eq(locations.size(), 5, "Should have 5 prototype locations")


func test_twenty_objects_total() -> void:
	var total: int = 0
	for loc: LocationData in CaseManager.get_all_locations():
		total += loc.investigable_objects.size()
	# 6 + 3 + 1 + 2 + 4 = 16 objects (matches our test data)
	assert_eq(total, 16, "Should have 16 total investigable objects")
