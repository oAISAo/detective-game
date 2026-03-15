## asset_fallback.gd
## Provides texture loading with automatic fallback to placeholder assets.
## If the requested asset does not exist, looks for a placeholder version in
## res://assets/placeholders/. If no placeholder exists either, returns a
## magenta "missing" texture.
extends Node

const PLACEHOLDER_DIR: String = "res://assets/placeholders/"

var _cache: Dictionary = {}


func get_texture(asset_path: String) -> Texture2D:
	if _cache.has(asset_path):
		return _cache[asset_path]

	# Try the exact path first
	if ResourceLoader.exists(asset_path):
		var tex := load(asset_path) as Texture2D
		if tex:
			_cache[asset_path] = tex
			return tex

	# Try placeholder version
	var filename := asset_path.get_file()
	if not filename.begins_with("placeholder_"):
		filename = "placeholder_" + filename
	var placeholder_path := PLACEHOLDER_DIR + filename
	if ResourceLoader.exists(placeholder_path):
		var tex := load(placeholder_path) as Texture2D
		if tex:
			_cache[asset_path] = tex
			return tex

	# Last resort: magenta missing texture
	return _get_missing_texture()


func _get_missing_texture() -> ImageTexture:
	if _cache.has("__missing__"):
		return _cache["__missing__"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.MAGENTA)
	var tex := ImageTexture.create_from_image(img)
	_cache["__missing__"] = tex
	return tex


func clear_cache() -> void:
	_cache.clear()


func reset() -> void:
	_cache.clear()


func serialize() -> Dictionary:
	return {}


func deserialize(_data: Dictionary) -> void:
	pass
