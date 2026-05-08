## test_evidence_value_data.gd
## Ensures shipped Riverside evidence authoring supports the Evidentiary Value UI.
extends GutTest


func before_each() -> void:
	GameManager.new_game()
	CaseManager.unload_case()
	CaseManager.load_case_folder("riverside_apartment")


func after_each() -> void:
	CaseManager.unload_case()


func test_all_riverside_evidence_has_evidentiary_value_text() -> void:
	var missing_ids: Array[String] = []

	for ev: EvidenceData in CaseManager.get_all_evidence():
		if ev.evidentiary_value_text.strip_edges().is_empty():
			missing_ids.append(ev.id)

	assert_eq(
		missing_ids,
		[],
		"All Riverside evidence should define evidentiary_value_text. Missing: %s"
			% ", ".join(missing_ids)
	)