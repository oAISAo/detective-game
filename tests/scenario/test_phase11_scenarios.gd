## test_phase11_scenarios.gd
## Scenario tests for Phase 11 — Lab, Surveillance & Warrant Systems.
## Tests end-to-end investigation workflows combining all three systems.
extends GutTest


const TEST_CASE_FILE: String = "test_case_phase11_scenario.json"

var _test_case_data: Dictionary = {
	"id": "case_phase11_scenario",
	"title": "Phase 11 Scenario Case",
	"description": "Full investigation flow.",
	"start_day": 1,
	"end_day": 10,
	"persons": [
		{
			"id": "p_victim",
			"name": "Daniel Webb",
			"role": "VICTIM",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 0,
		},
		{
			"id": "p_suspect_a",
			"name": "Alex Turner",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 3,
		},
		{
			"id": "p_suspect_b",
			"name": "Beth Collins",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 5,
		},
	],
	"evidence": [
		{
			"id": "ev_fibers",
			"name": "Clothing Fibers",
			"description": "Found on victim.",
			"type": "PHYSICAL",
			"location_found": "loc_scene",
			"related_persons": [],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
			"legal_categories": [],
		},
		{
			"id": "ev_fiber_match",
			"name": "Fiber Match Report",
			"description": "Lab confirms fibers match suspect A's jacket.",
			"type": "FORENSIC",
			"location_found": "lab",
			"related_persons": ["p_suspect_a"],
			"weight": 0.8,
			"importance_level": "KEY",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_cctv",
			"name": "CCTV Footage",
			"description": "Shows suspect near scene.",
			"type": "DIGITAL",
			"location_found": "loc_scene",
			"related_persons": ["p_suspect_a"],
			"weight": 0.7,
			"importance_level": "KEY",
			"legal_categories": ["PRESENCE", "OPPORTUNITY"],
		},
		{
			"id": "ev_email",
			"name": "Threatening Email",
			"description": "Email from suspect to victim.",
			"type": "DIGITAL",
			"location_found": "loc_office",
			"related_persons": ["p_suspect_a"],
			"weight": 0.8,
			"importance_level": "KEY",
			"legal_categories": ["MOTIVE"],
		},
		{
			"id": "ev_financials",
			"name": "Financial Records",
			"description": "Shows large debts.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": ["p_suspect_a"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
			"legal_categories": ["MOTIVE", "CONNECTION"],
		},
		{
			"id": "ev_phone_log",
			"name": "Phone Call Log",
			"description": "Calls between suspect and victim.",
			"type": "DIGITAL",
			"location_found": "loc_office",
			"related_persons": ["p_suspect_a", "p_suspect_b"],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
			"legal_categories": ["CONNECTION"],
		},
	],
	"statements": [],
	"events": [],
	"locations": [
		{"id": "loc_scene", "name": "Crime Scene", "searchable": true, "evidence_pool": []},
		{"id": "loc_office", "name": "Office", "searchable": true, "evidence_pool": []},
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
	LabManager.reset()
	SurveillanceManager.reset()
	WarrantManager.reset()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Scenario: Full Investigation — From Evidence to Arrest
# =========================================================================

func test_scenario_evidence_to_arrest() -> void:
	# Day 1: Discover initial evidence
	GameManager.discover_evidence("ev_fibers")
	GameManager.discover_evidence("ev_cctv")

	# Submit fibers to lab for analysis
	var lab_req: Dictionary = LabManager.submit_request(
		"ev_fibers", "fiber_analysis", "ev_fiber_match", 2
	)
	assert_false(lab_req.is_empty(), "Lab request should succeed")
	assert_eq(LabManager.get_pending_count(), 1)

	# Set up surveillance on suspect A
	var surv: Dictionary = SurveillanceManager.install_surveillance(
		"p_suspect_a", Enums.SurveillanceType.PHONE_TAP
	)
	assert_false(surv.is_empty(), "Surveillance should succeed")

	# Try search warrant with only CCTV (PRESENCE + OPPORTUNITY = 2 cats) — should succeed
	var search_ids: Array[String] = ["ev_cctv"]
	var search_result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_suspect_a", search_ids
	)
	assert_true(search_result["approved"], "Search warrant should be approved with 2 categories")

	# Try arrest with only CCTV — should fail (need 3 categories)
	var arrest_result: Dictionary = WarrantManager.arrest_suspect(
		"p_suspect_a", search_ids
	)
	assert_false(arrest_result["success"], "Arrest should fail with only 2 categories")

	# Complete lab work (discover fiber match result)
	LabManager.complete_all_instantly()
	assert_true(GameManager.has_evidence("ev_fiber_match"))
	assert_eq(LabManager.get_completed_requests().size(), 1)

	# Discover financial motive
	GameManager.discover_evidence("ev_email")

	# Now try arrest: CCTV (PRESENCE+OPPORTUNITY) + fiber_match (PRESENCE) + email (MOTIVE)
	# Unique categories: PRESENCE, OPPORTUNITY, MOTIVE = 3
	var arrest_ids: Array[String] = ["ev_cctv", "ev_fiber_match", "ev_email"]
	var final_arrest: Dictionary = WarrantManager.arrest_suspect(
		"p_suspect_a", arrest_ids
	)
	assert_true(final_arrest["success"], "Arrest should succeed with 3 categories")
	assert_true(WarrantManager.is_arrested("p_suspect_a"))

	# Clean up surveillance
	SurveillanceManager.complete_all_instantly()
	assert_eq(SurveillanceManager.get_active_count(), 0)


# =========================================================================
# Scenario: Progressive Category Building
# =========================================================================

func test_scenario_progressive_category_building() -> void:
	# Start with weak evidence — build up categories over time
	GameManager.discover_evidence("ev_phone_log")  # CONNECTION only

	# Check with judge — advised to find more
	var feedback: String = WarrantManager.get_judge_feedback(
		Enums.WarrantType.SEARCH,
		["ev_phone_log"]
	)
	assert_true(feedback.contains("one more category"))

	# Discover CCTV (PRESENCE + OPPORTUNITY)
	GameManager.discover_evidence("ev_cctv")

	# Now have CONNECTION + PRESENCE + OPPORTUNITY = 3 categories
	var all_ids: Array[String] = ["ev_phone_log", "ev_cctv"]
	assert_eq(WarrantManager.get_category_count(all_ids), 3)

	# Search warrant now possible (needs 2)
	assert_true(WarrantManager.can_approve_warrant(Enums.WarrantType.SEARCH, all_ids))

	# Arrest also possible (needs 3)
	assert_true(WarrantManager.can_approve_warrant(Enums.WarrantType.ARREST, all_ids))


# =========================================================================
# Scenario: Multiple Suspects Under Investigation
# =========================================================================

func test_scenario_parallel_suspect_investigation() -> void:
	GameManager.discover_evidence("ev_cctv")
	GameManager.discover_evidence("ev_email")
	GameManager.discover_evidence("ev_phone_log")

	# Surveillance both suspects simultaneously (max 2)
	var surv_a: Dictionary = SurveillanceManager.install_surveillance(
		"p_suspect_a", Enums.SurveillanceType.PHONE_TAP
	)
	var surv_b: Dictionary = SurveillanceManager.install_surveillance(
		"p_suspect_b", Enums.SurveillanceType.HOME_SURVEILLANCE
	)
	assert_false(surv_a.is_empty())
	assert_false(surv_b.is_empty())
	assert_eq(SurveillanceManager.get_active_count(), 2)

	# Both under surveillance
	assert_true(SurveillanceManager.is_person_under_surveillance("p_suspect_a"))
	assert_true(SurveillanceManager.is_person_under_surveillance("p_suspect_b"))

	# Arrest suspect A with sufficient evidence
	var arrest_ids: Array[String] = ["ev_cctv", "ev_email", "ev_phone_log"]
	# PRESENCE + OPPORTUNITY + MOTIVE + CONNECTION = 4 categories
	var result: Dictionary = WarrantManager.arrest_suspect("p_suspect_a", arrest_ids)
	assert_true(result["success"])

	# Suspect B still under surveillance
	assert_true(SurveillanceManager.is_person_under_surveillance("p_suspect_b"))
	assert_false(WarrantManager.is_arrested("p_suspect_b"))


# =========================================================================
# Scenario: Lab Capacity Management
# =========================================================================

func test_scenario_lab_capacity_management() -> void:
	GameManager.discover_evidence("ev_fibers")
	GameManager.discover_evidence("ev_cctv")
	GameManager.discover_evidence("ev_email")
	GameManager.discover_evidence("ev_phone_log")

	# Submit up to max concurrent
	LabManager.submit_request("ev_fibers", "fiber", "ev_fiber_match")
	LabManager.submit_request("ev_cctv", "enhance", "ev_cctv")  # same output id is fine
	LabManager.submit_request("ev_email", "decrypt", "ev_email")
	assert_eq(LabManager.get_pending_count(), 3)

	# 4th should be rejected (MAX_CONCURRENT_REQUESTS = 3)
	var reject: Dictionary = LabManager.submit_request("ev_phone_log", "trace", "ev_phone_log")
	assert_true(reject.is_empty())

	# Cancel one, then 4th should succeed
	var pending: Array[Dictionary] = LabManager.get_pending_requests()
	LabManager.cancel_request(pending[0]["id"])
	assert_eq(LabManager.get_pending_count(), 2)

	var retry: Dictionary = LabManager.submit_request("ev_phone_log", "trace", "ev_phone_log")
	assert_false(retry.is_empty(), "Should succeed after cancelling one")


# =========================================================================
# Scenario: Warrant Denial and Retry
# =========================================================================

func test_scenario_warrant_denial_and_retry() -> void:
	GameManager.discover_evidence("ev_fibers")  # No legal categories

	# First attempt: denied (no categories)
	var ids: Array[String] = ["ev_fibers"]
	var result: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_suspect_a", ids
	)
	assert_false(result["approved"])
	assert_eq(WarrantManager.get_denied_warrants().size(), 1)

	# Discover more evidence
	GameManager.discover_evidence("ev_cctv")  # PRESENCE + OPPORTUNITY

	# Second attempt: approved (2 categories)
	var ids2: Array[String] = ["ev_cctv"]
	var result2: Dictionary = WarrantManager.request_warrant(
		Enums.WarrantType.SEARCH, "p_suspect_a", ids2
	)
	assert_true(result2["approved"])
	assert_eq(WarrantManager.get_approved_warrants().size(), 1)
	assert_eq(WarrantManager.get_denied_warrants().size(), 1)  # First denial still recorded


# =========================================================================
# Scenario: Full State Persistence
# =========================================================================

func test_scenario_state_persistence() -> void:
	# Set up state across all three managers
	GameManager.discover_evidence("ev_fibers")
	GameManager.discover_evidence("ev_cctv")
	GameManager.discover_evidence("ev_email")

	LabManager.submit_request("ev_fibers", "fiber", "ev_fiber_match")
	SurveillanceManager.install_surveillance("p_suspect_a", Enums.SurveillanceType.PHONE_TAP)

	var w_ids: Array[String] = ["ev_cctv", "ev_email"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_suspect_a", w_ids)

	# Serialize all
	var lab_data: Dictionary = LabManager.serialize()
	var surv_data: Dictionary = SurveillanceManager.serialize()
	var warrant_data: Dictionary = WarrantManager.serialize()

	# Reset all
	LabManager.reset()
	SurveillanceManager.reset()
	WarrantManager.reset()

	# Verify clean state
	assert_false(LabManager.has_content())
	assert_false(SurveillanceManager.has_content())
	assert_false(WarrantManager.has_content())

	# Restore all
	LabManager.deserialize(lab_data)
	SurveillanceManager.deserialize(surv_data)
	WarrantManager.deserialize(warrant_data)

	# Verify restored state
	assert_eq(LabManager.get_pending_count(), 1)
	assert_eq(SurveillanceManager.get_active_count(), 1)
	assert_eq(WarrantManager.get_approved_warrants().size(), 1)
