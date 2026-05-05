## EvidenceWeightSection
## Displays the evidentiary weight progress bar and prose label for an evidence item.
## Pure display component — no signals, no live manager connections.
class_name EvidenceWeightSection
extends VBoxContainer


func populate(ev: EvidenceData) -> void:
	UIHelper.clear_children(self)
	add_theme_constant_override("separation", 6)

	var bar_color: Color = _get_bar_color(ev)

	var header_row := HBoxContainer.new()
	var header_label := Label.new()
	header_label.text = "Evidentiary Weight"
	header_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	header_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_label)
	var pct_label := Label.new()
	pct_label.text = "%.0f%%" % (ev.weight * 100.0)
	pct_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	pct_label.add_theme_color_override("font_color", bar_color)
	header_row.add_child(pct_label)
	add_child(header_row)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = ev.weight
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size.y = 10
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	fill_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.18)
	bg_style.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg_style)
	add_child(bar)

	var prose := Label.new()
	prose.text = _get_prose(ev.weight)
	prose.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
	prose.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	prose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(prose)


func clear() -> void:
	UIHelper.clear_children(self)


func _get_bar_color(ev: EvidenceData) -> Color:
	return UIColors.RED if EvidenceManager.is_contradicted(ev.id) else UIColors.AMBER


func _get_prose(weight: float) -> String:
	var pct: float = weight * 100.0
	if pct >= 85.0: return "Airtight. Will convict on its own."
	if pct >= 65.0: return "Strong. Holds up under cross-examination."
	if pct >= 40.0: return "Corroborating. Strengthens the case when combined with other evidence."
	if pct >= 20.0: return "Weak. Circumstantial \u2014 the defense will challenge this."
	return "Marginal. Context only."
