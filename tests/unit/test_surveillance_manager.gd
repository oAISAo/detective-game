## test_surveillance_manager.gd
## Unit tests for the SurveillanceManager autoload.
## Tests install, cancel, query, concurrent limits, completion, serialization.
extends GutTest


const TEST_CASE_FILE: String = "test_case_surveillance.json"

var _test_case_data: Dictionary = {
	"id": "case_surv_test",
	"title": "Surveillance Test Case",
	"description": "Tests surveillance manager.",
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
		{
			"id": "p_sam",
			"name": "Sam Lee",
			"role": "WITNESS",
			"personality_traits": [],
			"relationships": [],
			"pressure_threshold": 4,
		},
	],
	"evidence": [],
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
	SurveillanceManager.reset()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	CaseManager.unload_case()


# =========================================================================
# Install
# =========================================================================

func test_install_surveillance_returns_data() -> void:
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP
	)
	assert_false(op.is_empty(), "Should return operation data")
	assert_true(op["id"].begins_with("surv_"))
	assert_eq(op["target_person"], "p_mark")
	assert_eq(op["type"], Enums.SurveillanceType.PHONE_TAP)
	assert_eq(op["status"], "active")


func test_install_emits_signal() -> void:
	watch_signals(SurveillanceManager)
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	assert_signal_emitted(SurveillanceManager, "surveillance_installed")


func test_install_sets_expiry_day() -> void:
	GameManager.current_day = 2
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP, 3
	)
	assert_eq(op["active_days"], 3)
	assert_eq(op["day_installed"], 2)


func test_install_default_active_days() -> void:
	GameManager.current_day = 1
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP
	)
	assert_eq(op["active_days"], SurveillanceManager.DEFAULT_ACTIVE_DAYS)


func test_install_rejects_unknown_person() -> void:
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_nonexistent", Enums.SurveillanceType.PHONE_TAP
	)
	assert_true(op.is_empty(), "Should reject unknown person")
	assert_push_error("[SurveillanceManager] Person not found: p_nonexistent")


func test_install_rejects_duplicate_person() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	var dup: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.HOME_SURVEILLANCE
	)
	assert_true(dup.is_empty(), "Should reject duplicate person surveillance")
	assert_push_warning("[SurveillanceManager] Person already under surveillance: p_mark")


func test_install_respects_concurrent_limit() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	SurveillanceManager.install_surveillance("p_julia", Enums.SurveillanceType.HOME_SURVEILLANCE)
	var third: Dictionary = SurveillanceManager.install_surveillance(
		"p_sam", Enums.SurveillanceType.FINANCIAL_MONITORING
	)
	assert_true(third.is_empty(), "Should reject when at max concurrent (%d)" % SurveillanceManager.MAX_CONCURRENT)
	assert_push_warning("[SurveillanceManager] Maximum concurrent surveillance reached")
	assert_eq(SurveillanceManager.get_active_count(), 2)


func test_install_adds_to_game_manager_active() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	assert_eq(GameManager.active_surveillance.size(), 1, "Should add to GameManager")


func test_install_with_result_events() -> void:
	var events: Array[String] = ["evt_phone_call", "evt_meeting"]
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP, 2, events
	)
	assert_eq(op["result_events"].size(), 2)


func test_install_generates_unique_ids() -> void:
	var op1: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP
	)
	SurveillanceManager.cancel_surveillance(op1["id"])
	var op2: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.HOME_SURVEILLANCE
	)
	assert_ne(op1["id"], op2["id"], "IDs should be unique")


func test_install_invalid_active_days_uses_default() -> void:
	GameManager.current_day = 1
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP, 0
	)
	assert_eq(op["active_days"], SurveillanceManager.DEFAULT_ACTIVE_DAYS)


# =========================================================================
# Cancel
# =========================================================================

func test_cancel_surveillance_success() -> void:
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP
	)
	var cancelled: bool = SurveillanceManager.cancel_surveillance(op["id"])
	assert_true(cancelled)
	assert_eq(SurveillanceManager.get_active_count(), 0)


func test_cancel_emits_signal() -> void:
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP
	)
	watch_signals(SurveillanceManager)
	SurveillanceManager.cancel_surveillance(op["id"])
	assert_signal_emitted(SurveillanceManager, "surveillance_cancelled")


func test_cancel_removes_from_game_manager() -> void:
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP
	)
	SurveillanceManager.cancel_surveillance(op["id"])
	assert_eq(GameManager.active_surveillance.size(), 0)


func test_cancel_nonexistent_returns_false() -> void:
	assert_false(SurveillanceManager.cancel_surveillance("nonexistent"))
	assert_push_warning("[SurveillanceManager] Operation not found: nonexistent")


