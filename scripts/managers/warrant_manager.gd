## WarrantManager.gd
## Manages warrant requests with legal category validation, judge feedback,
## and arrest mechanics. Warrants are processed same-day (not delayed).
## Each warrant type requires a minimum number of unique legal categories
## from the supporting evidence.
extends BaseSubsystem


# --- Signals --- #

## Emitted when a warrant is approved.
signal warrant_approved(warrant_id: String, warrant_type: Enums.WarrantType, target: String)

## Emitted when a warrant is denied with judge feedback.
signal warrant_denied(warrant_id: String, warrant_type: Enums.WarrantType, feedback: String)

## Emitted when a suspect is arrested.
signal suspect_arrested(person_id: String)


# --- Constants --- #

## Required unique legal categories per warrant type.
const REQUIRED_CATEGORIES: Dictionary = {
	Enums.WarrantType.SEARCH: 2,
	Enums.WarrantType.SURVEILLANCE: 2,
	Enums.WarrantType.DIGITAL: 2,
	Enums.WarrantType.ARREST: 3,
}

## Human-readable names for legal categories.
const CATEGORY_NAMES: Dictionary = {
	Enums.LegalCategory.PRESENCE: "Presence",
	Enums.LegalCategory.MOTIVE: "Motive",
	Enums.LegalCategory.OPPORTUNITY: "Opportunity",
	Enums.LegalCategory.CONNECTION: "Connection",
}

## Human-readable names for warrant types.
const WARRANT_TYPE_NAMES: Dictionary = {
	Enums.WarrantType.SEARCH: "Search Warrant",
	Enums.WarrantType.SURVEILLANCE: "Surveillance Warrant",
	Enums.WarrantType.DIGITAL: "Digital Warrant",
	Enums.WarrantType.ARREST: "Arrest Warrant",
}


# --- State --- #

## All warrant requests: { warrant_id: Dictionary }
var _warrants: Dictionary = {}

## Suspects who have been arrested.
var _arrested_suspects: Array[String] = []

## Auto-incrementing ID counter.
var _next_id: int = 1


# --- Lifecycle --- #

func _ready() -> void:
	super()


# --- Warrant Requests --- #

## Requests a warrant. Returns a result dictionary with:
## { approved: bool, warrant_id: String, feedback: String }
func request_warrant(
	warrant_type: Enums.WarrantType,
	target: String,
	supporting_evidence_ids: Array[String]
) -> Dictionary:
	# Check for existing approved warrant of the same type+target
	if has_approved_warrant(warrant_type, target):
		return {
			"approved": false,
			"warrant_id": "",
			"feedback": "An approved %s for %s already exists." % [
				WARRANT_TYPE_NAMES.get(warrant_type, "warrant"), target
			],
		}

	var warrant_id: String = "warrant_%d" % _next_id
	_next_id += 1

	var categories: Array[int] = get_evidence_categories(supporting_evidence_ids)
	var required: int = REQUIRED_CATEGORIES.get(warrant_type, 2)
	var approved: bool = categories.size() >= required

	var warrant: Dictionary = {
		"id": warrant_id,
		"type": warrant_type,
		"target": target,
		"supporting_evidence": supporting_evidence_ids.duplicate(),
		"categories_provided": categories.duplicate(),
		"approved": approved,
		"day_requested": GameManager.current_day,
	}

	if approved:
		warrant["feedback"] = ""
		_warrants[warrant_id] = warrant
		GameManager.warrants_obtained.append(warrant_id)
		warrant_approved.emit(warrant_id, warrant_type, target)
		GameManager.log_action("Warrant approved: %s for %s" % [
			WARRANT_TYPE_NAMES.get(warrant_type, "Unknown"), target
		])
	else:
		var feedback: String = _generate_judge_feedback(warrant_type, categories)
		warrant["feedback"] = feedback
		_warrants[warrant_id] = warrant
		warrant_denied.emit(warrant_id, warrant_type, feedback)
		GameManager.log_action("Warrant denied: %s for %s — %s" % [
			WARRANT_TYPE_NAMES.get(warrant_type, "Unknown"), target, feedback
		])

	return {
		"approved": approved,
		"warrant_id": warrant_id,
		"feedback": warrant.get("feedback", ""),
	}


## Returns whether a warrant of the given type can be approved with the evidence.
func can_approve_warrant(
	warrant_type: Enums.WarrantType,
	supporting_evidence_ids: Array[String]
) -> bool:
	var categories: Array[int] = get_evidence_categories(supporting_evidence_ids)
	var required: int = REQUIRED_CATEGORIES.get(warrant_type, 2)
	return categories.size() >= required


# --- Legal Categories --- #

## Returns unique legal categories covered by the given evidence IDs.
func get_evidence_categories(evidence_ids: Array[String]) -> Array[int]:
	var unique_categories: Array[int] = []
	for ev_id: String in evidence_ids:
		var ev: EvidenceData = CaseManager.get_evidence(ev_id)
		if ev == null:
			continue
		for cat: int in ev.legal_categories:
			if cat not in unique_categories:
				unique_categories.append(cat)
	return unique_categories


