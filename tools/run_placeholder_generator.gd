## run_placeholder_generator.gd
## Runner script for generating placeholder assets.
## Usage: /Applications/Godot.app/Contents/MacOS/Godot --headless -s tools/run_placeholder_generator.gd
extends SceneTree


func _init() -> void:
	var results := PlaceholderAssetGenerator.generate_all_placeholders()
	print("Placeholder generation complete.")
	print("  Generated: %d" % results.generated)
	print("  Failed:    %d" % results.failed)
	print("  Total:     %d" % results.total)
	quit()
