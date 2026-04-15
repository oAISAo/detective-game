## UIColors.gd
## Semantic color token system for the detective game UI.
## Every UI element should draw its color from a named token here,
## not from raw Color() literals in screen scripts.
##
## After changing values in this file, run the one-command UI pipeline:
## bash tools/run_ui_theme_pipeline.sh
## This runs theme sync plus both guard tests.
class_name UIColors


# --- Background Layers --- #
## Three distinct dark values for panel depth layering.

## Deepest background layer (game root / window fill).
const BG_BASE: Color = Color(0.10, 0.10, 0.13)

## Mid-level panels (PanelContainer default).
const BG_PANEL: Color = Color(0.15, 0.15, 0.18)

## Surface-level panels (nested content areas, cards).
const BG_SURFACE: Color = Color(0.19, 0.19, 0.22)


# --- Semantic Accent Colors --- #
## Meaning-based accents used consistently across all screens.

## Amber/gold — clue, attention, pending, warning.
const AMBER: Color = Color(0.9, 0.7, 0.2)

## Warm amber-orange for warning/collision callouts.
const AMBER_WARNING: Color = Color(0.9, 0.55, 0.3)

## Muted blue — examined, informational, processing.
const BLUE: Color = Color(0.3, 0.55, 0.9)

## Muted green — processed, complete, success.
const GREEN: Color = Color(0.35, 0.75, 0.4)

## Desaturated red — contradiction, critical, violent evidence.
const RED: Color = Color(0.85, 0.3, 0.3)


# --- Text Hierarchy --- #
## Core levels plus named role-specific text tokens.

## Primary text — body copy, main content.
const TEXT_PRIMARY: Color = Color(0.85, 0.82, 0.78)

const TEXT_HOVER: Color = Color(1, 0.95, 0.88)

const TEXT_HIGHLIGHTED: Color = Color(0.7, 0.65, 0.6)

## Secondary text — hints, supplementary info, subtitles.
const TEXT_SECONDARY: Color = Color(0.7, 0.68, 0.65)

## Muted text — disabled states, placeholders, metadata.
const TEXT_GREY: Color = Color(0.5, 0.48, 0.45)

## Debug-action text accent for special dev-only controls.
const TEXT_DEBUG_ACTION: Color = Color(0.7, 0.5, 0.3)

## Disabled text — fully inactive elements.
const TEXT_DISABLED: Color = Color(0.38, 0.36, 0.33)


# --- Border --- #

## Subtle panel edge — barely visible, just enough to define structure.
const BORDER_SUBTLE: Color = Color(0.3, 0.28, 0.25, 0.6)


# --- Location Card Tokens --- #
## Colors specific to the location map/card presentation.

## Card shell and elevation.
const LOCATION_CARD_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.45)
const LOCATION_CARD_MEDIA_BG: Color = Color(0.08, 0.09, 0.11)

## Card hover feedback.
const LOCATION_CARD_HOVER_SHADOW: Color = Color(0.3, 0.55, 0.9, 0.45)
const LOCATION_CARD_HOVER_MODULATE: Color = Color(1.03, 1.03, 1.03)
const MODULATE_NEUTRAL: Color = Color.WHITE

## Placeholder and badge overlays.
const LOCATION_CARD_PLACEHOLDER_BG: Color = Color(0.10, 0.12, 0.18)
const LOCATION_CARD_BADGE_BG: Color = Color(0.0, 0.0, 0.0, 0.55)
const LOCATION_CARD_BADGE_BORDER_ALPHA: float = 0.4

