# GDScript Style

## Purpose

This file defines the low-level GDScript style to use in this project.

It complements `coding_conventions.md`.

Use this file for questions like:

- how to format expressions
- when to use `:=` versus `: Type = ...`
- how to write arrays, dictionaries, strings, and `match`
- how to cast, look up nodes, and type locals
- how to structure small functions and guards at the line level

Do not use this file for higher-level architecture, signal ownership, or UI composition rules.


## Baseline

Start from the Godot GDScript style guide, then follow the repo's stricter defaults:

- prefer explicitness over shorthand
- prefer typed code over dynamic code
- prefer readable step-by-step expressions over compressed clever syntax
- prefer stable formatting patterns that match existing scripts


## Core Rule

When two forms are both valid GDScript, choose the one that is easier to scan in a large gameplay codebase.

That usually means:

- explicit type annotations for meaningful values
- guard clauses instead of nesting
- multiline literals for structured payloads
- `%` string formatting instead of concatenation
- `match` for enum mapping


## Whitespace And Line Structure

- Use tabs for indentation in `.gd` files.
- Put one space after commas and around binary operators.
- Do not vertically align assignments or dictionary colons by hand.
- Use blank lines to separate logical phases inside a function.
- Break long calls and literals across lines before they become dense.

Preferred:

```gdscript
var error_msg: String = "Failed to open save file: %s (Error: %s)" % [
	tmp_path, error_string(FileAccess.get_open_error())
]
```

Avoid:

```gdscript
var error_msg:String="Failed to open save file: %s (Error: %s)"%[tmp_path,error_string(FileAccess.get_open_error())]
```


## Declaration Syntax

Use the normal Godot declaration order already present across the repo:

1. `class_name`
2. `extends`
3. `const`
4. `signal`
5. `@export` / `@onready` / fields
6. functions

Examples:

```gdscript
class_name LocationData
extends Resource

const SAVE_DIR: String = "user://saves/"

signal game_saved(slot: int)

@export var id: String = ""
@onready var location_grid: HFlowContainer = %LocationGrid

var _refresh_queued: bool = false
```


## Type Annotation Style

This repo prefers typed GDScript almost everywhere.

### Use `: Type = ...` For Important Values

Prefer explicit annotations when the type matters to the reader or crosses a boundary.

Use this form for:

- exported fields
- `@onready` node references
- manager API results
- dictionary payloads
- loaded resources
- values returned from engine APIs that would otherwise be `Variant`

Preferred:

```gdscript
var result: Dictionary = LocationInvestigationManager.start_investigation(location_id)
var file: FileAccess = FileAccess.open(path, FileAccess.READ)
var loc: LocationData = CaseManager.get_location(location_id)
```

### Use `:=` Only When The Type Is Obvious

`:=` is acceptable for short local values where the constructor or expression already makes the type obvious.

Common good cases in this repo:

```gdscript
var json := JSON.new()
var label := Label.new()
var stamp := Label.new()
```

Do not use `:=` when the inferred type would be unclear or when the variable is part of a public-facing contract.


## Annotations

Use annotations directly above the declaration they modify.

Preferred forms already used in the repo:

```gdscript
@export var name: String = ""
@export_range(0.0, 1.0, 0.01) var hover_intensity: float = 0.0:
	set(value):
		hover_intensity = value

@onready var location_grid: HFlowContainer = %LocationGrid
```

Rules:

- use `@export` for inspector-owned data
- use `@export_range` and related annotations when the editor constraint is meaningful
- use `@onready` only for scene-tree lookups that must wait until ready
- keep property setters short and local


## Constants And Literal Types

Declare constants with explicit types when they represent paths, IDs, sizes, or other stable contracts.

Preferred:

```gdscript
const SAVE_EXTENSION: String = ".json"
const _BACK_CONTENT_MIN_WIDTH: float = 100.0
const _LIST_BUTTON_PARENT_SEPARATION_META: StringName = &"_list_button_parent_separation_pending"
```

### Use `StringName` Literals For Static Engine Identifiers

Use `&"..."` when the value is a static `StringName`, especially for:

- theme type variations
- metadata keys
- bus names
- other engine identifier strings that are reused as identifiers, not free-form text

Examples already present in the repo:

```gdscript
button.theme_type_variation = &"ListButton"
_sfx_player.bus = &"Master"
const _LIST_BUTTON_PARENT_SEPARATION_META: StringName = &"_list_button_parent_separation_pending"
```


## Arrays And Dictionaries

### Typed Arrays

Prefer typed arrays whenever the element type is known.

