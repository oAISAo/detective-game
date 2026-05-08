# Coding Conventions

## Purpose

This file defines the coding conventions that new code should follow by default.

It is based on:

- the polished reference slice
	- `location_map`
	- `location_investigation`
	- `evidence_archive`
- the broader repo style in managers, systems, data resources, helpers, and tests
- the Godot GDScript style guide as a baseline

Use this file to keep new code aligned with the codebase that already exists.


## Scope

This document covers:

- file and class layout
- naming
- typing
- function and control-flow style
- comments and documentation
- error handling and logging
- literals and collection formatting
- test conventions

This document does not cover:

- architecture decisions already defined in `architecture.md`
- reusable feature patterns already defined in `common_patterns.md`
- signal contracts already defined in `signal_patterns.md`
- UI composition rules already defined in `ui_patterns.md`


## Baseline

Start from the Godot GDScript style guide, then apply these project-specific rules where the repo is stricter or more explicit.

Project bias:

- prefer clarity over brevity
- prefer explicit types over inference when the type is meaningful
- prefer descriptive names over short names
- prefer small helper methods over large mixed-responsibility methods
- prefer stable, documented contracts over clever shorthand


## Indentation And Formatting

- Use tabs for indentation in `.gd` files to match the existing codebase.
- Keep one blank line between top-level declarations and function blocks as the repo currently does.
- Use multiline literals for non-trivial dictionaries and arrays.
- Keep trailing commas in multiline dictionaries and arrays when the surrounding code already uses them.
- Prefer line breaks over dense one-line expressions when a statement becomes hard to scan.


## File Naming And Script Identity

- Use `snake_case.gd` for script file names.
- Use `PascalCase` for `class_name` values.
- Use `snake_case` for functions, variables, and signals.
- Use `SCREAMING_SNAKE_CASE` for constants.
- Use leading underscore for private or internal variables and helpers.

Examples already used across the repo:

- file: `location_investigation_manager.gd`
- class: `LocationData`
- function: `get_object_display_status`
- constant: `START_ERROR_UNKNOWN_LOCATION`
- private field: `_object_states`


## Default File Layout

Use this order unless a file has a strong reason to differ:

1. top-of-file `##` summary comments
2. `class_name` if the script is globally named
3. `extends`
4. constants
5. signals
6. exported fields / `@onready` references / state fields
7. lifecycle methods
8. public API
9. internal helpers

For larger scripts, split sections with `# --- Section Name --- #` comments.

Common section names already used in the repo:

- `# --- Constants --- #`
- `# --- Signals --- #`
- `# --- State --- #`
- `# --- Lifecycle --- #`
- `# --- Public API --- #`
- `# --- Internal --- #`

Use section markers when they improve scanability. Do not add them to tiny files that are already obvious.


## Typing Rules

This repo strongly prefers typed GDScript.

Do:

- type exported fields
- type `@onready` node references
- type local variables when the type carries meaning
- type function parameters and return values
- type signal payloads when the contract is known
- use typed arrays such as `Array[String]`, `Array[Dictionary]`, `Array[EvidenceData]`

Prefer explicit typing over inference for:

- manager API results
- loaded resources
- node lookups
- values crossing subsystem boundaries
- any variable whose meaning is clearer with a declared type

Inference is acceptable when the expression is obvious and local, for example:

- `var label := Label.new()`
- `var json := JSON.new()`

Do not leave important variables untyped just to save characters.


## Naming Rules

### Variables

- Use descriptive names that reflect the role of the value.
- Avoid generic names like `data`, `value`, `info`, `helper`, or `manager` unless the surrounding context makes them precise.
- Use singular names for single items and plural names for collections.

Preferred examples:

- `location_id`
- `completion_label`
- `discovered`
- `_selected_card`
- `remaining_actions`

### Booleans

Use names that read like predicates.

Preferred forms:

- `is_first_visit`
- `has_pending_lab_at_location`
- `can_go_back`
- `is_morning_briefing_shown`

### Signals

- Name signals after the event that occurred.
- Manager signals should usually be past-tense or completed-event names.
- Component signals should describe intent clearly.

Examples:

- `object_state_changed`
- `evidence_reviewed`
- `location_completed`
- `card_pressed`


## Constants And Magic Values

- Hoist reused values into named constants.
- Prefer semantic constants over unexplained raw numbers or strings.
- Keep related constants grouped together near the top of the file.

Examples already used in the repo:

- action IDs like `ACTION_VISUAL_INSPECTION`
- error codes like `START_ERROR_UNKNOWN_LOCATION`
- UI tuning values like `_DETAIL_SECTION_SPACING`
- save constants like `SAVE_DIR` and `SAVE_EXTENSION`

Leave one-off values inline only when the value is trivial and obviously local.


## Function Style

### Size And Focus

- Keep functions focused on one job.
- Prefer short helper methods over long mixed-responsibility methods.
- If a function needs multiple comment blocks to explain unrelated phases, it probably wants to be split.

### Return Types

- Always declare return types.
- Use `-> void` explicitly for procedures.
- Return structured dictionaries when callers need more than success/failure.

### Early Returns

Prefer guard clauses and early returns for invalid states and empty cases.

This style is common across screens, managers, and helpers in the repo.

### Query vs Command

- Query methods should read like queries and avoid side effects.
- Command methods should make state changes explicit.

Examples:

- queries: `get_location_completion`, `has_save`, `is_at_location`
- commands: `start_investigation`, `save_game`, `process_morning`


## Control Flow Conventions

- Prefer straightforward branching over dense nested logic.
- Use `match` for enum-to-label or enum-to-color mapping when it improves readability.
- Use small helper methods to isolate special-case logic.
- Prefer explicit loops over compressed logic when the loop body contains game rules or validation.


