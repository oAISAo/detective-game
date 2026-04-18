## Regression tests for case selection list-row styling and selection behavior.
extends GutTest


const CASE_SELECTION_SCENE: PackedScene = preload("res://scenes/ui/case_selection_screen.tscn")
const CASE_LIST_PATH: NodePath = "MarginContainer/VBoxContainer/ContentHBox/CaseListPanel/CaseListScroll/CaseListContainer"


func test_case_list_rows_use_list_button_variation() -> void:
	var screen: Control = CASE_SELECTION_SCENE.instantiate() as Control
	add_child_autofree(screen)

	var buttons: Array[Button] = _get_case_buttons(screen)
	assert_gt(buttons.size(), 0, "Expected at least one case button")
	for btn: Button in buttons:
		assert_eq(btn.theme_type_variation, &"ListButton")
		assert_true(btn.toggle_mode)
		assert_false(btn.disabled)


func test_select_case_updates_pressed_state_instead_of_disabling() -> void:
	var screen: Control = CASE_SELECTION_SCENE.instantiate() as Control
	add_child_autofree(screen)

	var buttons: Array[Button] = _get_case_buttons(screen)
	assert_gt(buttons.size(), 0, "Expected at least one case button")
	if buttons.is_empty():
		return

	buttons[0].emit_signal("pressed")

	for i: int in buttons.size():
		var should_be_selected: bool = i == 0
		assert_eq(buttons[i].button_pressed, should_be_selected)
		assert_false(buttons[i].disabled, "List selection should not disable buttons")


func _get_case_buttons(screen: Control) -> Array[Button]:
	var container: VBoxContainer = screen.get_node_or_null(CASE_LIST_PATH) as VBoxContainer
	assert_not_null(container, "Case list container should exist")
	if container == null:
		return []

	var buttons: Array[Button] = []
	for child: Node in container.get_children():
		if child is Button:
			buttons.append(child as Button)
	return buttons
