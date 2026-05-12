## test_notification_toast.gd
## Unit tests for the NotificationToast component.
## Verifies accent color mapping, mouse filter, child structure, and panel style.
extends GutTest


# ============================================================
# Accent Color Mapping
# ============================================================

func test_accent_color_evidence_is_clue() -> void:
	var color: Color = NotificationToast.get_accent_color(NotificationManager.NotificationType.EVIDENCE)
	assert_eq(color, UIColors.AMBER, "EVIDENCE should map to AMBER")


func test_accent_color_lab_result_is_clue() -> void:
	var color: Color = NotificationToast.get_accent_color(NotificationManager.NotificationType.LAB_RESULT)
	assert_eq(color, UIColors.AMBER, "LAB_RESULT should map to AMBER")


func test_accent_color_hint_is_clue() -> void:
	var color: Color = NotificationToast.get_accent_color(NotificationManager.NotificationType.HINT)
	assert_eq(color, UIColors.AMBER, "HINT should map to AMBER")


func test_accent_color_statement_is_processed() -> void:
	var color: Color = NotificationToast.get_accent_color(NotificationManager.NotificationType.STATEMENT)
	assert_eq(color, UIColors.GREEN, "STATEMENT should map to GREEN")


func test_accent_color_surveillance_is_processed() -> void:
	var color: Color = NotificationToast.get_accent_color(NotificationManager.NotificationType.SURVEILLANCE)
	assert_eq(color, UIColors.GREEN, "SURVEILLANCE should map to GREEN")


func test_accent_color_warrant_is_processed() -> void:
	var color: Color = NotificationToast.get_accent_color(NotificationManager.NotificationType.WARRANT)
	assert_eq(color, UIColors.GREEN, "WARRANT should map to GREEN")


func test_accent_color_story_is_processed() -> void:
	var color: Color = NotificationToast.get_accent_color(NotificationManager.NotificationType.STORY)
	assert_eq(color, UIColors.GREEN, "STORY should map to GREEN")


func test_accent_color_system_is_critical() -> void:
	var color: Color = NotificationToast.get_accent_color(NotificationManager.NotificationType.SYSTEM)
	assert_eq(color, UIColors.RED, "SYSTEM should map to RED")


# ============================================================
# Mouse Filter
# ============================================================

func test_toast_mouse_filter_is_ignore() -> void:
	var toast: Node = NotificationToast.new()
	add_child_autofree(toast)
	toast.setup({"title": "Test", "message": "Message", "type": NotificationManager.NotificationType.EVIDENCE})
	assert_eq(toast.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Toast should pass through clicks")


# ============================================================
# Child Structure
# ============================================================

func test_toast_builds_children_on_setup() -> void:
	var toast: Node = NotificationToast.new()
	add_child_autofree(toast)
	toast.setup({"title": "Title", "message": "Body", "type": NotificationManager.NotificationType.SYSTEM})
	assert_gt(toast.get_child_count(), 0, "Toast should have children after setup")


func test_toast_has_panel_style() -> void:
	var toast: Node = NotificationToast.new()
	add_child_autofree(toast)
	toast.setup({"title": "Title", "message": "Body", "type": NotificationManager.NotificationType.EVIDENCE})
	var style: StyleBox = toast.get_theme_stylebox("panel")
	assert_not_null(style, "Toast should have a panel StyleBox override")


func test_toast_minimum_width() -> void:
	var toast: Node = NotificationToast.new()
	add_child_autofree(toast)
	toast.setup({"title": "Title", "message": "Body", "type": NotificationManager.NotificationType.EVIDENCE})
	assert_eq(toast.custom_minimum_size.x, 350.0, "Toast should have 350px minimum width")


func test_toast_empty_message_omits_label() -> void:
	var toast: Node = NotificationToast.new()
	add_child_autofree(toast)
	toast.setup({"title": "Title Only", "message": "", "type": NotificationManager.NotificationType.SYSTEM})
	# Walk the tree: PanelContainer → MarginContainer → HBox → [bar, VBox]
	# VBox should have exactly 1 child (title only, no message label)
	var margin: MarginContainer = toast.get_child(0) as MarginContainer
	var row: HBoxContainer = margin.get_child(0) as HBoxContainer
	var text_col: VBoxContainer = row.get_child(1) as VBoxContainer
	assert_eq(text_col.get_child_count(), 1, "Empty message should produce only a title label")


func test_toast_with_message_has_two_labels() -> void:
	var toast: Node = NotificationToast.new()
	add_child_autofree(toast)
	toast.setup({"title": "Title", "message": "Some message", "type": NotificationManager.NotificationType.EVIDENCE})
	var margin: MarginContainer = toast.get_child(0) as MarginContainer
	var row: HBoxContainer = margin.get_child(0) as HBoxContainer
	var text_col: VBoxContainer = row.get_child(1) as VBoxContainer
	assert_eq(text_col.get_child_count(), 2, "Toast with message should have title + message labels")


# ============================================================
# Toast Container Input Passthrough (regression — prevents invisible overlay)
# ============================================================

## ToastAnchor and ToastContainer live on a high CanvasLayer (layer 5) in
## game_root.tscn. If their mouse_filter is MOUSE_FILTER_STOP (the default),
## they create an invisible input-blocking region that swallows clicks on
## game UI below. Both must be MOUSE_FILTER_IGNORE to pass events through.

func test_toast_anchor_mouse_filter_is_ignore() -> void:
	var scene: PackedScene = load("res://scenes/core/game_root.tscn") as PackedScene
	assert_not_null(scene, "game_root.tscn should load")
	var root: Node = scene.instantiate()
	add_child_autofree(root)
	var anchor: Control = root.get_node("ToastLayer/ToastAnchor") as Control
	assert_not_null(anchor, "ToastAnchor should exist")
	assert_eq(anchor.mouse_filter, Control.MOUSE_FILTER_IGNORE, "ToastAnchor must not block input")


func test_toast_container_mouse_filter_is_ignore() -> void:
	var scene: PackedScene = load("res://scenes/core/game_root.tscn") as PackedScene
	assert_not_null(scene, "game_root.tscn should load")
	var root: Node = scene.instantiate()
	add_child_autofree(root)
	var container: Control = root.get_node("ToastLayer/ToastAnchor/ToastContainer") as Control
	assert_not_null(container, "ToastContainer should exist")
	assert_eq(container.mouse_filter, Control.MOUSE_FILTER_IGNORE, "ToastContainer must not block input")
