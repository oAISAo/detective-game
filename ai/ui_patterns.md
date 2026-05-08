# UI Patterns

## Purpose

This file defines the default UI composition and presentation patterns for the project.

Use it to decide:

- how a screen should be structured
- when to use list, grid, detail, or coordinator layouts
- how to build dynamic UI safely
- how to handle placeholders, empty states, and media fallbacks
- how to apply shared tokens, badges, and selection states consistently

This guide is grounded in the strongest reference slice:

- `location_map`
- `location_investigation`
- `evidence_archive`
- `LocationCard`
- `EvidenceDetailPanel`
- `EvidencePinnedBar`


## Relationship To Other AI Docs

- `architecture.md` defines layer ownership and screen/component boundaries.
- `common_patterns.md` defines reusable feature-level shapes.
- `signal_patterns.md` defines signal contracts.
- `ui_patterns.md` defines how those screens and components should be built visually and structurally.

If there is overlap, use this rule:

- `architecture.md` for ownership
- `common_patterns.md` for feature shape
- `signal_patterns.md` for event routing
- `ui_patterns.md` for layout, composition, and visual-state behavior


## Core UI Model

The project UI follows these defaults:

- screens are built from `Control` nodes and container-driven layouts
- screens render manager state but do not own gameplay truth
- repeated UI units live in focused child components
- detail areas switch between placeholder state and populated state
- dynamic lists and grids are rebuilt from current state instead of patched manually unless a narrow targeted refresh is cheaper
- decorative children should not steal interaction from the component that owns the click or hover contract


## Use Semantic Tokens, Not Raw Styling

### Colors

Use `UIColors` tokens instead of raw `Color(...)` values in screen scripts.

Preferred examples:

- `UIColors.TEXT_PRIMARY`
- `UIColors.TEXT_GREY`
- `UIColors.BLUE`
- `UIColors.AMBER`
- `UIColors.BG_SURFACE`

### Font Sizes

Use `UIFonts` tokens instead of raw integers.

Preferred examples:

- `UIFonts.SIZE_TITLE`
- `UIFonts.SIZE_BODY`
- `UIFonts.SIZE_METADATA`
- `UIFonts.SIZE_PLACEHOLDER_INITIAL`

### Theme Variations First

Prefer theme type variations when one already exists.

Canonical examples:

- `SectionHeader`
- `ListButton`

Use direct theme overrides only when:

- a one-off runtime label is being created in code
- a tokenized override is clearer than introducing a new theme type


## Screen Shell Patterns

### Grid Selector Screen

Use for a browse-first screen with repeated visual cards.

Canonical reference:

- `location_map`

Characteristics:

- scrollable viewport
- padded inner margin so shadows and hover scale are not clipped
- one flow/grid container for repeated cards
- explicit empty state when no items are available

Rule:

- if cards have shadow, scale, or elevation, place the grid inside a padded margin container inside the scroll viewport

This is a tested contract in `test_location_map_ui.gd`.

### Multi-Column Investigation Screen

Use when the player needs to move between a target list, a scene/media panel, and a detail/action panel.

Canonical reference:

- `location_investigation`

Characteristics:

- left column for selectable targets
- center column for media or scene preview
- right column for the active target detail state
- placeholder state before selection or when data is missing

### Archive + Detail Screen

Use when the player browses a collection and inspects one record in depth.

Canonical reference:

- `evidence_archive`

Characteristics:

- collection/grid panel
- filter/search controls at the top
- optional quick-access secondary strip
- persistent detail panel on the side
- selected-card visual feedback


## Dynamic List And Grid Population

### Rebuild From Data Pattern

Use this for screens where the visible collection is derived from manager state.

Rules:

- clear the container before repopulating
- query current items from manager state
- create one component per item
- call `setup(...)` immediately after adding the child
- connect the child intent signal to the parent

Canonical references:

- `location_map._populate_locations()`
- `evidence_archive._populate_evidence_list()`

Pattern:

```gdscript
UIHelper.clear_children(list_root)

for item: Resource in items:
	var card: FeatureCard = CARD_SCENE.instantiate() as FeatureCard
	list_root.add_child(card)
	card.setup(item)
	card.card_pressed.connect(_on_card_pressed)
```

### Empty State Pattern

When a collection has no items, render an explicit empty message in the same container.

Rules:

- use a simple runtime `Label`
- center or expand it appropriately for the container
- style it with muted semantic text tokens

Canonical references:

- `location_map`
- `evidence_archive`
- `location_investigation`


## Placeholder And Content State Pattern

Detail-oriented screens should have a real placeholder state, not a half-empty content panel.

Use when:

- nothing is selected yet
- required data is missing
- a detail panel needs to clear on state load or invalid selection

Rules:

- keep placeholder and content containers separate
- toggle visibility rather than partially mutating one mixed container
- clear dynamic child sections when returning to placeholder mode