func test_cancel_already_cancelled_returns_false() -> void:
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP
	)
	SurveillanceManager.cancel_surveillance(op["id"])
	assert_false(SurveillanceManager.cancel_surveillance(op["id"]))
	assert_push_warning("[SurveillanceManager] Cannot cancel non-active operation")


func test_cancelled_person_can_be_re_surveilled() -> void:
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP
	)
	SurveillanceManager.cancel_surveillance(op["id"])
	assert_false(SurveillanceManager.is_person_under_surveillance("p_mark"))


# =========================================================================
# Query
# =========================================================================

func test_get_operation_returns_data() -> void:
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_mark", Enums.SurveillanceType.PHONE_TAP
	)
	var retrieved: Dictionary = SurveillanceManager.get_operation(op["id"])
	assert_eq(retrieved["target_person"], "p_mark")


func test_get_operation_nonexistent_returns_empty() -> void:
	var result: Dictionary = SurveillanceManager.get_operation("nonexistent")
	assert_true(result.is_empty())


func test_get_active_operations() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	SurveillanceManager.install_surveillance("p_julia", Enums.SurveillanceType.HOME_SURVEILLANCE)
	var active: Array[Dictionary] = SurveillanceManager.get_active_operations()
	assert_eq(active.size(), 2)


func test_get_operations_for_person() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	SurveillanceManager.install_surveillance("p_julia", Enums.SurveillanceType.HOME_SURVEILLANCE)
	var mark_ops: Array[Dictionary] = SurveillanceManager.get_operations_for_person("p_mark")
	assert_eq(mark_ops.size(), 1)
	assert_eq(mark_ops[0]["target_person"], "p_mark")


func test_get_operations_for_person_empty() -> void:
	var ops: Array[Dictionary] = SurveillanceManager.get_operations_for_person("p_sam")
	assert_eq(ops.size(), 0)


func test_is_person_under_surveillance() -> void:
	assert_false(SurveillanceManager.is_person_under_surveillance("p_mark"))
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	assert_true(SurveillanceManager.is_person_under_surveillance("p_mark"))


func test_has_content_false_when_empty() -> void:
	assert_false(SurveillanceManager.has_content())


func test_has_content_true_after_install() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	assert_true(SurveillanceManager.has_content())


func test_get_operation_count() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	assert_eq(SurveillanceManager.get_operation_count(), 1)


func test_get_results_for_operation_empty() -> void:
	var results: Array = SurveillanceManager.get_results_for_operation("nonexistent")
	assert_eq(results.size(), 0)


# =========================================================================
# Debug Completion
# =========================================================================

func test_complete_all_instantly() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	SurveillanceManager.install_surveillance("p_julia", Enums.SurveillanceType.HOME_SURVEILLANCE)
	var completed: Array = SurveillanceManager.complete_all_instantly()
	assert_eq(completed.size(), 2)
	assert_eq(SurveillanceManager.get_active_count(), 0)


func test_complete_all_emits_expired() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	watch_signals(SurveillanceManager)
	SurveillanceManager.complete_all_instantly()
	assert_signal_emitted(SurveillanceManager, "surveillance_expired")


func test_complete_all_skips_non_active() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	var op: Dictionary = SurveillanceManager.install_surveillance(
		"p_julia", Enums.SurveillanceType.HOME_SURVEILLANCE
	)
	SurveillanceManager.cancel_surveillance(op["id"])
	var completed: Array = SurveillanceManager.complete_all_instantly()
	assert_eq(completed.size(), 1, "Should only complete active operations")


func test_complete_all_clears_game_manager_active() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	SurveillanceManager.complete_all_instantly()
	assert_eq(GameManager.active_surveillance.size(), 0)


# =========================================================================
# Serialization
# =========================================================================

func test_serialize_deserialize_round_trip() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	SurveillanceManager.install_surveillance("p_julia", Enums.SurveillanceType.HOME_SURVEILLANCE)

	var data: Dictionary = SurveillanceManager.serialize()
	SurveillanceManager.reset()
	assert_eq(SurveillanceManager.get_operation_count(), 0)

	SurveillanceManager.deserialize(data)
	assert_eq(SurveillanceManager.get_operation_count(), 2)
	assert_eq(SurveillanceManager.get_active_count(), 2)


func test_serialize_preserves_completed() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	SurveillanceManager.complete_all_instantly()

	var data: Dictionary = SurveillanceManager.serialize()
	SurveillanceManager.reset()
	SurveillanceManager.deserialize(data)
	assert_eq(SurveillanceManager.get_operation_count(), 1)
	assert_eq(SurveillanceManager.get_active_count(), 0)


func test_reset_clears_all_state() -> void:
	SurveillanceManager.install_surveillance("p_mark", Enums.SurveillanceType.PHONE_TAP)
	SurveillanceManager.reset()
	assert_eq(SurveillanceManager.get_operation_count(), 0)
	assert_false(SurveillanceManager.has_content())
