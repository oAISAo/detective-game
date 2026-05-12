# Common Patterns

## Purpose

This file captures the implementation patterns that are already working well in the project.

Use this file after reading `architecture.md`.

- `architecture.md` defines ownership and system rules.
- `common_patterns.md` shows the default patterns to reuse inside those rules.

These patterns are based on the strongest reference slice:

- `location_map`
- `location_investigation`
- `evidence_archive`
- their child components
- the shared manager/navigation/save-load stack


## How To Use This File

When implementing a feature:

1. Pick the closest matching pattern here.
2. Reuse its structure before inventing a new one.
3. Only combine patterns when the feature clearly needs both.
4. If no pattern fits, extend the simplest one instead of building a new architecture style.

When authoring or reviewing evidence data semantics, also read `evidence_authoring.md` before deciding how to use `weight`, `importance_level`, or `critical_evidence_ids`.


## Pattern Selection

Use this quick guide first:

- Need a screen that renders manager state and routes actions: use `Thin Screen Controller`.
- Need a repeated UI item in a list or grid: use `Reusable Card Component`.
- Need one parent to own several tightly coupled UI sections: use `Coordinator Component With Owned Sub-Sections`.
- Need to update the current screen after the player just pressed something: use `Local Refresh After Direct Command`.
- Need to update one card or badge after a narrow state change: use `Targeted Refresh With Node Cache`.
- Need a live screen to react to many external runtime changes: use `Deferred Coalesced Refresh`.
- Need to move to another screen with context: use `Navigation With Minimal Payload`.
- Need a manager command to fail safely with a player-facing reason: use `Structured Command Result`.
- Need persistent feature state: use `Saveable Manager With state_loaded`.


## Thin Screen Controller

### Use When

- a screen renders data from one or more managers
- the screen owns selection, filters, or local display state
- the screen should be disposable and rebuildable at any time

### Rules

- validate `ScreenManager.navigation_data` in `_ready()`
- fetch immutable content from `CaseManager`
- fetch runtime and derived state from managers
- keep only display-only local state in the screen
- route mutations through manager commands
- rebuild from manager state after change

### Do Not Use When

- the screen is about to own persistent runtime truth
- gameplay rules would end up duplicated in the UI

### Canonical References

- `location_map`
- `location_investigation`
- `evidence_archive`

### Skeleton

```gdscript
extends Control

@onready var list_root: VBoxContainer = %ListRoot

var _selected_id: String = ""

func _ready() -> void:
	var nav_data: Dictionary = ScreenManager.navigation_data
	_validate_navigation(nav_data)
	_build_ui()


func _on_primary_action_pressed(item_id: String) -> void:
	FeatureManager.perform_action(item_id)
	_refresh_ui()


func _refresh_ui() -> void:
	_rebuild_from_manager_state()
```


## Reusable Card Component

### Use When

- the same UI unit appears many times in a list or grid
- the parent screen should not know the card's rendering details
- the component only needs a narrow input contract and one or two output signals

### Rules

- expose a small `setup(...)` API
- validate input and fall back safely if invalid
- emit typed user-intent signals upward
- keep hover, selected, and visual state local
- do not navigate directly or own gameplay truth

### Canonical References

- `LocationCard`
- `EvidencePolaroid`

### Skeleton

```gdscript
class_name FeatureCard
extends Control

signal card_pressed(item_id: String)

var _item_id: String = ""

func setup(data: Resource) -> void:
	if data == null:
		_apply_invalid_state("null data")
		return

	_item_id = str(data.get("id", "")).strip_edges()
	if _item_id.is_empty():
		_apply_invalid_state("missing id")
		return

	_render(data)
```


## Coordinator Component With Owned Sub-Sections

### Use When

- one UI area needs several tightly related sub-sections
- the parent screen should talk to one coordinator instead of many siblings
- the sub-sections are not broadly reusable on their own scene files

### Rules

