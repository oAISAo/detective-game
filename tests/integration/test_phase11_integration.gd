## test_phase11_integration.gd
## Integration tests for Phase 11 — Lab, Surveillance & Warrant Systems.
## Tests cross-system interactions: lab → evidence discovery, surveillance → tracking,
## warrant → evidence gating, arrest → warrant chain.
extends GutTest


const TEST_CASE_FILE: String = "test_case_phase11.json"

var _test_case_data: Dictionary = {
	"id": "case_phase11",
	"title": "Phase 11 Integration",
	"description": "Tests lab, surveillance, and warrant integration.",
	"start_day": 1,
	"end_day": 10,
	"persons": [
		{
			"id": "p_victim",
			"name": "Daniel",
			"role": "VICTIM",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 0,
		},
		{
			"id": "p_mark",
			"name": "Mark Bennett",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 3,
		},
		{
			"id": "p_julia",
			"name": "Julia Ross",
			"role": "SUSPECT",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 5,
		},
	],
	"evidence": [
		{
			"id": "ev_knife",
			"name": "Kitchen Knife",
			"description": "Found at scene.",
			"type": "PHYSICAL",
			"location_found": "loc_scene",
			"related_persons": ["p_mark"],
			"weight": 0.8,
			"importance_level": "KEY",
			"legal_categories": ["PRESENCE"],
		},
		{
			"id": "ev_knife_dna",
			"name": "Knife DNA Result",
			"description": "DNA analysis of knife.",
			"type": "FORENSIC",
			"location_found": "lab",
			"related_persons": ["p_mark"],
			"weight": 0.9,
			"importance_level": "KEY",
			"legal_categories": ["CONNECTION"],
		},
		{
			"id": "ev_motive_doc",
			"name": "Insurance Document",
			"description": "Shows financial motive.",
			"type": "DOCUMENT",
			"location_found": "loc_office",
			"related_persons": ["p_mark"],
			"weight": 0.7,
			"importance_level": "KEY",
			"legal_categories": ["MOTIVE"],
		},
		{
			"id": "ev_opportunity",
			"name": "Key Access",
			"description": "Had access to building.",
			"type": "PHYSICAL",
			"location_found": "loc_scene",
			"related_persons": ["p_mark"],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
			"legal_categories": ["OPPORTUNITY"],
		},
		{
			"id": "ev_blood",
			"name": "Blood Sample",
			"description": "On floor.",
			"type": "PHYSICAL",
			"location_found": "loc_scene",
			"related_persons": [],
			"weight": 0.7,
			"importance_level": "SUPPORTING",
			"legal_categories": [],
		},
		{
			"id": "ev_blood_result",
			"name": "Blood DNA",
			"description": "Lab result.",
			"type": "FORENSIC",
			"location_found": "lab",
			"related_persons": ["p_mark"],
			"weight": 0.9,
			"importance_level": "KEY",
			"legal_categories": ["PRESENCE", "CONNECTION"],
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
# Lab → Evidence Discovery
# =========================================================================

func test_lab_completion_discovers_evidence() -> void:
	GameManager.discover_evidence("ev_knife")
	LabManager.submit_request("ev_knife", "dna_analysis", "ev_knife_dna")
	assert_false(GameManager.has_evidence("ev_knife_dna"), "Output not yet discovered")
	LabManager.complete_all_instantly()
	assert_true(GameManager.has_evidence("ev_knife_dna"), "Output discovered after completion")


func test_lab_completion_output_usable_for_warrants() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_motive_doc")
	LabManager.submit_request("ev_knife", "dna_analysis", "ev_knife_dna")
	LabManager.complete_all_instantly()

	# ev_knife has PRESENCE, ev_knife_dna has CONNECTION, ev_motive_doc has MOTIVE
	var ids: Array[String] = ["ev_knife", "ev_knife_dna", "ev_motive_doc"]
	assert_eq(WarrantManager.get_category_count(ids), 3)
	assert_true(WarrantManager.can_approve_warrant(Enums.WarrantType.ARREST, ids))


func test_multiple_lab_requests_sequential() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_blood")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_dna")
	LabManager.submit_request("ev_blood", "dna", "ev_blood_result")
	assert_eq(LabManager.get_pending_count(), 2)
	LabManager.complete_all_instantly()
	assert_eq(LabManager.get_completed_requests().size(), 2)
	assert_true(GameManager.has_evidence("ev_knife_dna"))
	assert_true(GameManager.has_evidence("ev_blood_result"))


# =========================================================================
# Surveillance → Tracking
# =========================================================================

func test_surveillance_tracks_person() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	assert_true(SurveillanceManager.is_person_under_surveillance("p_mark"))
	assert_false(SurveillanceManager.is_person_under_surveillance("p_julia"))


func test_surveillance_expiry_clears_tracking() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	SurveillanceManager.complete_all_instantly()
	assert_false(SurveillanceManager.is_person_under_surveillance("p_mark"))


func test_surveillance_after_expiry_allows_reinstall() -> void:
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP
	)
	SurveillanceManager.complete_all_instantly()
	# After expiry, person is no longer under surveillance — can reinstall
	var op2: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.HOME_SURVEILLANCE
	)
	assert_false(op2.is_empty(), "Should allow reinstall after expiry")


