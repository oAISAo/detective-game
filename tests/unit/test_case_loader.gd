## test_case_loader.gd
## Unit tests for CaseLoader multi-file folder loading and DiscoveryRuleData.
## Tests cover: folder loading, file merging, error handling, CaseManager
## integration, and discovery rule data structures.
extends GutTest


# =============================================================================
# DiscoveryRuleData Tests
# =============================================================================

func test_discovery_rule_from_dict_full() -> void:
	var data := {
		"id": "dr_01",
		"evidence_id": "ev_knife",
		"location_id": "loc_kitchen",
		"conditions": ["day_gte:2", "evidence_discovered:ev_blood"],
		"description": "Found after blood is discovered on day 2+",
	}
	var rule := DiscoveryRuleData.from_dict(data)
	assert_eq(rule.id, "dr_01")
	assert_eq(rule.evidence_id, "ev_knife")
	assert_eq(rule.location_id, "loc_kitchen")
	assert_eq(rule.conditions.size(), 2)
	assert_eq(rule.conditions[0], "day_gte:2")
	assert_eq(rule.conditions[1], "evidence_discovered:ev_blood")
	assert_eq(rule.description, "Found after blood is discovered on day 2+")


func test_discovery_rule_from_dict_defaults() -> void:
	var rule := DiscoveryRuleData.from_dict({})
	assert_eq(rule.id, "")
	assert_eq(rule.evidence_id, "")
	assert_eq(rule.location_id, "")
	assert_eq(rule.conditions.size(), 0)
	assert_eq(rule.description, "")


func test_discovery_rule_validate_all_required() -> void:
	var rule := DiscoveryRuleData.from_dict({})
	var errors := rule.validate()
	assert_true(errors.size() >= 2, "Should have errors for id and evidence_id")
	assert_true(_has_error_containing(errors, "id is required"))
	assert_true(_has_error_containing(errors, "evidence_id is required"))


func test_discovery_rule_validate_valid() -> void:
	var rule := DiscoveryRuleData.from_dict({
		"id": "dr_01",
		"evidence_id": "ev_knife",
		"location_id": "loc_kitchen",
	})
	var errors := rule.validate()
	assert_eq(errors.size(), 0, "Valid rule should have no errors")


func test_discovery_rule_to_dict_roundtrip() -> void:
	var data := {
		"id": "dr_rt",
		"evidence_id": "ev_test",
		"location_id": "loc_test",
		"conditions": ["day_gte:3"],
		"description": "Roundtrip test",
	}
	var rule := DiscoveryRuleData.from_dict(data)
	var result := rule.to_dict()
	assert_eq(result["id"], "dr_rt")
	assert_eq(result["evidence_id"], "ev_test")
	assert_eq(result["location_id"], "loc_test")
	assert_eq(result["conditions"].size(), 1)
	assert_eq(result["conditions"][0], "day_gte:3")
	assert_eq(result["description"], "Roundtrip test")


func test_discovery_rule_conditions_not_shared() -> void:
	var rule := DiscoveryRuleData.from_dict({
		"id": "dr_01",
		"evidence_id": "ev_test",
		"location_id": "loc_test",
		"conditions": ["day_gte:2"],
	})
	var exported := rule.to_dict()
	exported["conditions"].append("extra_condition")
	assert_eq(rule.conditions.size(), 1, "Original should not be modified")


# =============================================================================
# CaseData discovery_rules Integration
# =============================================================================

func test_case_data_includes_discovery_rules() -> void:
	var data := {
		"id": "case_test",
		"title": "Test Case",
		"persons": [{"id": "p_victim", "name": "Victim", "role": "VICTIM"}],
		"discovery_rules": [
			{
				"id": "dr_01",
				"evidence_id": "ev_test",
				"location_id": "loc_test",
				"conditions": ["day_gte:2"],
			},
			{
				"id": "dr_02",
				"evidence_id": "ev_other",
				"location_id": "loc_other",
				"conditions": [],
			},
		],
	}
	var case_data := CaseData.from_dict(data)
	assert_eq(case_data.discovery_rules.size(), 2)
	assert_eq(case_data.discovery_rules[0].id, "dr_01")
	assert_eq(case_data.discovery_rules[1].evidence_id, "ev_other")


