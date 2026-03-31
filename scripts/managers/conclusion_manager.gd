## ConclusionManager.gd
## Manages the case conclusion flow: case report submission, prosecutor
## confidence scoring, outcome determination, and epilogue generation.
## This is the endgame system — the most important emotional moment of the game.
extends Node


# --- Signals --- #

## Emitted when a case report is submitted.
signal report_submitted(report: Dictionary)

## Emitted when the prosecutor has evaluated the report.
signal prosecutor_evaluated(score: float, level: Enums.ConfidenceLevel)

## Emitted when the player chooses to charge, investigate, or review.
signal player_choice_made(choice: String)

## Emitted when the final case outcome is determined.
signal outcome_determined(outcome: Enums.CaseOutcome)


# --- Constants --- #

## Scoring factor weights (must sum to 1.0 before bonuses/penalties).
const WEIGHT_EVIDENCE: float = 0.30
const WEIGHT_TIMELINE: float = 0.25
const WEIGHT_MOTIVE: float = 0.20
const WEIGHT_ALTERNATIVES: float = 0.15

## Bonus/penalty factors (additive, not part of the 90% base).
const PENALTY_CONTRADICTIONS: float = 0.10
const BONUS_COVERAGE: float = 0.10

## Confidence level thresholds.
const THRESHOLD_MODERATE: float = 0.40
const THRESHOLD_STRONG: float = 0.70
const THRESHOLD_PERFECT: float = 0.90

## The five report sections.
const REPORT_SECTIONS: Array[String] = [
	"suspect", "motive", "weapon", "time", "access",
]

## Prosecutor dialogue per confidence level.
const PROSECUTOR_DIALOGUE: Dictionary = {
	Enums.ConfidenceLevel.WEAK: "This theory has serious holes.",
	Enums.ConfidenceLevel.MODERATE: "You might convince a jury, but the defense will push.",
	Enums.ConfidenceLevel.STRONG: "This case is ready for court.",
	Enums.ConfidenceLevel.PERFECT: "This is airtight.",
}

## Player choice options after seeing the score.
const CHOICE_CHARGE: String = "charge"
const CHOICE_INVESTIGATE: String = "investigate"
const CHOICE_REVIEW: String = "review"


# --- State --- #

## The submitted case report: { section_name: { answer: String, evidence: Array[String] } }
var _report: Dictionary = {}

## The computed confidence score (0.0–1.0).
var _confidence_score: float = 0.0

## The confidence level enum.
var _confidence_level: Enums.ConfidenceLevel = Enums.ConfidenceLevel.WEAK

## The final case outcome.
var _outcome: Enums.CaseOutcome = Enums.CaseOutcome.INCORRECT_THEORY

## Whether a report has been submitted and evaluated.
var _evaluated: bool = false

## The player's choice after seeing the score.
var _player_choice: String = ""


# --- Lifecycle --- #

func _ready() -> void:
	print("[ConclusionManager] Initialized.")


# --- Report Submission --- #

## Submits a full case report. Returns true if valid.
## report_data format: { "suspect": { "answer": "p_mark", "evidence": ["ev1"] }, ... }
func submit_report(report_data: Dictionary) -> bool:
	if has_report():
		push_warning("[ConclusionManager] Report already submitted.")
		return false
	# Validate all sections present
	for section: String in REPORT_SECTIONS:
		if section not in report_data:
			push_warning("[ConclusionManager] Missing report section: %s" % section)
			return false
		var entry: Dictionary = report_data[section]
		if not entry.has("answer") or not entry.has("evidence"):
			push_warning("[ConclusionManager] Invalid section format: %s" % section)
			return false

	_report = report_data.duplicate(true)
	_evaluate_report()
	report_submitted.emit(_report)
	return true


## Returns the current report, or empty dict if none submitted.
func get_report() -> Dictionary:
	return _report.duplicate(true)


## Returns whether a report has been submitted.
func has_report() -> bool:
	return not _report.is_empty()


## Clears the submitted report so the player can revise and resubmit.
func _retract_report() -> void:
	_report.clear()
	_confidence_score = 0.0
	_confidence_level = Enums.ConfidenceLevel.WEAK
	_evaluated = false


# --- Scoring Engine --- #

