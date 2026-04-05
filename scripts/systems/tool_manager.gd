## ToolManager.gd
## Manages investigation tools available to the detective.
## Tools are used at locations to reveal hidden evidence on investigable objects.
extends BaseSubsystem


# --- Signals --- #

## Emitted when a tool is used on an object.
signal tool_used(tool_id: String, object_id: String)

## Emitted when a tool is unlocked.
signal tool_unlocked(tool_id: String)


# --- Constants --- #

## Registry of all investigation tools.
const TOOL_REGISTRY: Dictionary = {
	"fingerprint_powder": {
		"name": "Fingerprint Powder",
		"description": "Reveals latent fingerprints on surfaces.",
	},
	"uv_light": {
		"name": "UV Light",
		"description": "Reveals hidden biological traces and treated substances.",
	},
	"chemical_test": {
		"name": "Chemical Residue Test",
		"description": "Detects chemical residues and cleaning agents.",
	},
}


# --- State --- #

## Set of tool IDs the player currently has access to.
var available_tools: Array[String] = []

## Tracks tool usage: { "tool_id:object_id": true }
var _tool_usage_log: Dictionary = {}


# --- Lifecycle --- #

func _ready() -> void:
	super()
	available_tools.assign(TOOL_REGISTRY.keys())


## Resets tool state for a new game.
func reset() -> void:
	available_tools.assign(TOOL_REGISTRY.keys())
	_tool_usage_log.clear()


# --- Tool Queries --- #

## Returns true if the tool exists in the registry.
func is_valid_tool(tool_id: String) -> bool:
	return tool_id in TOOL_REGISTRY


## Returns true if the player has the specified tool available.
func has_tool(tool_id: String) -> bool:
	return tool_id in available_tools


## Returns the display name of a tool.
func get_tool_name(tool_id: String) -> String:
	if tool_id not in TOOL_REGISTRY:
		return ""
	return TOOL_REGISTRY[tool_id]["name"]


## Returns all available tool IDs.
func get_available_tools() -> Array[String]:
	return available_tools.duplicate()


## Returns tools that are compatible with the given object.
## Cross-references object.tool_requirements with available tools.
func get_compatible_tools(object_data: InvestigableObjectData) -> Array[String]:
	var compatible: Array[String] = []
	for req: String in object_data.tool_requirements:
		if req in available_tools:
			compatible.append(req)
	return compatible


# --- Tool Usage --- #

## Checks if a tool can be used on an object.
## Returns empty string if valid, or an error message.
func validate_tool_use(tool_id: String, object_data: InvestigableObjectData) -> String:
	if not is_valid_tool(tool_id):
		return "Unknown tool: %s" % tool_id
	if not has_tool(tool_id):
		return "Tool not available: %s" % tool_id
	if tool_id not in object_data.tool_requirements:
		return "Tool '%s' is not compatible with '%s'" % [get_tool_name(tool_id), object_data.name]
	return ""


## Uses a tool on an object. Returns evidence IDs revealed, or empty if invalid.
func use_tool(tool_id: String, object_data: InvestigableObjectData) -> Array[String]:
	var error: String = validate_tool_use(tool_id, object_data)
	if not error.is_empty():
		push_warning("[ToolManager] %s" % error)
		return []

	var usage_key: String = "%s:%s" % [tool_id, object_data.id]
	if usage_key in _tool_usage_log:
		return []

	_tool_usage_log[usage_key] = true
	tool_used.emit(tool_id, object_data.id)
	return object_data.evidence_results.duplicate()


## Returns true if a tool has already been used on an object.
func has_used_tool(tool_id: String, object_id: String) -> bool:
	return "%s:%s" % [tool_id, object_id] in _tool_usage_log


## Unlocks a new tool for the player.
func unlock_tool(tool_id: String) -> bool:
	if not is_valid_tool(tool_id):
		push_error("[ToolManager] Cannot unlock unknown tool: %s" % tool_id)
		return false
	if tool_id in available_tools:
		return false
	available_tools.append(tool_id)
	tool_unlocked.emit(tool_id)
	return true


# --- Serialization --- #

## Serializes tool manager state.
func serialize() -> Dictionary:
	return {
		"available_tools": available_tools.duplicate(),
		"tool_usage_log": _tool_usage_log.duplicate(),
	}


## Restores tool manager state from saved data.
func deserialize(data: Dictionary) -> void:
	available_tools.assign(data.get("available_tools", TOOL_REGISTRY.keys()))
	_tool_usage_log = data.get("tool_usage_log", {})