func test_case_data_discovery_rules_default_empty() -> void:
	var case_data := CaseData.from_dict({
		"id": "case_test",
		"title": "Test Case",
		"persons": [{"id": "p_victim", "name": "Victim", "role": "VICTIM"}],
	})
	assert_eq(case_data.discovery_rules.size(), 0)


func test_case_data_validates_discovery_rules() -> void:
	var data := {
		"id": "case_test",
		"title": "Test Case",
		"persons": [{"id": "p_victim", "name": "Victim", "role": "VICTIM"}],
		"discovery_rules": [
			{"id": "", "evidence_id": "", "location_id": ""},
		],
	}
	var case_data := CaseData.from_dict(data)
	var errors := case_data.validate()
	assert_true(_has_error_containing(errors, "DiscoveryRuleData"))


func test_case_data_to_dict_includes_discovery_rules() -> void:
	var data := {
		"id": "case_test",
		"title": "Test Case",
		"persons": [{"id": "p_victim", "name": "Victim", "role": "VICTIM"}],
		"discovery_rules": [
			{
				"id": "dr_01",
				"evidence_id": "ev_test",
				"location_id": "loc_test",
				"conditions": [],
			},
		],
	}
	var case_data := CaseData.from_dict(data)
	var result := case_data.to_dict()
	assert_true(result.has("discovery_rules"))
	assert_eq(result["discovery_rules"].size(), 1)
	assert_eq(result["discovery_rules"][0]["id"], "dr_01")


# =============================================================================
# CaseLoader Folder Loading Tests
# =============================================================================

func test_load_riverside_apartment_case() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	assert_not_null(case_data, "Should load riverside_apartment case: %s" % "; ".join(errors))
	if case_data == null:
		return
	assert_eq(case_data.id, "riverside_apartment")
	assert_eq(case_data.title, "The Riverside Apartment Murder")


func test_riverside_case_metadata() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded: %s" % "; ".join(errors))
		return
	assert_eq(case_data.start_day, 1)
	assert_eq(case_data.end_day, 4)
	assert_eq(case_data.solution_suspect, "p_julia")
	assert_false(case_data.solution_motive.is_empty())
	assert_eq(case_data.solution_time_day, 1)


func test_riverside_suspects_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_eq(case_data.persons.size(), 5, "Should have 5 persons (victim + 3 suspects + 1 witness)")
	# Verify the victim
	var victim_found := false
	var suspect_count := 0
	var witness_count := 0
	for person: PersonData in case_data.persons:
		if person.id == "p_victim":
			assert_eq(person.role, Enums.PersonRole.VICTIM)
			victim_found = true
		elif person.role == Enums.PersonRole.SUSPECT:
			suspect_count += 1
		elif person.role == Enums.PersonRole.WITNESS:
			witness_count += 1
	assert_true(victim_found, "Should include the victim")
	assert_eq(suspect_count, 3, "Should have 3 suspects")
	assert_eq(witness_count, 1, "Should have 1 witness")


func test_riverside_locations_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_eq(case_data.locations.size(), 4, "Should have 4 locations")
	# Check that specific locations exist
	var location_ids: Array[String] = []
	for loc: LocationData in case_data.locations:
		location_ids.append(loc.id)
	assert_true("loc_victim_apartment" in location_ids)
	assert_true("loc_hallway" in location_ids)
	assert_true("loc_victim_office" in location_ids)
	assert_true("loc_parking_lot" in location_ids)


func test_riverside_evidence_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.evidence.size() >= 20, "Should have at least 20 evidence items, got %d" % case_data.evidence.size())


func test_riverside_critical_evidence() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.critical_evidence_ids.size() >= 4, "Should have critical evidence IDs")
	assert_true("ev_julia_fingerprint_glass" in case_data.critical_evidence_ids)
	assert_true("ev_elevator_logs" in case_data.critical_evidence_ids)


