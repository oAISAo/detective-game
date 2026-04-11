## test_json_to_resource_pipeline.gd
## Integration test: Verifies the complete JSON → typed Resource conversion pipeline.
## Phase 1: End-to-end test that writes JSON, loads it through CaseManager,
## and verifies every resource type is correctly converted and queryable.
extends GutTest


const TEST_CASE_FILE: String = "test_pipeline.json"

## A comprehensive test case that includes all resource types.
var _full_case_data: Dictionary = {
	"id": "case_pipeline",
	"title": "Pipeline Integration Test Case",
	"description": "Tests the full JSON → Resource conversion pipeline.",
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
			"personality_traits": ["MANIPULATIVE", "CALM"],
			"relationships": [{"person_b": "p_victim", "type": "SPOUSE"}],
			"pressure_threshold": 5,
		},
	],
	"evidence": [
		{
			"id": "ev_knife",
			"name": "Kitchen Knife",
			"description": "A knife found in the kitchen sink.",
			"type": "FORENSIC",
			"location_found": "loc_apartment",
			"related_persons": ["p_julia"],
			"weight": 0.9,
			"importance_level": "CRITICAL",
			"discovery_method": "VISUAL",
			"requires_lab_analysis": true,
			"legal_categories": ["PRESENCE", "OPPORTUNITY"],
		},
	],
	"statements": [
		{
			"id": "s_julia_01",
			"person_id": "p_julia",
			"text": "I never entered the kitchen.",
			"day_given": 1,
			"related_evidence": ["ev_knife"],
			"related_event": "evt_argument",
		},
	],
	"events": [
		{
			"id": "evt_argument",
			"description": "Loud argument heard",
			"time": "20:15",
			"day": 1,
			"location": "loc_apartment",
			"involved_persons": ["p_victim", "p_julia"],
			"supporting_evidence": ["ev_knife"],
			"certainty_level": "CONFIRMED",
		},
	],
	"locations": [
		{
			"id": "loc_apartment",
			"name": "Victim's Apartment",
			"searchable": true,
			"investigable_objects": [
				{
					"id": "obj_sink",
					"name": "Kitchen Sink",
					"description": "A stainless steel sink with dishes",
					"available_actions": ["visual_inspection", "fingerprint_analysis"],
					"tool_requirements": ["fingerprint_powder"],
					"evidence_results": ["ev_knife"],
				},
			],
			"evidence_pool": ["ev_knife"],
		},
	],
	"event_triggers": [
		{
			"id": "trigger_lab_result",
			"trigger_type": "TIMED",
			"trigger_day": 3,
			"conditions": ["lab_complete:lab_knife"],
			"actions": ["deliver_lab_result"],
			"result_events": [],
		},
	],
	"interrogation_topics": [
		{
			"id": "topic_kitchen",
			"person_id": "p_julia",
			"topic_name": "Kitchen access",
			"trigger_conditions": ["evidence:ev_knife"],
			"required_evidence": ["ev_knife"],
			"statements": ["s_julia_01"],
			"impact_level": "BREAKPOINT",
		},
	],
	"actions": [
		{
			"id": "act_visit_apartment",
			"name": "Visit Apartment",
			"type": "VISIT_LOCATION",
			"time_cost": 0,
			"target": "loc_apartment",
			"requirements": [],
			"results": ["evidence:ev_knife"],
		},
	],
	"insights": [
		{
			"id": "insight_kitchen_lie",
			"description": "Julia lied about never entering the kitchen",
			"source_evidence": ["ev_knife", "s_julia_01"],
			"strengthens_theory": "theory_julia",
			"unlocks_topic": "topic_kitchen",
		},
	],
	"lab_requests": [
		{
			"id": "lab_knife",
			"input_evidence_id": "ev_knife",
			"analysis_type": "fingerprint",
			"day_submitted": 1,
			"completion_day": 3,
			"output_evidence_id": "ev_knife_prints",
		},
	],
	"surveillance_requests": [
		{
			"id": "surv_julia_phone",
			"target_person": "p_julia",
			"type": "PHONE_TAP",
			"day_installed": 2,
			"active_days": 2,
			"result_events": ["evt_julia_call"],
		},
	],
}


# --- Setup / Teardown --- #

func before_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	var dir: DirAccess = DirAccess.open("res://data/cases")
	if dir == null:
		DirAccess.make_dir_recursive_absolute("res://data/cases")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_full_case_data, "\t"))
	file.close()


func before_each() -> void:
	CaseManager.unload_case()


func after_all() -> void:
	var path: String = "res://data/cases/%s" % TEST_CASE_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


# --- Pipeline Tests --- #

func test_pipeline_loads_successfully() -> void:
	var result: bool = CaseManager.load_case(TEST_CASE_FILE)
	assert_true(result, "Pipeline test case should load successfully")


func test_pipeline_case_data_is_typed() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var case_data: CaseData = CaseManager.get_case_data()
	assert_not_null(case_data, "CaseData should not be null")
	assert_true(case_data is CaseData, "Should be CaseData type")
	assert_eq(case_data.id, "case_pipeline")


func test_pipeline_persons_are_typed() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var person: PersonData = CaseManager.get_person("p_julia")
	assert_not_null(person)
	assert_true(person is PersonData, "Should be PersonData type")
	assert_eq(person.role, Enums.PersonRole.SUSPECT)
	assert_eq(person.personality_traits.size(), 2)
	# Verify enum conversion worked
	assert_true(Enums.PersonalityTrait.MANIPULATIVE in person.personality_traits)
	assert_true(Enums.PersonalityTrait.CALM in person.personality_traits)


