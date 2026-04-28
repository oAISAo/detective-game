## EvidenceManager.gd
## Manages evidence-related features: filtering, searching, pinning,
## comparison, contradiction detection, and progressive hints.
## Phase 5: Central hub for all evidence system logic.
extends BaseSubsystem


# --- Signals --- #

## Emitted when evidence is pinned to the quick-access bar.
signal evidence_pinned(evidence_id: String)

## Emitted when evidence is unpinned from the quick-access bar.
signal evidence_unpinned(evidence_id: String)

## Emitted when a new insight is generated from evidence comparison.
signal insight_generated(insight_id: String)

## Emitted when a new contradiction is detected between statement and evidence.
signal contradiction_detected(statement_id: String, evidence_id: String)

## Emitted when a progressive hint is delivered.
signal hint_delivered(hint_text: String, source: String)
signal state_loaded

## Emitted when the player sets a verdict on a statement-evidence link.
signal statement_verdict_changed(evidence_id: String, statement_id: String, verdict: String)

## Emitted when the player updates a note on a statement-evidence link.
signal statement_note_changed(evidence_id: String, statement_id: String)


# --- Constants --- #

## Maximum number of pinned evidence items.
const MAX_PINNED: int = 5


# --- State --- #

## IDs of evidence pinned to the quick-access bar.
var pinned_evidence: Array[String] = []

## Detected contradictions: [{statement_id, evidence_id, statement_text, person_id}]
var detected_contradictions: Array[Dictionary] = []

## Player verdicts per statement-evidence pair.
## Key: "evidence_id:statement_id", Value: StatementVerdictData
var _statement_verdicts: Dictionary = {}


# --- Lifecycle --- #

func _ready() -> void:
	super()
	# Defer signal connection to ensure GameManager is initialized regardless of autoload order
	_connect_game_manager_signals.call_deferred()


func _connect_game_manager_signals() -> void:
	if GameManager and GameManager.has_signal("evidence_discovered"):
		GameManager.evidence_discovered.connect(_on_evidence_discovered)


# --- Query: Discovered Evidence Data --- #

## Returns EvidenceData resources for all discovered evidence.
func get_discovered_evidence_data() -> Array[EvidenceData]:
	var result: Array[EvidenceData] = []
	for eid: String in GameManager.discovered_evidence:
		var ev: EvidenceData = CaseManager.get_evidence(eid)
		if ev != null:
			result.append(ev)
	return result


# --- Filtering --- #

## Filters discovered evidence by type.
func filter_by_type(type: Enums.EvidenceType) -> Array[EvidenceData]:
	var result: Array[EvidenceData] = []
	for ev: EvidenceData in get_discovered_evidence_data():
		if ev.type == type:
			result.append(ev)
	return result


## Filters discovered evidence by tag.
func filter_by_tag(tag: String) -> Array[EvidenceData]:
	var result: Array[EvidenceData] = []
	for ev: EvidenceData in get_discovered_evidence_data():
		if tag in ev.tags:
			result.append(ev)
	return result


# --- Search --- #

## Searches discovered evidence by name, description, or tags (case-insensitive).
func search_evidence(query: String) -> Array[EvidenceData]:
	if query.is_empty():
		return get_discovered_evidence_data()

	var lower_query: String = query.to_lower()
	var result: Array[EvidenceData] = []
	for ev: EvidenceData in get_discovered_evidence_data():
		if lower_query in ev.name.to_lower():
			result.append(ev)
		elif lower_query in ev.description.to_lower():
			result.append(ev)
		elif _matches_tags(ev, lower_query):
			result.append(ev)
	return result


## Checks if any tag on the evidence matches the query.
func _matches_tags(ev: EvidenceData, query: String) -> bool:
	for tag: String in ev.tags:
		if query in tag.to_lower():
			return true
	return false


# --- Pinning --- #

## Pins evidence to the quick-access bar. Returns true on success.
func pin_evidence(evidence_id: String) -> bool:
	if evidence_id in pinned_evidence:
		return false
	if pinned_evidence.size() >= MAX_PINNED:
		push_warning("[EvidenceManager] Cannot pin — maximum %d items reached." % MAX_PINNED)
		return false
	if not GameManager.has_evidence(evidence_id):
		push_error("[EvidenceManager] Cannot pin undiscovered evidence: %s" % evidence_id)
		return false
	pinned_evidence.append(evidence_id)
	evidence_pinned.emit(evidence_id)
	return true


## Unpins evidence from the quick-access bar. Returns true on success.
func unpin_evidence(evidence_id: String) -> bool:
	if evidence_id not in pinned_evidence:
		return false
	pinned_evidence.erase(evidence_id)
	evidence_unpinned.emit(evidence_id)
	return true


## Returns whether the given evidence is pinned.
func is_pinned(evidence_id: String) -> bool:
	return evidence_id in pinned_evidence


## Returns a copy of the pinned evidence IDs.
func get_pinned_evidence() -> Array[String]:
	return pinned_evidence.duplicate()