func test_riverside_events_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.events.size() >= 6, "Should have timeline events")


func test_riverside_event_triggers_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.event_triggers.size() >= 5, "Should have event triggers, got %d" % case_data.event_triggers.size())
	# Check for morning briefing trigger
	var has_morning_briefing := false
	for trigger: EventTriggerData in case_data.event_triggers:
		if trigger.id == "trig_morning_briefing_day1":
			has_morning_briefing = true
			assert_eq(trigger.trigger_type, Enums.TriggerType.DAY_START)
			assert_eq(trigger.trigger_day, 1)
			assert_true(trigger.actions.size() >= 3, "Morning briefing should have multiple actions")
	assert_true(has_morning_briefing, "Should have Day 1 morning briefing trigger")


func test_riverside_statements_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.statements.size() >= 4, "Should have statements")


func test_riverside_actions_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.actions.size() >= 4, "Should have actions")


func test_riverside_insights_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.insights.size() >= 2, "Should have insights")


func test_riverside_discovery_rules_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.discovery_rules.size() >= 8, "Should have discovery rules, got %d" % case_data.discovery_rules.size())


func test_riverside_lab_requests_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.lab_requests.size() >= 3, "Should have lab requests")


func test_riverside_interrogation_topics_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.interrogation_topics.size() >= 3, "Should have interrogation topics")


func test_riverside_interrogation_triggers_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.interrogation_triggers.size() >= 3, "Should have interrogation triggers")


func test_riverside_surveillance_requests_loaded() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	assert_true(case_data.surveillance_requests.size() >= 1, "Should have surveillance requests")


func test_riverside_case_validates() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("riverside_apartment", errors)
	if case_data == null:
		fail_test("Case not loaded")
		return
	var validation_errors := case_data.validate()
	assert_eq(validation_errors.size(), 0, "Case should validate cleanly: %s" % "; ".join(validation_errors))


# =============================================================================
# CaseLoader Error Handling
# =============================================================================

func test_load_nonexistent_folder_returns_null() -> void:
	var errors: Array[String] = []
	var case_data: CaseData = CaseLoader.load_from_folder("nonexistent_case_xyz", errors)
	assert_null(case_data, "Should return null for nonexistent folder")
	assert_true(errors.size() > 0, "Should report errors")


func test_load_nonexistent_folder_reports_error() -> void:
	var errors: Array[String] = []
	CaseLoader.load_from_folder("nonexistent_case_xyz", errors)
	assert_true(_has_error_containing(errors, "not found"))


# =============================================================================
# CaseManager.load_case_folder Integration
# =============================================================================

func _reset_case_manager() -> void:
	CaseManager.unload_case()


func test_case_manager_load_case_folder() -> void:
	_reset_case_manager()
	var result := CaseManager.load_case_folder("riverside_apartment")
	assert_true(result, "Should load case folder successfully")
	assert_true(CaseManager.case_loaded_flag)
	var case_data := CaseManager.get_case_data()
	assert_not_null(case_data)
	assert_eq(case_data.id, "riverside_apartment")
	_reset_case_manager()


func test_case_manager_folder_query_persons() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var sarah := CaseManager.get_person("p_sarah")
	assert_not_null(sarah)
	assert_eq(sarah.name, "Sarah Klein")
	assert_eq(sarah.role, Enums.PersonRole.WITNESS)
	var suspects := CaseManager.get_suspects()
	assert_eq(suspects.size(), 3)
	_reset_case_manager()


func test_case_manager_folder_query_evidence() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var fingerprint := CaseManager.get_evidence("ev_julia_fingerprint_glass")
	assert_not_null(fingerprint)
	assert_eq(fingerprint.type, Enums.EvidenceType.FORENSIC)
	assert_eq(fingerprint.importance_level, Enums.ImportanceLevel.CRITICAL)
	_reset_case_manager()


func test_case_manager_folder_query_locations() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var apartment := CaseManager.get_location("loc_victim_apartment")
	assert_not_null(apartment)
	assert_true(apartment.searchable)
	assert_true(apartment.investigable_objects.size() >= 3, "Apartment should have investigable objects")
	_reset_case_manager()


