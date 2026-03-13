## test_resource_classes.gd
## Unit tests for all Resource data classes.
## Phase 1: Verify from_dict(), validate(), and to_dict() for every Resource type.
extends GutTest


# =============================================================================
# EvidenceData
# =============================================================================

func test_evidence_from_dict_full() -> void:
	var data := {
		"id": "ev_01",
		"name": "Kitchen Knife",
		"description": "A sharp knife found in the sink.",
		"type": "FORENSIC",
		"location_found": "loc_kitchen",
		"discovered_day": 1,
		"related_persons": ["p_julia", "p_mark"],
		"tags": ["weapon", "critical"],
		"lab_status": "NOT_SUBMITTED",
		"requires_lab_analysis": true,
		"weight": 0.9,
		"importance_level": "CRITICAL",
		"discovery_method": "VISUAL",
		"legal_categories": ["PRESENCE", "OPPORTUNITY"],
	}
	var ev := EvidenceData.from_dict(data)
	assert_eq(ev.id, "ev_01")
	assert_eq(ev.name, "Kitchen Knife")
	assert_eq(ev.type, Enums.EvidenceType.FORENSIC)
	assert_eq(ev.location_found, "loc_kitchen")
	assert_eq(ev.discovered_day, 1)
	assert_eq(ev.related_persons.size(), 2)
	assert_true("p_julia" in ev.related_persons)
	assert_eq(ev.tags.size(), 2)
	assert_eq(ev.lab_status, Enums.LabStatus.NOT_SUBMITTED)
	assert_true(ev.requires_lab_analysis)
	assert_almost_eq(ev.weight, 0.9, 0.001)
	assert_eq(ev.importance_level, Enums.ImportanceLevel.CRITICAL)
	assert_eq(ev.discovery_method, Enums.DiscoveryMethod.VISUAL)
	assert_eq(ev.legal_categories.size(), 2)


func test_evidence_from_dict_defaults() -> void:
	var ev := EvidenceData.from_dict({})
	assert_eq(ev.id, "")
	assert_eq(ev.name, "")
	assert_eq(ev.type, Enums.EvidenceType.OBJECT)
	assert_eq(ev.importance_level, Enums.ImportanceLevel.SUPPORTING)
	assert_almost_eq(ev.weight, 0.5, 0.001)
	assert_false(ev.requires_lab_analysis)


func test_evidence_validate_missing_id() -> void:
	var ev := EvidenceData.from_dict({"name": "Test"})
	var errors := ev.validate()
	assert_true(errors.size() > 0, "Should have validation errors")
	assert_true(_has_error_containing(errors, "id is required"))


func test_evidence_validate_invalid_weight() -> void:
	var ev := EvidenceData.from_dict({"id": "ev_01", "name": "Test", "weight": 1.5})
	var errors := ev.validate()
	assert_true(_has_error_containing(errors, "weight must be"))


func test_evidence_to_dict_roundtrip() -> void:
	var original := {
		"id": "ev_rt",
		"name": "Roundtrip Evidence",
		"description": "Testing roundtrip",
		"type": "DOCUMENT",
		"weight": 0.7,
		"importance_level": "CRITICAL",
	}
	var ev := EvidenceData.from_dict(original)
	var result := ev.to_dict()
	assert_eq(result["id"], "ev_rt")
	assert_eq(result["name"], "Roundtrip Evidence")
	assert_eq(result["type"], "DOCUMENT")
	assert_eq(result["importance_level"], "CRITICAL")


# =============================================================================
# PersonData
# =============================================================================

func test_person_from_dict_full() -> void:
	var data := {
		"id": "p_julia",
		"name": "Julia Ross",
		"role": "SUSPECT",
		"personality_traits": ["MANIPULATIVE", "CALM"],
		"relationships": [{"person_b": "p_victim", "type": "SPOUSE"}],
		"pressure_threshold": 5,
	}
	var person := PersonData.from_dict(data)
	assert_eq(person.id, "p_julia")
	assert_eq(person.name, "Julia Ross")
	assert_eq(person.role, Enums.PersonRole.SUSPECT)
	assert_eq(person.personality_traits.size(), 2)
	assert_eq(person.relationships.size(), 1)
	assert_eq(person.relationships[0].person_b, "p_victim")
	assert_eq(person.relationships[0].type, Enums.RelationshipType.SPOUSE)
	assert_eq(person.relationships[0].person_a, "p_julia", "person_a should be auto-injected")
	assert_eq(person.pressure_threshold, 5)