Canonical references:

- `location_investigation` using `PlaceholderState` and `TargetState`
- `EvidenceDetailPanel.clear()` and `show_evidence(...)`

Pattern:

```gdscript
func clear() -> void:
	_placeholder_state.visible = true
	_content_state.visible = false
	UIHelper.clear_children(dynamic_section_root)
```


## Dynamic Section Anchors

Use anchor containers when a screen or coordinator owns sections that are created programmatically.

Use when:

- the section is tightly owned by one coordinator
- the section may change independently of scene-file layout
- the layout order matters and is part of the UI contract

Rules:

- define a stable anchor node in the scene
- add one owned child section into that anchor
- keep layout order explicit and test it when important

Canonical references:

- `EvidenceDetailPanel` using `LabSectionAnchor`, `WeightSectionAnchor`, and `NotesSectionAnchor`

This is a tested layout contract in `test_evidence_archive_ui.gd`.


## Scroll Patterns

### Hidden But Functional Scrollbars

When scrollbars should remain usable but visually unobtrusive, set their modulate to transparent.

Canonical references:

- `evidence_archive`
- `EvidenceDetailPanel`

Pattern:

```gdscript
scroll.get_v_scroll_bar().modulate = Color.TRANSPARENT
```

### Shadow Padding Inside Scroll Views

If cards use hover scale, shadows, or border glow, add padding inside the scroll viewport.

Canonical reference:

- `location_map`

Rule:

- do not let the scroll container crop the interactive elevation treatment


## List Button Pattern

Use `UIHelper.apply_list_button_style(...)` for vertically stacked selectable rows.

Canonical reference:

- `location_investigation`

Rules:

- use a plain `Button` as the direct row control
- apply shared list-button styling through `UIHelper`
- encode row content in button text when Godot button hit-testing becomes unreliable with nested child controls

Important constraint:

- do not place child controls inside these list buttons for the investigation target list; that breaks click detection over the text area in this project’s Godot 4 setup

Pattern:

```gdscript
var btn: Button = Button.new()
UIHelper.apply_list_button_style(btn, is_selected, HORIZONTAL_ALIGNMENT_LEFT)
btn.text = item_label
btn.pressed.connect(_on_item_selected.bind(item_id))
```


## Card Component Pattern

Card-like components should own their full interaction surface.

Canonical reference:

- `LocationCard`

Rules:

- route hover and click handling through the card root
- set decorative child controls to `MOUSE_FILTER_IGNORE`
- keep the card's hover, scale, border, and modulate behavior inside the component
- pre-build base and hover styles instead of recomputing them every event

Use when:

- one visual card contains image, footer, badges, and multiple decorative sub-controls
- the entire card should behave like one clickable surface


## Selection Pattern

When a screen has one active item, keep a single selected-node reference and update only the previous and next selections.

Canonical reference:

- `evidence_archive`

Rules:

- clear previous selection before applying the next one
- keep selected visuals inside the child component if possible
- rebuild selection after list repopulation only when the selected ID still exists


## Badge And Metadata Pattern

Use badge pills for compact semantic metadata, not for long-form explanation.

Canonical references:

- `EvidenceDetailPanel` header badges
- shared helper `UIHelper.make_badge_pill(...)`

Rules:

- use badge pills for importance, type, and legal/category labels
- keep badge text uppercase and compact
- use semantic accent colors from `UIColors`
- generate badges through the helper instead of duplicating pill styling in screens


## Media And Image Patterns

### Safe Media Fallback

When media paths may be missing or invalid, show a designed placeholder instead of leaving blank space.

Canonical references:

- `LocationCard` image placeholder
- `location_investigation` scene placeholder

Rules:

- validate the resource path
- show real media when valid
- otherwise show a placeholder with an initial, name, or explanatory notice
- use semantic tokens for placeholder styling

### Rounded Media Clip Pattern

When media should fit inside a rounded panel without visual bleed, wrap it in a clipping container with matching radius.

Canonical references:

- `location_investigation` center scene clip
- `LocationCard` media frame treatment

Rules:

- duplicate or override panel margins when the default theme would misalign the clip area
- use a `PanelContainer` with `clip_children` for rounded clipping

### Square Media Sync Pattern

When one image area must remain square, sync height from width at runtime.

Canonical reference:

- `EvidenceDetailPanel._sync_evidence_image_square(...)`

This is a tested contract in `test_evidence_archive_ui.gd`.


## Search And Filter Controls

Search/filter controls belong to the collection screen, not the manager, when they only affect the current presentation.

Canonical reference:

- `evidence_archive`

Rules:

- keep current search text and filter selection as screen-local state
- use `OptionButton` item IDs for robust enum filtering
- treat index `0` as the explicit no-filter sentinel when appropriate
- rebuild the collection when the filter or search query changes