func test_case_manager_folder_query_evidence_by_location() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var apartment_evidence := CaseManager.get_evidence_by_location("loc_victim_apartment")
	assert_true(apartment_evidence.size() >= 5, "Apartment should have multiple evidence items")
	_reset_case_manager()


func test_case_manager_folder_query_triggers() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var day_start_triggers := CaseManager.get_triggers_by_type("DAY_START")
	assert_true(day_start_triggers.size() >= 2, "Should have day start triggers")
	var conditional_triggers := CaseManager.get_triggers_by_type("CONDITIONAL")
	assert_true(conditional_triggers.size() >= 2, "Should have conditional triggers")
	_reset_case_manager()


func test_case_manager_folder_query_discovery_rules() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var all_rules := CaseManager.get_all_discovery_rules()
	assert_true(all_rules.size() >= 8, "Should have discovery rules loaded")
	var apartment_rules := CaseManager.get_discovery_rules_for_location("loc_victim_apartment")
	assert_true(apartment_rules.size() >= 3, "Apartment should have multiple discovery rules")
	_reset_case_manager()


func test_case_manager_folder_query_discovery_rule_by_evidence() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var rules := CaseManager.get_discovery_rules_for_evidence("ev_hidden_safe")
	assert_eq(rules.size(), 1)
	assert_eq(rules[0].location_id, "loc_victim_office")
	assert_true(rules[0].conditions.size() >= 1)
	_reset_case_manager()


func test_case_manager_folder_load_nonexistent() -> void:
	_reset_case_manager()
	var result := CaseManager.load_case_folder("nonexistent_case")
	assert_false(result, "Should fail for nonexistent case folder")
	assert_false(CaseManager.case_loaded_flag)
	assert_push_error("Failed to load case folder")


func test_case_manager_folder_emits_case_loaded() -> void:
	_reset_case_manager()
	watch_signals(CaseManager)
	CaseManager.load_case_folder("riverside_apartment")
	assert_signal_emitted_with_parameters(CaseManager, "case_loaded", ["riverside_apartment"])
	_reset_case_manager()


func test_case_manager_folder_emits_load_failed() -> void:
	_reset_case_manager()
	watch_signals(CaseManager)
	CaseManager.load_case_folder("nonexistent_case")
	assert_signal_emitted(CaseManager, "case_load_failed")
	assert_push_error("Failed to load case folder")


# =============================================================================
# Morning Briefing Event Trigger Content Tests
# =============================================================================

func test_morning_briefing_day1_unlocks_locations() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var trigger := CaseManager.get_event_trigger("trig_morning_briefing_day1")
	assert_not_null(trigger, "Day 1 morning briefing trigger should exist")
	var has_unlock_apartment := false
	var has_unlock_hallway := false
	for action: String in trigger.actions:
		if action == "unlock_location:loc_victim_apartment":
			has_unlock_apartment = true
		elif action == "unlock_location:loc_hallway":
			has_unlock_hallway = true
	assert_true(has_unlock_apartment, "Morning briefing should unlock the victim's apartment")
	assert_true(has_unlock_hallway, "Morning briefing should unlock the hallway")
	_reset_case_manager()


func test_morning_briefing_day1_unlocks_suspects() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var trigger := CaseManager.get_event_trigger("trig_morning_briefing_day1")
	assert_not_null(trigger)
	var has_unlock_sarah := false
	for action: String in trigger.actions:
		if action == "unlock_interrogation:p_sarah":
			has_unlock_sarah = true
	assert_true(has_unlock_sarah, "Morning briefing should unlock Sarah for interrogation")
	# Mark is unlocked on Day 2, not Day 1
	var trigger_day2 := CaseManager.get_event_trigger("trig_morning_briefing_day2")
	assert_not_null(trigger_day2)
	var has_unlock_mark := false
	for action: String in trigger_day2.actions:
		if action == "unlock_interrogation:p_mark":
			has_unlock_mark = true
	assert_true(has_unlock_mark, "Day 2 briefing should unlock Mark for interrogation")
	_reset_case_manager()