## Returns EvidenceData for all pinned evidence items.
func get_pinned_evidence_data() -> Array[EvidenceData]:
	var result: Array[EvidenceData] = []
	for eid: String in pinned_evidence:
		var ev: EvidenceData = CaseManager.get_evidence(eid)
		if ev != null:
			result.append(ev)
	return result


# --- Comparison --- #

## Compares two evidence items. Returns the generated InsightData, or null if
## no valid comparison exists or the insight was already discovered.
func compare_evidence(evidence_a: String, evidence_b: String) -> InsightData:
	var all_insights: Array[InsightData] = CaseManager.get_all_insights()
	for insight: InsightData in all_insights:
		if evidence_a in insight.source_evidence and evidence_b in insight.source_evidence:
			if insight.id in GameManager.discovered_insights:
				return null  # Already known
			GameManager.discover_insight(insight.id)
			insight_generated.emit(insight.id)
			NotificationManager.notify_story("New insight: %s" % insight.description)
			return insight
	return null  # No valid comparison


## Returns evidence IDs that can be compared with the given evidence to produce
## an undiscovered insight. Only includes discovered evidence.
func get_valid_comparisons_for(evidence_id: String) -> Array[String]:
	var result: Array[String] = []
	var all_insights: Array[InsightData] = CaseManager.get_all_insights()
	for insight: InsightData in all_insights:
		if insight.id in GameManager.discovered_insights:
			continue
		if evidence_id in insight.source_evidence:
			for other: String in insight.source_evidence:
				if other != evidence_id and other not in result:
					if GameManager.has_evidence(other):
						result.append(other)
	return result


# --- Testimony & Contradictions --- #

## Returns all statements accessible to the player (day_given <= current day).
func get_testimony() -> Array[StatementData]:
	var result: Array[StatementData] = []
	var all_stmts: Array[StatementData] = CaseManager.get_all_statements()
	for stmt: StatementData in all_stmts:
		if stmt.day_given > 0 and stmt.day_given <= GameManager.current_day:
			result.append(stmt)
	return result


## Re-scans all testimony for contradictions with discovered evidence.
## Updates detected_contradictions and returns the full list.
func check_contradictions() -> Array[Dictionary]:
	var new_list: Array[Dictionary] = []
	var all_stmts: Array[StatementData] = CaseManager.get_all_statements()
	for stmt: StatementData in all_stmts:
		for ev_id: String in stmt.contradicting_evidence:
			if GameManager.has_evidence(ev_id):
				new_list.append({
					"statement_id": stmt.id,
					"evidence_id": ev_id,
					"statement_text": stmt.text,
					"person_id": stmt.person_id,
				})
	detected_contradictions = new_list
	return detected_contradictions.duplicate(true)


