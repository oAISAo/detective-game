## Guard test for serialized theme/resources.
## Blocks script constant symbol references inside .tres files.
extends GutTest


const ROOT_DIR: String = "res://"
const FORBIDDEN_SYMBOLS: Array[String] = [
	"UIColors.",
	"UIFonts.",
]
const EXCLUDED_DIRS: Array[String] = [
	".git",
	".godot",
]


func test_tres_files_do_not_reference_script_symbols() -> void:
	var tres_files: Array[String] = _collect_tres_files(ROOT_DIR)
	assert_gt(tres_files.size(), 0, "Expected at least one .tres file in project")

	var offending: Array[String] = []
	for tres_path: String in tres_files:
		var content: String = FileAccess.get_file_as_string(tres_path)
		for symbol: String in FORBIDDEN_SYMBOLS:
			if content.contains(symbol):
				offending.append("%s contains %s" % [tres_path, symbol])

	assert_eq(
		offending.size(),
		0,
		".tres files must not contain script symbols:\n%s" % "\n".join(offending)
	)


func _collect_tres_files(root_dir: String) -> Array[String]:
	var results: Array[String] = []
	_walk_dirs_for_tres(root_dir, results)
	return results


func _walk_dirs_for_tres(dir_path: String, results: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	assert_not_null(dir, "Directory should be readable: %s" % dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var entry_name: String = dir.get_next()
		if entry_name.is_empty():
			break

		var child_path: String = dir_path.path_join(entry_name)
		if dir.current_is_dir():
			if EXCLUDED_DIRS.has(entry_name):
				continue
			_walk_dirs_for_tres(child_path, results)
			continue

		if entry_name.ends_with(".tres"):
			results.append(child_path)
	dir.list_dir_end()