func test_pipeline_evidence_enums_converted() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var ev: EvidenceData = CaseManager.get_evidence("ev_knife")
	assert_not_null(ev)
	assert_eq(ev.type, Enums.EvidenceType.FORENSIC)
	assert_eq(ev.importance_level, Enums.ImportanceLevel.CRITICAL)
	assert_eq(ev.discovery_method, Enums.DiscoveryMethod.VISUAL)
	assert_true(ev.requires_lab_analysis)
	# Verify legal_categories enum array conversion
	assert_eq(ev.legal_categories.size(), 2)
	assert_true(Enums.LegalCategory.PRESENCE in ev.legal_categories)
	assert_true(Enums.LegalCategory.OPPORTUNITY in ev.legal_categories)


func test_pipeline_nested_relationships_typed() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var person: PersonData = CaseManager.get_person("p_julia")
	assert_eq(person.relationships.size(), 1)
	var rel: RelationshipData = person.relationships[0]
	assert_true(rel is RelationshipData, "Should be RelationshipData type")
	assert_eq(rel.person_a, "p_julia")
	assert_eq(rel.person_b, "p_victim")
	assert_eq(rel.type, Enums.RelationshipType.SPOUSE)


func test_pipeline_nested_investigable_objects_typed() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var loc: LocationData = CaseManager.get_location("loc_apartment")
	assert_not_null(loc)
	assert_eq(loc.investigable_objects.size(), 1)
	var obj: InvestigableObjectData = loc.investigable_objects[0]
	assert_true(obj is InvestigableObjectData, "Should be InvestigableObjectData type")
	assert_eq(obj.id, "obj_sink")
	assert_eq(obj.available_actions.size(), 2)
	assert_eq(obj.tool_requirements.size(), 1)
	assert_true("fingerprint_powder" in obj.tool_requirements)


func test_pipeline_statements_typed() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var stmt: StatementData = CaseManager.get_statement("s_julia_01")
	assert_not_null(stmt)
	assert_true(stmt is StatementData)
	assert_eq(stmt.person_id, "p_julia")
	assert_eq(stmt.related_evidence.size(), 1)


func test_pipeline_events_typed() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var evt: EventData = CaseManager.get_event("evt_argument")
	assert_not_null(evt)
	assert_true(evt is EventData)
	assert_eq(evt.certainty_level, Enums.CertaintyLevel.CONFIRMED)
	assert_eq(evt.involved_persons.size(), 2)


func test_pipeline_event_triggers_typed() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var trigger: EventTriggerData = CaseManager.get_event_trigger("trigger_lab_result")
	assert_not_null(trigger)
	assert_true(trigger is EventTriggerData)
	assert_eq(trigger.trigger_type, Enums.TriggerType.TIMED)
	assert_eq(trigger.trigger_day, 3)


func test_pipeline_interrogation_topics_typed() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var topic: InterrogationTopicData = CaseManager.get_interrogation_topic("topic_kitchen")
	assert_not_null(topic)
	assert_true(topic is InterrogationTopicData)
	assert_eq(topic.impact_level, Enums.ImpactLevel.BREAKPOINT)
	assert_eq(topic.required_evidence.size(), 1)


func test_pipeline_actions_typed() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var action: ActionData = CaseManager.get_action("act_visit_apartment")
	assert_not_null(action)
	assert_true(action is ActionData)
	assert_eq(action.type, Enums.ActionType.VISIT_LOCATION)
	assert_eq(action.time_cost, 0)


func test_pipeline_insights_typed() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var insight: InsightData = CaseManager.get_insight("insight_kitchen_lie")
	assert_not_null(insight)
	assert_true(insight is InsightData)
	assert_eq(insight.source_evidence.size(), 2)
	assert_eq(insight.unlocks_topic, "topic_kitchen")


func test_pipeline_case_data_contains_all_sections() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var case_data: CaseData = CaseManager.get_case_data()
	assert_eq(case_data.persons.size(), 2)
	assert_eq(case_data.evidence.size(), 1)
	assert_eq(case_data.statements.size(), 1)
	assert_eq(case_data.events.size(), 1)
	assert_eq(case_data.locations.size(), 1)
	assert_eq(case_data.event_triggers.size(), 1)
	assert_eq(case_data.interrogation_topics.size(), 1)
	assert_eq(case_data.actions.size(), 1)
	assert_eq(case_data.insights.size(), 1)
	assert_eq(case_data.lab_requests.size(), 1)
	assert_eq(case_data.surveillance_requests.size(), 1)


func test_pipeline_case_validates_without_errors() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var case_data: CaseData = CaseManager.get_case_data()
	var errors: Array[String] = case_data.validate()
	assert_eq(errors.size(), 0, "Full pipeline case should validate cleanly: %s" % str(errors))


func test_pipeline_roundtrip_to_dict() -> void:
	CaseManager.load_case(TEST_CASE_FILE)
	var case_data: CaseData = CaseManager.get_case_data()
	var exported: Dictionary = case_data.to_dict()
	# Re-parse the exported dictionary
	var reimported: CaseData = CaseData.from_dict(exported)
	assert_eq(reimported.id, case_data.id)
	assert_eq(reimported.persons.size(), case_data.persons.size())
	assert_eq(reimported.evidence.size(), case_data.evidence.size())
	assert_eq(reimported.locations.size(), case_data.locations.size())
	assert_eq(reimported.statements.size(), case_data.statements.size())
	assert_eq(reimported.events.size(), case_data.events.size())
