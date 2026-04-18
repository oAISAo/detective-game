## Regression tests for shared back-button icon helper layout.
extends GutTest


const UI_HELPER = preload("res://scripts/ui/ui_helper.gd")
const BACK_CONTENT_NODE_NAME: String = "BackButtonContent"


func test_apply_back_button_icon_uses_end_day_metrics_and_keeps_content_inside() -> void:
	var button: Button = Button.new()
	button.text = "\u2190 Back"
	button.custom_minimum_size = Vector2.ZERO

	UI_HELPER.apply_back_button_icon(button, "Back")

	var content: MarginContainer = button.get_node_or_null(BACK_CONTENT_NODE_NAME) as MarginContainer
	assert_not_null(content, "Back button content container should be created")
	assert_eq(button.text, "", "Back helper should own text rendering via child labels")
	assert_eq(button.size_flags_vertical, Control.SIZE_SHRINK_CENTER, "Back button should not stretch to header row height")
	assert_true(button.custom_minimum_size.x >= 100.0, "Back button width must not collapse below End Day baseline")
	assert_eq(button.custom_minimum_size.y, 36.0, "Back button height should match End Day baseline")
	assert_eq(content.get_theme_constant("margin_top"), 10, "Back button top content margin should match End Day visual density")
	assert_eq(content.get_theme_constant("margin_bottom"), 10, "Back button bottom content margin should match End Day visual density")

	var normal_style: StyleBox = button.get_theme_stylebox("normal")
	assert_not_null(normal_style, "Back button should have a normal style after helper call")
	assert_true(normal_style.get_content_margin(SIDE_LEFT) >= 24.0, "Back button left padding should match End Day styling")
	assert_true(normal_style.get_content_margin(SIDE_BOTTOM) >= 10.0, "Back button bottom padding should match End Day styling")

	var row: HBoxContainer = content.get_child(0) as HBoxContainer
	assert_not_null(row, "Back content row should exist")
	assert_eq(row.get_child_count(), 2, "Back content row should have icon and text labels")
	assert_eq((row.get_child(0) as Label).text, "arrow_back_ios", "Icon label should use Material ligature")
	assert_eq((row.get_child(1) as Label).text, "Back", "Text label should be the requested back label")
	button.free()


func test_apply_back_button_icon_rebuilds_content_without_duplicates() -> void:
	var button: Button = Button.new()

	UI_HELPER.apply_back_button_icon(button, "Back")
	UI_HELPER.apply_back_button_icon(button, "Back")

	var content_count: int = 0
	for child: Node in button.get_children():
		if child.name == BACK_CONTENT_NODE_NAME:
			content_count += 1

	assert_eq(content_count, 1, "Back button should only contain one generated content container")
	button.free()


func test_apply_list_button_style_sets_variation_and_selection_state() -> void:
	var button: Button = Button.new()

	UI_HELPER.apply_list_button_style(button, true, HORIZONTAL_ALIGNMENT_LEFT)

	assert_eq(button.theme_type_variation, &"ListButton")
	assert_true(button.toggle_mode)
	assert_true(button.button_pressed)
	assert_eq(button.alignment, HORIZONTAL_ALIGNMENT_LEFT)
	assert_true(button.has_theme_stylebox_override("normal"))
	assert_true(button.has_theme_stylebox_override("hover"))
	assert_true(button.has_theme_stylebox_override("pressed"))
	assert_true(button.has_theme_stylebox_override("hover_pressed"))

	var hover_pressed_style: StyleBoxFlat = button.get_theme_stylebox("hover_pressed") as StyleBoxFlat
	assert_not_null(hover_pressed_style, "List button should provide explicit hover_pressed style")
	if hover_pressed_style:
		assert_eq(hover_pressed_style.bg_color.a, 0.0)
		assert_eq(hover_pressed_style.border_width_left, 1)
		assert_eq(hover_pressed_style.border_width_top, 1)
		assert_eq(hover_pressed_style.border_width_right, 1)
		assert_eq(hover_pressed_style.border_width_bottom, 1)
	button.free()


func test_set_list_button_selected_toggles_pressed_state() -> void:
	var button: Button = Button.new()
	UI_HELPER.apply_list_button_style(button, false)

	UI_HELPER.set_list_button_selected(button, true)
	assert_true(button.button_pressed)

	UI_HELPER.set_list_button_selected(button, false)
	assert_false(button.button_pressed)
	button.free()


func test_apply_list_button_style_sets_parent_box_separation_to_zero() -> void:
	var list_container: VBoxContainer = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 9)

	var button: Button = Button.new()
	list_container.add_child(button)

	UI_HELPER.apply_list_button_style(button, false)

	assert_eq(list_container.get_theme_constant("separation"), 0)
	list_container.free()