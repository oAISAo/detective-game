# Project Architecture

## Purpose

This file defines the default architecture for new screens, features, and bug fixes.

It is based on the strongest existing reference slice:

- `location_map`
- `location_investigation`
- `evidence_archive`
- their child components
- the shared manager/navigation/save-load stack behind them

Use this file to keep future work consistent, testable, and low-ambiguity.


## Scope

This document covers:

- feature slice structure
- ownership boundaries
- screen and component responsibilities
- manager responsibilities
- signal and refresh rules
- navigation and save/load contracts
- testing expectations

This document does not cover:

- detailed visual styling
- case-specific gameplay content
- asset naming rules
- one-off layout details unless they demonstrate a reusable architecture rule


## Layer Model

### Data Layer

- Static case content lives in JSON files and typed data resources.
- Case data is read through loaders and `CaseManager` queries.
- Data objects define content, not runtime UI state.
- Do not store player progress, selection state, or transient UI flags in data resources.
- Evidence authoring semantics for `weight`, `importance_level`, statement materiality, and `critical_evidence_ids` live in `evidence_authoring.md`. Read that file before changing those fields or their meaning.

### Game Logic Layer

- Runtime game state lives in managers.
- Stateful managers should extend `BaseSubsystem` and participate in reset/save/load.
- Managers own commands, queries, derived state, validation, and typed signals.
- Managers may depend on other managers and data lookups.
- Managers must not depend on UI nodes, scene tree structure, or Control-specific behavior.

### UI Layer

- Screens are thin controllers over manager state.
- Child components render narrow slices of UI and emit user intent upward.
- UI reads immutable data and derived state from managers.
- UI decides presentation and interaction flow, but not gameplay rules.


## Default Feature Slice

Build new features in this shape unless there is a strong reason not to:

1. Data resource or case JSON defines static content.
2. Manager owns mutable runtime state and exposes commands, queries, and typed signals.
3. Screen reads `ScreenManager.navigation_data`, validates inputs, and renders from manager state.
4. Child components are instantiated from scenes or created programmatically when tightly owned by the parent.
5. User actions go screen/component -> manager command.
6. Manager updates state and emits signals.
7. Screen refreshes locally, performs a targeted refresh, or coalesces a deferred refresh depending on who owns the interaction loop.
8. Tests cover manager behavior, screen behavior, and any cross-screen flow that matters.

Use `location_map`, `location_investigation`, and `evidence_archive` as the canonical examples of this slice.


## Screen Responsibilities

Screens are controllers, not state owners.

Do:

- validate `ScreenManager.navigation_data` in `_ready()`
- fetch immutable content from `CaseManager`
- fetch runtime and derived state from managers
- route button presses and UI actions into manager commands
- manage selection, filter text, hover state, and other display-only local state
- rebuild UI from current manager state instead of maintaining a second source of truth
- connect runtime signals in `_ready()` when the screen must stay live while open
- disconnect those signals in `_exit_tree()`
- show safe fallback UI when required data is missing

Do not:

- implement core gameplay logic in the screen
- keep shadow copies of manager-owned runtime state
- mutate saveable game state directly from UI collections or dictionaries
- navigate by loading scenes directly; always use `ScreenManager`
- rely on child components to perform screen-level orchestration

Default rule for local state:

- keep only UI-only state in the screen
- if state affects gameplay, persistence, derived status, unlocks, or other screens, move it to a manager


## Child Component Responsibilities

Child components should stay focused and reusable.

Do:

- give each component one clear job
- expose a small `setup(...)` or `populate(...)` API
- emit typed signals upward for user intent
- own only display state such as hover, selected visuals, expanded state, or local formatting
- validate setup input and fail safely with placeholder UI when needed
- stay independent of parent internals except for the explicit contract the parent gives them

Do not:

- query unrelated managers unless the component is explicitly a coordinator component
- navigate directly between screens
- reach into sibling nodes
- own gameplay truth that must survive refresh, reload, or save/load

Allowed patterns:

- scene-based reusable components like `LocationCard` or `EvidencePolaroid`
- tightly owned sub-components created programmatically by a parent coordinator like `EvidenceDetailPanel`


## Manager Responsibilities

Managers are the source of truth for runtime behavior.

Do:

