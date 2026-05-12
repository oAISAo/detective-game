## Unit tests for reusable amber WaitButton component.
extends GutTest


const WAIT_BUTTON_SCENE_PATH: String = "res://scenes/ui/components/wait_button.tscn"


func _instantiate_wait_button() -> Control:
	var scene: PackedScene = load(WAIT_BUTTON_SCENE_PATH) as PackedScene
	assert_not_null(scene, "WaitButton scene should load")
	if scene == null:
		return null

	var button: Control = scene.instantiate() as Control
	assert_not_null(button, "WaitButton scene should instantiate")
	if button != null:
		add_child_autofree(button)
	return button


func _left_click_event() -> InputEventMouseButton:
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	return click


func test_wait_button_scene_has_expected_structure() -> void:
	var button: Control = _instantiate_wait_button()
	if button == null:
		return

	assert_not_null(button.get_node_or_null("Background"), "WaitButton should contain a Background node")
	assert_not_null(button.get_node_or_null("ContentMargin"), "WaitButton should contain an inner content margin")
	assert_not_null(button.get_node_or_null("ContentMargin/Content"), "WaitButton should contain a Content row")
	assert_not_null(button.get_node_or_null("ContentMargin/Content/LabelActionText"), "WaitButton should contain left action label")
	assert_not_null(button.get_node_or_null("ContentMargin/Content/HBoxRight/HourglassIcon"), "WaitButton should contain hourglass icon label")
	assert_not_null(button.get_node_or_null("ContentMargin/Content/HBoxRight/LabelMeta"), "WaitButton should contain right meta label")


func test_wait_button_uses_full_width_sizing() -> void:
	var button: Control = _instantiate_wait_button()
	if button == null:
		return

	assert_eq(button.size_flags_horizontal, Control.SIZE_EXPAND_FILL,
		"WaitButton should expand to fill the available width like ActionButton.")


func test_wait_button_content_margin_matches_action_button_padding() -> void:
	var button: Control = _instantiate_wait_button()
	if button == null:
		return

	var content_margin: MarginContainer = button.get_node_or_null("ContentMargin") as MarginContainer
	assert_not_null(content_margin)
	if content_margin == null:
		return

	assert_eq(content_margin.get_theme_constant("margin_top"), 10)
	assert_eq(content_margin.get_theme_constant("margin_bottom"), 10)


func test_wait_button_action_text_export_updates_label() -> void:
	var button: Control = _instantiate_wait_button()
	if button == null:
		return

	button.set("action_text", "Photo Analysis")
	var action_label: Label = button.get_node_or_null("ContentMargin/Content/LabelActionText") as Label
	assert_not_null(action_label)
	if action_label != null:
		assert_eq(action_label.text, "Photo Analysis")


func test_wait_button_uses_hourglass_material_ligature() -> void:
	var button: Control = _instantiate_wait_button()
	if button == null:
		return

	var icon_label: Label = button.get_node_or_null("ContentMargin/Content/HBoxRight/HourglassIcon") as Label
	assert_not_null(icon_label)
	if icon_label == null:
		return

	assert_eq(icon_label.text, "hourglass", "Icon label should use Material ligature text")
	assert_not_null(icon_label.get_theme_font("font"), "Icon label should have a font override for icon ligatures")


func test_wait_button_emits_pressed_signal_on_left_click() -> void:
	var button: Control = _instantiate_wait_button()
	if button == null:
		return

	watch_signals(button)
	button._gui_input(_left_click_event())
	assert_signal_emitted(button, "pressed")


func test_wait_button_submitted_blocks_pressed_signal() -> void:
	var button: Control = _instantiate_wait_button()
	if button == null:
		return

	button.set("submitted", true)
	watch_signals(button)
	button._gui_input(_left_click_event())
	assert_signal_not_emitted(button, "pressed")


func test_wait_button_panel_style_has_side_expand_margins_for_shadow() -> void:
	var button: Control = _instantiate_wait_button()
	if button == null:
		return

	var panel_style: StyleBoxFlat = button.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(panel_style)
	if panel_style == null:
		return

	assert_eq(panel_style.content_margin_top, 0.0)
	assert_eq(panel_style.content_margin_bottom, 0.0)
	assert_eq(panel_style.expand_margin_left, 6.0)
	assert_eq(panel_style.expand_margin_right, 6.0)
	assert_eq(panel_style.expand_margin_top, 6.0)
	assert_eq(panel_style.expand_margin_bottom, 6.0)


func test_wait_button_right_section_width_grows_for_pending_state_copy() -> void:
	var button: Control = _instantiate_wait_button()
	if button == null:
		return

	var background: Node = button.get_node_or_null("Background")
	assert_not_null(background)
	if background == null:
		return

	button.set("submitted", false)
	var ready_width: float = float(background.get("right_section_width"))

	button.set("submitted", true)
	var pending_width: float = float(background.get("right_section_width"))

	assert_true(pending_width > ready_width,
		"Right split width should grow when the meta copy changes from Submit to Pending")


func test_wait_button_hover_updates_background_intensity() -> void:
	var button: Control = _instantiate_wait_button()
	if button == null:
		return

	var background: Node = button.get_node_or_null("Background")
	assert_not_null(background)
	if background == null:
		return

	button.call("_on_mouse_entered")
	assert_true(float(background.get("hover_intensity")) > 0.0, "Hover should increase background intensity")
	button.call("_on_mouse_exited")
	assert_eq(float(background.get("hover_intensity")), 0.0, "Exit hover should reset background intensity")