## Comments And Documentation

### Top-Of-File Comments

Use `##` comments at the top of scripts to explain:

- what the script is
- what responsibility it owns
- any important lifecycle or dependency notes

### Public Function Comments

Document important public methods with `##` comments.

Focus comments on:

- purpose
- important assumptions
- return behavior
- side effects when they matter

### Section Comments

Use `# --- Section Name --- #` for large files with multiple responsibilities.

### Inline Comments

Inline comments should explain why, not narrate obvious syntax.

Good uses already present in the repo:

- reasoning about lab upgrade behavior
- why a deferred refresh is needed
- why a button must remain child-free for hit detection
- why a temp save file is renamed atomically

Do not add low-value comments that restate the next line.


## Error Handling And Logging

- Use `push_error(...)` for invalid states or failed operations that should be visible during development.
- Use `push_warning(...)` for recoverable problems or fallback conditions.
- Return safe fallback values when possible instead of crashing UI flows.
- Pair player-facing failures with a structured result or a notification when the UI needs to explain the failure.

Common style:

- log with a subsystem prefix in brackets, for example `[SaveManager]` or `[LocationInvestigationManager]`
- keep error messages specific enough to debug without re-reading the caller


## Resource And Data Class Conventions

Data resource classes in this repo usually follow this shape:

1. top-of-file summary comment
2. `class_name` + `extends Resource`
3. documented fields
4. `from_dict(...)`
5. `validate()`
6. `to_dict()`

Rules:

- export simple fields that should appear in the Inspector or serialize directly
- type nested arrays explicitly
- keep parsing and serialization explicit
- keep validation readable and additive


## Manager And System Conventions

Managers and systems typically follow these conventions:

- group constants, signals, state, lifecycle, and APIs into sections
- expose typed signals and typed queries
- keep internal dictionaries private with underscore-prefixed names
- return structured dictionaries when commands need rich failure context
- emit signals after meaningful state changes
- defer autoload-to-autoload signal hookups when initialization order may vary

Do not bury major state changes in UI scripts.


## UI Script Conventions

UI scripts in this repo usually follow these conventions:

- preload child scenes into typed `PackedScene` constants
- type `@onready` nodes explicitly
- keep screen-local UI state private with underscore-prefixed fields
- use `UIHelper`, `UIColors`, and `UIFonts` instead of duplicating presentation code
- clear and rebuild dynamic containers explicitly
- validate navigation payloads and missing data early

For UI-specific composition rules, follow `ui_patterns.md`.


## Collections And Literal Formatting

- Prefer multiline dictionaries when the payload has named fields or spans multiple concepts.
- Align multiline dictionary entries one per line.
- Prefer typed arrays where possible.
- Use `.duplicate(true)` only when a deep copy is actually needed.
- Use `.assign(...)` when converting array payloads into typed arrays, as already done in the repo.


## Casting And Instantiation

- Cast instantiated scenes to their expected type when appropriate.
- Cast node lookups when the type matters for later API use.
- Prefer explicit node types on `@onready` declarations.

Common examples:

- `var card: LocationCard = LocationCardScene.instantiate()`
- `var scroll: ScrollContainer = screen.get_node(...)`
- `var value_anchor: VBoxContainer = screen.get_node(...) as VBoxContainer`


## Null And Validity Checks

- Check for `null` when loading resources, finding data, or casting runtime-created nodes.
- Use `is_instance_valid(...)` when holding references to nodes that may have been freed.
- Use `get_node_or_null(...)` for optional scene structure.

Prefer explicit guards over optimistic chaining when a missing value would change control flow.


## Testing Conventions

The test suite follows a stable GUT shape.

### Base Shape

- tests extend `GutTest`
- use `before_each()` for routine state reset
- use `before_all()` and `after_all()` when test files create temporary resources or fixtures
- use `after_each()` or `after_all()` to clean up transient state and files

### Test Naming

- name tests in `snake_case`
- make names behavior-oriented and explicit
- keep names long enough to explain the scenario being verified

Examples already used in the repo:

- `test_location_map_scroll_content_has_shadow_padding`
- `test_completed_lab_state_uses_lab_request_status_text`
- `test_evidence_signals_emitted_during_inspection`

### Assertions

- prefer assertions that explain intended behavior
- include a message when the failure context would otherwise be ambiguous
- test emitted signals when signal behavior is part of the contract


## Preferred Project Idioms

These small habits repeat across the repo and should remain the default:

- `UIHelper.safe_disconnect(...)` for teardown-safe signal cleanup
- `UIHelper.clear_children(...)` for dynamic container rebuilds
- `call_deferred(...)` when same-frame state changes should coalesce or when tree timing matters
- `push_error(...)` plus safe fallback UI/state instead of silent failure
- explicit status helper methods like `get_*`, `has_*`, and `is_*`


## Avoid

Do not add new code that defaults to these patterns:

- untyped public APIs when the contract is known
- vague names like `temp`, `stuff`, `thing`, `manager`, `helper`
- long mixed-responsibility functions with UI, state mutation, and validation intertwined
- raw UI colors and font sizes in screen scripts when shared tokens exist
- string-based signal connection syntax when normal typed signal syntax works
- hidden side effects in methods that look like queries
- silent failure branches that neither log nor return useful context
- tests with generic names that do not explain the scenario


## Decision Rule

When unsure how to write a new script, match the closest existing script in the same layer:

1. data/resource class for parsing and validation
2. manager/system for stateful logic and signals
3. screen or component for UI logic
4. GUT test for setup and assertions

Prefer consistency with the current repo over introducing a personal style variation.
