## Unit tests for ThemeTokenSync.
## Verifies token-to-theme mappings and serialized theme safety.
extends GutTest


const THEME_PATH: String = "res://resources/themes/main_theme.tres"
const THEME_TOKEN_SYNC = preload("res://tools/sync_theme_from_tokens.gd")
const UI_COLORS = preload("res://scripts/ui/ui_colors.gd")
const UI_FONTS = preload("res://scripts/ui/ui_fonts.gd")


func _load_theme_copy() -> Theme:
	var theme: Theme = load(THEME_PATH) as Theme
	assert_not_null(theme, "Main theme should load")
	if theme == null:
		return Theme.new()
	return theme.duplicate(true) as Theme


func test_apply_tokens_sets_default_font_size() -> void:
	var theme: Theme = _load_theme_copy()
	THEME_TOKEN_SYNC.apply_tokens(theme)
	assert_eq(theme.default_font_size, UI_FONTS.SIZE_BODY)


func test_apply_tokens_sets_button_token_values() -> void:
	var theme: Theme = _load_theme_copy()
	THEME_TOKEN_SYNC.apply_tokens(theme)

	assert_eq(theme.get_color("font_color", "Button"), UI_COLORS.TEXT_PRIMARY)
	assert_eq(theme.get_color("font_hover_color", "Button"), UI_COLORS.TEXT_HOVER)
	assert_eq(theme.get_color("font_pressed_color", "Button"), UI_COLORS.TEXT_HIGHLIGHTED)
	assert_eq(theme.get_color("font_disabled_color", "Button"), UI_COLORS.TEXT_DISABLED)
	assert_eq(theme.get_font_size("font_size", "Button"), UI_FONTS.SIZE_SECTION)


func test_apply_tokens_sets_list_button_contract() -> void:
	var theme: Theme = _load_theme_copy()
	THEME_TOKEN_SYNC.apply_tokens(theme)

	assert_eq(theme.get_color("font_color", "ListButton"), UI_COLORS.TEXT_SECONDARY)
	assert_eq(theme.get_color("font_hover_color", "ListButton"), UI_COLORS.TEXT_HOVER)
	assert_eq(theme.get_color("font_pressed_color", "ListButton"), UI_COLORS.TEXT_HOVER)
	assert_eq(theme.get_color("font_hover_pressed_color", "ListButton"), UI_COLORS.TEXT_HOVER)
	assert_eq(theme.get_color("font_disabled_color", "ListButton"), UI_COLORS.TEXT_DISABLED)
	assert_eq(theme.get_font_size("font_size", "ListButton"), UI_FONTS.SIZE_SECTION)

	var normal_style: StyleBoxFlat = theme.get_stylebox("normal", "ListButton") as StyleBoxFlat
	assert_not_null(normal_style, "ListButton normal style should exist")
	if normal_style:
		assert_eq(normal_style.border_width_left, 0)
		assert_eq(normal_style.border_width_top, 0)
		assert_eq(normal_style.border_width_right, 0)
		assert_eq(normal_style.border_width_bottom, 1)
		assert_eq(normal_style.bg_color.a, 0.0)
		assert_eq(normal_style.corner_radius_bottom_left, 0)
		assert_eq(normal_style.corner_radius_bottom_right, 0)
		assert_eq(normal_style.expand_margin_left, -6.0)
		assert_eq(normal_style.expand_margin_right, -6.0)
		assert_eq(normal_style.content_margin_top, 10.0)
		assert_eq(normal_style.content_margin_bottom, 10.0)

	var hover_style: StyleBoxFlat = theme.get_stylebox("hover", "ListButton") as StyleBoxFlat
	assert_not_null(hover_style, "ListButton hover style should exist")
	if hover_style:
		assert_eq(hover_style.bg_color.a, 0.0)
		assert_eq(hover_style.border_width_left, 0)
		assert_eq(hover_style.border_width_top, 0)
		assert_eq(hover_style.border_width_right, 0)
		assert_eq(hover_style.border_width_bottom, 1)
		assert_eq(hover_style.corner_radius_bottom_left, 0)
		assert_eq(hover_style.corner_radius_bottom_right, 0)
		assert_eq(hover_style.expand_margin_left, -6.0)
		assert_eq(hover_style.expand_margin_right, -6.0)

	var pressed_style: StyleBoxFlat = theme.get_stylebox("pressed", "ListButton") as StyleBoxFlat
	assert_not_null(pressed_style, "ListButton pressed style should exist")
	if pressed_style:
		assert_eq(pressed_style.border_width_left, 1)
		assert_eq(pressed_style.border_width_top, 1)
		assert_eq(pressed_style.border_width_right, 1)
		assert_eq(pressed_style.border_width_bottom, 1)
		assert_eq(pressed_style.border_color, UI_COLORS.MODULATE_NEUTRAL)
		assert_eq(pressed_style.bg_color.a, 0.0)
		assert_eq(pressed_style.expand_margin_left, -6.0)
		assert_eq(pressed_style.expand_margin_right, -6.0)
		assert_eq(pressed_style.shadow_size, 5)
		assert_true(pressed_style.shadow_color.a > 0.0)

	var hover_pressed_style: StyleBoxFlat = theme.get_stylebox("hover_pressed", "ListButton") as StyleBoxFlat
	assert_not_null(hover_pressed_style, "ListButton hover_pressed style should exist")
	if hover_pressed_style:
		assert_eq(hover_pressed_style.border_width_left, 1)
		assert_eq(hover_pressed_style.border_width_top, 1)
		assert_eq(hover_pressed_style.border_width_right, 1)
		assert_eq(hover_pressed_style.border_width_bottom, 1)
		assert_eq(hover_pressed_style.border_color, UI_COLORS.MODULATE_NEUTRAL)
		assert_eq(hover_pressed_style.bg_color.a, 0.0)
		assert_eq(hover_pressed_style.shadow_size, 5)


