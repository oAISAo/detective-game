## case_data.gd
## Top-level container for all case data.
## Holds references to all persons, evidence, events, locations, etc.
class_name CaseData
extends Resource


## Unique identifier for this case.
@export var id: String = ""

## Display title of the case.
@export var title: String = ""

## Description / synopsis of the case.
@export var description: String = ""

## First investigation day.
@export var start_day: int = 1

## Last investigation day.
@export var end_day: int = 4

## All persons involved in the case.
var persons: Array[PersonData] = []

## All locations in the case.
var locations: Array[LocationData] = []

## All evidence items in the case.
var evidence: Array[EvidenceData] = []

## All statements recorded in the case.
var statements: Array[StatementData] = []

## All events in the case timeline.
var events: Array[EventData] = []

## All event triggers.
var event_triggers: Array[EventTriggerData] = []

## All interrogation topics.
var interrogation_topics: Array[InterrogationTopicData] = []

## All available actions.
var actions: Array[ActionData] = []

## All insights.
var insights: Array[InsightData] = []

## All lab request definitions.
var lab_requests: Array[LabRequestData] = []

## All surveillance request definitions.
var surveillance_requests: Array[SurveillanceRequestData] = []

## All interrogation triggers (evidence-based reactions during interrogation).
var interrogation_triggers: Array[InterrogationTriggerData] = []

## All discovery rules (conditional evidence availability).
var discovery_rules: Array[DiscoveryRuleData] = []

## Solution: correct suspect person ID.
var solution_suspect: String = ""

## Solution: correct motive description.
var solution_motive: String = ""

## Solution: correct weapon/method.
var solution_weapon: String = ""

## Solution: correct time of crime in minutes from midnight.
var solution_time_minutes: int = -1

## Solution: correct day of crime.
var solution_time_day: int = -1

## Solution: how the suspect accessed the location.
var solution_access: String = ""

## IDs of evidence considered critical for the case.
var critical_evidence_ids: Array[String] = []


## Creates a CaseData from a JSON dictionary.
static func from_dict(data: Dictionary) -> CaseData:
	var res := CaseData.new()
	res.id = data.get("id", "")
	res.title = data.get("title", "")
	res.description = data.get("description", "")
	res.start_day = int(data.get("start_day", 1))
	res.end_day = int(data.get("end_day", 4))

	# Parse persons
	res.persons = []
	for item: Dictionary in data.get("persons", []):
		res.persons.append(PersonData.from_dict(item))

	# Parse locations
	res.locations = []
	for item: Dictionary in data.get("locations", []):
		res.locations.append(LocationData.from_dict(item))

	# Parse evidence
	res.evidence = []
	for item: Dictionary in data.get("evidence", []):
		res.evidence.append(EvidenceData.from_dict(item))

	# Parse statements
	res.statements = []
	for item: Dictionary in data.get("statements", []):
		res.statements.append(StatementData.from_dict(item))

	# Parse events
	res.events = []
	for item: Dictionary in data.get("events", []):
		res.events.append(EventData.from_dict(item))

	# Parse event triggers
	res.event_triggers = []
	for item: Dictionary in data.get("event_triggers", []):
		res.event_triggers.append(EventTriggerData.from_dict(item))

	# Parse interrogation topics
	res.interrogation_topics = []
	for item: Dictionary in data.get("interrogation_topics", []):
		res.interrogation_topics.append(InterrogationTopicData.from_dict(item))

	# Parse actions
	res.actions = []
	for item: Dictionary in data.get("actions", []):
		res.actions.append(ActionData.from_dict(item))

	# Parse insights
	res.insights = []
	for item: Dictionary in data.get("insights", []):
		res.insights.append(InsightData.from_dict(item))

	# Parse lab requests
	res.lab_requests = []
	for item: Dictionary in data.get("lab_requests", []):
		res.lab_requests.append(LabRequestData.from_dict(item))

	# Parse surveillance requests
	res.surveillance_requests = []
	for item: Dictionary in data.get("surveillance_requests", []):
		res.surveillance_requests.append(SurveillanceRequestData.from_dict(item))

	# Parse interrogation triggers
	res.interrogation_triggers = []
	for item: Dictionary in data.get("interrogation_triggers", []):
		res.interrogation_triggers.append(InterrogationTriggerData.from_dict(item))

	# Parse discovery rules
	res.discovery_rules = []
	for item: Dictionary in data.get("discovery_rules", []):
		res.discovery_rules.append(DiscoveryRuleData.from_dict(item))

	# Parse solution data
	var solution: Dictionary = data.get("solution", {})
	res.solution_suspect = solution.get("suspect", "")
	res.solution_motive = solution.get("motive", "")
	res.solution_weapon = solution.get("weapon", "")
	res.solution_time_minutes = int(solution.get("time_minutes", -1))
	res.solution_time_day = int(solution.get("time_day", -1))
	res.solution_access = solution.get("access", "")

	# Parse critical evidence IDs
	var crit: Array = data.get("critical_evidence_ids", [])
	res.critical_evidence_ids = []
	for eid in crit:
		res.critical_evidence_ids.append(str(eid))

	return res


