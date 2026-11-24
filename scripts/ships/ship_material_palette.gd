class_name ShipMaterialPalette
extends Node
## Applies the VOID HORIZON palette to an imported ship model whose GLB materials have no colors.
##
## Why: `light_fighter_model.glb` (checked 2026-11-24) stores NO baseColor for materials 01-04, no textures and
## no vertex colors, so Godot renders them white (glTF default 1,1,1). Only the glass and the two emissive
## materials carry colors. This node recolors by material-name prefix ("01 | Ceramic armor" -> key "01") with
## per-surface override materials; the GLB is not modified. Remove this node once the GLB is re-exported with colors.
##
## Add as a child of the model root (e.g. VisualRoot/ShipModel/MaterialPalette).

## Material-name prefix -> albedo. Art direction: aged ivory ceramic, graphite, weathered steel.
@export var palette: Dictionary = {
	"01": Color("#B9B19B"),  # Ceramic armor, ash -> aged ivory
	"02": Color("#8E8470"),  # Replacement armor -> darker stone/ivory, reads as a replaced panel
	"03": Color("#2A3036"),  # Graphite structure
	"04": Color("#7C8288"),  # Brushed titanium -> weathered steel
}
## Without environment reflections strongly metallic surfaces go very dark; clamp for readability.
@export_range(0.0, 1.0, 0.01) var max_metallic: float = 0.45

var _cache: Dictionary = {}


func _ready() -> void:
	var model: Node = get_parent()
	if model == null:
		return
	var changed: int = 0
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var key: String = _key_for(source.resource_name)
			if not palette.has(key):
				continue
			mesh_instance.set_surface_override_material(surface, _recolored(source, palette[key] as Color))
			changed += 1
	if changed == 0:
		push_warning("ShipMaterialPalette: no surfaces matched; check material names / palette keys.")


func _key_for(material_name: String) -> String:
	var bar: int = material_name.find("|")
	return material_name.substr(0, bar).strip_edges() if bar > 0 else material_name.strip_edges()


func _recolored(source: StandardMaterial3D, color: Color) -> StandardMaterial3D:
	var id: int = source.get_instance_id()
	if _cache.has(id):
		return _cache[id] as StandardMaterial3D
	var copy := source.duplicate() as StandardMaterial3D
	copy.albedo_color = color
	copy.metallic = minf(copy.metallic, max_metallic)
	_cache[id] = copy
	return copy