- the coordinator owns composition and signal wiring
- sub-sections stay focused and do not reference each other directly
- setup happens once from the parent after required resources are available
- the coordinator exposes a small public API like `setup(...)`, `show_item(...)`, `clear()`

### Canonical Reference

- `EvidenceDetailPanel`

### Skeleton

```gdscript
class_name FeatureDetailPanel
extends VBoxContainer

signal item_requested(item_id: String)

var _sub_section_a: VBoxContainer = null
var _sub_section_b: VBoxContainer = null

func setup(shared_resource: Resource) -> void:
	_sub_section_a = SubSectionA.new()
	add_child(_sub_section_a)

	_sub_section_b = SubSectionB.new()
	add_child(_sub_section_b)

	clear()


func show_item(item_id: String) -> void:
	# Fetch data, populate owned sections, update local buttons
	pass
```


## Local Refresh After Direct Command

### Use When

- the current screen initiated the state change
- the affected UI is mostly local to the same screen
- rebuilding the current screen is cheap and clear

### Rules

- call the manager command
- immediately rebuild from manager state
- do not wait for your own signal just to refresh the same screen

### Canonical Reference

- `location_investigation` after inspect actions

### Pattern

```gdscript
func _on_action_pressed(item_id: String) -> void:
	FeatureManager.perform_action(item_id)
	_refresh_ui()
```


## Targeted Refresh With Node Cache

### Use When

- one runtime event affects a small known subset of the UI
- rebuilding the whole list would be noisy or unnecessary
- the screen already has stable IDs for visible items

### Rules

- keep a dictionary from runtime ID to node
- update only the affected card, badge, or section
- rebuild the full list only when identity or ordering changed

### Canonical Reference

- `evidence_archive` card badge refreshes

### Pattern

```gdscript
var _card_nodes: Dictionary = {}

func _refresh_card_badges(item_id: String) -> void:
	var card: FeatureCard = _card_nodes.get(item_id) as FeatureCard
	if card != null and is_instance_valid(card):
		card.refresh_badges()
```


## Deferred Coalesced Refresh

### Use When

- a screen remains open while many external runtime changes can occur
- several signals may fire in the same frame
- only one rebuild is needed after those changes settle

### Rules

- connect all relevant runtime signals to one handler
- gate with a `_refresh_queued` flag
- schedule one deferred refresh
- clear the flag inside the refresh method
- verify the screen is still inside the tree before rebuilding

### Canonical Reference

- `location_map`

### Pattern

```gdscript
var _refresh_queued: bool = false

func _on_runtime_state_changed(_arg1: Variant = null, _arg2: Variant = null) -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_refresh_ui")


func _refresh_ui() -> void:
	_refresh_queued = false
	if not is_inside_tree():
		return
	_rebuild_from_manager_state()
```


## Structured Command Result

### Use When

- a manager command can fail for multiple expected reasons
- the screen needs a player-facing message or a clear branch decision
- returning only `bool` would hide useful context

### Rules

- return a dictionary with at least `success`
- include a stable error code for logic branches
- include a user-facing fallback message when the UI must notify the player
- keep the command side-effect free on failure

### Canonical Reference

- `LocationInvestigationManager.start_investigation(...)`

### Pattern

```gdscript
func perform_action(item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {
			"success": false,
			"error_code": "missing_id",
			"error_message": "That item is unavailable right now.",
		}

	return {
		"success": true,
		"error_code": "",
		"error_message": "",
	}
```


## Navigation With Minimal Payload

### Use When

- the next screen needs a small amount of context to select or open the right record
- the rest of the state already lives in managers

### Rules

- call `ScreenManager.navigate_to(...)`
- pass only the minimum identifying payload, usually IDs
- validate payload on the destination screen
- never pass large mutable state blobs through navigation

### Canonical References

- map -> location investigation with `location_id`
- investigation -> evidence archive with `evidence_id`

### Pattern

```gdscript
ScreenManager.navigate_to("feature_detail", {
	"item_id": item_id,
})
```


