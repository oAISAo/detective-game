## ActionButtonBackground.gd
## Draws the adaptive diagonal split background for ActionButton.
class_name ActionButtonBackground
extends Control


## Visual mode: 0 = normal (blue), 1 = completed (green), 2 = disabled (dimmed blue).
enum ColorMode { NORMAL, COMPLETED, DISABLED }

const RIGHT_SECTION_MAX_RATIO: float = 0.46
const DIAGONAL_MAX_TILT: float = 12.0
const LEFT_BASE_ALPHA: float = 0.46
const RIGHT_BASE_ALPHA: float = 0.30
const DISABLED_ALPHA_FACTOR: float = 0.55


@export_range(0.0, 1.0, 0.01) var hover_intensity: float = 0.0:
	set(value):
		hover_intensity = clampf(value, 0.0, 1.0)
		queue_redraw()

@export_range(0.0, 1000.0, 1.0) var right_section_width: float = 90.0:
	set(value):
		right_section_width = maxf(0.0, value)
		queue_redraw()

@export var color_mode: int = ColorMode.NORMAL:
	set(value):
		color_mode = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var width: float = size.x
	var height: float = size.y
	if width <= 0.0 or height <= 0.0:
		return

	var max_right: float = maxf(1.0, width - 1.0)
	var ratio_capped_right: float = maxf(1.0, width * RIGHT_SECTION_MAX_RATIO)
	var clamped_right: float = minf(maxf(1.0, right_section_width), max_right)
	clamped_right = minf(clamped_right, ratio_capped_right)

	var top_split_x: float = width - clamped_right
	var tilt: float = minf(clamped_right * 0.24, DIAGONAL_MAX_TILT)
	var bottom_split_x: float = clampf(top_split_x - tilt, 0.0, width)

	draw_polygon(
		PackedVector2Array([
			Vector2(0.0, 0.0),
			Vector2(top_split_x, 0.0),
			Vector2(bottom_split_x, height),
			Vector2(0.0, height),
		]),
		PackedColorArray([_left_color()])
	)

	draw_polygon(
		PackedVector2Array([
			Vector2(top_split_x, 0.0),
			Vector2(width, 0.0),
			Vector2(width, height),
			Vector2(bottom_split_x, height),
		]),
		PackedColorArray([_right_color()])
	)


func _left_color() -> Color:
	var accent: Color = _accent_color()
	var left_color: Color = accent.lerp(UIColors.BG_SURFACE, 0.55)
	var alpha: float = LEFT_BASE_ALPHA + (0.18 * hover_intensity)
	if color_mode == ColorMode.DISABLED:
		alpha *= DISABLED_ALPHA_FACTOR
	left_color.a = alpha
	return left_color


func _right_color() -> Color:
	var accent: Color = _accent_color()
	var right_color: Color = UIColors.BG_SURFACE.darkened(0.35)
	right_color = right_color.lerp(accent, 0.08)
	var alpha: float = RIGHT_BASE_ALPHA + (0.10 * hover_intensity)
	if color_mode == ColorMode.DISABLED:
		alpha *= DISABLED_ALPHA_FACTOR
	right_color.a = alpha
	return right_color


func _accent_color() -> Color:
	match color_mode:
		ColorMode.COMPLETED:
			return UIColors.GREEN.lerp(UIColors.TEXT_GREY, 0.3)
		ColorMode.DISABLED:
			return UIColors.BLUE.lerp(UIColors.TEXT_GREY, 0.4)
		_:
			return UIColors.BLUE
