## Regression test for location investigation header layout.
extends GutTest


func test_back_button_reserves_vertical_space_in_tall_header() -> void:
	var scene: PackedScene = load("res://scenes/ui/location_investigation.tscn") as PackedScene
	assert_not_null(scene, "Location investigation scene should load")

	var instance: Control = scene.instantiate() as Control
	assert_not_null(instance, "Location investigation scene should instantiate")

	var back_button: Button = instance.get_node_or_null("MarginContainer/VBoxContainer/Header/BackButtonMargin/BackButton") as Button
	assert_not_null(back_button, "BackButton should exist in location investigation header")
	assert_eq(
		back_button.size_flags_vertical,
		Control.SIZE_SHRINK_CENTER,
		"BackButton should shrink-center within the tall header row"
	)
	assert_true(
		back_button.custom_minimum_size.y >= 40.0,
		"Location investigation back button should reserve extra vertical room to avoid bottom squeeze"
	)

	instance.free()


func test_main_columns_panels_use_expected_stretch_ratios() -> void:
	var scene: PackedScene = load("res://scenes/ui/location_investigation.tscn") as PackedScene
	assert_not_null(scene, "Location investigation scene should load")

	var instance: Control = scene.instantiate() as Control
	assert_not_null(instance, "Location investigation scene should instantiate")

	var left_panel: PanelContainer = instance.get_node_or_null("MarginContainer/VBoxContainer/MainColumns/LeftPanel") as PanelContainer
	var center_panel: PanelContainer = instance.get_node_or_null("MarginContainer/VBoxContainer/MainColumns/CenterPanel") as PanelContainer
	var right_panel: PanelContainer = instance.get_node_or_null("MarginContainer/VBoxContainer/MainColumns/RightPanel") as PanelContainer
	assert_not_null(left_panel)
	assert_not_null(center_panel)
	assert_not_null(right_panel)

	if left_panel and center_panel and right_panel:
		assert_eq(left_panel.size_flags_stretch_ratio, 0.75, "Left panel should be 30% (0.75 ratio)")
		assert_eq(center_panel.size_flags_stretch_ratio, 1.0, "Center panel should be 40% (1.0 ratio)")
		assert_eq(right_panel.size_flags_stretch_ratio, 0.75, "Right panel should be 30% (0.75 ratio)")

	instance.free()