Preferred:

```gdscript
var locations: Array[LocationData] = CaseManager.get_all_locations()
var errors: Array[String] = []
var obj_dicts: Array[Dictionary] = []
```

### Typed Empty Literals Inside Expressions

When a typed empty array is needed inside a dictionary or return expression, use a cast.

Preferred:

```gdscript
return [] as Array[String]

return {
	"attached_evidence": [] as Array[String],
}
```

### Converting Variant Arrays

When data comes from JSON, save payloads, or `Dictionary.get(...)`, convert it explicitly.

Preferred:

```gdscript
var result_events: Array[String] = []
result_events.assign(surv_info.get("result_events", []))
```

Use `.assign(...)` when moving untyped payloads into typed arrays.

### Dictionary Access

Use `dict.get("key", default)` when:

- the data is optional
- the dictionary came from JSON or save data
- the key may legitimately be missing

Use `dict["key"]` only when the contract is guaranteed and absence would be a bug.

Preferred:

```gdscript
var file_version: int = save_data.get("save_version", 0)
var game_state: Dictionary = data.get("game_state", {})
```


## String Style

### Prefer `%` Formatting Over Concatenation

Use `%` formatting for logs, notifications, file paths, and player-facing text with inserted values.

Preferred:

```gdscript
push_warning("[SaveManager] Save version mismatch: file=%d, current=%d" % [
	file_version, SAVE_VERSION
])

var key: String = "%s:%d" % [person_id, entry["time_minutes"]]
```

Avoid dense concatenation like:

```gdscript
var text: String = "Day " + str(day) + " begins."
```

### Use `str(...)` For Safe Fallback Conversion

When a dictionary value may be non-string or optional, wrap it with `str(...)` rather than assuming the type.

Preferred:

```gdscript
var error_message: String = str(result.get("error_message", "Unable to visit this location right now."))
```


## Conditions And Boolean Expressions

### Prefer Guard Clauses

Handle invalid state and empty cases early.

Preferred:

```gdscript
if not _is_valid_slot(slot):
	return false

if locations.is_empty():
	_add_empty_state_message("No locations available.")
	return
```

### Prefer GDScript Boolean Keywords

Use:

- `and`
- `or`
- `not`

Do not write C-style boolean operators.

### Prefer Intent-Revealing Predicates

Use engine helpers and predicate methods when available:

- `is_empty()` for strings and arrays
- `is_inside_tree()` for tree presence
- `is_instance_valid(...)` for potentially freed nodes
- `has_method(...)` when calling into optional systems

### Use Ternaries Sparingly

Inline conditional expressions are fine for short, obvious value selection.

Preferred:

```gdscript
var ev_name: String = output_ev.name if output_ev else output_id
```

Avoid nested or long ternaries. Split them into normal `if` blocks when the expression stops being immediate.


## `if`, `match`, And Branching Style

### Use `if` For Simple Control Flow

Use `if` / `elif` / `else` when there are only a few branches or when each branch performs real work.

### Use `match` For Enum Or Token Mapping

Use `match` when mapping enums or small token sets to labels, colors, or behavior categories.

Preferred:

```gdscript
match type:
	Enums.EvidenceType.FORENSIC: return "Forensic"
	Enums.EvidenceType.DOCUMENT: return "Document"
	Enums.EvidenceType.PHOTO: return "Photo"
return "Unknown"
```

Rules:

- one-line `match` branches are fine for trivial returns or assignments
- use multiline branch bodies when the branch does real work
- always provide a safe fallback when unknown input is possible


## Loop Style

Prefer explicit loops over compressed collection tricks.

Preferred:

```gdscript
var unlocked: Array[LocationData] = []
for loc: LocationData in locations:
	if GameManager.is_location_unlocked(loc.id):
		unlocked.append(loc)
```

When iterating Variant-heavy data, type the loop variable if the element contract is known.

Preferred:

```gdscript
for obj_dict: Dictionary in data.get("investigable_objects", []):
	res.investigable_objects.append(InvestigableObjectData.from_dict(obj_dict))
```


## Function Call Formatting

Keep short calls on one line.

Break calls across lines when:

- the argument list becomes hard to scan
- one argument is a structured dictionary
- the formatted string or array literal is already multiline

Preferred:

```gdscript
ScreenManager.navigate_to("location_investigation", {
	"location_id": location_id,
})
```

Use trailing commas in multiline dictionaries and arrays.


## Node Lookup And Instantiation

### Local Scene Nodes

Prefer `%NodeName` with an explicitly typed `@onready` variable for owned scene nodes.

