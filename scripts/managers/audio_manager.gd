## AudioManager.gd
## Centralized audio system for SFX and music playback.
## Extends BaseSubsystem for GameManager lifecycle integration (reset/serialize/deserialize).
## Registries are empty — no audio assets needed yet. Future phases add entries.
extends BaseSubsystem


# --- Signals --- #

## Emitted when a music track changes (or stops).
signal music_changed(track_id: String)

## Emitted when an SFX is played successfully.
signal sfx_played(sfx_id: String)


# --- Audio Players --- #

var _sfx_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer


# --- Registries --- #
## Maps string IDs to resource paths. Populated in future phases.

const SFX_REGISTRY: Dictionary = {}
const MUSIC_REGISTRY: Dictionary = {}


# --- State --- #

var _sfx_volume: float = 1.0
var _music_volume: float = 1.0
var _current_music: String = ""

const DEFAULT_SFX_VOLUME: float = 1.0
const DEFAULT_MUSIC_VOLUME: float = 1.0


# --- Lifecycle --- #

func _ready() -> void:
	super()

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFXPlayer"
	_sfx_player.bus = &"Master"
	add_child(_sfx_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = &"Master"
	add_child(_music_player)

	_music_player.finished.connect(_on_music_finished)


# --- Public API --- #

## Plays a sound effect by registry key. Warns and does nothing if the key is missing.
func play_sfx(sfx_id: String) -> void:
	if not SFX_REGISTRY.has(sfx_id):
		push_warning("[AudioManager] Unknown SFX key: '%s'" % sfx_id)
		return
	var path: String = SFX_REGISTRY[sfx_id]
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("[AudioManager] Failed to load SFX: '%s' at '%s'" % [sfx_id, path])
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = linear_to_db(_sfx_volume)
	_sfx_player.play()
	sfx_played.emit(sfx_id)


## Plays a music track by registry key. Warns and does nothing if the key is missing.
func play_music(track_id: String) -> void:
	if not MUSIC_REGISTRY.has(track_id):
		push_warning("[AudioManager] Unknown music key: '%s'" % track_id)
		return
	if _current_music == track_id and _music_player.playing:
		return
	var path: String = MUSIC_REGISTRY[track_id]
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("[AudioManager] Failed to load music: '%s' at '%s'" % [track_id, path])
		return
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(_music_volume)
	_music_player.play()
	_current_music = track_id
	music_changed.emit(track_id)


## Stops the current music track. Safe to call when nothing is playing.
func stop_music() -> void:
	_music_player.stop()
	var was_playing: String = _current_music
	_current_music = ""
	if not was_playing.is_empty():
		music_changed.emit("")


## Sets SFX volume (clamped to [0.0, 1.0]).
func set_sfx_volume(vol: float) -> void:
	_sfx_volume = clampf(vol, 0.0, 1.0)


## Returns current SFX volume.
func get_sfx_volume() -> float:
	return _sfx_volume


## Sets music volume (clamped to [0.0, 1.0]).
func set_music_volume(vol: float) -> void:
	_music_volume = clampf(vol, 0.0, 1.0)
	if _music_player.playing:
		_music_player.volume_db = linear_to_db(_music_volume)


## Returns current music volume.
func get_music_volume() -> float:
	return _music_volume


## Returns the current music track ID, or empty string if none.
func get_current_music() -> String:
	return _current_music


## Returns true if music is currently playing.
func is_music_playing() -> bool:
	return _music_player.playing


# --- Subsystem Lifecycle --- #

## Resets audio state with default volumes and stops music.
func reset() -> void:
	_sfx_volume = DEFAULT_SFX_VOLUME
	_music_volume = DEFAULT_MUSIC_VOLUME
	_music_player.stop()
	_current_music = ""


## Returns state for save/load.
func serialize() -> Dictionary:
	return {
		"sfx_volume": _sfx_volume,
		"music_volume": _music_volume,
		"current_music": _current_music,
	}


## Restores state from saved data.
func deserialize(data: Dictionary) -> void:
	_sfx_volume = clampf(data.get("sfx_volume", DEFAULT_SFX_VOLUME), 0.0, 1.0)
	_music_volume = clampf(data.get("music_volume", DEFAULT_MUSIC_VOLUME), 0.0, 1.0)
	var track: String = data.get("current_music", "")
	if not track.is_empty() and MUSIC_REGISTRY.has(track):
		play_music(track)
	else:
		_current_music = ""


# --- Internal --- #

func _on_music_finished() -> void:
	_current_music = ""
	music_changed.emit("")
