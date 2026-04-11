## UIFonts.gd
## Semantic font-size token system for the detective game UI.
## Every font size should reference a named constant here,
## not raw integer literals in screen scripts or .tscn overrides.
##
## The theme (main_theme.tres) defines Label type variations that
## use these sizes. Screens should set theme_type_variation on Labels
## rather than calling add_theme_font_size_override().
class_name UIFonts


# --- Size Scale --- #

## Screen header — the main title label on every screen (e.g. "Evidence Archive").
const SIZE_SCREEN_HEADER: int = 26

const SIZE_TITLE: int = 20

## Section header — sub-headings within a screen (e.g. "Approved Warrants").
const SIZE_SECTION: int = 18

## Body — default reading size for content, descriptions, list items.
const SIZE_BODY: int = 16

## Metadata — timestamps, counters, badges, fine print.
const SIZE_METADATA: int = 12
