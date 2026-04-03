## test_lab_manager.gd
## Unit tests for the LabManager autoload.
## Tests submit, cancel, query, concurrent limits, completion, serialization.
extends GutTest


const TEST_CASE_FILE: String = "test_case_lab.json"

var _test_case_data: Dictionary = {
	"id": "case_lab_test",
	"title": "Lab Test Case",
	"description": "Tests lab manager.",
	"start_day": 1,
	"end_day": 5,
	"persons": [
		{
			"id": "p_victim",
			"name": "Daniel",
			"role": "VICTIM",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 0,
		},
	],
	"evidence": [
		{
			"id": "ev_knife",
			"name": "Kitchen Knife",
			"description": "Found in sink.",
			"type": "PHYSICAL",
			"location_found": "loc_apartment",
			"related_persons": [],
			"weight": 0.8,
			"importance_level": "KEY",
		},
		{
			"id": "ev_prints",
			"name": "Fingerprints",
			"description": "On door handle.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": [],
			"weight": 0.6,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_blood",
			"name": "Blood Sample",
			"description": "On floor.",
			"type": "PHYSICAL",
			"location_found": "loc_apartment",
			"related_persons": [],
			"weight": 0.7,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_fiber",
			"name": "Fiber Sample",
			"description": "On victim.",
			"type": "PHYSICAL",
			"location_found": "loc_apartment",
			"related_persons": [],
			"weight": 0.5,
			"importance_level": "SUPPORTING",
		},
		{
			"id": "ev_knife_result",
			"name": "Knife Analysis",
			"description": "Lab result from knife.",
			"type": "FORENSIC",
			"location_found": "lab",
			"related_persons": [],
			"weight": 0.9,
			"importance_level": "KEY",
		},
		{
			"id": "ev_prints_result",
			"name": "Prints Match",
			"description": "Lab result from prints.",
			"type": "FORENSIC",
			"location_found": "lab",
			"related_persons": [],
			"weight": 0.9,
			"importance_level": "KEY",
		},
		{
			"id": "ev_blood_result",
			"name": "Blood DNA",
			"description": "Lab result from blood.",
			"type": "FORENSIC",
			"location_found": "lab",
			"related_persons": [],
			"weight": 0.9,
			"importance_level": "KEY",
		},
		{
			"id": "ev_fiber_result",
			"name": "Fiber Match",
			"description": "Lab result from fiber.",
			"type": "FORENSIC",
			"location_found": "lab",
			"related_persons": [],
			"weight": 0.8,
			"importance_level": "SUPPORTING",
		},
	],
	"statements": [],
	"events": [],
	"locations": [
		{"id": "loc_apartment", "name": "Apartment", "searchable": true, "evidence_pool": []},
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


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Submit
# =========================================================================

func test_submit_request_returns_data() -> void:
	GameManager.discover_evidence("ev_knife")
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna_analysis", "ev_knife_result")
	assert_false(req.is_empty(), "Should return request data")
	assert_true(req["id"].begins_with("lab_"))
	assert_eq(req["input_evidence_id"], "ev_knife")
	assert_eq(req["analysis_type"], "dna_analysis")
	assert_eq(req["output_evidence_id"], "ev_knife_result")
	assert_eq(req["status"], "pending")


func test_submit_emits_signal() -> void:
	GameManager.discover_evidence("ev_knife")
	watch_signals(LabManager)
	LabManager.submit_request("ev_knife", "dna_analysis", "ev_knife_result")
	assert_signal_emitted(LabManager, "lab_submitted")


func test_submit_increments_pending_count() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_prints")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	LabManager.submit_request("ev_prints", "fingerprint", "ev_prints_result")
	assert_eq(LabManager.get_pending_count(), 2)


func test_submit_sets_completion_day() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.current_day = 3
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result", 2)
	assert_eq(req["completion_day"], 5, "completion_day = current_day + processing_days")


func test_submit_default_processing_days() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.current_day = 1
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	assert_eq(req["completion_day"], 2, "Default: 1 day processing")


func test_submit_rejects_undiscovered_evidence() -> void:
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	assert_true(req.is_empty(), "Should reject undiscovered evidence")
	assert_eq(LabManager.get_pending_count(), 0)
	assert_push_error("[LabManager] Evidence not discovered: ev_knife")


func test_submit_rejects_already_submitted() -> void:
	GameManager.discover_evidence("ev_knife")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	var dup: Dictionary = LabManager.submit_request("ev_knife", "other", "ev_knife_result")
	assert_true(dup.is_empty(), "Should reject duplicate submission")
	assert_push_warning("[LabManager] Evidence already submitted for analysis: ev_knife")
	assert_eq(LabManager.get_pending_count(), 1)


func test_submit_respects_concurrent_limit() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_prints")
	GameManager.discover_evidence("ev_blood")
	GameManager.discover_evidence("ev_fiber")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	LabManager.submit_request("ev_prints", "fingerprint", "ev_prints_result")
	LabManager.submit_request("ev_blood", "dna", "ev_blood_result")
	var fourth: Dictionary = LabManager.submit_request("ev_fiber", "fiber", "ev_fiber_result")
	assert_true(fourth.is_empty(), "Should reject when at max concurrent (%d)" % LabManager.MAX_CONCURRENT_REQUESTS)
	assert_push_warning("[LabManager] Maximum concurrent requests reached")
	assert_eq(LabManager.get_pending_count(), 3)


func test_submit_adds_to_game_manager_active() -> void:
	GameManager.discover_evidence("ev_knife")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	assert_eq(GameManager.active_lab_requests.size(), 1, "Should add to GameManager")


func test_submit_invalid_processing_days_uses_default() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.current_day = 1
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result", 0)
	assert_eq(req["completion_day"], 2, "Should use default processing days")


func test_submit_generates_unique_ids() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_prints")
	var r1: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	var r2: Dictionary = LabManager.submit_request("ev_prints", "fingerprint", "ev_prints_result")
	assert_ne(r1["id"], r2["id"], "IDs should be unique")


# =========================================================================
# Cancel
# =========================================================================

func test_cancel_request_success() -> void:
	GameManager.discover_evidence("ev_knife")
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	var cancelled: bool = LabManager.cancel_request(req["id"])
	assert_true(cancelled)
	assert_eq(LabManager.get_pending_count(), 0)


func test_cancel_emits_signal() -> void:
	GameManager.discover_evidence("ev_knife")
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	watch_signals(LabManager)
	LabManager.cancel_request(req["id"])
	assert_signal_emitted(LabManager, "lab_cancelled")


func test_cancel_removes_from_game_manager() -> void:
	GameManager.discover_evidence("ev_knife")
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	LabManager.cancel_request(req["id"])
	assert_eq(GameManager.active_lab_requests.size(), 0)


func test_cancel_nonexistent_returns_false() -> void:
	assert_false(LabManager.cancel_request("nonexistent"))
	assert_push_warning("[LabManager] Request not found: nonexistent")


func test_cancel_already_cancelled_returns_false() -> void:
	GameManager.discover_evidence("ev_knife")
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	LabManager.cancel_request(req["id"])
	assert_false(LabManager.cancel_request(req["id"]))
	assert_push_warning("[LabManager] Cannot cancel non-pending request")


func test_cancelled_evidence_can_be_resubmitted() -> void:
	GameManager.discover_evidence("ev_knife")
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	LabManager.cancel_request(req["id"])
	assert_false(LabManager.is_evidence_submitted("ev_knife"), "After cancel, should not be submitted")


# =========================================================================
# Query
# =========================================================================

func test_get_request_returns_data() -> void:
	GameManager.discover_evidence("ev_knife")
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	var retrieved: Dictionary = LabManager.get_request(req["id"])
	assert_eq(retrieved["input_evidence_id"], "ev_knife")


func test_get_request_nonexistent_returns_empty() -> void:
	var result: Dictionary = LabManager.get_request("nonexistent")
	assert_true(result.is_empty())


func test_get_pending_requests() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_prints")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	LabManager.submit_request("ev_prints", "fingerprint", "ev_prints_result")
	var pending: Array[Dictionary] = LabManager.get_pending_requests()
	assert_eq(pending.size(), 2)


func test_get_completed_requests_initially_empty() -> void:
	var completed: Array[Dictionary] = LabManager.get_completed_requests()
	assert_eq(completed.size(), 0)


func test_is_evidence_submitted() -> void:
	GameManager.discover_evidence("ev_knife")
	assert_false(LabManager.is_evidence_submitted("ev_knife"))
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	assert_true(LabManager.is_evidence_submitted("ev_knife"))


func test_get_estimated_completion() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.current_day = 2
	var req: Dictionary = LabManager.submit_request("ev_knife", "dna", "ev_knife_result", 3)
	assert_eq(LabManager.get_estimated_completion(req["id"]), 5)


func test_get_estimated_completion_nonexistent() -> void:
	assert_eq(LabManager.get_estimated_completion("nonexistent"), -1)


func test_has_content_false_when_empty() -> void:
	assert_false(LabManager.has_content())


func test_has_content_true_after_submit() -> void:
	GameManager.discover_evidence("ev_knife")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	assert_true(LabManager.has_content())


func test_get_request_count() -> void:
	GameManager.discover_evidence("ev_knife")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	assert_eq(LabManager.get_request_count(), 1)


# =========================================================================
# Debug Completion
# =========================================================================

func test_complete_all_instantly() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_prints")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	LabManager.submit_request("ev_prints", "fingerprint", "ev_prints_result")
	var results: Array = LabManager.complete_all_instantly()
	assert_eq(results.size(), 2)
	assert_eq(LabManager.get_pending_count(), 0)
	assert_eq(LabManager.get_completed_requests().size(), 2)


func test_complete_all_instantly_discovers_output_evidence() -> void:
	GameManager.discover_evidence("ev_knife")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	LabManager.complete_all_instantly()
	assert_true(GameManager.has_evidence("ev_knife_result"), "Output evidence should be discovered")


func test_complete_all_emits_lab_completed() -> void:
	GameManager.discover_evidence("ev_knife")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	watch_signals(LabManager)
	LabManager.complete_all_instantly()
	assert_signal_emitted(LabManager, "lab_completed")


func test_complete_all_skips_non_pending() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_prints")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	var req2: Dictionary = LabManager.submit_request("ev_prints", "fingerprint", "ev_prints_result")
	LabManager.cancel_request(req2["id"])
	var results: Array = LabManager.complete_all_instantly()
	assert_eq(results.size(), 1, "Should only complete pending requests")


# =========================================================================
# Serialization
# =========================================================================

func test_serialize_deserialize_round_trip() -> void:
	GameManager.discover_evidence("ev_knife")
	GameManager.discover_evidence("ev_prints")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	LabManager.submit_request("ev_prints", "fingerprint", "ev_prints_result")

	var data: Dictionary = LabManager.serialize()
	LabManager.reset()
	assert_eq(LabManager.get_request_count(), 0)

	LabManager.deserialize(data)
	assert_eq(LabManager.get_request_count(), 2)
	assert_eq(LabManager.get_pending_count(), 2)


func test_serialize_preserves_state() -> void:
	GameManager.discover_evidence("ev_knife")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	LabManager.complete_all_instantly()

	var data: Dictionary = LabManager.serialize()
	LabManager.reset()
	LabManager.deserialize(data)
	assert_eq(LabManager.get_completed_requests().size(), 1)
	assert_eq(LabManager.get_pending_count(), 0)


func test_reset_clears_all_state() -> void:
	GameManager.discover_evidence("ev_knife")
	LabManager.submit_request("ev_knife", "dna", "ev_knife_result")
	LabManager.reset()
	assert_eq(LabManager.get_request_count(), 0)
	assert_false(LabManager.has_content())