## Internal: evaluates the submitted report and computes confident score.
func _evaluate_report() -> void:
	var evidence_score: float = _calculate_evidence_score()
	var timeline_score: float = _calculate_timeline_score()
	var motive_score: float = _calculate_motive_score()
	var alternatives_score: float = _calculate_alternatives_score()
	var contradiction_penalty: float = _calculate_contradiction_penalty()
	var coverage_bonus: float = _calculate_coverage_bonus()

	# Base score from weighted factors
	var base: float = (
		evidence_score * WEIGHT_EVIDENCE
		+ timeline_score * WEIGHT_TIMELINE
		+ motive_score * WEIGHT_MOTIVE
		+ alternatives_score * WEIGHT_ALTERNATIVES
	)

	# Apply bonus and penalty
	_confidence_score = clampf(base + coverage_bonus - contradiction_penalty, 0.0, 1.0)
	_confidence_level = _score_to_level(_confidence_score)
	_evaluated = true
	prosecutor_evaluated.emit(_confidence_score, _confidence_level)


## Calculates evidence strength score (0.0–1.0).
## Based on average weight of evidence supporting the report.
func _calculate_evidence_score() -> float:
	var total_weight: float = 0.0
	var count: int = 0
	for section: String in REPORT_SECTIONS:
		var entry: Dictionary = _report.get(section, {})
		var ev_ids: Array = entry.get("evidence", [])
		for ev_id in ev_ids:
			var ev: EvidenceData = CaseManager.get_evidence(str(ev_id))
			if ev != null:
				total_weight += ev.weight
				count += 1
	if count == 0:
		return 0.0
	return clampf(total_weight / float(count), 0.0, 1.0)


## Calculates timeline accuracy score (0.0–1.0).
## Compares reported time against the solution time.
func _calculate_timeline_score() -> float:
	var case_data: CaseData = CaseManager.get_case_data()
	if case_data == null:
		return 0.0

	var time_entry: Dictionary = _report.get("time", {})
	var answer: String = time_entry.get("answer", "")
	if answer.is_empty():
		return 0.0

	# Parse reported time
	var parsed: Array[int] = _parse_time_answer(answer)
	var reported_minutes: int = parsed[0]
	var reported_day: int = parsed[1]

	var sol_day: int = case_data.solution_time_day
	var sol_minutes: int = case_data.solution_time_minutes

	if sol_day < 0 or sol_minutes < 0:
		# No solution time defined — give partial credit for having an answer
		return 0.5

	if reported_day < 0 or reported_minutes < 0:
		# Could not parse — give minimal credit
		return 0.2

	# Score based on accuracy
	var day_correct: bool = (reported_day == sol_day)
	var time_diff: int = absi(reported_minutes - sol_minutes)

	if day_correct and time_diff <= 15:
		return 1.0  # Within 15 minutes
	elif day_correct and time_diff <= 60:
		return 0.7  # Within an hour
	elif day_correct:
		return 0.4  # Right day, wrong time
	return 0.1  # Wrong day


## Parses a time answer string. Returns [minutes, day].
## Accepts formats: "1260 1" (minutes day), "21:00 Day 1" (HH:MM Day D).
func _parse_time_answer(answer: String) -> Array[int]:
	# Try "minutes day" format (used internally)
	var parts: PackedStringArray = answer.strip_edges().split(" ")
	if parts.size() >= 2:
		if parts[0].is_valid_int() and parts[-1].is_valid_int():
			return [int(parts[0]), int(parts[-1])]
		# Try "HH:MM Day D"
		if ":" in parts[0] and parts.size() >= 3:
			var time_parts: PackedStringArray = parts[0].split(":")
			if time_parts.size() == 2 and time_parts[0].is_valid_int() and time_parts[1].is_valid_int():
				var mins: int = int(time_parts[0]) * 60 + int(time_parts[1])
				var day_val: int = int(parts[-1]) if parts[-1].is_valid_int() else -1
				return [mins, day_val]
	return [-1, -1]


## Calculates motive proof score (0.0–1.0).
## Checks if the reported motive answer is non-empty and has evidence.
func _calculate_motive_score() -> float:
	var motive_entry: Dictionary = _report.get("motive", {})
	var answer: String = str(motive_entry.get("answer", ""))
	var evidence: Array = motive_entry.get("evidence", [])

	if answer.is_empty():
		return 0.0
	if evidence.is_empty():
		return 0.3  # Claim without evidence

	# Check if any evidence has MOTIVE legal category
	var has_motive_cat: bool = false
	for ev_id in evidence:
		var ev: EvidenceData = CaseManager.get_evidence(str(ev_id))
		if ev != null:
			for cat: int in ev.legal_categories:
				if cat == Enums.LegalCategory.MOTIVE:
					has_motive_cat = true
					break
		if has_motive_cat:
			break

	return 1.0 if has_motive_cat else 0.6