func test_person_from_dict_defaults() -> void:
	var person := PersonData.from_dict({})
	assert_eq(person.id, "")
	assert_eq(person.role, Enums.PersonRole.WITNESS)
	assert_eq(person.personality_traits.size(), 0)
	assert_eq(person.relationships.size(), 0)
	assert_eq(person.pressure_threshold, 0)


func test_person_validate_missing_fields() -> void:
	var person := PersonData.from_dict({})
	var errors := person.validate()
	assert_true(_has_error_containing(errors, "id is required"))
	assert_true(_has_error_containing(errors, "name is required"))


func test_person_to_dict_roundtrip() -> void:
	var data := {
		"id": "p_test",
		"name": "Test Person",
		"role": "WITNESS",
		"personality_traits": ["ANXIOUS"],
		"relationships": [],
		"pressure_threshold": 3,
	}
	var person := PersonData.from_dict(data)
	var result := person.to_dict()
	assert_eq(result["id"], "p_test")
	assert_eq(result["role"], "WITNESS")
	assert_eq(result["pressure_threshold"], 3)


# =============================================================================
# RelationshipData
# =============================================================================

func test_relationship_from_dict() -> void:
	var data := {"person_a": "p_01", "person_b": "p_02", "type": "ENEMY"}
	var rel := RelationshipData.from_dict(data)
	assert_eq(rel.person_a, "p_01")
	assert_eq(rel.person_b, "p_02")
	assert_eq(rel.type, Enums.RelationshipType.ENEMY)


func test_relationship_validate_missing_person_b() -> void:
	var rel := RelationshipData.from_dict({"person_a": "p_01"})
	var errors := rel.validate()
	assert_true(_has_error_containing(errors, "person_b is required"))


func test_relationship_to_dict() -> void:
	var rel := RelationshipData.from_dict({"person_a": "p_01", "person_b": "p_02", "type": "SPOUSE"})
	var result := rel.to_dict()
	assert_eq(result["type"], "SPOUSE")


# =============================================================================
# StatementData
# =============================================================================

func test_statement_from_dict_full() -> void:
	var data := {
		"id": "s_01",
		"person_id": "p_julia",
		"text": "I was home all evening.",
		"day_given": 1,
		"related_evidence": ["ev_camera"],
		"related_event": "evt_argument",
	}
	var stmt := StatementData.from_dict(data)
	assert_eq(stmt.id, "s_01")
	assert_eq(stmt.person_id, "p_julia")
	assert_eq(stmt.text, "I was home all evening.")
	assert_eq(stmt.day_given, 1)
	assert_eq(stmt.related_evidence.size(), 1)
	assert_eq(stmt.related_event, "evt_argument")


func test_statement_validate_missing_fields() -> void:
	var stmt := StatementData.from_dict({})
	var errors := stmt.validate()
	assert_true(_has_error_containing(errors, "id is required"))
	assert_true(_has_error_containing(errors, "person_id is required"))
	assert_true(_has_error_containing(errors, "text is required"))


func test_statement_to_dict_roundtrip() -> void:
	var stmt := StatementData.from_dict({"id": "s_rt", "person_id": "p_01", "text": "Test"})
	var result := stmt.to_dict()
	assert_eq(result["id"], "s_rt")
	assert_eq(result["person_id"], "p_01")


# =============================================================================
# EventData
# =============================================================================

