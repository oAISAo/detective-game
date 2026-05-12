# Signal Patterns

## Purpose

This file defines the approved signal patterns for this project.

Use it to decide:

- when to use a signal instead of a direct call
- who should emit signals
- who should subscribe to them
- how signal callbacks should refresh UI
- how to avoid duplicate connections, ghost listeners, and circular flows

This guide is grounded in the strongest reference slice:

- `location_map`
- `location_investigation`
- `evidence_archive`
- `EvidenceDetailPanel`
- `LocationInvestigationManager`
- `EvidenceManager`


## Relationship To Other AI Docs

- `architecture.md` defines layer ownership and boundaries.
- `common_patterns.md` defines reusable implementation shapes.
- `signal_patterns.md` defines the signal contracts inside those shapes.

If these files overlap, follow this rule:

- `architecture.md` for who owns behavior
- `common_patterns.md` for which shape to reuse
- `signal_patterns.md` for how events move between those owners


## Core Model

This project uses Signal Up, Call Down.

Default rule:

- children emit signals upward
- parents call child methods downward
- managers emit state-change signals outward
- screens translate manager signals into UI refresh, selection update, or navigation

Signals are for events that already happened or user intent that must be handed upward.

Direct method calls are for commands.

Use direct calls for:

- screen -> manager command
- parent -> child update
- screen -> detail panel `show_*` or `clear()` style APIs

Use signals for:

- child component -> parent user intent
- manager -> screen state updates
- manager -> manager notifications when systems need to react across boundaries
- lifecycle notifications like `state_loaded`, `screen_changed`, `modal_opened`


## Signal Roles By Layer

### Child Component Signals

Child components should emit narrow user-intent signals upward.

Canonical examples:

- `card_pressed(location_id: String)`
- `evidence_requested(evidence_id: String)`
- `pin_toggled(evidence_id: String)`

These signals mean:

- the component does not decide navigation
- the component does not mutate global runtime state directly
- the parent decides what action to take next

### Manager Signals

Managers emit runtime state changes outward after the state changed.

Canonical examples:

- `object_state_changed(location_id, object_id, new_state)`
- `evidence_found(evidence_id, object_id, method)`
- `investigation_started(location_id, is_first_visit)`
- `location_completed(location_id)`
- `evidence_pinned(evidence_id)`
- `evidence_unpinned(evidence_id)`
- `evidence_reviewed(evidence_id)`
- `statement_verdict_changed(evidence_id, statement_id, verdict)`
- `state_loaded`

These signals mean:

- the manager remains the source of truth
- listeners react to completed state changes
- screens and components rebuild from manager state instead of trusting cached UI state

### Screen Callbacks

Screens should subscribe to signals and translate them into one of three outcomes:

- local rebuild
- targeted refresh
- navigation or selection update

Screens should not turn signal callbacks into a second rules engine.


## Naming Rules

### Manager Signal Names

Manager and system signals should be descriptive and usually past-tense.

Preferred styles:

- `object_state_changed`
- `evidence_found`
- `location_completed`
- `statement_verdict_changed`
- `player_notes_changed`

Allowed lifecycle names:

- `state_loaded`
- `screen_changed`
- `modal_opened`
- `modal_closed`

Avoid vague custom names such as:

- `changed`
- `done`
- `updated`
- `pressed`

### Child Component Signal Names

Child component signals should encode the user intent or UI event, not expose a raw built-in name.

Preferred styles:

- `card_pressed`
- `evidence_requested`
- `pin_toggled`
- `output_evidence_requested`

Avoid wrapping built-in button signals with equally vague custom names.


## Payload Rules

Prefer typed payloads whenever the contract is known.

Do:

- pass stable IDs and compact derived context
- pass enums where the receiving side needs the resolved state directly
- pass only the minimum information needed by listeners

Do not:

- emit giant dictionaries when a few typed fields would do
- pass full node references across unrelated layers unless the emitter/listener are tightly local
- force listeners to re-derive obvious context that the manager already knows

Good examples:

- `signal object_state_changed(location_id: String, object_id: String, new_state: Enums.InvestigationState)`
- `signal evidence_reviewed(evidence_id: String)`
- `signal evidence_requested(evidence_id: String)`


## Connection Ownership

The node that benefits from the signal should own the connection.