func test_morning_briefing_day2_content() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var trigger := CaseManager.get_event_trigger("trig_morning_briefing_day2")
	assert_not_null(trigger, "Day 2 morning briefing trigger should exist")
	assert_eq(trigger.trigger_day, 2)
	var has_unlock_office := false
	var has_unlock_julia := false
	var has_unlock_lucas := false
	for action: String in trigger.actions:
		if action == "unlock_location:loc_victim_office":
			has_unlock_office = true
		elif action == "unlock_interrogation:p_julia":
			has_unlock_julia = true
		elif action == "unlock_interrogation:p_lucas":
			has_unlock_lucas = true
	assert_true(has_unlock_office, "Day 2 briefing should unlock the office")
	assert_true(has_unlock_julia, "Day 2 briefing should unlock Julia")
	assert_true(has_unlock_lucas, "Day 2 briefing should unlock Lucas")
	_reset_case_manager()


# =============================================================================
# Conditional Event Trigger Content Tests
# =============================================================================

func test_office_unlock_trigger() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var trigger := CaseManager.get_event_trigger("trig_unlock_office")
	assert_not_null(trigger, "Office unlock trigger should exist")
	assert_eq(trigger.trigger_type, Enums.TriggerType.CONDITIONAL)
	assert_true("evidence_discovered:ev_mark_call_log" in trigger.conditions)
	var has_unlock_office := false
	for action: String in trigger.actions:
		if action == "unlock_location:loc_victim_office":
			has_unlock_office = true
	assert_true(has_unlock_office, "Should unlock victim office")
	_reset_case_manager()


func test_julia_search_warrant_trigger() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var trigger := CaseManager.get_event_trigger("trig_warrant_julia_search")
	assert_not_null(trigger, "Julia search warrant trigger should exist")
	assert_eq(trigger.trigger_type, Enums.TriggerType.CONDITIONAL)
	assert_true("warrant_obtained:warrant_julia_search" in trigger.conditions)
	_reset_case_manager()


func test_final_day_adds_mandatory_action() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var trigger := CaseManager.get_event_trigger("trig_final_day_pressure")
	assert_not_null(trigger, "Final day trigger should exist")
	assert_eq(trigger.trigger_type, Enums.TriggerType.DAY_START)
	assert_eq(trigger.trigger_day, 4)
	var has_mandatory := false
	for action: String in trigger.actions:
		if action == "add_mandatory:submit_case_report":
			has_mandatory = true
	assert_true(has_mandatory, "Final day should add mandatory report submission")
	_reset_case_manager()


# =============================================================================
# Discovery Rule Content Tests
# =============================================================================

func test_discovery_rule_hidden_safe_conditions() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var rule := CaseManager.get_discovery_rule("dr_hidden_safe")
	assert_not_null(rule)
	assert_eq(rule.evidence_id, "ev_hidden_safe")
	assert_eq(rule.location_id, "loc_victim_office")
	assert_true("evidence_discovered:ev_accounting_files" in rule.conditions)
	_reset_case_manager()


func test_discovery_rule_personal_journal_day_gate() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var rule := CaseManager.get_discovery_rule("dr_personal_journal")
	assert_not_null(rule)
	assert_eq(rule.evidence_id, "ev_personal_journal")
	assert_true("day_gte:3" in rule.conditions)
	_reset_case_manager()


func test_discovery_rule_deleted_messages_warrant() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var rule := CaseManager.get_discovery_rule("dr_deleted_messages")
	assert_not_null(rule)
	assert_true("warrant_obtained:warrant_julia_phone" in rule.conditions)
	assert_true("day_gte:3" in rule.conditions)
	_reset_case_manager()


func test_discovery_rule_julia_shoes_warrant() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var rule := CaseManager.get_discovery_rule("dr_julia_shoes")
	assert_not_null(rule)
	assert_eq(rule.evidence_id, "ev_julia_shoes")
	assert_eq(rule.location_id, "loc_victim_apartment")
	assert_true("warrant_obtained:warrant_julia_search" in rule.conditions)
	_reset_case_manager()


