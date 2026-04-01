## InvestigationTools.gd
## Facade autoload grouping investigation tool managers:
## LabManager, SurveillanceManager, WarrantManager.
##
## Migration path:
##   Old: LabManager.submit_request(...)
##   New: InvestigationTools.lab.submit_request(...)
##
##   Old: SurveillanceManager.start_surveillance(...)
##   New: InvestigationTools.surveillance.start_surveillance(...)
##
##   Old: WarrantManager.request_warrant(...)
##   New: InvestigationTools.warrant.request_warrant(...)
##
## Once all references have been migrated, the individual LabManager,
## SurveillanceManager, and WarrantManager autoloads can be removed
## from project.godot.
extends Node


var lab: Node
var surveillance: Node
var warrant: Node


func _ready() -> void:
	lab = _create_child("res://scripts/managers/lab_manager.gd", "LabManager")
	surveillance = _create_child("res://scripts/managers/surveillance_manager.gd", "SurveillanceManager")
	warrant = _create_child("res://scripts/managers/warrant_manager.gd", "WarrantManager")


func _create_child(script_path: String, node_name: String) -> Node:
	var script: GDScript = load(script_path) as GDScript
	var instance: Node = Node.new()
	instance.set_script(script)
	instance.name = node_name
	add_child(instance)
	return instance