### Search Icon Overlay Pattern

If a search input needs an embedded icon, add a decorative label inside the input and ignore mouse events on the icon.

Canonical reference:

- `evidence_archive._add_search_icon()`


## Quick-Access Secondary Strip

Use a secondary bar when a small curated subset of items needs fast access while the main collection remains visible.

Canonical reference:

- `EvidencePinnedBar`

Rules:

- let the bar hide itself when empty
- preserve any fixed label child while rebuilding dynamic buttons
- use simple flat buttons for compact navigation affordances
- repopulate the strip from manager state


## Programmatic Typography Adjustments

Use runtime font variation or per-label overrides only for truly local presentation needs.

Canonical reference:

- italicized no-actions hint in `location_investigation`

Rules:

- prefer semantic theme sizes first
- use `FontVariation` for one-off stylistic emphasis when the font asset set is limited
- keep such adjustments local and explicit


## Status And Callout Text

Short status labels should use semantic colors that match gameplay meaning.

Canonical references:

- investigation status text in `location_investigation`
- location status badge colors in `LocationCard`

Rules:

- amber for pending or not inspected
- blue for informational or in-progress/examined states
- muted grey for exhausted, inactive, or metadata states
- green for completed or confirmed success states when appropriate


## Error And Missing-Data UI

Missing or invalid data should produce a safe UI state.

Canonical references:

- `location_investigation` missing `location_id` / missing location
- `LocationCard` invalid setup fallback

Rules:

- log the error
- show a stable, readable fallback state
- hide controls that no longer make sense
- do not leave the user with half-rendered panels or broken buttons


## UI Helper Usage

Prefer shared helper methods when the project already has a stable UI contract for them.

Canonical helpers:

- `UIHelper.clear_children(...)`
- `UIHelper.apply_list_button_style(...)`
- `UIHelper.apply_back_button_icon(...)`
- `UIHelper.add_section_header(...)`
- `UIHelper.make_badge_pill(...)`

Default rule:

- if a helper already standardizes appearance or lifecycle for a UI element, use the helper instead of re-implementing the styling inline


## Testable UI Contracts

Some UI patterns are important enough to preserve with tests.

Already proven contracts include:

- map scroll content has inner padding so card shadows are not clipped
- evidence detail image stays square when sized
- lab section and evidentiary value section appear in the correct first-column order
- notes live in the third column below statements

When a layout choice materially affects usability or visual integrity, add a UI test for it.


## Anti-Patterns

Do not add these in new UI code:

- raw `Color(...)` literals in screens when a `UIColors` token already exists
- raw font-size integers when a `UIFonts` token already exists
- duplicated badge styling instead of using `UIHelper.make_badge_pill(...)`
- decorative child controls intercepting card hover/click input
- nested child controls inside investigation list buttons
- blank media areas with no fallback state
- half-cleared detail panels instead of explicit placeholder/content states
- full-screen rebuilds when a narrow targeted UI update is sufficient


## Mini Templates

### Scrollable Card Grid

```gdscript
extends Control

@onready var grid: GridContainer = %Grid

func _populate_items(items: Array[Resource]) -> void:
	UIHelper.clear_children(grid)
	if items.is_empty():
		var empty := Label.new()
		empty.text = "No items available."
		empty.add_theme_color_override("font_color", UIColors.TEXT_GREY)
		grid.add_child(empty)
		return

	for item: Resource in items:
		var card: FeatureCard = CARD_SCENE.instantiate() as FeatureCard
		grid.add_child(card)
		card.setup(item)
```

### Placeholder / Detail Toggle

```gdscript
func clear_detail() -> void:
	placeholder_state.visible = true
	detail_state.visible = false
	UIHelper.clear_children(dynamic_actions)


func show_detail(data: Resource) -> void:
	placeholder_state.visible = false
	detail_state.visible = true
	_populate_from_data(data)
```

### Safe Image Fallback

```gdscript
func _set_image(image_path: String, fallback_text: String) -> void:
	if image_path.strip_edges().is_empty() or not ResourceLoader.exists(image_path):
		_show_placeholder(fallback_text)
		return

	var texture: Resource = load(image_path)
	if texture is Texture2D:
		image_rect.texture = texture as Texture2D
		image_rect.visible = true
		placeholder.visible = false
		return

	_show_placeholder(fallback_text)
```


## Decision Rule

If you are unsure how to build a new UI slice, choose the smallest combination of these patterns:

1. semantic tokens from `UIColors` and `UIFonts`
2. container-driven screen shell
3. explicit placeholder/content states for detail views
4. focused card or section components for repeated UI
5. safe media and empty-state fallbacks
6. helper-based styling when the project already has a stable helper

Default to the existing reference slice before inventing a new UI style or interaction contract.
