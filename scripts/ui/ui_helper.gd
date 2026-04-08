## UIHelper.gd
## Shared UI utility methods used across multiple screens.
## Eliminates duplication of common label/formatting/signal helpers.
## Phase D3: Adds ConfirmationFlash and SelectionPulse animation helpers.
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
## Uses the SectionHeader theme type variation and uppercases the text.
static func add_section_header(text: String, parent: Control) -> void:
	var label := Label.new()
	label.text = text.to_upper()
	label.theme_type_variation = &"SectionHeader"
	parent.add_child(label)


## Shows a brief inline confirmation flash on a parent control.
## The label scales slightly, then fades out over 0.6s.
## Use after evidence submission, theory filing, lab queuing, etc.
static func confirmation_flash(text: String, parent: Control, color: Color = UIColors.ACCENT_PROCESSED) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)

	# Scale up slightly, then fade out
	label.pivot_offset = label.size / 2.0
	var tween: Tween = parent.create_tween()
	tween.tween_property(label, "scale", Vector2(1.05, 1.05), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.tween_callback(label.queue_free)


## Shows a "SUBMITTED" stamp overlay on a control element.
## Used for lab queue submissions to give a "case file stamped" feel.
static func stamp_flash(parent: Control) -> void:
	var stamp := Label.new()
	stamp.text = "SUBMITTED"
	stamp.add_theme_color_override("font_color", UIColors.ACCENT_PROCESSED)
	stamp.add_theme_font_size_override("font_size", 28)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp.modulate.a = 0.0

	# Fill the entire parent so text alignment centers properly
	stamp.set_anchors_preset(Control.PRESET_FULL_RECT)
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(stamp)

	# Slam in with scale, then fade out
	stamp.scale = Vector2(1.4, 1.4)
	stamp.pivot_offset = parent.size / 2.0
	var tween: Tween = parent.create_tween()
	tween.tween_property(stamp, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(stamp, "scale", Vector2(1.0, 1.0), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(0.4)
	tween.tween_property(stamp, "modulate:a", 0.0, 0.35)
	tween.tween_callback(stamp.queue_free)


## Briefly pulses a control's modulate to highlight selection.
## Flashes the accent color alpha, then returns to normal.
static func selection_pulse(control: Control) -> void:
	var tween: Tween = control.create_tween()
	tween.tween_property(control, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)


## Applies the SurfacePanel theme type variation to a PanelContainer.
## Use this on programmatically created PanelContainers that sit inside
## a screen (which already uses BG_PANEL), so they get the lighter
## BG_SURFACE background and subtler border defined in main_theme.tres.
static func apply_surface_style(panel: PanelContainer) -> void:
	panel.theme_type_variation = &"SurfacePanel"