## Calculates alternative suspects eliminated score (0.0–1.0).
## Based on how many suspects have been investigated vs total.
func _calculate_alternatives_score() -> float:
	var suspects: Array[PersonData] = CaseManager.get_suspects()
	if suspects.size() <= 1:
		return 1.0  # Only one suspect, trivially eliminated alternatives

	var interr_mgr: Node = get_node_or_null("/root/InterrogationManager")
	var investigated_count: int = 0
	for suspect: PersonData in suspects:
		# Consider a suspect "investigated" if they have any fired triggers
		# or accumulated pressure (meaning an interrogation session occurred).
		if interr_mgr != null:
			var fired: Array = interr_mgr.get_fired_triggers_for_person(suspect.id)
			if not fired.is_empty():
				investigated_count += 1
				continue
			if interr_mgr.get_pressure_for_person(suspect.id) > 0:
				investigated_count += 1
				continue
		# Fallback: check GameManager.completed_interrogations for legacy saves
		if GameManager.completed_interrogations.has(suspect.id):
			investigated_count += 1

	return clampf(float(investigated_count) / float(suspects.size()), 0.0, 1.0)


## Calculates contradiction penalty (0.0–PENALTY_CONTRADICTIONS).
## Based on theory inconsistencies.
func _calculate_contradiction_penalty() -> float:
	var theory_mgr: Node = get_node_or_null("/root/TheoryManager")
	if theory_mgr == null:
		return 0.0

	var theories: Array[Dictionary] = theory_mgr.get_all_theories()
	if theories.is_empty():
		return 0.0

	# Check the first complete theory for inconsistencies
	for theory: Dictionary in theories:
		if theory_mgr.is_complete(theory["id"]):
			var inconsistencies: Array = theory_mgr.get_inconsistencies(theory["id"])
			if not inconsistencies.is_empty():
				var penalty_per: float = PENALTY_CONTRADICTIONS / 3.0
				return minf(float(inconsistencies.size()) * penalty_per, PENALTY_CONTRADICTIONS)
			return 0.0

	return 0.0


## Calculates coverage bonus (0.0–BONUS_COVERAGE).
## Based on percentage of critical evidence discovered.
func _calculate_coverage_bonus() -> float:
	var case_data: CaseData = CaseManager.get_case_data()
	if case_data == null:
		return 0.0

	var critical_ids: Array[String] = case_data.critical_evidence_ids
	if critical_ids.is_empty():
		return BONUS_COVERAGE  # No critical evidence defined — full bonus

	var discovered: int = 0
	for eid: String in critical_ids:
		if GameManager.has_evidence(eid):
			discovered += 1

	var coverage: float = float(discovered) / float(critical_ids.size())
	return coverage * BONUS_COVERAGE


## Converts a score to a confidence level.
func _score_to_level(score: float) -> Enums.ConfidenceLevel:
	if score >= THRESHOLD_PERFECT:
		return Enums.ConfidenceLevel.PERFECT
	elif score >= THRESHOLD_STRONG:
		return Enums.ConfidenceLevel.STRONG
	elif score >= THRESHOLD_MODERATE:
		return Enums.ConfidenceLevel.MODERATE
	return Enums.ConfidenceLevel.WEAK


# --- Scoring Queries --- #

## Returns the confidence score (0.0–1.0).
func get_confidence_score() -> float:
	return _confidence_score


## Returns the confidence level enum.
func get_confidence_level() -> Enums.ConfidenceLevel:
	return _confidence_level


## Returns the prosecutor dialogue for the current level.
func get_prosecutor_dialogue() -> String:
	return PROSECUTOR_DIALOGUE.get(_confidence_level, "")


## Returns whether the report has been evaluated.
func is_evaluated() -> bool:
	return _evaluated


# --- Player Choice --- #

## Records the player's choice after seeing the prosecutor's response.
## Valid choices: "charge", "investigate", "review"
func make_choice(choice: String) -> bool:
	if choice not in [CHOICE_CHARGE, CHOICE_INVESTIGATE, CHOICE_REVIEW]:
		push_warning("[ConclusionManager] Invalid choice: %s" % choice)
		return false
	_player_choice = choice
	player_choice_made.emit(choice)

	match choice:
		CHOICE_CHARGE:
			_determine_outcome()
		CHOICE_INVESTIGATE:
			# Return to investigation — clear report so the player can resubmit later
			_retract_report()
		CHOICE_REVIEW:
			# Let the player revise their report
			_retract_report()

	return true


## Returns the player's choice.
func get_player_choice() -> String:
	return _player_choice


# --- Outcome Determination --- #

