## Runner script for syncing main_theme.tres from UIColors/UIFonts tokens.
## Usage:
## /Applications/Godot.app/Contents/MacOS/Godot --headless --path "/path/to/project" -s tools/run_theme_token_sync.gd
extends SceneTree

const THEME_TOKEN_SYNC = preload("res://tools/sync_theme_from_tokens.gd")


func _init() -> void:
	var save_err: int = THEME_TOKEN_SYNC.sync_main_theme()
	if save_err != OK:
		print("[ThemeTokenSync] Sync failed with error code: %d" % save_err)
		quit(1)
		return

	print("[ThemeTokenSync] Synced res://resources/themes/main_theme.tres")
	quit()