## Returns validation errors for the entire case. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("CaseData: id is required")
	if title.is_empty():
		errors.append("CaseData: title is required")
	if end_day < start_day:
		errors.append("CaseData: end_day must be >= start_day")
	if persons.is_empty():
		errors.append("CaseData: at least one person is required")

	# Validate all nested resources
	for person: PersonData in persons:
		errors.append_array(person.validate())
	for loc: LocationData in locations:
		errors.append_array(loc.validate())
	for ev: EvidenceData in evidence:
		errors.append_array(ev.validate())
	for stmt: StatementData in statements:
		errors.append_array(stmt.validate())
	for evt: EventData in events:
		errors.append_array(evt.validate())
	for trigger: EventTriggerData in event_triggers:
		errors.append_array(trigger.validate())
	for topic: InterrogationTopicData in interrogation_topics:
		errors.append_array(topic.validate())
	for action: ActionData in actions:
		errors.append_array(action.validate())
	for insight: InsightData in insights:
		errors.append_array(insight.validate())
	for lab_req: LabRequestData in lab_requests:
		errors.append_array(lab_req.validate())
	for surv_req: SurveillanceRequestData in surveillance_requests:
		errors.append_array(surv_req.validate())
	for interr_trig: InterrogationTriggerData in interrogation_triggers:
		errors.append_array(interr_trig.validate())
	for rule: DiscoveryRuleData in discovery_rules:
		errors.append_array(rule.validate())

	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	var result := {
		"id": id,
		"title": title,
		"description": description,
		"start_day": start_day,
		"end_day": end_day,
	}

	var arr: Array[Dictionary] = []

	arr = []
	for p: PersonData in persons:
		arr.append(p.to_dict())
	result["persons"] = arr

	arr = []
	for l: LocationData in locations:
		arr.append(l.to_dict())
	result["locations"] = arr

	arr = []
	for e: EvidenceData in evidence:
		arr.append(e.to_dict())
	result["evidence"] = arr

	arr = []
	for s: StatementData in statements:
		arr.append(s.to_dict())
	result["statements"] = arr

	arr = []
	for ev: EventData in events:
		arr.append(ev.to_dict())
	result["events"] = arr

	arr = []
	for t: EventTriggerData in event_triggers:
		arr.append(t.to_dict())
	result["event_triggers"] = arr

	arr = []
	for topic: InterrogationTopicData in interrogation_topics:
		arr.append(topic.to_dict())
	result["interrogation_topics"] = arr

	arr = []
	for a: ActionData in actions:
		arr.append(a.to_dict())
	result["actions"] = arr

	arr = []
	for i: InsightData in insights:
		arr.append(i.to_dict())
	result["insights"] = arr

	arr = []
	for lr: LabRequestData in lab_requests:
		arr.append(lr.to_dict())
	result["lab_requests"] = arr

	arr = []
	for sr: SurveillanceRequestData in surveillance_requests:
		arr.append(sr.to_dict())
	result["surveillance_requests"] = arr

	arr = []
	for it: InterrogationTriggerData in interrogation_triggers:
		arr.append(it.to_dict())
	result["interrogation_triggers"] = arr

	arr = []
	for dr: DiscoveryRuleData in discovery_rules:
		arr.append(dr.to_dict())
	result["discovery_rules"] = arr

	return result
