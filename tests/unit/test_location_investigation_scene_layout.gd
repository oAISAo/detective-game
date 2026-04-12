## Regression test for location investigation header layout.
extends GutTest


func test_back_button_does_not_use_shrink_center_vertical_sizing() -> void:
	var scene: PackedScene = load("res://scenes/ui/location_investigation.tscn") as PackedScene
	assert_not_null(scene, "Location investigation scene should load")

	var instance: Control = scene.instantiate() as Control
	assert_not_null(instance, "Location investigation scene should instantiate")

	var back_button: Button = instance.get_node_or_null("MarginContainer/VBoxContainer/Header/BackButton") as Button
	assert_not_null(back_button, "BackButton should exist in location investigation header")
	assert_ne(
		back_button.size_flags_vertical,
		Control.SIZE_SHRINK_CENTER,
		"BackButton must not use vertical shrink-center because it compresses perceived bottom padding"
	)
	assert_true(
		back_button.custom_minimum_size.y <= 0.0,
		"Scene should not force a back-button min height; helper applies runtime sizing"
	)

	instance.free()


func test_main_columns_panels_use_equal_stretch_ratios() -> void:
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
		assert_eq(left_panel.size_flags_stretch_ratio, 1.0)
		assert_eq(center_panel.size_flags_stretch_ratio, 1.0)
		assert_eq(right_panel.size_flags_stretch_ratio, 1.0)

	instance.free()


func test_detail_placeholder_defaults_are_center_aligned() -> void:
	var scene: PackedScene = load("res://scenes/ui/location_investigation.tscn") as PackedScene
	assert_not_null(scene, "Location investigation scene should load")

	var instance: Control = scene.instantiate() as Control
	assert_not_null(instance, "Location investigation scene should instantiate")

	var detail_panel: VBoxContainer = instance.get_node_or_null("MarginContainer/VBoxContainer/MainColumns/RightPanel/RightVBox/DetailPanel") as VBoxContainer
	var detail_title: Label = instance.get_node_or_null("MarginContainer/VBoxContainer/MainColumns/RightPanel/RightVBox/DetailPanel/DetailTitle") as Label
	var detail_description: Label = instance.get_node_or_null("MarginContainer/VBoxContainer/MainColumns/RightPanel/RightVBox/DetailPanel/DetailDescription") as Label
	assert_not_null(detail_panel)
	assert_not_null(detail_title)
	assert_not_null(detail_description)

	if detail_panel and detail_title and detail_description:
		assert_eq(detail_panel.alignment, BoxContainer.ALIGNMENT_CENTER)
		assert_eq(detail_title.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
		assert_eq(detail_description.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
		assert_eq(detail_description.vertical_alignment, VERTICAL_ALIGNMENT_CENTER)

	instance.free()