# =========================================================================
# Warrant → Evidence Gating
# =========================================================================

func test_warrant_requires_sufficient_categories() -> void:
	# 1 category = denied
	var ids1: Array[String] = ["ev_knife"]
	assert_false(WarrantManager.can_approve_warrant(Enums.WarrantType.SEARCH, ids1))

	# 2 categories = approved
	var ids2: Array[String] = ["ev_knife", "ev_motive_doc"]
	assert_true(WarrantManager.can_approve_warrant(Enums.WarrantType.SEARCH, ids2))


func test_warrant_judge_feedback_quality() -> void:
	var ids: Array[String] = ["ev_knife"]
	var feedback: String = WarrantManager.get_judge_feedback(Enums.WarrantType.SEARCH, ids)
	# Should mention missing categories
	assert_true(feedback.length() > 10, "Feedback should be substantive")
	assert_true(
		feedback.contains("Motive") or feedback.contains("Opportunity") or feedback.contains("Connection"),
		"Should suggest specific missing categories"
	)


func test_denied_warrant_records_history() -> void:
	var ids: Array[String] = ["ev_knife"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)
	assert_eq(WarrantManager.get_denied_warrants().size(), 1)
	assert_eq(WarrantManager.get_approved_warrants().size(), 0)


# =========================================================================
# Arrest Mechanics
# =========================================================================

func test_arrest_requires_three_categories() -> void:
	# 2 categories = insufficient
	var ids2: Array[String] = ["ev_knife", "ev_motive_doc"]
	var result: Dictionary = WarrantManager.arrest_suspect("p_mark", ids2)
	assert_false(result["success"])
	assert_false(WarrantManager.is_arrested("p_mark"))

	# 3 categories = sufficient
	var ids3: Array[String] = ["ev_knife", "ev_motive_doc", "ev_opportunity"]
	result = WarrantManager.arrest_suspect("p_mark", ids3)
	assert_true(result["success"])
	assert_true(WarrantManager.is_arrested("p_mark"))


func test_arrest_creates_warrant_record() -> void:
	var ids: Array[String] = ["ev_knife", "ev_motive_doc", "ev_opportunity"]
	WarrantManager.arrest_suspect("p_mark", ids)
	# arrest_suspect internally calls request_warrant(ARREST, ...)
	var approved: Array[Dictionary] = WarrantManager.get_approved_warrants()
	assert_true(approved.size() >= 1, "Arrest should create warrant record")


# =========================================================================
# Cross-System: Lab → Warrant → Arrest
# =========================================================================

func test_lab_evidence_enables_arrest() -> void:
	# Start: evidence with only PRESENCE category
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_motive_doc")

	# 2 categories so far: PRESENCE + MOTIVE — not enough for arrest
	var ids_before: Array[String] = ["ev_knife", "ev_motive_doc"]
	assert_false(WarrantManager.can_approve_warrant(Enums.WarrantType.ARREST, ids_before))

	# Submit knife to lab, get DNA result (adds CONNECTION category)
	LabManager.submit_request("ev_knife", "dna", "ev_knife_dna")
	LabManager.complete_all_instantly()

	# Now have 3 categories: PRESENCE + MOTIVE + CONNECTION
	var ids_after: Array[String] = ["ev_knife", "ev_motive_doc", "ev_knife_dna"]
	assert_true(WarrantManager.can_approve_warrant(Enums.WarrantType.ARREST, ids_after))

	# Arrest should succeed
	var result: Dictionary = WarrantManager.arrest_suspect("p_mark", ids_after)
	assert_true(result["success"], "Lab evidence should enable arrest")


# =========================================================================
# All Three Managers Coexist
# =========================================================================

func test_all_managers_reset_independently() -> void:
	GameManager.discover_evidence("ev_knife")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_dna")
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	var ids: Array[String] = ["ev_knife", "ev_motive_doc"]
	WarrantManager.request_warrant(Enums.WarrantType.SEARCH, "p_mark", ids)

	LabManager.reset()
	assert_eq(LabManager.get_request_count(), 0)
	assert_true(SurveillanceManager.has_content(), "SurveillanceManager unaffected")
	assert_true(WarrantManager.has_content(), "WarrantManager unaffected")


func test_all_managers_serialize_independently() -> void:
	GameManager.discover_evidence("ev_knife")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_dna")
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)

	var lab_data: Dictionary = LabManager.serialize()
	var surv_data: Dictionary = SurveillanceManager.serialize()

	LabManager.reset()
	SurveillanceManager.reset()
	LabManager.deserialize(lab_data)
	SurveillanceManager.deserialize(surv_data)

	assert_eq(LabManager.get_request_count(), 1)
	assert_eq(SurveillanceManager.get_operation_count(), 1)


# =========================================================================
# Screen Registration
# =========================================================================

func test_phase11_screens_registered() -> void:
	var screens: Dictionary = ScreenManager.SCREEN_SCENES
	assert_has(screens, "lab_queue", "lab_queue screen should be registered")
	assert_has(screens, "surveillance_panel", "surveillance_panel screen should be registered")
	assert_has(screens, "warrant_office", "warrant_office screen should be registered")
	assert_eq(screens.size(), 16, "Should now have 16 screens total")