Default ownership rules:

- parent screens connect child component signals
- screens connect manager signals they need while visible
- coordinator components connect owned sub-sections
- managers connect other managers only when the cross-system dependency is real and justified

Do not make children responsible for connecting themselves into parent workflows beyond their own owned sub-sections.


## Connection Lifecycle

### Standard Lifecycle

- connect in `_ready()` when the connection lifetime matches the node lifetime
- connect in `setup(...)` when the connection depends on owned sub-components created at runtime
- disconnect in `_exit_tree()` when the connection outlives the emitting node or uses stored callables

### Stored Callable Pattern

Use stored `Callable` values when you create inline callbacks and need to disconnect later.

Canonical references:

- `evidence_archive`
- `EvidenceDetailPanel`

Pattern:

```gdscript
var _on_item_changed_cb: Callable

func _ready() -> void:
	_on_item_changed_cb = func(_item_id: String) -> void:
		_refresh_ui()
	FeatureManager.item_changed.connect(_on_item_changed_cb)


func _exit_tree() -> void:
	UIHelper.safe_disconnect(FeatureManager.item_changed, _on_item_changed_cb)
```

### Duplicate Connection Guard

If the same helper may run multiple times, guard against duplicate connections.

Canonical reference:

- `location_map._bind_refresh_signal(...)`

Pattern:

```gdscript
func _bind_refresh_signal(signal_ref: Signal) -> void:
	if not signal_ref.is_connected(_on_runtime_state_changed):
		signal_ref.connect(_on_runtime_state_changed)
```

### Preferred Connect Style

Prefer `signal.connect(callable)` syntax.

Do not add new string-based `connect("signal_name", ...)` calls unless there is no reasonable alternative.


## Refresh Routing Patterns

Signals should drive the smallest correct refresh.

### Pattern 1: Local Direct Command, Then Refresh

Use when the current screen initiated the mutation itself.

Pattern:

- screen calls manager command
- screen refreshes locally
- no signal subscription is required just to update the same screen

Canonical reference:

- `location_investigation` after inspect actions

### Pattern 2: Targeted Refresh On Narrow Event

Use when a manager signal affects one known visual target.

Pattern:

- screen subscribes to the manager signal
- callback updates one cached card or section
- full rebuild is avoided

Canonical reference:

- `evidence_archive` reacting to `evidence_reviewed` and lab submission state

Do not use this pattern when the signal changes list membership or ordering. In that case, rebuild the visible collection instead of trying to patch one card in place.

### Pattern 3: Deferred Coalesced Refresh

Use when many external signals can affect a live screen at once.

Pattern:

- connect multiple manager signals to one refresh callback
- accept unused arguments in a shared callback when necessary
- queue one deferred rebuild using a guard flag

Canonical reference:

- `location_map`

Pattern:

```gdscript
var _refresh_queued: bool = false

func _on_runtime_state_changed(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_refresh_ui")
```


## Parent-Mediated Signal Chains

When one child component needs to cause a screen-level action, route the event through the parent.

Use this chain:

- child emits intent
- parent receives it
- parent decides whether to refresh, mutate manager state, or navigate

Canonical references:

- `LocationCard.card_pressed` -> `LocationMap._on_location_pressed`
- `EvidenceDetailPanel.evidence_requested` -> `EvidenceArchive._on_evidence_requested`
- `EvidenceDetailPanel.pin_toggled` -> `EvidenceArchive._on_detail_pin_toggled`
- `EvidenceLabSection.output_evidence_requested` -> `EvidenceDetailPanel._on_output_evidence_requested` -> `evidence_requested.emit(...)`

Do not let sibling components connect to each other directly for screen-level flows.


## Bound Context For Dynamic Controls

Dynamic buttons often need to carry stable context into a callback.

Preferred pattern:

- use `Callable.bind(...)` on typed signal connections
- keep the callback signature simple and explicit

Canonical reference:

- dynamically created object buttons in `location_investigation`

Pattern:

```gdscript
var btn: Button = Button.new()
btn.pressed.connect(_on_object_selected.bind(object_id))
```

Use this when the UI creates repeated controls at runtime and each control needs its own ID.


## Manager Emission Rules

Managers should emit after a real state transition, not before.

Rules:

- mutate state first when the emitted payload describes the new state
- emit only if the state actually changed
- keep commands idempotent when repeated calls should do nothing
- emit first-time-only signals only once

Canonical references:

- `object_state_changed` only after the new investigation state is resolved
- `evidence_reviewed` only on the first review
- `evidence_sent_to_board` only on the first send

Do not emit a signal every time a method is called if nothing meaningful changed.


## Lifecycle Signals For Save/Load

Persistent managers should emit `state_loaded` after deserialization finishes.

Use `state_loaded` when:

- open screens must rebuild from restored manager state
- coordinator components must clear stale local selections or details
- archive lists, card grids, or detail panels must repopulate after load

Canonical references:

- `LocationInvestigationManager.state_loaded`
- `EvidenceManager.state_loaded`
- screens and components in the evidence slice reacting by refreshing or clearing

Default listener behavior on `state_loaded`:

- rebuild a visible list
- clear stale detail UI
- repopulate dynamic children


## Manager-To-Manager Signals

Use manager-to-manager connections when one subsystem genuinely needs to react to another subsystem's state changes.

Rules:

- keep the dependency explicit
- connect lazily or deferred if autoload order is uncertain
- do not create circular manager signal loops

Canonical reference:

- `EvidenceManager` defers its connection to `GameManager.evidence_discovered`

Do not introduce a global signal bus for local feature flows that already have a natural owner.


## When Not To Use Signals

Use direct calls instead of signals when:

- a parent is commanding a child
- a screen is issuing a manager command
- a component is updating its own private visual state
- the interaction is simple and purely local

Avoid signals for:

- top-down commands
- hidden control flow that makes behavior hard to trace
- high-frequency transient data that does not need event semantics
- local screen wiring that can be solved with a normal method call


## Anti-Patterns

Do not add these patterns in new code:

- string-based custom signal names that hide intent
- duplicate connections to the same `Callable`
- screens reacting to their own direct command through a signal when a local refresh is clearer
- child components navigating directly to screens
- sibling components connecting to each other for parent-owned behavior
- global event buses for local UI behavior
- manager signals emitted before the source of truth is updated
- callback forests where every signal creates more signals with no clear owner


## Testing Signal Behavior

Signal behavior is part of the contract and should be tested when it matters.

Preferred GUT pattern:

```gdscript
watch_signals(FeatureManager)
FeatureManager.perform_action("some_id")
assert_signal_emitted(FeatureManager, "item_changed")
```

Use this to test:

- a signal is emitted when a real state change happens
- a signal is not emitted when an operation is idempotent or rejected
- payload-sensitive signals emit the expected parameters when the test needs that precision

Canonical references:

- `test_location_investigation_ui.gd` for `evidence_found` and `object_state_changed`
- integration tests across the repo using `watch_signals(...)`, `assert_signal_emitted(...)`, and `assert_signal_emitted_with_parameters(...)`


## Mini Templates

### Child Intent Signal

```gdscript
class_name FeatureCard
extends Control

signal card_pressed(item_id: String)

var _item_id: String = ""

func _ready() -> void:
	gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		card_pressed.emit(_item_id)
```

### Screen Listening To Manager Signals

```gdscript
var _on_item_changed_cb: Callable

func _ready() -> void:
	_on_item_changed_cb = func(_item_id: String) -> void:
		_refresh_ui()
	FeatureManager.item_changed.connect(_on_item_changed_cb)


func _exit_tree() -> void:
	UIHelper.safe_disconnect(FeatureManager.item_changed, _on_item_changed_cb)
```

### Manager State Change Signal

```gdscript
signal item_changed(item_id: String, new_state: int)

func set_item_state(item_id: String, new_state: int) -> void:
	var previous_state: int = _item_states.get(item_id, 0)
	if previous_state == new_state:
		return
	_item_states[item_id] = new_state
	item_changed.emit(item_id, new_state)
```


## Decision Rule

If you are unsure whether to use a signal, ask this in order:

1. Is this a command from parent to child or screen to manager?
   Use a direct call.
2. Is this user intent traveling upward from a child component?
   Use a typed child signal.
3. Is this a runtime state change other parts of the system must observe?
   Use a manager signal.
4. Does the visible screen only need to refresh itself after its own command?
   Skip the signal and refresh locally.

Default to the simplest option that preserves clear ownership.
