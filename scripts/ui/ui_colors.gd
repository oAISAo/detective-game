## UIColors.gd
## Semantic color token system for the detective game UI.
## Every UI element should draw its color from a named token here,
## not from raw Color() literals in screen scripts.
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
const ACCENT_CLUE: Color = Color(0.9, 0.7, 0.2)

## Muted blue — examined, informational, processing.
const ACCENT_EXAMINED: Color = Color(0.3, 0.55, 0.9)

## Muted green — processed, complete, success.
const ACCENT_PROCESSED: Color = Color(0.35, 0.75, 0.4)

## Desaturated red — contradiction, critical, violent evidence.
const ACCENT_CRITICAL: Color = Color(0.85, 0.3, 0.3)


# --- Text Hierarchy --- #
## Four levels from most to least prominent.

## Primary text — body copy, main content.
const TEXT_PRIMARY: Color = Color(0.85, 0.82, 0.78)

## Secondary text — hints, supplementary info, subtitles.
const TEXT_SECONDARY: Color = Color(0.6, 0.55, 0.4)

## Muted text — disabled states, placeholders, metadata.
const TEXT_MUTED: Color = Color(0.5, 0.48, 0.45)

## Disabled text — fully inactive elements.
const TEXT_DISABLED: Color = Color(0.38, 0.36, 0.33)


# --- Border --- #

## Subtle panel edge — barely visible, just enough to define structure.
const BORDER_SUBTLE: Color = Color(0.3, 0.28, 0.25, 0.6)


# --- Location Card Tokens --- #
## Colors specific to the location map/card presentation.

## Card shell and elevation.
const LOCATION_CARD_BG: Color = BG_BASE
const LOCATION_CARD_BORDER: Color = Color(0.40, 0.40, 0.43, 1.0)
const LOCATION_CARD_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.45)
const LOCATION_CARD_MEDIA_BG: Color = Color(0.08, 0.09, 0.11)

## Card hover feedback.
const LOCATION_CARD_HOVER_BORDER: Color = ACCENT_EXAMINED
const LOCATION_CARD_HOVER_SHADOW: Color = Color(0.3, 0.55, 0.9, 0.45)
const LOCATION_CARD_HOVER_MODULATE: Color = Color(1.03, 1.03, 1.03)
const MODULATE_NEUTRAL: Color = Color.WHITE

## Card action button treatment.
const LOCATION_CARD_BUTTON_BG: Color = Color(0.76, 0.74, 0.70)
const LOCATION_CARD_BUTTON_BORDER: Color = Color(0.60, 0.58, 0.54, 0.4)
const LOCATION_CARD_BUTTON_BG_HOVER: Color = TEXT_PRIMARY
const LOCATION_CARD_BUTTON_BG_PRESSED: Color = Color(0.65, 0.63, 0.60)
const LOCATION_CARD_BUTTON_TEXT: Color = Color(0.12, 0.11, 0.10)
const LOCATION_CARD_BUTTON_TEXT_HOVER: Color = Color(0.08, 0.07, 0.06)
const LOCATION_CARD_BUTTON_TEXT_PRESSED: Color = Color(0.20, 0.18, 0.16)

## Placeholder and badge overlays.
const LOCATION_CARD_PLACEHOLDER_BG: Color = Color(0.10, 0.12, 0.18)
const LOCATION_CARD_PLACEHOLDER_TEXT: Color = TEXT_PRIMARY
const LOCATION_CARD_BADGE_BG: Color = Color(0.0, 0.0, 0.0, 0.55)
const LOCATION_CARD_BADGE_BORDER_ALPHA: float = 0.4


# --- Legacy aliases (preserve backward compat with existing code) --- #

const MUTED: Color = TEXT_MUTED
const SECONDARY: Color = TEXT_SECONDARY
const HEADER: Color = Color(0.7, 0.68, 0.65)


# --- Semantic Status Helpers --- #
## Commonly repeated status-color mappings for convenience.

## Softer green for completed/past items (lower saturation than ACCENT_PROCESSED).
const STATUS_COMPLETE: Color = Color(0.5, 0.7, 0.5)

## Blue for in-progress/processing states.
const STATUS_PROCESSING: Color = Color(0.3, 0.6, 0.85)

## Amber for not-yet-submitted / awaiting action.
const STATUS_PENDING: Color = ACCENT_CLUE

## Bright green for items ready / available now.
const STATUS_AVAILABLE: Color = ACCENT_PROCESSED

## Muted color for unknown/unvisited states.
const STATUS_UNKNOWN: Color = TEXT_MUTED
