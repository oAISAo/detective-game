## asset_fallback.gd
## Provides texture loading with automatic fallback to placeholder assets.
## If the requested asset does not exist, looks for a placeholder version in
## res://assets/placeholders/. If no placeholder exists either, returns a
## magenta "missing" texture.
extends Node

const PLACEHOLDER_DIR: String = "res://assets/placeholders/"

## Maximum number of cached textures before eviction kicks in.
const MAX_CACHE_SIZE: int = 64

var _cache: Dictionary = {}

## Tracks access order for LRU eviction. Most recently used at the end.
var _access_order: Array[String] = []


func get_texture(asset_path: String) -> Texture2D:
	if _cache.has(asset_path):
		_touch(asset_path)
		return _cache[asset_path]

	# Try the exact path first
	if ResourceLoader.exists(asset_path):
		var tex := load(asset_path) as Texture2D
		if tex:
			_store(asset_path, tex)
			return tex

	# Try placeholder version
	var filename := asset_path.get_file()
	if not filename.begins_with("placeholder_"):
		filename = "placeholder_" + filename
	var placeholder_path := PLACEHOLDER_DIR + filename
	if ResourceLoader.exists(placeholder_path):
		var tex := load(placeholder_path) as Texture2D
		if tex:
			_store(asset_path, tex)
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
	_access_order.clear()


func reset() -> void:
	_cache.clear()
	_access_order.clear()


## Stores a texture in the cache, evicting the least recently used entry if full.
func _store(key: String, tex: Texture2D) -> void:
	if _cache.size() >= MAX_CACHE_SIZE and not _cache.has(key):
		_evict_oldest()
	_cache[key] = tex
	_touch(key)


## Moves a key to the end of the access order (most recently used).
func _touch(key: String) -> void:
	var idx: int = _access_order.find(key)
	if idx >= 0:
		_access_order.remove_at(idx)
	_access_order.append(key)


## Evicts the least recently used cache entry.
func _evict_oldest() -> void:
	while _access_order.size() > 0 and _cache.size() >= MAX_CACHE_SIZE:
		var oldest: String = _access_order.pop_front()
		# Don't evict the missing texture sentinel
		if oldest == "__missing__":
			_access_order.append(oldest)
			continue
		_cache.erase(oldest)


func serialize() -> Dictionary:
	return {}


func deserialize(_data: Dictionary) -> void:
	pass