func test_event_from_dict_full() -> void:
	var data := {
		"id": "evt_01",
		"description": "Loud argument heard",
		"time": "20:15",
		"day": 1,
		"location": "loc_apartment",
		"involved_persons": ["p_victim", "p_julia"],
		"certainty_level": "CONFIRMED",
	}
	var evt := EventData.from_dict(data)
	assert_eq(evt.id, "evt_01")
	assert_eq(evt.time, "20:15")
	assert_eq(evt.day, 1)
	assert_eq(evt.location, "loc_apartment")
	assert_eq(evt.involved_persons.size(), 2)
	assert_eq(evt.certainty_level, Enums.CertaintyLevel.CONFIRMED)


func test_event_validate_missing_day() -> void:
	var evt := EventData.from_dict({"id": "evt_01", "description": "Test"})
	var errors := evt.validate()
	assert_true(_has_error_containing(errors, "day must be positive"))


func test_event_to_dict_roundtrip() -> void:
	var evt := EventData.from_dict({"id": "evt_rt", "description": "Test", "day": 2, "certainty_level": "LIKELY"})
	var result := evt.to_dict()
	assert_eq(result["id"], "evt_rt")
	assert_eq(result["certainty_level"], "LIKELY")


# =============================================================================
# LocationData
# =============================================================================

func test_location_from_dict_full() -> void:
	var data := {
		"id": "loc_apt",
		"name": "Victim's Apartment",
		"searchable": true,
		"investigable_objects": [
			{
				"id": "obj_table",
				"name": "Dining Table",
				"description": "A wooden dining table",
				"available_actions": ["visual_inspection", "fingerprint_analysis"],
				"evidence_results": ["ev_fingerprint"],
			}
		],
		"evidence_pool": ["ev_fingerprint", "ev_knife"],
	}
	var loc := LocationData.from_dict(data)
	assert_eq(loc.id, "loc_apt")
	assert_eq(loc.name, "Victim's Apartment")
	assert_true(loc.searchable)
	assert_eq(loc.investigable_objects.size(), 1)
	assert_eq(loc.investigable_objects[0].id, "obj_table")
	assert_eq(loc.investigable_objects[0].available_actions.size(), 2)
	assert_eq(loc.evidence_pool.size(), 2)


func test_location_validate_missing_fields() -> void:
	var loc := LocationData.from_dict({})
	var errors := loc.validate()
	assert_true(_has_error_containing(errors, "id is required"))
	assert_true(_has_error_containing(errors, "name is required"))


func test_location_to_dict_roundtrip() -> void:
	var loc := LocationData.from_dict({"id": "loc_rt", "name": "Test Location", "evidence_pool": ["ev_01"]})
	var result := loc.to_dict()
	assert_eq(result["id"], "loc_rt")
	assert_eq(result["evidence_pool"].size(), 1)


# =============================================================================
# InvestigableObjectData
# =============================================================================

func test_investigable_object_from_dict() -> void:
	var data := {
		"id": "obj_01",
		"name": "Wine Glass",
		"description": "Two wine glasses on the table",
		"available_actions": ["visual_inspection", "fingerprint_analysis"],
		"tool_requirements": ["fingerprint_powder"],
		"evidence_results": ["ev_fingerprint"],
		"investigation_state": "NOT_INSPECTED",
	}
	var obj := InvestigableObjectData.from_dict(data)
	assert_eq(obj.id, "obj_01")
	assert_eq(obj.name, "Wine Glass")
	assert_eq(obj.available_actions.size(), 2)
	assert_eq(obj.tool_requirements.size(), 1)
	assert_eq(obj.investigation_state, Enums.InvestigationState.NOT_INSPECTED)


func test_investigable_object_validate() -> void:
	var obj := InvestigableObjectData.from_dict({})
	var errors := obj.validate()
	assert_true(_has_error_containing(errors, "id is required"))
	assert_true(_has_error_containing(errors, "name is required"))


# =============================================================================
# InterrogationTopicData
# =============================================================================

