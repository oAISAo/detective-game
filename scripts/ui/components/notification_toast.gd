## NotificationToast.gd
## Slide-in toast notification that appears at the top-right of the screen.
## Built programmatically — no .tscn needed.
## Slides in from the right, auto-dismisses after 3.5 seconds.
## Used by GameRoot to surface NotificationManager events in real-time.
class_name NotificationToast
extends PanelContainer


const SLIDE_IN_DURATION: float = 0.25
const DISPLAY_DURATION: float = 3.5
const SLIDE_OUT_DURATION: float = 0.2
const TOAST_WIDTH: float = 350.0
const ACCENT_BAR_WIDTH: float = 4.0

## Maps NotificationType values to accent colors.
const ACCENT_MAP: Dictionary = {
	NotificationManager.NotificationType.EVIDENCE: UIColors.ACCENT_CLUE,
	NotificationManager.NotificationType.LAB_RESULT: UIColors.ACCENT_CLUE,
	NotificationManager.NotificationType.HINT: UIColors.ACCENT_CLUE,
	NotificationManager.NotificationType.STATEMENT: UIColors.ACCENT_PROCESSED,
	NotificationManager.NotificationType.SURVEILLANCE: UIColors.ACCENT_PROCESSED,
	NotificationManager.NotificationType.WARRANT: UIColors.ACCENT_PROCESSED,
	NotificationManager.NotificationType.STORY: UIColors.ACCENT_PROCESSED,
	NotificationManager.NotificationType.SYSTEM: UIColors.ACCENT_CRITICAL,
}


## Returns the accent color for a given NotificationType.
static func get_accent_color(type: NotificationManager.NotificationType) -> Color:
	return ACCENT_MAP.get(type, UIColors.TEXT_MUTED)


## Builds child nodes and starts the slide-in animation.
func setup(title: String, message: String, type: NotificationManager.NotificationType) -> void:
	# Panel styling
	custom_minimum_size.x = TOAST_WIDTH
	size_flags_horizontal = Control.SIZE_SHRINK_END
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_panel_style()

	# Content margin
	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	# Main row: accent bar + text column
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	# Accent bar
	var accent_color: Color = get_accent_color(type)
	var bar: ColorRect = ColorRect.new()
	bar.custom_minimum_size = Vector2(ACCENT_BAR_WIDTH, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.color = accent_color
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bar)

	# Text column
	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 4)
	row.add_child(text_col)

	# Title label
	var title_label: Label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", UIFonts.SIZE_BODY)
	title_label.add_theme_color_override("font_color", UIColors.TEXT_PRIMARY)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.add_child(title_label)

	# Message label
	if not message.is_empty():
		var msg_label: Label = Label.new()
		msg_label.text = message
		msg_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)
		msg_label.add_theme_color_override("font_color", UIColors.TEXT_SECONDARY)
		msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_col.add_child(msg_label)

	# Start hidden off-screen, then animate in
	modulate.a = 0.0
	_animate()


func _apply_panel_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UIColors.BG_SURFACE
	style.border_color = UIColors.BORDER_SUBTLE
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	add_theme_stylebox_override("panel", style)


func _animate() -> void:
	var tween: Tween = create_tween()
	# Slide in: fade from 0 to 1
	tween.tween_property(self, "modulate:a", 1.0, SLIDE_IN_DURATION)
	# Hold
	tween.tween_interval(DISPLAY_DURATION)
	# Slide out: fade to 0
	tween.tween_property(self, "modulate:a", 0.0, SLIDE_OUT_DURATION)
	tween.tween_callback(queue_free)
