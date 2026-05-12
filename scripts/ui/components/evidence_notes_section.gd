## EvidenceNotesSection
## Displays a handwriting-styled TextEdit for player notes on an evidence item.
## Auto-saves to EvidenceManager on every keystroke — no explicit save button.
class_name EvidenceNotesSection
extends VBoxContainer


func populate(evidence_id: String, handwriting_font: Font = null) -> void:
	UIHelper.clear_children(self)
	add_theme_constant_override("separation", 8)

	var header := Label.new()
	header.text = "My Notes"
	header.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
	header.theme_type_variation = &"SectionHeader"
	add_child(header)

	var text_edit := TextEdit.new()
	text_edit.placeholder_text = "Your private notes about this evidence\u2026"
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.custom_minimum_size.y = 120
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	if handwriting_font != null:
		text_edit.add_theme_font_override("font", handwriting_font)
	text_edit.add_theme_font_size_override("font_size", UIFonts.SIZE_SECTION)
	text_edit.text = EvidenceManager.get_player_notes(evidence_id)
	add_child(text_edit)

	text_edit.text_changed.connect(
		func() -> void:
			EvidenceManager.set_player_notes(evidence_id, text_edit.text)
	)


func clear() -> void:
	UIHelper.clear_children(self)
