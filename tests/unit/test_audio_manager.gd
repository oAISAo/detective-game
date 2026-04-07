## test_audio_manager.gd
## Unit tests for the AudioManager autoload singleton.
## Phase D9: Verify volume clamping, graceful missing-key handling,
## serialize/deserialize round-trip, reset, and signal behavior.
extends GutTest


# --- Setup --- #

func before_each() -> void:
	AudioManager.reset()


# ============================================================
# Volume Clamping — SFX
# ============================================================

func test_sfx_volume_default_is_one() -> void:
	assert_eq(AudioManager.get_sfx_volume(), 1.0, "Default SFX volume should be 1.0")


func test_set_sfx_volume_normal() -> void:
	AudioManager.set_sfx_volume(0.5)
	assert_eq(AudioManager.get_sfx_volume(), 0.5, "SFX volume should be set to 0.5")


func test_set_sfx_volume_clamps_high() -> void:
	AudioManager.set_sfx_volume(2.5)
	assert_eq(AudioManager.get_sfx_volume(), 1.0, "SFX volume above 1.0 should clamp to 1.0")


func test_set_sfx_volume_clamps_low() -> void:
	AudioManager.set_sfx_volume(-0.5)
	assert_eq(AudioManager.get_sfx_volume(), 0.0, "SFX volume below 0.0 should clamp to 0.0")


# ============================================================
# Volume Clamping — Music
# ============================================================

func test_music_volume_default_is_one() -> void:
	assert_eq(AudioManager.get_music_volume(), 1.0, "Default music volume should be 1.0")


func test_set_music_volume_normal() -> void:
	AudioManager.set_music_volume(0.7)
	assert_eq(AudioManager.get_music_volume(), 0.7, "Music volume should be set to 0.7")


func test_set_music_volume_clamps_high() -> void:
	AudioManager.set_music_volume(5.0)
	assert_eq(AudioManager.get_music_volume(), 1.0, "Music volume above 1.0 should clamp to 1.0")


func test_set_music_volume_clamps_low() -> void:
	AudioManager.set_music_volume(-1.0)
	assert_eq(AudioManager.get_music_volume(), 0.0, "Music volume below 0.0 should clamp to 0.0")


# ============================================================
# Graceful Missing Key — SFX
# ============================================================

func test_play_sfx_missing_key_does_not_crash() -> void:
	# Should warn but not crash
	AudioManager.play_sfx("nonexistent_sound")
	assert_true(true, "play_sfx with missing key should not crash")


func test_play_sfx_missing_key_does_not_emit_signal() -> void:
	watch_signals(AudioManager)
	AudioManager.play_sfx("nonexistent_sound")
	assert_signal_not_emitted(AudioManager, "sfx_played")


# ============================================================
# Graceful Missing Key — Music
# ============================================================

func test_play_music_missing_key_does_not_crash() -> void:
	AudioManager.play_music("nonexistent_track")
	assert_true(true, "play_music with missing key should not crash")


func test_play_music_missing_key_does_not_emit_signal() -> void:
	watch_signals(AudioManager)
	AudioManager.play_music("nonexistent_track")
	assert_signal_not_emitted(AudioManager, "music_changed")


# ============================================================
# Stop Music
# ============================================================

func test_stop_music_when_nothing_playing_does_not_crash() -> void:
	AudioManager.stop_music()
	assert_true(true, "stop_music when nothing playing should not crash")


func test_stop_music_clears_current_music() -> void:
	AudioManager.stop_music()
	assert_eq(AudioManager.get_current_music(), "", "Current music should be empty after stop")


func test_is_music_playing_false_by_default() -> void:
	assert_false(AudioManager.is_music_playing(), "No music should be playing by default")


# ============================================================
# Serialize / Deserialize
# ============================================================

func test_serialize_returns_volumes() -> void:
	AudioManager.set_sfx_volume(0.3)
	AudioManager.set_music_volume(0.8)
	var data: Dictionary = AudioManager.serialize()
	assert_eq(data["sfx_volume"], 0.3, "Serialized SFX volume should be 0.3")
	assert_eq(data["music_volume"], 0.8, "Serialized music volume should be 0.8")


func test_deserialize_restores_volumes() -> void:
	var data: Dictionary = {
		"sfx_volume": 0.4,
		"music_volume": 0.6,
		"current_music": "",
	}
	AudioManager.deserialize(data)
	assert_eq(AudioManager.get_sfx_volume(), 0.4, "Deserialized SFX volume should be 0.4")
	assert_eq(AudioManager.get_music_volume(), 0.6, "Deserialized music volume should be 0.6")


func test_deserialize_clamps_invalid_volumes() -> void:
	var data: Dictionary = {
		"sfx_volume": 99.0,
		"music_volume": -5.0,
		"current_music": "",
	}
	AudioManager.deserialize(data)
	assert_eq(AudioManager.get_sfx_volume(), 1.0, "Deserialized SFX volume should clamp to 1.0")
	assert_eq(AudioManager.get_music_volume(), 0.0, "Deserialized music volume should clamp to 0.0")


func test_deserialize_empty_dict_uses_defaults() -> void:
	AudioManager.set_sfx_volume(0.2)
	AudioManager.deserialize({})
	assert_eq(AudioManager.get_sfx_volume(), 1.0, "Missing sfx_volume should default to 1.0")
	assert_eq(AudioManager.get_music_volume(), 1.0, "Missing music_volume should default to 1.0")


# ============================================================
# Reset
# ============================================================

func test_reset_restores_default_sfx_volume() -> void:
	AudioManager.set_sfx_volume(0.1)
	AudioManager.reset()
	assert_eq(AudioManager.get_sfx_volume(), 1.0, "Reset should restore SFX volume to 1.0")


func test_reset_restores_default_music_volume() -> void:
	AudioManager.set_music_volume(0.2)
	AudioManager.reset()
	assert_eq(AudioManager.get_music_volume(), 1.0, "Reset should restore music volume to 1.0")


func test_reset_clears_current_music() -> void:
	AudioManager.reset()
	assert_eq(AudioManager.get_current_music(), "", "Reset should clear current music")


# ============================================================
# API Method Existence
# ============================================================

func test_has_play_sfx_method() -> void:
	assert_true(AudioManager.has_method("play_sfx"), "AudioManager should have 'play_sfx' method")


func test_has_play_music_method() -> void:
	assert_true(AudioManager.has_method("play_music"), "AudioManager should have 'play_music' method")


func test_has_stop_music_method() -> void:
	assert_true(AudioManager.has_method("stop_music"), "AudioManager should have 'stop_music' method")


func test_has_set_sfx_volume_method() -> void:
	assert_true(AudioManager.has_method("set_sfx_volume"), "AudioManager should have 'set_sfx_volume' method")


func test_has_set_music_volume_method() -> void:
	assert_true(AudioManager.has_method("set_music_volume"), "AudioManager should have 'set_music_volume' method")
