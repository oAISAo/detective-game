## Enums.gd
## Global enum definitions used across the entire project.
## These are autoloaded via preload or referenced directly.
class_name Enums


## The type of evidence collected during investigation.
enum EvidenceType {
	FORENSIC,
	DOCUMENT,
	PHOTO,
	RECORDING,
	FINANCIAL,
	DIGITAL,
	OBJECT,
}

## The role a person plays in the case.
enum PersonRole {
	VICTIM,
	SUSPECT,
	WITNESS,
	INVESTIGATOR,
	TECHNICIAN,
}

## The type of relationship between two persons.
enum RelationshipType {
	SPOUSE,
	COWORKER,
	BUSINESS_PARTNER,
	FRIEND,
	ENEMY,
	FAMILY,
}

## The current status of evidence submitted to the lab.
enum LabStatus {
	NOT_SUBMITTED,
	PROCESSING,
	COMPLETED,
}

## Personality traits that affect interrogation behavior.
enum PersonalityTrait {
	AGGRESSIVE,
	ANXIOUS,
	MANIPULATIVE,
	CALM,
}

## How important a piece of evidence is to the case.
enum ImportanceLevel {
	CRITICAL,
	SUPPORTING,
	OPTIONAL,
}

## How the evidence was discovered.
enum DiscoveryMethod {
	VISUAL,
	TOOL,
	COMPARISON,
	LAB,
	SURVEILLANCE,
}

## How certain we are about an event's occurrence.
enum CertaintyLevel {
	CONFIRMED,
	LIKELY,
	CLAIMED,
	UNKNOWN,
}

## How much impact an interrogation trigger has.
enum ImpactLevel {
	MINOR,
	MAJOR,
	BREAKPOINT,
}

## The investigation state of an object at a location.
enum InvestigationState {
	NOT_INSPECTED,
	PARTIALLY_EXAMINED,
	FULLY_EXAMINED,
}

## The type of action the player can take.
enum ActionType {
	INTERROGATION,
	VISIT_LOCATION,
	SEARCH_LOCATION,
	EXAMINE_DEVICE,
	ANALYZE_EVIDENCE,
}

## The current time slot within a day.
enum TimeSlot {
	MORNING,
	AFTERNOON,
	EVENING,
	NIGHT,
}

## How an event trigger is activated.
enum TriggerType {
	TIMED,
	CONDITIONAL,
	DAY_START,
}

## Legal categories used for warrant validation.
enum LegalCategory {
	PRESENCE,
	MOTIVE,
	OPPORTUNITY,
	CONNECTION,
}

## How a suspect reacts during interrogation.
enum ReactionType {
	DENIAL,
	ADMISSION,
	ANGER,
	PANIC,
	SILENCE,
	REVELATION,
	PARTIAL_CONFESSION,
	DEFLECTION,
}

## The type of surveillance that can be installed.
enum SurveillanceType {
	PHONE_TAP,
	HOME_SURVEILLANCE,
	FINANCIAL_MONITORING,
}