## Returns the count of unique categories for the given evidence.
func get_category_count(evidence_ids: Array[String]) -> int:
	return get_evidence_categories(evidence_ids).size()


## Returns the number of categories required for a warrant type.
func get_required_categories(warrant_type: Enums.WarrantType) -> int:
	return REQUIRED_CATEGORIES.get(warrant_type, 2)


# --- Judge Feedback --- #

## Generates category-specific judge feedback for a denied warrant.
func _generate_judge_feedback(
	warrant_type: Enums.WarrantType,
	provided_categories: Array[int]
) -> String:
	var required: int = REQUIRED_CATEGORIES.get(warrant_type, 2)
	var missing_count: int = required - provided_categories.size()

	if provided_categories.is_empty():
		return "You haven't provided any supporting evidence."

	# Find which categories are missing
	var all_categories: Array[int] = [
		Enums.LegalCategory.PRESENCE,
		Enums.LegalCategory.MOTIVE,
		Enums.LegalCategory.OPPORTUNITY,
		Enums.LegalCategory.CONNECTION,
	]
	var missing: Array[String] = []
	for cat: int in all_categories:
		if cat not in provided_categories:
			missing.append(CATEGORY_NAMES.get(cat, "Unknown"))

	if missing_count == 1:
		return "You need one more category. Consider establishing: %s." % " or ".join(missing)
	return "You need %d more categories. Consider establishing: %s." % [
		missing_count, ", ".join(missing)
	]


## Returns judge feedback for a hypothetical warrant request (without filing).
func get_judge_feedback(
	warrant_type: Enums.WarrantType,
	evidence_ids: Array[String]
) -> String:
	var categories: Array[int] = get_evidence_categories(evidence_ids)
	var required: int = REQUIRED_CATEGORIES.get(warrant_type, 2)
	if categories.size() >= required:
		return "This evidence should be sufficient."
	return _generate_judge_feedback(warrant_type, categories)


# --- Arrest Mechanics --- #

## Arrests a suspect. Requires an ARREST warrant (3+ categories).
## Returns a result dictionary with { success: bool, feedback: String }.
func arrest_suspect(
	person_id: String,
	supporting_evidence_ids: Array[String]
) -> Dictionary:
	# Check if already arrested
	if is_arrested(person_id):
		return {"success": false, "feedback": "Suspect already under arrest."}

	# Validate person exists
	var person: PersonData = CaseManager.get_person(person_id)
	if person == null:
		push_error("[WarrantManager] Person not found: %s" % person_id)
		return {"success": false, "feedback": "Suspect not found."}

	# Request arrest warrant
	var result: Dictionary = request_warrant(
		Enums.WarrantType.ARREST, person_id, supporting_evidence_ids
	)

	if not result.get("approved", false):
		return {"success": false, "feedback": result.get("feedback", "Insufficient evidence.")}

	_arrested_suspects.append(person_id)
	suspect_arrested.emit(person_id)
	GameManager.log_action("Suspect arrested: %s" % person.name)
	return {"success": true, "feedback": "Arrest warrant approved. Suspect taken into custody."}


## Returns whether a suspect has been arrested.
func is_arrested(person_id: String) -> bool:
	return person_id in _arrested_suspects


## Returns all arrested suspect IDs.
func get_arrested_suspects() -> Array[String]:
	return _arrested_suspects.duplicate()


# --- Query --- #

## Returns whether an approved warrant of the given type+target already exists.
func has_approved_warrant(warrant_type: Enums.WarrantType, target: String) -> bool:
	for w: Dictionary in _warrants.values():
		if w.get("approved", false) and w.get("type", -1) == warrant_type and w.get("target", "") == target:
			return true
	return false


## Returns a specific warrant by ID.
func get_warrant(warrant_id: String) -> Dictionary:
	if warrant_id in _warrants:
		return _warrants[warrant_id].duplicate()
	return {}


## Returns all approved warrants.
func get_approved_warrants() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for w: Dictionary in _warrants.values():
		if w.get("approved", false):
			result.append(w.duplicate())
	return result


## Returns all denied warrants.
func get_denied_warrants() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for w: Dictionary in _warrants.values():
		if not w.get("approved", false):
			result.append(w.duplicate())
	return result


## Returns the total number of warrants filed.
func get_warrant_count() -> int:
	return _warrants.size()


## Returns whether the manager has any data.
func has_content() -> bool:
	return not _warrants.is_empty() or not _arrested_suspects.is_empty()


# --- Serialization --- #

## Returns the warrant manager state for saving.
func serialize() -> Dictionary:
	return {
		"warrants": _warrants.duplicate(true),
		"arrested_suspects": _arrested_suspects.duplicate(),
		"next_id": _next_id,
	}


## Restores warrant manager state from saved data.
func deserialize(data: Dictionary) -> void:
	_warrants = data.get("warrants", {}).duplicate(true)
	_arrested_suspects.assign(data.get("arrested_suspects", []))
	_next_id = data.get("next_id", 1)


## Resets all warrant manager state for a new game.
func reset() -> void:
	_warrants.clear()
	_arrested_suspects.clear()
	_next_id = 1
