@tool
class_name LightFighterModel
extends Node3D
## Visual placeholder of the Light Fighter, assembled from ShipHullBuilder meshes.
##
## This is the REPLACEABLE part of the ship: it only draws. Attachment points, collision, camera
## target and config live on the ship root, so an imported model can replace this node without
## touching them (see docs/PHASE_02_LIGHT_FIGHTER.md, "Replacement strategy").
## @tool: builds in the editor too. Children are not saved into the scene (no owner).

@export_group("Colors")
@export var hull_color: Color = Color(0.03, 0.06, 0.14)       # dark navy
@export var armor_color: Color = Color(0.10, 0.11, 0.13)      # graphite
@export var engine_housing_color: Color = Color(0.05, 0.055, 0.065)
@export var accent_color: Color = Color(1.0, 0.42, 0.08)      # controlled accent
@export var canopy_glow_color: Color = Color(0.0, 0.55, 0.80) # cyan


func _ready() -> void:
	rebuild()


func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.free()

	_add_part("Fuselage", ShipHullBuilder.fuselage(), _metal(hull_color, 0.7, 0.35))
	_add_part("Wings", ShipHullBuilder.wings(), _metal(armor_color, 0.8, 0.40))
	_add_part("Canards", ShipHullBuilder.canards(), _metal(armor_color, 0.8, 0.40))
	_add_part("Fins", ShipHullBuilder.fins(), _metal(hull_color, 0.7, 0.35))
	_add_part("Nacelles", ShipHullBuilder.nacelles(), _metal(engine_housing_color, 0.9, 0.30))
	_add_part("Canopy", ShipHullBuilder.canopy(), _canopy_material())
	_add_part("Accents", ShipHullBuilder.accents(), _accent_material())


func _add_part(part_name: String, mesh: ArrayMesh, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)


func _metal(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _canopy_material() -> StandardMaterial3D:
	var material := _metal(Color(0.02, 0.07, 0.11), 0.3, 0.10)
	material.emission_enabled = true
	material.emission = canopy_glow_color
	material.emission_energy_multiplier = 0.5
	return material


func _accent_material() -> StandardMaterial3D:
	var material := _metal(accent_color, 0.2, 0.5)
	material.emission_enabled = true
	material.emission = accent_color
	material.emission_energy_multiplier = 1.0
	return material
