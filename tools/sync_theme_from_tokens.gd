## ThemeTokenSync.gd
## Synchronizes semantic UI tokens into the serialized main theme resource.
class_name ThemeTokenSync
extends RefCounted


const DEFAULT_THEME_PATH: String = "res://resources/themes/main_theme.tres"
const UI_COLORS = preload("res://scripts/ui/ui_colors.gd")
const UI_FONTS = preload("res://scripts/ui/ui_fonts.gd")


static func sync_main_theme(theme_path: String = DEFAULT_THEME_PATH) -> int:
	var theme: Theme = load(theme_path) as Theme
	if theme == null:
		push_error("[ThemeTokenSync] Failed to load theme at %s" % theme_path)
		return ERR_CANT_OPEN

	apply_tokens(theme)

	var save_err: int = ResourceSaver.save(theme, theme_path)
	if save_err != OK:
		push_error("[ThemeTokenSync] Failed to save theme to %s (err=%d)" % [theme_path, save_err])
	return save_err


static func apply_tokens(theme: Theme) -> void:
	if theme == null:
		push_error("[ThemeTokenSync] apply_tokens called with null theme")
		return

	theme.default_font_size = UI_FONTS.SIZE_BODY

	_apply_button_tokens(theme)
	_apply_primary_button_tokens(theme)
	_apply_list_button_tokens(theme)
	_apply_action_button_tokens(theme)
	_apply_label_tokens(theme)
	_apply_variation_tokens(theme)
	_apply_scene_variation_tokens(theme)


