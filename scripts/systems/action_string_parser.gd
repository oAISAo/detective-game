## action_string_parser.gd
## Shared parser for colon-delimited action/condition strings used across
## ActionSystem, EventSystem, InterrogationManager, and case data.
## Centralizes all prefix constants and provides a single parse function
## so a typo causes a compile-time error instead of a silent runtime failure.
class_name ActionStringParser


# =========================================================================
# Requirement prefixes (ActionSystem._check_requirements)
# =========================================================================

const REQ_EVIDENCE := "evidence"
const REQ_LOCATION := "location"
const REQ_WARRANT := "warrant"
const REQ_ACTION_COMPLETED := "action_completed"
const REQ_INSIGHT := "insight"
const REQ_DAY := "day"


# =========================================================================
# Result prefixes (ActionSystem._apply_single_result)
# =========================================================================

const RES_EVIDENCE := "evidence"
const RES_INSIGHT := "insight"
const RES_LOCATION := "location"
const RES_WARRANT := "warrant"
const RES_MANDATORY := "mandatory"
const RES_LAB_REQUEST := "lab_request"
const RES_SURVEILLANCE := "surveillance"


# =========================================================================
# Event condition prefixes (EventSystem._check_conditions)
# =========================================================================

const COND_EVIDENCE_DISCOVERED := "evidence_discovered"
const COND_LOCATION_VISITED := "location_visited"
const COND_ACTION_COMPLETED := "action_completed"
const COND_WARRANT_OBTAINED := "warrant_obtained"
const COND_DAY := "day"
const COND_DAY_GTE := "day_gte"
const COND_LAB_COMPLETE := "lab_complete"
const COND_INSIGHT_DISCOVERED := "insight_discovered"
const COND_INTERROGATION_COMPLETED := "interrogation_completed"
const COND_TRIGGER_FIRED := "trigger_fired"


# =========================================================================
# Event action prefixes (EventSystem._dispatch_action)
# =========================================================================

const ACT_UNLOCK_EVIDENCE := "unlock_evidence"
const ACT_UNLOCK_EVENT := "unlock_event"
const ACT_UNLOCK_LOCATION := "unlock_location"
const ACT_UNLOCK_INTERROGATION := "unlock_interrogation"
const ACT_DELIVER_LAB_RESULTS := "deliver_lab_results"
const ACT_UNLOCK_WARRANT := "unlock_warrant"
const ACT_ADD_MANDATORY := "add_mandatory"
const ACT_SHOW_DIALOGUE := "show_dialogue"
const ACT_NOTIFY := "notify"


# =========================================================================
# Interrogation topic condition prefixes
# =========================================================================

const TOPIC_EVIDENCE := "evidence"
const TOPIC_STATEMENT := "statement"
const TOPIC_LOCATION := "location"


# =========================================================================
# Parsing
# =========================================================================

## Parsed result from a colon-delimited string.
## prefix = the part before the first colon, value = everything after.
## If the string has no colon, prefix is empty and value is the full string.

## Parses a "prefix:value" string. Returns [prefix, value].
## If no colon is found, returns ["", original_string].
static func parse(action_string: String) -> PackedStringArray:
	var parts: PackedStringArray = action_string.split(":", true, 1)
	if parts.size() < 2:
		return PackedStringArray(["", action_string])
	return PackedStringArray([parts[0].strip_edges(), parts[1].strip_edges()])


## Convenience: returns just the prefix portion.
static func get_prefix(action_string: String) -> String:
	return parse(action_string)[0]


## Convenience: returns just the value portion.
static func get_value(action_string: String) -> String:
	return parse(action_string)[1]


## Builds a "prefix:value" string from components.
static func build(prefix: String, value: String) -> String:
	return "%s:%s" % [prefix, value]