Preferred:

```gdscript
@onready var location_grid: HFlowContainer = %LocationGrid
```

### Optional Or Dynamic Nodes

Use `get_node_or_null(...)` when a node may not exist.

Preferred:

```gdscript
var old_content: Node = button.get_node_or_null(_BACK_CONTENT_NODE_NAME)
```

### Autoload Lookups

For optional global systems, use `get_node_or_null("/root/...")` plus `has_method(...)` when needed.

Preferred:

```gdscript
var event_sys: Node = get_node_or_null("/root/EventSystem")
if event_sys and event_sys.has_method("evaluate_day_start_triggers"):
	event_sys.call("evaluate_day_start_triggers")
```

### Scene Instantiation

Type instantiated scenes when the expected script type is known.

Preferred:

```gdscript
var card: LocationCard = LocationCardScene.instantiate()
```


## Casting Style

Use `as Type` when converting engine-returned `Variant` values into a known type.

Common repo patterns:

```gdscript
var parent_box: BoxContainer = button.get_parent() as BoxContainer
var stream: AudioStream = load(path) as AudioStream
var game_state: Dictionary = json.data
```

Rules:

- cast after `load(...)` when the resource type matters
- cast node parents or lookups when the API depends on the concrete type
- cast enum values from saved dictionaries when restoring typed state
- do not scatter unnecessary casts when the type is already declared and obvious


## Property Setters

Use inline setters for editor-backed or UI-backed properties that must immediately update local state.

Preferred shape:

```gdscript
@export var disabled: bool = false:
	set(value):
		disabled = value
		_update_visual_state()
```

Rules:

- keep setter bodies short
- keep side effects local to the owning node or control
- do not hide major gameplay mutations in property setters


## Static Functions

Use `static func` for stateless helpers that do not depend on node instance state.

Good fit:

- formatting helpers
- label mapping helpers
- safe utility wrappers

Example shape already used in the repo:

```gdscript
static func safe_disconnect(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)
```


## Comments At The Syntax Level

`coding_conventions.md` covers comment policy. At the line level, follow these syntax rules:

- use `##` for declaration-level documentation comments
- use `#` for normal inline comments
- put one space after the comment marker
- keep inline comments short and attached to the specific line or block they explain

Preferred:

```gdscript
## Returns metadata about a save slot.
func get_save_info(slot: int) -> Dictionary:
	# Version check
	var file_version: int = save_data.get("save_version", 0)
```


## Small Expression Preferences

Prefer these forms because they already match the repo:

- `if not condition:` over `if condition == false:`
- `if value == null:` when null is the specific failure being checked
- `if node:` when simple truthiness is enough for a resource or node reference
- `value.method()` over manual string or array state checks when the API exists
- `append_array(...)` and `assign(...)` over manual copying loops when the intent is direct transfer


## Avoid

Avoid these syntax habits in new code:

- leaving important locals as untyped `Variant`
- using `:=` for values whose type is not obvious
- concatenating strings for formatted logs or UI text
- nested ternary expressions
- large inline dictionaries stuffed onto one line
- broad chains of `dict.get(...).get(...).get(...)` when intermediate values deserve names
- unnecessary casts on already-typed locals
- C-style habits imported from other languages


## Copyable Patterns

### Typed Guard + Structured Return

```gdscript
func load_game(slot: int) -> bool:
	if not _is_valid_slot(slot):
		save_error.emit("Invalid save slot: %d" % slot)
		return false

	var path: String = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		save_error.emit("No save file found in slot %d." % slot)
		return false

	return true
```

### Typed Array From Payload

```gdscript
var event_ids: Array[String] = []
event_ids.assign(surv_info.get("result_events", []))
```

### Short `match` Mapper

```gdscript
static func get_legal_category_label(cat: int) -> String:
	match cat:
		Enums.LegalCategory.PRESENCE: return "Presence"
		Enums.LegalCategory.MOTIVE: return "Motive"
		Enums.LegalCategory.OPPORTUNITY: return "Opportunity"
		Enums.LegalCategory.CONNECTION: return "Connection"
	return "Unknown"
```

### Typed Node Lookup

```gdscript
@onready var location_grid: HFlowContainer = %LocationGrid

func _refresh_map() -> void:
	if not is_inside_tree():
		return
	_populate_locations()
```


## Decision Rule

When unsure between two valid GDScript forms:

1. prefer the form already common in nearby project code
2. prefer the more explicit typed form
3. prefer the version that makes failure paths and data shape obvious

Consistency matters more than stylistic novelty.