func test_interrogation_topic_from_dict() -> void:
	var data := {
		"id": "topic_01",
		"person_id": "p_julia",
		"topic_name": "Whereabouts on the evening",
		"trigger_conditions": ["evidence:ev_camera"],
		"required_evidence": ["ev_camera"],
		"impact_level": "MAJOR",
	}
	var topic := InterrogationTopicData.from_dict(data)
	assert_eq(topic.id, "topic_01")
	assert_eq(topic.person_id, "p_julia")
	assert_eq(topic.topic_name, "Whereabouts on the evening")
	assert_eq(topic.trigger_conditions.size(), 1)
	assert_eq(topic.impact_level, Enums.ImpactLevel.MAJOR)


func test_interrogation_topic_validate_missing_fields() -> void:
	var topic := InterrogationTopicData.from_dict({})
	var errors := topic.validate()
	assert_true(_has_error_containing(errors, "id is required"))
	assert_true(_has_error_containing(errors, "person_id is required"))
	assert_true(_has_error_containing(errors, "topic_name is required"))


# =============================================================================
# ActionData
# =============================================================================

func test_action_from_dict() -> void:
	var data := {
		"id": "act_01",
		"name": "Interrogate Julia",
		"type": "INTERROGATION",
		"time_cost": 1,
		"target": "p_julia",
		"requirements": ["evidence:ev_fingerprint"],
		"results": ["statement:s_julia_02"],
	}
	var action := ActionData.from_dict(data)
	assert_eq(action.id, "act_01")
	assert_eq(action.name, "Interrogate Julia")
	assert_eq(action.type, Enums.ActionType.INTERROGATION)
	assert_eq(action.time_cost, 1)
	assert_eq(action.target, "p_julia")
	assert_eq(action.requirements.size(), 1)
	assert_eq(action.results.size(), 1)


func test_action_validate_negative_time_cost() -> void:
	var action := ActionData.from_dict({"id": "act_01", "name": "Test", "time_cost": -1})
	var errors := action.validate()
	assert_true(_has_error_containing(errors, "time_cost must be non-negative"))


# =============================================================================
# EventTriggerData
# =============================================================================

func test_event_trigger_from_dict() -> void:
	var data := {
		"id": "trigger_01",
		"trigger_type": "DAY_START",
		"trigger_day": 2,
		"conditions": [],
		"actions": ["show_briefing"],
		"result_events": ["evt_briefing"],
	}
	var trigger := EventTriggerData.from_dict(data)
	assert_eq(trigger.id, "trigger_01")
	assert_eq(trigger.trigger_type, Enums.TriggerType.DAY_START)
	assert_eq(trigger.trigger_day, 2)
	assert_eq(trigger.actions.size(), 1)
	assert_eq(trigger.result_events.size(), 1)


func test_event_trigger_validate() -> void:
	var trigger := EventTriggerData.from_dict({})
	var errors := trigger.validate()
	assert_true(_has_error_containing(errors, "id is required"))


# =============================================================================
# InsightData
# =============================================================================

func test_insight_from_dict() -> void:
	var data := {
		"id": "insight_01",
		"description": "Julia lied about being home",
		"source_evidence": ["ev_camera", "s_julia_01"],
		"strengthens_theory": "theory_julia_guilty",
		"unlocks_topic": "topic_alibi",
	}
	var insight := InsightData.from_dict(data)
	assert_eq(insight.id, "insight_01")
	assert_eq(insight.description, "Julia lied about being home")
	assert_eq(insight.source_evidence.size(), 2)
	assert_eq(insight.strengthens_theory, "theory_julia_guilty")
	assert_eq(insight.unlocks_topic, "topic_alibi")


func test_insight_validate_empty_sources() -> void:
	var insight := InsightData.from_dict({"id": "insight_01", "description": "Test"})
	var errors := insight.validate()
	assert_true(_has_error_containing(errors, "source_evidence must not be empty"))


# =============================================================================
# LabRequestData
# =============================================================================

func test_lab_request_from_dict() -> void:
	var data := {
		"id": "lab_01",
		"input_evidence_id": "ev_knife",
		"analysis_type": "fingerprint",
		"day_submitted": 1,
		"completion_day": 2,
		"output_evidence_id": "ev_knife_prints",
	}
	var req := LabRequestData.from_dict(data)
	assert_eq(req.id, "lab_01")
	assert_eq(req.input_evidence_id, "ev_knife")
	assert_eq(req.analysis_type, "fingerprint")
	assert_eq(req.day_submitted, 1)
	assert_eq(req.completion_day, 2)
	assert_eq(req.output_evidence_id, "ev_knife_prints")


