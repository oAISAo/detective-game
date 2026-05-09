## evidence_data.gd
## Represents a piece of evidence in the investigation.
class_name EvidenceData
extends Resource


## Unique identifier for this evidence.
@export var id: String = ""

## Display name of the evidence.
@export var name: String = ""

## Description of the evidence.
@export var description: String = ""

## The type of evidence.
@export var type: Enums.EvidenceType = Enums.EvidenceType.OBJECT

## ID of the location where this evidence was found.
@export var location_found: String = ""

## IDs of persons related to this evidence.
@export var related_persons: Array[String] = []

## Current lab analysis status.
@export var lab_status: Enums.LabStatus = Enums.LabStatus.NOT_SUBMITTED

## Text result from lab analysis (populated when lab completes).
@export var lab_result_text: String = ""

## Whether this evidence requires lab analysis to be fully useful.
@export var requires_lab_analysis: bool = false

## Path to the evidence image resource.
@export var image: String = ""

## Relative weight/importance as a float (0.0–1.0).
@export var weight: float = 0.5

## Evidence-specific interpretation shown in the Evidentiary Value section.
@export var evidentiary_value_text: String = ""

## How important this evidence is to the case.
@export var importance_level: Enums.ImportanceLevel = Enums.ImportanceLevel.SUPPORTING

## How the player originally acquired this evidence.
@export var discovery_method: Enums.DiscoveryMethod = Enums.DiscoveryMethod.VISUAL

## ID of the parent evidence this item was derived from, if any.
@export var derived_from: String = ""

## Optional hint text for the progressive hint system. If empty, a generic hint is generated.
@export var hint_text: String = ""

## IDs of statements potentially relevant to this evidence item.
@export var linked_statements: Array[String] = []

## Legal categories this evidence supports (PRESENCE, MOTIVE, etc.).
var legal_categories: Array[int] = []  # Enums.LegalCategory values

## Validation error captured while parsing discovery_method.
var _discovery_method_validation_error: String = ""


## Creates an EvidenceData from a JSON dictionary.
static func from_dict(data: Dictionary) -> EvidenceData:
	var res := EvidenceData.new()
	res.id = data.get("id", "")
	res.name = data.get("name", "")
	res.description = data.get("description", "")
	res.type = EnumHelper.parse_enum(
		Enums.EvidenceType,
		data.get("type", "OBJECT"),
		Enums.EvidenceType.OBJECT
	) as Enums.EvidenceType
	res.location_found = data.get("location_found", "")
	res.related_persons.assign(data.get("related_persons", []))
	res.lab_status = EnumHelper.parse_enum(
		Enums.LabStatus,
		data.get("lab_status", "NOT_SUBMITTED"),
		Enums.LabStatus.NOT_SUBMITTED
	) as Enums.LabStatus
	res.lab_result_text = data.get("lab_result_text", "")
	res.requires_lab_analysis = data.get("requires_lab_analysis", false)
	res.image = data.get("image", "")
	res.weight = float(data.get("weight", 0.5))
	res.evidentiary_value_text = data.get("evidentiary_value_text", "")
	res.importance_level = EnumHelper.parse_enum(
		Enums.ImportanceLevel,
		data.get("importance_level", "SUPPORTING"),
		Enums.ImportanceLevel.SUPPORTING
	) as Enums.ImportanceLevel
	res._set_discovery_method_from_string(str(data.get("discovery_method", "")))
	res.derived_from = str(data.get("derived_from", "")).strip_edges()
	res.hint_text = data.get("hint_text", "")
	res.linked_statements.assign(data.get("linked_statements", []))
	res.legal_categories = EnumHelper.parse_enum_array(
		Enums.LegalCategory,
		data.get("legal_categories", [])
	)
	return res


func _set_discovery_method_from_string(value: String) -> void:
	var normalized_value: String = value.to_upper().strip_edges()
	var evidence_label: String = id if not id.is_empty() else "<unknown>"

	if normalized_value.is_empty():
		_discovery_method_validation_error = (
			"EvidenceData: discovery_method is required for evidence '%s'" % evidence_label
		)
		return

	if normalized_value not in Enums.DiscoveryMethod:
		_discovery_method_validation_error = (
			"EvidenceData: invalid discovery_method '%s' for evidence '%s'" % [value, evidence_label]
		)
		return

	discovery_method = Enums.DiscoveryMethod[normalized_value]
	_discovery_method_validation_error = ""


## Returns validation errors. Empty array means valid.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if id.is_empty():
		errors.append("EvidenceData: id is required")
	if name.is_empty():
		errors.append("EvidenceData: name is required")
	if not _discovery_method_validation_error.is_empty():
		errors.append(_discovery_method_validation_error)
	if not derived_from.is_empty() and derived_from == id:
		errors.append("EvidenceData: derived_from cannot reference self")
	if weight < 0.0 or weight > 1.0:
		errors.append("EvidenceData: weight must be between 0.0 and 1.0")
	return errors


## Serializes to a dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"type": EnumHelper.enum_to_string(Enums.EvidenceType, type),
		"location_found": location_found,
		"related_persons": related_persons.duplicate(),
		"lab_status": EnumHelper.enum_to_string(Enums.LabStatus, lab_status),
		"lab_result_text": lab_result_text,
		"requires_lab_analysis": requires_lab_analysis,
		"image": image,
		"weight": weight,
		"evidentiary_value_text": evidentiary_value_text,
		"importance_level": EnumHelper.enum_to_string(Enums.ImportanceLevel, importance_level),
		"discovery_method": EnumHelper.enum_to_string(Enums.DiscoveryMethod, discovery_method),
		"derived_from": derived_from,
		"hint_text": hint_text,
		"linked_statements": linked_statements.duplicate(),
		"legal_categories": EnumHelper.enum_array_to_strings(Enums.LegalCategory, legal_categories),
	}