## Saveable Manager With `state_loaded`

### Use When

- a feature owns player progress or runtime state that must survive save/load
- open screens need a stable signal to clear or rebuild after load

### Rules

- extend `BaseSubsystem`
- implement `reset()`, `serialize()`, and `deserialize()`
- restore only runtime state, not UI node state
- emit `state_loaded` at the end of `deserialize()`

### Canonical References

- `EvidenceManager`
- `LocationInvestigationManager`

### Pattern

```gdscript
extends BaseSubsystem

signal state_loaded

var _state: Dictionary = {}

func reset() -> void:
	_state.clear()


func serialize() -> Dictionary:
	return {"state": _state.duplicate(true)}


func deserialize(data: Dictionary) -> void:
	_state = data.get("state", {})
	state_loaded.emit()
```


## Safe Signal Lifecycle

### Use When

- a screen or component connects to manager or child signals during its lifetime
- the same signal must be disconnected later

### Rules

- connect in `_ready()`
- disconnect in `_exit_tree()`
- store `Callable` values when using inline functions
- avoid duplicate connections
- prefer `UIHelper.safe_disconnect(...)` where the codebase already uses it

### Canonical References

- `location_map`
- `evidence_archive`
- `evidence_detail_panel`

### Pattern

```gdscript
var _on_item_changed_cb: Callable

func _ready() -> void:
	_on_item_changed_cb = func(_item_id: String) -> void:
		_refresh_ui()
	FeatureManager.item_changed.connect(_on_item_changed_cb)


func _exit_tree() -> void:
	UIHelper.safe_disconnect(FeatureManager.item_changed, _on_item_changed_cb)
```


## Empty State And Invalid Data Fallback

### Use When

- the screen can legitimately have zero items
- setup data may be missing, invalid, or partially unavailable
- the UI should fail safely instead of breaking interaction flow

### Rules

- render an explicit empty-state message
- log invalid input with `push_error` or `push_warning`
- show placeholder text, imagery, or section state instead of crashing or leaving broken controls visible

### Canonical References

- `location_map` empty-state message
- `location_investigation` error and placeholder states
- `LocationCard` invalid setup fallback


## Dynamic Child Replacement

### Use When

- a screen builds a section only when data exists
- a detail panel swaps between placeholder state and populated state
- one section must be torn down and rebuilt cleanly

### Rules

- remove old dynamic children before adding replacements
- keep helper methods for section teardown
- keep placeholder and content states mutually exclusive

### Canonical References

- `location_investigation` clues section replacement
- `EvidenceDetailPanel.clear()`


## Search And Filter In The Screen

### Use When

- filtering or search is local to the current visible list
- source data still belongs to a manager

### Rules

- fetch the current discovered/available items from the manager
- apply current search and filter UI state in the screen
- keep sorting logic close to the screen when it is purely presentation-driven
- move filtering rules into the manager only if they become shared gameplay logic

### Canonical Reference

- `evidence_archive`


## Pattern Boundaries

These patterns are approved defaults, not interchangeable shortcuts.

- Do not turn a `Thin Screen Controller` into a hidden manager.
- Do not let a `Reusable Card Component` start coordinating siblings.
- Do not use `Deferred Coalesced Refresh` when a local or targeted refresh is simpler.
- Do not pass manager state through navigation when an ID is enough.
- Do not move saveable state into UI nodes just because one screen currently owns the interaction.


## Default Starting Point For New Work

For most new features in this project, start with this combination:

1. `Thin Screen Controller`
2. `Reusable Card Component` or one focused child section
3. `Structured Command Result` for manager mutations that can fail
4. `Local Refresh After Direct Command` first
5. upgrade to `Targeted Refresh` or `Deferred Coalesced Refresh` only if runtime behavior requires it
6. `Saveable Manager With state_loaded` if the feature owns persistent runtime state

If a new feature cannot be described as a combination of these patterns, stop and compare it against the reference slice before designing something new.