# =============================================================================
# Case Content Integrity Tests
# =============================================================================

func test_all_evidence_references_valid_locations() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var case_data := CaseManager.get_case_data()
	var location_ids: Array[String] = []
	for loc: LocationData in case_data.locations:
		location_ids.append(loc.id)
	for ev: EvidenceData in case_data.evidence:
		if not ev.location_found.is_empty():
			assert_true(ev.location_found in location_ids,
				"Evidence %s references location %s which doesn't exist" % [ev.id, ev.location_found])
	_reset_case_manager()


func test_all_evidence_references_valid_persons() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var case_data := CaseManager.get_case_data()
	var person_ids: Array[String] = []
	for person: PersonData in case_data.persons:
		person_ids.append(person.id)
	for ev: EvidenceData in case_data.evidence:
		for person_id: String in ev.related_persons:
			assert_true(person_id in person_ids,
				"Evidence %s references person %s which doesn't exist" % [ev.id, person_id])
	_reset_case_manager()


func test_all_statements_reference_valid_persons() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var case_data := CaseManager.get_case_data()
	var person_ids: Array[String] = []
	for person: PersonData in case_data.persons:
		person_ids.append(person.id)
	for stmt: StatementData in case_data.statements:
		assert_true(stmt.person_id in person_ids,
			"Statement %s references person %s which doesn't exist" % [stmt.id, stmt.person_id])
	_reset_case_manager()


func test_critical_evidence_exists_in_evidence_list() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var case_data := CaseManager.get_case_data()
	var evidence_ids: Array[String] = []
	for ev: EvidenceData in case_data.evidence:
		evidence_ids.append(ev.id)
	for crit_id: String in case_data.critical_evidence_ids:
		assert_true(crit_id in evidence_ids,
			"Critical evidence %s not found in evidence list" % crit_id)
	_reset_case_manager()


func test_discovery_rules_reference_valid_evidence() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var case_data := CaseManager.get_case_data()
	var evidence_ids: Array[String] = []
	for ev: EvidenceData in case_data.evidence:
		evidence_ids.append(ev.id)
	for rule: DiscoveryRuleData in case_data.discovery_rules:
		assert_true(rule.evidence_id in evidence_ids,
			"Discovery rule %s references evidence %s which doesn't exist" % [rule.id, rule.evidence_id])
	_reset_case_manager()


func test_discovery_rules_reference_valid_locations() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var case_data := CaseManager.get_case_data()
	var location_ids: Array[String] = []
	for loc: LocationData in case_data.locations:
		location_ids.append(loc.id)
	for rule: DiscoveryRuleData in case_data.discovery_rules:
		assert_true(rule.location_id in location_ids,
			"Discovery rule %s references location %s which doesn't exist" % [rule.id, rule.location_id])
	_reset_case_manager()


func test_solution_suspect_exists_in_persons() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var case_data := CaseManager.get_case_data()
	var person_ids: Array[String] = []
	for person: PersonData in case_data.persons:
		person_ids.append(person.id)
	assert_true(case_data.solution_suspect in person_ids,
		"Solution suspect %s not found in persons" % case_data.solution_suspect)
	_reset_case_manager()


func test_investigable_objects_reference_valid_evidence() -> void:
	_reset_case_manager()
	CaseManager.load_case_folder("riverside_apartment")
	var case_data := CaseManager.get_case_data()
	var evidence_ids: Array[String] = []
	for ev: EvidenceData in case_data.evidence:
		evidence_ids.append(ev.id)
	for loc: LocationData in case_data.locations:
		for obj: InvestigableObjectData in loc.investigable_objects:
			for ev_id: String in obj.evidence_results:
				assert_true(ev_id in evidence_ids,
					"Object %s at %s references evidence %s which doesn't exist" % [obj.id, loc.id, ev_id])
	_reset_case_manager()


# =============================================================================
# Helpers
# =============================================================================

func _has_error_containing(errors: Array[String], substring: String) -> bool:
	for err: String in errors:
		if substring in err:
			return true
	return false
