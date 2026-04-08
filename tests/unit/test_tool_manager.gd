## test_tool_manager.gd
## Unit tests for the ToolManager autoload singleton.
## Phase 6: Verify tool registry, availability, compatibility, usage, and serialization.
extends GutTest


var _tool_mgr: Node = null


func before_each() -> void:
	_tool_mgr = get_node_or_null("/root/ToolManager")
	if _tool_mgr:
		_tool_mgr.reset()


# --- Tool Registry Tests --- #

func test_all_tools_registered() -> void:
	assert_eq(_tool_mgr.TOOL_REGISTRY.size(), 4, "Should have 4 tools in registry")


func test_fingerprint_powder_is_valid() -> void:
	assert_true(_tool_mgr.is_valid_tool("fingerprint_powder"), "fingerprint_powder should be valid")


func test_uv_light_is_valid() -> void:
	assert_true(_tool_mgr.is_valid_tool("uv_light"), "uv_light should be valid")


func test_chemical_test_is_valid() -> void:
	assert_true(_tool_mgr.is_valid_tool("chemical_test"), "chemical_test should be valid")


func test_unknown_tool_is_not_valid() -> void:
	assert_false(_tool_mgr.is_valid_tool("laser_gun"), "Unknown tool should not be valid")


# --- Tool Availability Tests --- #

func test_all_tools_available_by_default() -> void:
	var tools: Array[String] = _tool_mgr.get_available_tools()
	assert_eq(tools.size(), 4, "Should have 4 available tools")
	assert_has(tools, "fingerprint_powder")
	assert_has(tools, "uv_light")
	assert_has(tools, "chemical_test")
	assert_has(tools, "forensic_kit")


func test_has_tool_returns_true_for_available() -> void:
	assert_true(_tool_mgr.has_tool("fingerprint_powder"))


func test_has_tool_returns_false_for_unavailable() -> void:
	_tool_mgr.available_tools.clear()
	assert_false(_tool_mgr.has_tool("fingerprint_powder"))


# --- Tool Name Queries --- #

func test_get_tool_name_fingerprint() -> void:
	assert_eq(_tool_mgr.get_tool_name("fingerprint_powder"), "Fingerprint Powder")


func test_get_tool_name_uv() -> void:
	assert_eq(_tool_mgr.get_tool_name("uv_light"), "UV Light")


func test_get_tool_name_chemical() -> void:
	assert_eq(_tool_mgr.get_tool_name("chemical_test"), "Chemical Residue Test")


func test_get_tool_name_unknown_returns_empty() -> void:
	assert_eq(_tool_mgr.get_tool_name("nonexistent"), "")


# --- Tool Compatibility Tests --- #

func test_compatible_tools_match_requirements() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "test_obj"
	obj.name = "Test Object"
	obj.tool_requirements = ["fingerprint_powder", "uv_light"]
	var compatible: Array[String] = _tool_mgr.get_compatible_tools(obj)
	assert_eq(compatible.size(), 2)
	assert_has(compatible, "fingerprint_powder")
	assert_has(compatible, "uv_light")


func test_compatible_tools_excludes_unavailable() -> void:
	_tool_mgr.available_tools.clear()
	_tool_mgr.available_tools.append("fingerprint_powder")
	var obj := InvestigableObjectData.new()
	obj.id = "test_obj"
	obj.name = "Test Object"
	obj.tool_requirements = ["fingerprint_powder", "uv_light"]
	var compatible: Array[String] = _tool_mgr.get_compatible_tools(obj)
	assert_eq(compatible.size(), 1)
	assert_has(compatible, "fingerprint_powder")


func test_compatible_tools_empty_when_no_requirements() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "test_obj"
	obj.name = "Test Object"
	obj.tool_requirements = []
	var compatible: Array[String] = _tool_mgr.get_compatible_tools(obj)
	assert_eq(compatible.size(), 0)


# --- Tool Validation Tests --- #

func test_validate_valid_tool_use() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "test_obj"
	obj.name = "Test Object"
	obj.tool_requirements = ["fingerprint_powder"]
	var error: String = _tool_mgr.validate_tool_use("fingerprint_powder", obj)
	assert_eq(error, "", "Valid tool use should return empty error")


func test_validate_unknown_tool() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "test_obj"
	obj.name = "Test Object"
	obj.tool_requirements = []
	var error: String = _tool_mgr.validate_tool_use("laser_gun", obj)
	assert_string_contains(error, "Unknown tool")


func test_validate_unavailable_tool() -> void:
	_tool_mgr.available_tools.clear()
	var obj := InvestigableObjectData.new()
	obj.id = "test_obj"
	obj.name = "Test Object"
	obj.tool_requirements = ["fingerprint_powder"]
	var error: String = _tool_mgr.validate_tool_use("fingerprint_powder", obj)
	assert_string_contains(error, "not available")


func test_validate_incompatible_tool() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "test_obj"
	obj.name = "Test Object"
	obj.tool_requirements = ["uv_light"]
	var error: String = _tool_mgr.validate_tool_use("fingerprint_powder", obj)
	assert_string_contains(error, "not compatible")