func test_lab_request_validate_invalid_days() -> void:
	var req := LabRequestData.from_dict({
		"id": "lab_01",
		"input_evidence_id": "ev_01",
		"analysis_type": "dna",
		"day_submitted": 3,
		"completion_day": 1,
	})
	var errors := req.validate()
	assert_true(_has_error_containing(errors, "completion_day must be >= day_submitted"))


func test_lab_request_validate_missing_fields() -> void:
	var req := LabRequestData.from_dict({})
	var errors := req.validate()
	assert_true(_has_error_containing(errors, "id is required"))
	assert_true(_has_error_containing(errors, "input_evidence_id is required"))
	assert_true(_has_error_containing(errors, "analysis_type is required"))


# =============================================================================
# SurveillanceRequestData
# =============================================================================

func test_surveillance_from_dict() -> void:
	var data := {
		"id": "surv_01",
		"target_person": "p_julia",
		"type": "PHONE_TAP",
		"day_installed": 1,
		"active_days": 3,
		"result_events": ["evt_phone_call"],
	}
	var surv := SurveillanceRequestData.from_dict(data)
	assert_eq(surv.id, "surv_01")
	assert_eq(surv.target_person, "p_julia")
	assert_eq(surv.type, Enums.SurveillanceType.PHONE_TAP)
	assert_eq(surv.day_installed, 1)
	assert_eq(surv.active_days, 3)
	assert_eq(surv.result_events.size(), 1)


func test_surveillance_validate_invalid_active_days() -> void:
	var surv := SurveillanceRequestData.from_dict({
		"id": "surv_01",
		"target_person": "p_01",
		"active_days": 0,
	})
	var errors := surv.validate()
	assert_true(_has_error_containing(errors, "active_days must be positive"))


# =============================================================================
# CaseData
# =============================================================================

func test_case_data_from_dict_minimal() -> void:
	var data := {
		"id": "case_01",
		"title": "Test Case",
		"description": "A test",
		"start_day": 1,
		"end_day": 4,
		"persons": [{"id": "p_01", "name": "John", "role": "VICTIM"}],
		"evidence": [{"id": "ev_01", "name": "Knife", "type": "FORENSIC"}],
		"locations": [{"id": "loc_01", "name": "Apartment"}],
	}
	var case_data := CaseData.from_dict(data)
	assert_eq(case_data.id, "case_01")
	assert_eq(case_data.title, "Test Case")
	assert_eq(case_data.start_day, 1)
	assert_eq(case_data.end_day, 4)
	assert_eq(case_data.persons.size(), 1)
	assert_eq(case_data.evidence.size(), 1)
	assert_eq(case_data.locations.size(), 1)


func test_case_data_validate_empty() -> void:
	var case_data := CaseData.from_dict({})
	var errors := case_data.validate()
	assert_true(_has_error_containing(errors, "id is required"))
	assert_true(_has_error_containing(errors, "title is required"))
	assert_true(_has_error_containing(errors, "at least one person is required"))


func test_case_data_validate_invalid_days() -> void:
	var case_data := CaseData.from_dict({
		"id": "case_01",
		"title": "Test",
		"start_day": 5,
		"end_day": 3,
		"persons": [{"id": "p_01", "name": "John"}],
	})
	var errors := case_data.validate()
	assert_true(_has_error_containing(errors, "end_day must be >= start_day"))


func test_case_data_validates_nested_resources() -> void:
	var data := {
		"id": "case_01",
		"title": "Test",
		"persons": [{"id": "p_01", "name": "John"}],
		"evidence": [{"name": "Missing ID evidence"}],  # missing id
	}
	var case_data := CaseData.from_dict(data)
	var errors := case_data.validate()
	assert_true(_has_error_containing(errors, "EvidenceData: id is required"))