## Determines the final case outcome based on the report and confidence.
func _determine_outcome() -> void:
	var correct_suspect: bool = _is_correct_suspect()

	if correct_suspect and _confidence_score >= THRESHOLD_PERFECT:
		_outcome = Enums.CaseOutcome.PERFECT_SOLUTION
	elif correct_suspect and _confidence_score >= THRESHOLD_MODERATE:
		_outcome = Enums.CaseOutcome.CORRECT_BUT_INCOMPLETE
	elif not correct_suspect and _confidence_score >= THRESHOLD_MODERATE:
		_outcome = Enums.CaseOutcome.WRONG_BUT_PLAUSIBLE
	else:
		_outcome = Enums.CaseOutcome.INCORRECT_THEORY

	outcome_determined.emit(_outcome)
	GameManager._log_action("Case concluded: %s" % get_outcome_name())


## Returns whether the submitted suspect matches the solution.
func _is_correct_suspect() -> bool:
	var case_data: CaseData = CaseManager.get_case_data()
	if case_data == null:
		return false

	var suspect_entry: Dictionary = _report.get("suspect", {})
	var reported_suspect: String = str(suspect_entry.get("answer", ""))
	return reported_suspect == case_data.solution_suspect


## Returns the case outcome.
func get_outcome() -> Enums.CaseOutcome:
	return _outcome


## Returns the outcome name as a display string.
func get_outcome_name() -> String:
	match _outcome:
		Enums.CaseOutcome.PERFECT_SOLUTION:
			return "Perfect Solution"
		Enums.CaseOutcome.CORRECT_BUT_INCOMPLETE:
			return "Correct But Incomplete"
		Enums.CaseOutcome.WRONG_BUT_PLAUSIBLE:
			return "Wrong Suspect, Plausible Theory"
		Enums.CaseOutcome.INCORRECT_THEORY:
			return "Incorrect Theory"
	return "Unknown"


# --- Epilogue --- #

## Generates the epilogue summary: what was discovered vs missed.
func get_epilogue() -> Dictionary:
	var case_data: CaseData = CaseManager.get_case_data()
	if case_data == null:
		return {"discovered": [], "missed": []}

	var discovered: Array[Dictionary] = []
	var missed: Array[Dictionary] = []

	for ev: EvidenceData in CaseManager.get_all_evidence():
		var entry: Dictionary = {"id": ev.id, "name": ev.name}
		if GameManager.has_evidence(ev.id):
			discovered.append(entry)
		else:
			missed.append(entry)

	return {
		"discovered": discovered,
		"missed": missed,
		"outcome": get_outcome_name(),
		"score": _confidence_score,
		"dialogue": get_prosecutor_dialogue(),
	}


## Returns whether the manager has active state.
func has_content() -> bool:
	return not _report.is_empty() or _evaluated


# --- Individual Score Accessors (for testing/debug) --- #

## Returns the evidence strength component (0.0–1.0).
func get_evidence_score() -> float:
	return _calculate_evidence_score()


## Returns the timeline accuracy component (0.0–1.0).
func get_timeline_score() -> float:
	return _calculate_timeline_score()


## Returns the motive proof component (0.0–1.0).
func get_motive_score() -> float:
	return _calculate_motive_score()


## Returns the alternatives eliminated component (0.0–1.0).
func get_alternatives_score() -> float:
	return _calculate_alternatives_score()


## Returns the contradiction penalty (0.0–0.1).
func get_contradiction_penalty() -> float:
	return _calculate_contradiction_penalty()


## Returns the coverage bonus (0.0–0.1).
func get_coverage_bonus() -> float:
	return _calculate_coverage_bonus()


# --- Serialization --- #

## Serializes conclusion state.
func serialize() -> Dictionary:
	return {
		"report": _report.duplicate(true),
		"confidence_score": _confidence_score,
		"confidence_level": _confidence_level,
		"outcome": _outcome,
		"evaluated": _evaluated,
		"player_choice": _player_choice,
	}


## Restores conclusion state from saved data.
func deserialize(data: Dictionary) -> void:
	_report = data.get("report", {})
	_confidence_score = data.get("confidence_score", 0.0)
	_confidence_level = data.get("confidence_level", Enums.ConfidenceLevel.WEAK) as Enums.ConfidenceLevel
	_outcome = data.get("outcome", Enums.CaseOutcome.INCORRECT_THEORY) as Enums.CaseOutcome
	_evaluated = data.get("evaluated", false)
	_player_choice = data.get("player_choice", "")


## Resets all conclusion state.
func reset() -> void:
	_report.clear()
	_confidence_score = 0.0
	_confidence_level = Enums.ConfidenceLevel.WEAK
	_outcome = Enums.CaseOutcome.INCORRECT_THEORY
	_evaluated = false
	_player_choice = ""