func test_apply_tokens_sets_header_variation_values() -> void:
	var theme: Theme = _load_theme_copy()
	THEME_TOKEN_SYNC.apply_tokens(theme)

	assert_eq(theme.get_color("font_color", "PanelHeader"), UI_COLORS.TEXT_PRIMARY)
	assert_eq(theme.get_font_size("font_size", "PanelHeader"), UI_FONTS.SIZE_PANEL_HEADER)
	assert_eq(theme.get_color("font_color", "SectionHeader"), UI_COLORS.TEXT_SECONDARY)
	assert_eq(theme.get_font_size("font_size", "SectionHeader"), UI_FONTS.SIZE_SECTION)
	assert_eq(theme.get_color("font_color", "MetadataLabel"), UI_COLORS.TEXT_GREY)
	assert_eq(theme.get_font_size("font_size", "MetadataLabel"), UI_FONTS.SIZE_METADATA)


func test_apply_tokens_sets_action_button_label_variations() -> void:
	var theme: Theme = _load_theme_copy()
	THEME_TOKEN_SYNC.apply_tokens(theme)

	assert_eq(theme.get_color("font_color", "ActionButtonLabel"), UI_COLORS.TEXT_PRIMARY)
	assert_eq(theme.get_font_size("font_size", "ActionButtonLabel"), UI_FONTS.SIZE_SECTION)
	assert_not_null(theme.get_font("font", "ActionButtonLabel"),
		"ActionButtonLabel should have the medium font assigned")

	assert_eq(theme.get_color("font_color", "ActionButtonMeta"), UI_COLORS.TEXT_SECONDARY)
	assert_eq(theme.get_font_size("font_size", "ActionButtonMeta"), UI_FONTS.SIZE_SECTION)


func test_main_theme_is_serialized_without_script_symbols() -> void:
	var content: String = FileAccess.get_file_as_string(THEME_PATH)
	assert_false(content.contains("UIColors."), "main_theme.tres must not reference UIColors directly")
	assert_false(content.contains("UIFonts."), "main_theme.tres must not reference UIFonts directly")