- own mutable runtime state
- expose explicit commands for mutations
- expose query methods for derived state
- centralize rule evaluation and status calculation
- emit typed, descriptive, past-tense signals when state changes
- return structured results for command failures when the screen needs a player-facing reason
- use descriptive constants and enums for public states and actions
- implement `reset()`, `serialize()`, and `deserialize()` when the manager owns persistent state
- emit `state_loaded` after deserializing persistent state
- defer manager-to-manager signal hookup when autoload order may be uncertain

Do not:

- access screen nodes or UI layout structure
- hide important rule decisions inside UI callbacks
- scatter the same derived-state logic across multiple screens
- use untyped or vague signals when a specific contract is known

Default public API split:

- commands: `start_investigation`, `inspect_object`, `toggle_pin`
- queries: `get_location_completion`, `get_object_display_status`, `get_discovered_evidence_data`
- signals: `object_state_changed`, `evidence_pinned`, `state_loaded`


## Data Flow And Navigation

Use one-way flow by default:

`case data -> manager queries -> screen -> child components`

Use command flow for mutations:

`child component or screen -> manager command -> state change -> signal -> refresh`

Navigation contract:

- all screen transitions go through `ScreenManager.navigate_to(...)` or `ScreenManager.navigate_back()`
- pass only the minimum navigation payload needed by the destination screen
- destination screens must validate navigation data before building UI
- navigation data is input only; it is not a substitute for manager state

Default navigation examples:

- map card press -> start investigation in manager -> navigate to `location_investigation`
- clue card press in investigation screen -> navigate to `evidence_archive` with `evidence_id`


## Signal Rules

This project uses Signal Up, Call Down.

Rules:

- child components signal user intent upward
- parents call child methods downward
- managers emit state-change events outward
- screens translate manager signals into UI refresh behavior
- use typed signal signatures whenever the payload is known
- use descriptive, past-tense signal names for state changes

Connection rules:

- connect in `_ready()`
- disconnect in `_exit_tree()` when the connection lifetime is tied to the screen or component
- avoid duplicate connections
- store `Callable` values when disconnection needs the same reference later
- prefer local connections for screen-specific behavior; do not introduce a global signal bus for local UI wiring


## Refresh Strategy

Choose the smallest refresh that keeps behavior correct.

### Local Refresh After Direct Commands

Use this when the current screen owns the user action and can immediately rebuild from manager state.

Examples:

- `location_investigation` calls a manager command, then runs `_refresh_ui()`
- detail-panel actions can update only the currently shown panel state

### Targeted Refresh For Narrow Runtime Changes

Use this when a single card, badge, or section can be updated without rebuilding the whole screen.

Examples:

- `evidence_archive` refreshes badges for one evidence card after pin/review changes

### Deferred Coalesced Refresh For Live Screens

Use this when multiple external runtime signals can arrive while a screen remains open.

Examples:

- `location_map` subscribes to relevant runtime signals and coalesces them into one deferred refresh

Default rule:

- if one command changes one local view, refresh locally
- if one runtime event changes one known visual target, refresh that target
- if many external state changes can affect the visible list, queue one deferred rebuild


## Save And Load Contract

Saveable runtime state belongs in managers, not screens.

Rules:

- screens and components should be disposable and rebuildable from manager state
- persistent managers extend `BaseSubsystem`
- `reset()` returns the manager to new-game state
- `serialize()` returns only runtime/player state
- `deserialize()` restores that runtime/player state
- managers emit `state_loaded` after deserialization so open screens can clear or refresh safely
- screen-local selections, filters, scroll positions, and hover state are transient by default unless product requirements say otherwise


## Testing Expectations

Every new system or bug fix should reinforce this architecture with tests.

Required expectations:

- bug fixes get a regression test when possible
- new manager behavior gets manager-focused tests
- new screens and components get UI-focused tests where behavior or layout contracts matter
- cross-screen or cross-manager flows get scenario or integration coverage when the interaction is important

Test at the level that owns the behavior:

- manager tests for commands, derived state, persistence, and signals
- UI tests for rendering contracts, refresh behavior, and interaction plumbing
- scenario tests for end-to-end flow across days, locations, evidence, or navigation

Default setup pattern:

- start from a known game state
- load case data
- reset relevant managers
- unlock only what the test needs
- assert behavior, not internal implementation details


## Anti-Patterns

