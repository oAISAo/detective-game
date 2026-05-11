## EvidenceValueSection
## Displays the player-facing evidentiary value summary for an evidence item.
## Shows a qualitative tier, case-authored interpretation text, and an optional
## contested warning derived from contradiction state.
class_name EvidenceValueSection
extends VBoxContainer


func populate(ev: EvidenceData) -> void:
	UIHelper.clear_children(self)
	add_theme_constant_override("separation", 6)

	var header_label := Label.new()
	header_label.text = "Evidentiary Value"
	header_label.theme_type_variation = &"SectionHeader"
	add_child(header_label)

	var tier_label := Label.new()
	tier_label.text = _get_tier_label(ev.weight)
	tier_label.add_theme_color_override("font_color", UIColors.TEXT_PRIMARY)
	tier_label.add_theme_font_size_override("font_size", UIFonts.SIZE_BODY)
	add_child(tier_label)

	var interpretation_label := Label.new()
	interpretation_label.text = _get_interpretation_text(ev)
	interpretation_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
	interpretation_label.add_theme_font_size_override("font_size", UIFonts.SIZE_BODY)
	interpretation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(interpretation_label)

	if EvidenceManager.is_contradicted(ev.id):
		var warning_label := Label.new()
		warning_label.text = "Contested by a credible statement"
		warning_label.add_theme_color_override(
			"font_color",
			UIColors.TEXT_GREY.lerp(UIColors.AMBER_WARNING, 0.4)
		)
		warning_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
		warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(warning_label)


func clear() -> void:
	UIHelper.clear_children(self)


func _get_tier_label(weight: float) -> String:
	if weight >= 0.85:
		return "Airtight"
	if weight >= 0.65:
		return "Strong"
	if weight >= 0.40:
		return "Supporting"
	if weight >= 0.20:
		return "Weak"
	return "Marginal"


func _get_interpretation_text(ev: EvidenceData) -> String:
	if not ev.evidentiary_value_text.is_empty():
		return ev.evidentiary_value_text
	return ev.description