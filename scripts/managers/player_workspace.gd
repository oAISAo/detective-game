## PlayerWorkspace.gd
## Facade autoload grouping player workspace managers:
## TimelineManager, TheoryManager, BoardManager.
##
## Migration path:
##   Old: TimelineManager.add_event(...)
##   New: PlayerWorkspace.timeline.add_event(...)
##
##   Old: TheoryManager.create_theory(...)
##   New: PlayerWorkspace.theory.create_theory(...)
##
##   Old: BoardManager.add_pin(...)
##   New: PlayerWorkspace.board.add_pin(...)
##
## Once all references have been migrated, the individual TimelineManager,
## TheoryManager, and BoardManager autoloads can be removed from
## project.godot.
extends Node


var timeline: Node
var theory: Node
var board: Node


func _ready() -> void:
	timeline = _create_child("res://scripts/managers/timeline_manager.gd", "TimelineManager")
	theory = _create_child("res://scripts/managers/theory_manager.gd", "TheoryManager")
	board = _create_child("res://scripts/managers/board_manager.gd", "BoardManager")
	# These children duplicate the existing autoloads during migration.
	# Unregister them so the autoloads remain the authoritative subsystems.
	GameManager.unregister_subsystem(timeline)
	GameManager.unregister_subsystem(theory)
	GameManager.unregister_subsystem(board)


func _create_child(script_path: String, node_name: String) -> Node:
	var script: GDScript = load(script_path) as GDScript
	var instance: Node = Node.new()
	instance.set_script(script)
	instance.name = node_name
	add_child(instance)
	return instance
