## UIHelper.gd
## Shared UI utility methods used across multiple screens.
## Eliminates duplication of common label/formatting/signal helpers.
class_name UIHelper


## Returns a human-readable label for an evidence type.
static func get_evidence_type_label(type: Enums.EvidenceType) -> String:
	match type:
		Enums.EvidenceType.FORENSIC: return "Forensic"
		Enums.EvidenceType.DOCUMENT: return "Document"
		Enums.EvidenceType.PHOTO: return "Photo"
		Enums.EvidenceType.RECORDING: return "Recording"
		Enums.EvidenceType.FINANCIAL: return "Financial"
		Enums.EvidenceType.DIGITAL: return "Digital"
		Enums.EvidenceType.OBJECT: return "Object"
	return "Unknown"


## Returns the display name for a location, or the raw ID if not found.
static func get_location_name(location_id: String) -> String:
	if location_id.is_empty():
		return "Unknown"
	var loc: LocationData = CaseManager.get_location(location_id)
	return loc.name if loc else location_id


## Returns a human-readable label for a legal category.
static func get_legal_category_label(cat: int) -> String:
	match cat:
		Enums.LegalCategory.PRESENCE: return "Presence"
		Enums.LegalCategory.MOTIVE: return "Motive"
		Enums.LegalCategory.OPPORTUNITY: return "Opportunity"
		Enums.LegalCategory.CONNECTION: return "Connection"
	return "Unknown"


## Safely disconnects a signal callback if it is currently connected.
static func safe_disconnect(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)


## Creates and adds a styled section header label to a parent container.
static func add_section_header(text: String, parent: Control) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", UIColors.HEADER)
	parent.add_child(label)
