## base_subsystem.gd
## Base class for all game subsystems that participate in the
## GameManager registry (reset, serialize, deserialize lifecycle).
class_name BaseSubsystem
extends Node


func _ready() -> void:
	GameManager.register_subsystem(self)


## Resets the subsystem to its initial state. Override in subclasses.
func reset() -> void:
	pass


## Returns the subsystem state as a dictionary for saving. Override in subclasses.
func serialize() -> Dictionary:
	return {}


## Restores subsystem state from a saved dictionary. Override in subclasses.
func deserialize(_data: Dictionary) -> void:
	pass