## Returns contradictions for a specific statement.
func get_contradictions_for_statement(statement_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c: Dictionary in detected_contradictions:
		if c.get("statement_id", "") == statement_id:
			result.append(c)
	return result


## Returns whether the given statement has any detected contradictions.
func has_contradiction(statement_id: String) -> bool:
	for c: Dictionary in detected_contradictions:
		if c.get("statement_id", "") == statement_id:
			return true
	return false


# --- Statements & Verdicts --- #

## Returns whether the player has unlocked the given statement (heard it in interrogation).
func is_statement_unlocked(statement_id: String) -> bool:
	return StatementManager.is_statement_unlocked(statement_id)


## Returns StatementData items visible for a given evidence item.
## Only returns statements that are linked to this evidence AND unlocked by the player.
func get_statements_for_evidence(evidence_id: String) -> Array[StatementData]:
	var ev: EvidenceData = CaseManager.get_evidence(evidence_id)
	if ev == null:
		return []
	var result: Array[StatementData] = []
	for stmt_id: String in ev.linked_statements:
		if not is_statement_unlocked(stmt_id):
			continue
		var stmt: StatementData = CaseManager.get_statement(stmt_id)
		if stmt != null:
			result.append(stmt)
	return result


## Returns the player's verdict for a statement relative to an evidence item.
## Returns "unclassified" if no verdict has been set.
func get_statement_verdict(evidence_id: String, statement_id: String) -> String:
	var key: String = "%s:%s" % [evidence_id, statement_id]
	var vd: StatementVerdictData = _statement_verdicts.get(key, null)
	return vd.verdict if vd != null else "unclassified"


## Sets the player's verdict for a statement relative to an evidence item.
## Valid verdicts: "unclassified", "contradiction", "supports", "unresolved".
func set_statement_verdict(evidence_id: String, statement_id: String, verdict: String) -> void:
	if verdict not in StatementVerdictData.VALID_VERDICTS:
		push_error("[EvidenceManager] Invalid verdict '%s'" % verdict)
		return
	var key: String = "%s:%s" % [evidence_id, statement_id]
	var vd: StatementVerdictData = _statement_verdicts.get(key, null)
	if vd == null:
		vd = StatementVerdictData.new(evidence_id, statement_id)
		_statement_verdicts[key] = vd
	vd.verdict = verdict
	statement_verdict_changed.emit(evidence_id, statement_id, verdict)


## Sets a player note on a statement-evidence link.
func set_statement_note(evidence_id: String, statement_id: String, note: String) -> void:
	var key: String = "%s:%s" % [evidence_id, statement_id]
	var vd: StatementVerdictData = _statement_verdicts.get(key, null)
	if vd == null:
		vd = StatementVerdictData.new(evidence_id, statement_id)
		_statement_verdicts[key] = vd
	vd.player_note = note
	statement_note_changed.emit(evidence_id, statement_id)


# --- Lab Analysis --- #

## Submits evidence for lab analysis. Returns true if the request was accepted.
## Delegates to LabManager, which looks up the lab recipe from CaseManager.
func submit_to_lab(evidence_id: String) -> bool:
	return LabManager.submit_to_lab(evidence_id)


# --- Progressive Discovery Hints --- #

## Requests a progressive hint. Returns a dictionary with hint details,
## or an empty dictionary if no hint is available.
## Conditions: budget not exceeded, critical evidence missing, day >= 2, location visited.
func request_hint() -> Dictionary:
	if not GameManager.use_hint():
		return {}

	var hint: Dictionary = _find_best_hint()
	if hint.is_empty():
		# Refund the hint if nothing to suggest
		GameManager.hints_used -= 1
		return {}

	hint_delivered.emit(hint.get("text", ""), hint.get("source", ""))
	NotificationManager.notify_hint(hint.get("text", ""))
	return hint


## Finds the best available hint based on undiscovered critical evidence.
func _find_best_hint() -> Dictionary:
	var all_evidence: Array[EvidenceData] = CaseManager.get_all_evidence()
	for ev: EvidenceData in all_evidence:
		if ev.importance_level != Enums.ImportanceLevel.CRITICAL:
			continue
		if GameManager.has_evidence(ev.id):
			continue
		if GameManager.current_day < 2:
			continue
		if ev.location_found.is_empty():
			continue
		if not GameManager.has_visited_location(ev.location_found):
			continue
		# This evidence qualifies for a hint
		var hint_text: String = ev.hint_text if not ev.hint_text.is_empty() else _generate_hint_text(ev)
		var location: LocationData = CaseManager.get_location(ev.location_found)
		var loc_name: String = location.name if location else ev.location_found
		return {
			"text": hint_text,
			"source": "Technician",
			"target_evidence": ev.id,
			"location": loc_name,
		}
	return {}


## Generates a generic hint text from evidence metadata.
func _generate_hint_text(ev: EvidenceData) -> String:
	var location: LocationData = CaseManager.get_location(ev.location_found)
	var loc_name: String = location.name if location else "the scene"
	return "Have you looked more carefully at %s?" % loc_name


# --- Auto-detection --- #

## Called when new evidence is discovered. Re-checks for contradictions.
func _on_evidence_discovered(_evidence_id: String) -> void:
	var old_keys: Dictionary = {}
	for c: Dictionary in detected_contradictions:
		old_keys["%s:%s" % [c.get("statement_id", ""), c.get("evidence_id", "")]] = true

	check_contradictions()

	for c: Dictionary in detected_contradictions:
		var key: String = "%s:%s" % [c.get("statement_id", ""), c.get("evidence_id", "")]
		if key not in old_keys:
			contradiction_detected.emit(c.get("statement_id", ""), c.get("evidence_id", ""))


# --- Serialization --- #

## Returns the evidence manager state as a dictionary for saving.
func serialize() -> Dictionary:
	return {
		"pinned_evidence": pinned_evidence.duplicate(),
		"detected_contradictions": detected_contradictions.duplicate(true),
		"statement_verdicts": _serialize_verdicts(),
	}


func _serialize_verdicts() -> Dictionary:
	var out: Dictionary = {}
	for key: String in _statement_verdicts:
		out[key] = _statement_verdicts[key].to_dict()
	return out


## Restores evidence manager state from a saved dictionary.
func deserialize(data: Dictionary) -> void:
	pinned_evidence.assign(data.get("pinned_evidence", []))
	detected_contradictions.clear()
	var saved_contradictions: Array = data.get("detected_contradictions", [])
	for item: Variant in saved_contradictions:
		if item is Dictionary:
			detected_contradictions.append(item)
	_statement_verdicts.clear()
	var saved_verdicts: Dictionary = data.get("statement_verdicts", {})
	for key: String in saved_verdicts:
		var vd: StatementVerdictData = StatementVerdictData.from_dict(saved_verdicts[key])
		_statement_verdicts[key] = vd
	state_loaded.emit()


## Resets all evidence manager state for a new game.
func reset() -> void:
	pinned_evidence.clear()
	detected_contradictions.clear()
	_statement_verdicts.clear()
