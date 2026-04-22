## lab_request_data.gd
## Represents a request to analyze evidence in the forensic lab.
class_name LabRequestData
extends Resource


## Unique identifier for this lab request.
@export var id: String = ""

## ID of the evidence being submitted for analysis.
@export var input_evidence_id: String = ""

## Type of analysis to perform (e.g., "fingerprint", "dna", "chemical").
@export var analysis_type: String = ""

## Day the request was submitted.
@export var day_submitted: int = 0

## Day the results will be available.
@export var completion_day: int = 0

## ID of the new evidence produced by the analysis.
@export var output_evidence_id: String = ""

## How the lab result relates to the input evidence.
## "upgrade" — raw input is replaced by the analyzed output (e.g. ev_shoe_print_raw → ev_shoe_print).
## "derive"  — input evidence stays in the player's collection; the output is added alongside
##             (e.g. ev_wine_glasses → ev_julia_fingerprint_glass).
@export var lab_transform: String = "upgrade"


## Creates a LabRequestData from a JSON dictionary.
static func from_dict(data: Dictionary) -> LabRequestData:
	var res := LabRequestData.new()
	res.id = data.get("id", "")
	res.input_evidence_id = data.get("input_evidence_id", "")
	res.analysis_type = data.get("analysis_type", "")
	res.day_submitted = int(data.get("day_submitted", 0))
	res.completion_day = int(data.get("completion_day", 0))
	res.output_evidence_id = data.get("output_evidence_id", "")
	res.lab_transform = data.get("lab_transform", "upgrade")
	return res


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("LabRequestData: id is required")
	if input_evidence_id.is_empty():
		errors.append("LabRequestData: input_evidence_id is required")
	if analysis_type.is_empty():
		errors.append("LabRequestData: analysis_type is required")
	if completion_day < day_submitted:
		errors.append("LabRequestData: completion_day must be >= day_submitted")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"input_evidence_id": input_evidence_id,
		"analysis_type": analysis_type,
		"day_submitted": day_submitted,
		"completion_day": completion_day,
		"output_evidence_id": output_evidence_id,
		"lab_transform": lab_transform,
	}