func test_case_data_to_dict_roundtrip() -> void:
	var data := {
		"id": "case_rt",
		"title": "Roundtrip Case",
		"description": "Testing",
		"start_day": 1,
		"end_day": 4,
		"persons": [{"id": "p_01", "name": "John", "role": "VICTIM"}],
		"evidence": [{"id": "ev_01", "name": "Knife", "type": "FORENSIC"}],
	}
	var case_data := CaseData.from_dict(data)
	var result := case_data.to_dict()
	assert_eq(result["id"], "case_rt")
	assert_eq(result["title"], "Roundtrip Case")
	assert_eq(result["persons"].size(), 1)
	assert_eq(result["evidence"].size(), 1)


func test_case_data_handles_missing_sections() -> void:
	var data := {
		"id": "case_minimal",
		"title": "Minimal Case",
		"persons": [{"id": "p_01", "name": "John"}],
	}
	var case_data := CaseData.from_dict(data)
	assert_eq(case_data.evidence.size(), 0)
	assert_eq(case_data.statements.size(), 0)
	assert_eq(case_data.events.size(), 0)
	assert_eq(case_data.event_triggers.size(), 0)
	assert_eq(case_data.interrogation_topics.size(), 0)
	assert_eq(case_data.actions.size(), 0)
	assert_eq(case_data.insights.size(), 0)
	assert_eq(case_data.lab_requests.size(), 0)
	assert_eq(case_data.surveillance_requests.size(), 0)


# =============================================================================
# EnumHelper
# =============================================================================

func test_enum_helper_parse_valid() -> void:
	var result := EnumHelper.parse_enum(Enums.EvidenceType, "FORENSIC")
	assert_eq(result, Enums.EvidenceType.FORENSIC)


func test_enum_helper_parse_case_insensitive() -> void:
	var result := EnumHelper.parse_enum(Enums.EvidenceType, "forensic")
	assert_eq(result, Enums.EvidenceType.FORENSIC)


func test_enum_helper_parse_with_whitespace() -> void:
	var result := EnumHelper.parse_enum(Enums.EvidenceType, "  DOCUMENT  ")
	assert_eq(result, Enums.EvidenceType.DOCUMENT)


func test_enum_helper_parse_invalid_returns_default() -> void:
	var result := EnumHelper.parse_enum(Enums.EvidenceType, "NONEXISTENT", 99)
	assert_eq(result, 99)
	assert_push_warning("EnumHelper")


func test_enum_helper_parse_empty_returns_default() -> void:
	var result := EnumHelper.parse_enum(Enums.EvidenceType, "", 42)
	assert_eq(result, 42)


func test_enum_helper_to_string() -> void:
	var result := EnumHelper.enum_to_string(Enums.PersonRole, Enums.PersonRole.SUSPECT)
	assert_eq(result, "SUSPECT")


func test_enum_helper_to_string_unknown() -> void:
	var result := EnumHelper.enum_to_string(Enums.PersonRole, 999)
	assert_eq(result, "UNKNOWN")


func test_enum_helper_parse_array() -> void:
	var values := ["FORENSIC", "DOCUMENT", "PHOTO"]
	var result := EnumHelper.parse_enum_array(Enums.EvidenceType, values)
	assert_eq(result.size(), 3)
	assert_eq(result[0], Enums.EvidenceType.FORENSIC)
	assert_eq(result[1], Enums.EvidenceType.DOCUMENT)
	assert_eq(result[2], Enums.EvidenceType.PHOTO)


func test_enum_helper_array_to_strings() -> void:
	var values: Array = [Enums.EvidenceType.FORENSIC, Enums.EvidenceType.DOCUMENT]
	var result := EnumHelper.enum_array_to_strings(Enums.EvidenceType, values)
	assert_eq(result.size(), 2)
	assert_eq(result[0], "FORENSIC")
	assert_eq(result[1], "DOCUMENT")


# =============================================================================
# Helpers
# =============================================================================

func _has_error_containing(errors: Array[String], substring: String) -> bool:
	for err: String in errors:
		if err.contains(substring):
			return true
	return false