# --- Tool Usage Tests --- #

func test_use_tool_returns_evidence() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "obj_shelf"
	obj.name = "Shelf"
	obj.tool_requirements = ["fingerprint_powder"]
	obj.evidence_results = ["ev_prints"]
	var results: Array[String] = _tool_mgr.use_tool("fingerprint_powder", obj)
	assert_eq(results.size(), 1, "Should return 1 evidence result")
	assert_has(results, "ev_prints")


func test_use_tool_emits_signal() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "obj_table"
	obj.name = "Table"
	obj.tool_requirements = ["uv_light"]
	obj.evidence_results = ["ev_traces"]
	watch_signals(_tool_mgr)
	_tool_mgr.use_tool("uv_light", obj)
	assert_signal_emitted_with_parameters(_tool_mgr, "tool_used", ["uv_light", "obj_table"])


func test_use_tool_twice_returns_empty() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "obj_counter"
	obj.name = "Counter"
	obj.tool_requirements = ["chemical_test"]
	obj.evidence_results = ["ev_residue"]
	_tool_mgr.use_tool("chemical_test", obj)
	var results: Array[String] = _tool_mgr.use_tool("chemical_test", obj)
	assert_eq(results.size(), 0, "Second use should return empty")


func test_use_invalid_tool_returns_empty() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "obj_test"
	obj.name = "Test"
	obj.tool_requirements = ["uv_light"]
	obj.evidence_results = ["ev_test"]
	var results: Array[String] = _tool_mgr.use_tool("fingerprint_powder", obj)
	assert_eq(results.size(), 0, "Incompatible tool should return empty")
	assert_push_warning("[ToolManager] Tool 'Fingerprint Powder' is not compatible with 'Test'")


func test_has_used_tool_tracking() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "obj_test"
	obj.name = "Test"
	obj.tool_requirements = ["fingerprint_powder"]
	obj.evidence_results = ["ev_test"]
	assert_false(_tool_mgr.has_used_tool("fingerprint_powder", "obj_test"))
	_tool_mgr.use_tool("fingerprint_powder", obj)
	assert_true(_tool_mgr.has_used_tool("fingerprint_powder", "obj_test"))


# --- Unlock Tool Tests --- #

func test_unlock_new_tool() -> void:
	# Remove a tool first, then unlock it
	_tool_mgr.available_tools.erase("chemical_test")
	assert_false(_tool_mgr.has_tool("chemical_test"))
	watch_signals(_tool_mgr)
	var result: bool = _tool_mgr.unlock_tool("chemical_test")
	assert_true(result, "Should successfully unlock")
	assert_true(_tool_mgr.has_tool("chemical_test"))
	assert_signal_emitted_with_parameters(_tool_mgr, "tool_unlocked", ["chemical_test"])


func test_unlock_already_available_returns_false() -> void:
	var result: bool = _tool_mgr.unlock_tool("fingerprint_powder")
	assert_false(result, "Already available tool should return false")


func test_unlock_invalid_tool_returns_false() -> void:
	var result: bool = _tool_mgr.unlock_tool("nonexistent_tool")
	assert_false(result, "Invalid tool should return false")
	assert_push_error("Cannot unlock unknown tool")


# --- Serialization Tests --- #

func test_serialize_captures_state() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "obj_ser"
	obj.name = "SerTest"
	obj.tool_requirements = ["fingerprint_powder"]
	obj.evidence_results = ["ev_ser"]
	_tool_mgr.use_tool("fingerprint_powder", obj)
	var data: Dictionary = _tool_mgr.serialize()
	assert_true(data.has("available_tools"))
	assert_true(data.has("tool_usage_log"))
	assert_eq(data["available_tools"].size(), 4)
	assert_true(data["tool_usage_log"].has("fingerprint_powder:obj_ser"))


func test_deserialize_restores_state() -> void:
	var saved: Dictionary = {
		"available_tools": ["uv_light"],
		"tool_usage_log": {"uv_light:obj_a": true},
	}
	_tool_mgr.deserialize(saved)
	assert_eq(_tool_mgr.available_tools.size(), 1)
	assert_true(_tool_mgr.has_tool("uv_light"))
	assert_false(_tool_mgr.has_tool("fingerprint_powder"))
	assert_true(_tool_mgr.has_used_tool("uv_light", "obj_a"))


func test_reset_clears_all_state() -> void:
	var obj := InvestigableObjectData.new()
	obj.id = "obj_reset"
	obj.name = "Reset"
	obj.tool_requirements = ["uv_light"]
	obj.evidence_results = ["ev_r"]
	_tool_mgr.use_tool("uv_light", obj)
	_tool_mgr.reset()
	assert_eq(_tool_mgr.available_tools.size(), 4, "All tools restored after reset")
	assert_false(_tool_mgr.has_used_tool("uv_light", "obj_reset"), "Usage log cleared")
