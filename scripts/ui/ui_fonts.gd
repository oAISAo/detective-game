## UIFonts.gd
## Semantic font-size token system for the detective game UI.
## Every font size should reference a named constant here,
## not raw integer literals in screen scripts or .tscn overrides.
##
## After changing values in this file, run the one-command UI pipeline:
## bash tools/run_ui_theme_pipeline.sh
## This runs theme sync plus both guard tests.
##
## The theme (main_theme.tres) defines Label type variations that
## use these sizes. Screens should set theme_type_variation on Labels
## rather than calling add_theme_font_size_override().
class_name UIFonts


# --- Size Scale --- #

## Placeholder initial in image fallback panels.
const SIZE_PLACEHOLDER_INITIAL: int = 64

## Large display title used on the title screen.
const SIZE_TITLE_SCREEN: int = 40

## Large section title used in selector headers and placeholder initials.
const SIZE_PANEL_HEADER: int = 30

## Large button/menu label size.
const SIZE_MENU_BUTTON: int = 22

const SIZE_TITLE: int = 20

## Section header — sub-headings within a screen (e.g. "Approved Warrants").
const SIZE_SECTION: int = 18

## Body — default reading size for content, descriptions, list items.
const SIZE_BODY: int = 16

## Slightly emphasized small body copy (callouts/warnings).
const SIZE_CALLOUT: int = 14

## Dense detail text for compact rows and metadata supplements.
const SIZE_DETAIL: int = 13

## Metadata — timestamps, counters, badges, fine print.
const SIZE_METADATA: int = 12

## UI-specific display sizes for iconography and stamp effects.
const SIZE_ICON: int = 36
const SIZE_ICON_GLOW: int = 38
const SIZE_NAV_LABEL_GLOW: int = 15
const SIZE_STAMP: int = 28