Avoid these by default:

- UI scripts owning gameplay truth
- managers reaching into scene nodes
- child components navigating directly to other screens
- duplicated derived-state logic across multiple screens
- direct scene loading instead of `ScreenManager`
- persistent state stored only in screens or components
- broad refreshes when a narrow targeted refresh is already available and safe
- local screen dictionaries quietly becoming a second source of truth
- introducing a new architecture style for one feature when the existing slice already solves the problem


## Canonical References

Use these files as implementation anchors before inventing a new pattern:

- `scripts/ui/screens/location_map.gd`
	- thin screen controller
	- runtime signal subscription
	- deferred coalesced refresh
	- screen navigation via manager + `ScreenManager`

- `scripts/ui/components/location_card.gd`
	- reusable child component with `setup(...)`
	- typed upward signal
	- safe fallback behavior for invalid input

- `scripts/ui/screens/location_investigation.gd`
	- local refresh after direct commands
	- screen-owned selection state
	- dynamic child section creation
	- screen-to-screen navigation from a selected clue

- `scripts/managers/location_investigation_manager.gd`
	- manager as source of truth
	- command/query split
	- derived state owned by the manager
	- structured command results and typed signals

- `scripts/ui/screens/evidence_archive.gd`
	- complex screen controller with filtering and selection
	- targeted card refreshes
	- proper signal connection and cleanup

- `scripts/ui/components/evidence_detail_panel.gd`
	- parent-owned coordinator component
	- programmatic sub-component composition
	- child-to-parent event routing without leaking screen logic downward

- `scripts/managers/evidence_manager.gd`
	- persistent manager state
	- state restoration via `state_loaded`
	- query helpers for screens and components

- `scripts/base_subsystem.gd`
	- subsystem lifecycle contract for reset/save/load

- `scripts/ui/screen_manager.gd`
	- the only supported screen navigation contract


## Mini Templates

### New Feature Slice Checklist

For a new feature, default to this checklist:

1. Define or extend typed case data.
2. Add or extend one manager that owns runtime truth.
3. Add one screen script that reads manager state and routes commands.
4. Add focused child components for repeated UI parts.
5. Add tests at the manager level and UI level.
6. Add scenario coverage if the feature changes cross-screen flow.


### Screen Template

```gdscript
extends Control

@onready var list_root: VBoxContainer = %ListRoot

var _selected_id: String = ""
var _refresh_queued: bool = false

func _ready() -> void:
	var nav_data: Dictionary = ScreenManager.navigation_data
	_connect_runtime_signals()
	_build_ui(nav_data)


func _exit_tree() -> void:
	_disconnect_runtime_signals()


func _on_primary_action_pressed(item_id: String) -> void:
	FeatureManager.perform_action(item_id)
	_refresh_ui()


func _refresh_ui() -> void:
	_rebuild_from_manager_state()
```

Use this when the screen owns the interaction loop and rebuilds safely from manager state.


### Manager Template

```gdscript
extends BaseSubsystem

signal item_changed(item_id: String)
signal state_loaded

var _state: Dictionary = {}

func reset() -> void:
	_state.clear()


func perform_action(item_id: String) -> Dictionary:
	if not _state.has(item_id):
		return {"success": false, "error_message": "Unknown item."}
	_state[item_id] = true
	item_changed.emit(item_id)
	return {"success": true}


func is_complete(item_id: String) -> bool:
	return _state.get(item_id, false)


func serialize() -> Dictionary:
	return {"state": _state.duplicate(true)}


func deserialize(data: Dictionary) -> void:
	_state = data.get("state", {})
	state_loaded.emit()
```

Use this when the feature owns saveable runtime state.


### Child Component Template

```gdscript
class_name FeatureCard
extends Control

signal card_pressed(item_id: String)

var _item_id: String = ""

func setup(data: Resource) -> void:
	if data == null:
		_apply_invalid_state()
		return
	_item_id = str(data.get("id", "")).strip_edges()
	if _item_id.is_empty():
		_apply_invalid_state()
		return
	_render(data)
```

Use this when a repeated UI unit needs a narrow setup contract and an upward intent signal.


## Decision Rule

When implementing a new feature, prefer the smallest design that still matches this architecture.

If a new feature looks unusual, first try to map it onto one of the existing reference shapes before introducing a new pattern.