static func _apply_button_tokens(theme: Theme) -> void:
	theme.set_color("font_color", "Button", UI_COLORS.TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", UI_COLORS.TEXT_HOVER)
	theme.set_color("font_pressed_color", "Button", UI_COLORS.TEXT_HIGHLIGHTED)
	theme.set_color("font_disabled_color", "Button", UI_COLORS.TEXT_DISABLED)
	theme.set_font_size("font_size", "Button", UI_FONTS.SIZE_SECTION)


static func _apply_primary_button_tokens(theme: Theme) -> void:
	theme.set_color("font_color", "PrimaryButton", UI_COLORS.TEXT_PRIMARY)
	theme.set_color("font_hover_color", "PrimaryButton", UI_COLORS.TEXT_HOVER)
	theme.set_color("font_pressed_color", "PrimaryButton", UI_COLORS.TEXT_HIGHLIGHTED)
	theme.set_color("font_disabled_color", "PrimaryButton", UI_COLORS.TEXT_DISABLED)
	theme.set_font_size("font_size", "PrimaryButton", UI_FONTS.SIZE_SECTION)


static func _apply_list_button_tokens(theme: Theme) -> void:
	theme.set_color("font_color", "ListButton", UI_COLORS.TEXT_SECONDARY)
	theme.set_color("font_hover_color", "ListButton", UI_COLORS.TEXT_HOVER)
	theme.set_color("font_pressed_color", "ListButton", UI_COLORS.TEXT_HOVER)
	theme.set_color("font_hover_pressed_color", "ListButton", UI_COLORS.TEXT_HOVER)
	theme.set_color("font_disabled_color", "ListButton", UI_COLORS.TEXT_DISABLED)
	theme.set_font_size("font_size", "ListButton", UI_FONTS.SIZE_SECTION)

	var normal_style: StyleBoxFlat = _create_list_button_style(
		Color(UI_COLORS.BG_SURFACE.r, UI_COLORS.BG_SURFACE.g, UI_COLORS.BG_SURFACE.b, 0.0),
		UI_COLORS.BORDER_SUBTLE,
		0, 0, 0, 1,
		true
	)
	theme.set_stylebox("normal", "ListButton", normal_style)

	var hover_style: StyleBoxFlat = _create_list_button_style(
		Color(UI_COLORS.BG_SURFACE.r, UI_COLORS.BG_SURFACE.g, UI_COLORS.BG_SURFACE.b, 0.0),
		UI_COLORS.BORDER_SUBTLE,
		0, 0, 0, 1,
		true
	)
	theme.set_stylebox("hover", "ListButton", hover_style)

	var pressed_style: StyleBoxFlat = _create_list_button_style(
		Color(UI_COLORS.BG_SURFACE.r, UI_COLORS.BG_SURFACE.g, UI_COLORS.BG_SURFACE.b, 0.0),
		UI_COLORS.MODULATE_NEUTRAL,
		1, 1, 1, 1
	)
	pressed_style.shadow_color = Color(UI_COLORS.MODULATE_NEUTRAL.r, UI_COLORS.MODULATE_NEUTRAL.g, UI_COLORS.MODULATE_NEUTRAL.b, 0.35)
	pressed_style.shadow_size = 5
	pressed_style.shadow_offset = Vector2(0, 0)
	theme.set_stylebox("pressed", "ListButton", pressed_style)
	theme.set_stylebox("hover_pressed", "ListButton", pressed_style.duplicate(true))

	var disabled_style: StyleBoxFlat = _create_list_button_style(
		Color(UI_COLORS.BG_SURFACE.r, UI_COLORS.BG_SURFACE.g, UI_COLORS.BG_SURFACE.b, 0.0),
		Color(UI_COLORS.TEXT_DISABLED.r, UI_COLORS.TEXT_DISABLED.g, UI_COLORS.TEXT_DISABLED.b, 0.55),
		0, 0, 0, 1,
		true
	)
	theme.set_stylebox("disabled", "ListButton", disabled_style)
	theme.set_stylebox("focus", "ListButton", StyleBoxEmpty.new())


static func _create_list_button_style(
	bg_color: Color,
	border_color: Color,
	border_left: int,
	border_top: int,
	border_right: int,
	border_bottom: int,
	flat_bottom_corners: bool = false
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_left
	style.border_width_top = border_top
	style.border_width_right = border_right
	style.border_width_bottom = border_bottom
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	style.expand_margin_left = -6.0
	style.expand_margin_right = -6.0
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 0 if flat_bottom_corners else 8
	style.corner_radius_bottom_right = 0 if flat_bottom_corners else 8
	return style


static func _apply_action_button_tokens(theme: Theme) -> void:
	_set_variation_base(theme, "ActionButtonLabel", "Label")
	theme.set_color("font_color", "ActionButtonLabel", UI_COLORS.TEXT_PRIMARY)
	theme.set_font_size("font_size", "ActionButtonLabel", UI_FONTS.SIZE_SECTION)

	var medium_font: Font = theme.get_font("font", "Button")
	if medium_font != null:
		theme.set_font("font", "ActionButtonLabel", medium_font)

	_set_variation_base(theme, "ActionButtonMeta", "Label")
	theme.set_color("font_color", "ActionButtonMeta", UI_COLORS.TEXT_SECONDARY)
	theme.set_font_size("font_size", "ActionButtonMeta", UI_FONTS.SIZE_SECTION)


static func _apply_label_tokens(theme: Theme) -> void:
	theme.set_color("font_color", "Label", UI_COLORS.TEXT_PRIMARY)
	theme.set_font_size("font_size", "Label", UI_FONTS.SIZE_BODY)
	theme.set_color("default_color", "RichTextLabel", UI_COLORS.TEXT_PRIMARY)
	theme.set_font_size("font_size", "RichTextLabel", UI_FONTS.SIZE_BODY)
	theme.set_color("font_color", "LineEdit", UI_COLORS.TEXT_PRIMARY)
	theme.set_font_size("font_size", "LineEdit", UI_FONTS.SIZE_BODY)


static func _apply_variation_tokens(theme: Theme) -> void:
	theme.set_color("font_color", "PanelHeader", UI_COLORS.TEXT_PRIMARY)
	theme.set_font_size("font_size", "PanelHeader", UI_FONTS.SIZE_PANEL_HEADER)

	theme.set_color("font_color", "SectionHeader", UI_COLORS.TEXT_SECONDARY)
	theme.set_font_size("font_size", "SectionHeader", UI_FONTS.SIZE_SECTION)

	theme.set_color("font_color", "MetadataLabel", UI_COLORS.TEXT_GREY)
	theme.set_font_size("font_size", "MetadataLabel", UI_FONTS.SIZE_METADATA)


static func _apply_scene_variation_tokens(theme: Theme) -> void:
	_set_variation_base(theme, "ListButton", "Button")
	_set_variation_base(theme, "TitleMenuButton", "Button")
	_set_variation_base(theme, "TitleDebugButton", "Button")
	_set_variation_base(theme, "TitleScreenHeader", "Label")
	_set_variation_base(theme, "PanelHeader", "Label")
	_set_variation_base(theme, "EmptyStateLabel", "Label")
	_set_variation_base(theme, "DetailStateLabel", "Label")
	_set_variation_base(theme, "WarningLabel", "Label")
	_set_variation_base(theme, "BriefingText", "RichTextLabel")

	theme.set_font_size("font_size", "TitleMenuButton", UI_FONTS.SIZE_MENU_BUTTON)

	theme.set_font_size("font_size", "TitleDebugButton", UI_FONTS.SIZE_MENU_BUTTON)
	theme.set_color("font_color", "TitleDebugButton", UI_COLORS.TEXT_DEBUG_ACTION)
	theme.set_color("font_hover_color", "TitleDebugButton", UI_COLORS.TEXT_HOVER)
	theme.set_color("font_pressed_color", "TitleDebugButton", UI_COLORS.TEXT_HIGHLIGHTED)
	theme.set_color("font_disabled_color", "TitleDebugButton", UI_COLORS.TEXT_DISABLED)

	theme.set_color("font_color", "TitleScreenHeader", UI_COLORS.TEXT_PRIMARY)
	theme.set_font_size("font_size", "TitleScreenHeader", UI_FONTS.SIZE_TITLE_SCREEN)

	theme.set_color("font_color", "PanelHeader", UI_COLORS.TEXT_PRIMARY)
	theme.set_font_size("font_size", "PanelHeader", UI_FONTS.SIZE_PANEL_HEADER)

	var header_font: Font = theme.get_font("font", "PanelHeader")
	if header_font != null:
		theme.set_font("font", "TitleScreenHeader", header_font)
		theme.set_font("font", "PanelHeader", header_font)

	theme.set_color("font_color", "EmptyStateLabel", UI_COLORS.TEXT_GREY)
	theme.set_font_size("font_size", "EmptyStateLabel", UI_FONTS.SIZE_BODY)

	theme.set_color("font_color", "DetailStateLabel", UI_COLORS.TEXT_GREY)
	theme.set_font_size("font_size", "DetailStateLabel", UI_FONTS.SIZE_BODY)

	theme.set_color("font_color", "WarningLabel", UI_COLORS.AMBER_WARNING)
	theme.set_font_size("font_size", "WarningLabel", UI_FONTS.SIZE_CALLOUT)

	theme.set_color("default_color", "BriefingText", UI_COLORS.TEXT_PRIMARY)
	theme.set_font_size("font_size", "BriefingText", UI_FONTS.SIZE_TITLE)


static func _set_variation_base(theme: Theme, variation: String, base_type: String) -> void:
	if theme.has_method("set_type_variation"):
		theme.call("set_type_variation", variation, base_type)
