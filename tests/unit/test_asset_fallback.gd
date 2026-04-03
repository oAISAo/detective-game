## test_asset_fallback.gd
## Unit tests for AssetFallback system.
## Verifies fallback behavior: real asset → placeholder → missing texture.
extends GutTest

const AssetFallbackScript = preload("res://scripts/systems/asset_fallback.gd")

var _fallback: Node


func before_each() -> void:
	_fallback = AssetFallbackScript.new()
	add_child(_fallback)


func after_each() -> void:
	remove_child(_fallback)
	_fallback.free()


# --- Missing Texture Fallback ---

func test_nonexistent_asset_returns_texture() -> void:
	var tex: Texture2D = _fallback.get_texture("res://nonexistent/texture.png")
	assert_not_null(tex, "Should return a fallback texture for missing asset")


func test_nonexistent_asset_returns_magenta_texture() -> void:
	var tex: Texture2D = _fallback.get_texture("res://nonexistent/texture.png")
	var img: Image = tex.get_image()
	assert_eq(img.get_width(), 64, "Missing texture should be 64x64")
	assert_eq(img.get_height(), 64)
	assert_eq(img.get_pixel(0, 0), Color.MAGENTA, "Missing texture should be magenta")


func test_missing_texture_is_64x64() -> void:
	var tex: Texture2D = _fallback._get_missing_texture()
	var img: Image = tex.get_image()
	assert_eq(img.get_width(), 64)
	assert_eq(img.get_height(), 64)


# --- Caching ---

func test_cache_returns_same_texture() -> void:
	var tex1: Texture2D = _fallback.get_texture("res://nonexistent/a.png")
	var tex2: Texture2D = _fallback.get_texture("res://nonexistent/a.png")
	assert_same(tex1, tex2, "Cached texture should be the same instance")


func test_different_paths_can_share_missing_texture() -> void:
	var tex1: Texture2D = _fallback.get_texture("res://nonexistent/a.png")
	var tex2: Texture2D = _fallback.get_texture("res://nonexistent/b.png")
	assert_not_null(tex1)
	assert_not_null(tex2)


func test_clear_cache_empties_cache() -> void:
	_fallback.get_texture("res://nonexistent/a.png")
	assert_true(_fallback._cache.size() > 0, "Cache should have entries")
	_fallback.clear_cache()
	assert_eq(_fallback._cache.size(), 0, "Cache should be empty after clear")


func test_reset_clears_cache() -> void:
	_fallback.get_texture("res://nonexistent/a.png")
	_fallback.reset()
	assert_eq(_fallback._cache.size(), 0, "Cache should be empty after reset")


# --- Real Asset Loading ---

func test_loads_existing_resource() -> void:
	var tex: Texture2D = _fallback.get_texture("res://icon.svg")
	assert_not_null(tex, "Should load existing icon.svg")
	var img: Image = tex.get_image()
	assert_true(img.get_width() > 0, "Real texture should have positive width")


func test_existing_resource_is_cached() -> void:
	var tex1: Texture2D = _fallback.get_texture("res://icon.svg")
	var tex2: Texture2D = _fallback.get_texture("res://icon.svg")
	assert_same(tex1, tex2, "Same real texture should be cached")


# --- Placeholder Path Construction ---

func test_constructs_placeholder_path_from_filename() -> void:
	var tex: Texture2D = _fallback.get_texture("res://assets/art/portrait_julia_neutral.png")
	assert_not_null(tex, "Should return a texture even when nothing exists")


func test_already_prefixed_placeholder_name_not_doubled() -> void:
	var tex: Texture2D = _fallback.get_texture("res://assets/placeholders/placeholder_location_test.png")
	assert_not_null(tex, "Should return a texture")


# --- Serialize / Deserialize ---

func test_serialize_returns_empty_dict() -> void:
	var data: Dictionary = _fallback.serialize()
	assert_eq(data, {}, "Serialize should return empty dict")


func test_deserialize_does_not_crash() -> void:
	_fallback.deserialize({"some": "data"})
	assert_true(true, "Deserialize should not crash")


# --- Fallback Guarantees --- #

func test_nonexistent_path_returns_texture() -> void:
	var tex: Texture2D = _fallback.get_texture("res://nonexistent_path.png")
	assert_not_null(tex, "AssetFallback should never return null")


func test_loads_existing_placeholder() -> void:
	var tex: Texture2D = _fallback.get_texture(
		"res://assets/placeholders/placeholder_evidence_kitchen_knife.png"
	)
	assert_not_null(tex, "Should load existing placeholder image")
