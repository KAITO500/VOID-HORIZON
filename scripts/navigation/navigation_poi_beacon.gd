class_name NavigationPoiBeacon
extends Node3D
## Visible testbed destination that registers itself as a real, node-backed POI.

@export var target_id: StringName = &""
@export var display_name: String = "NAVIGATION BEACON"
@export var category: NavigationTarget.Category = NavigationTarget.Category.STATION
@export var registry_path: NodePath = NodePath("../SpaceNavigation/Registry")
@export var beacon_color: Color = Color("A45BDF")

var _registry: NavigationTargetRegistry


func _ready() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "BeaconVisual"
	var mesh := SphereMesh.new()
	mesh.radius = 10.0
	mesh.height = 20.0
	mesh.radial_segments = 12
	mesh.rings = 8
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = beacon_color.darkened(0.45)
	material.emission_enabled = true
	material.emission = beacon_color
	material.emission_energy_multiplier = 1.5
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)
	_registry = get_node_or_null(registry_path) as NavigationTargetRegistry
	if _registry == null:
		push_error("NavigationPoiBeacon: registry_path must resolve to NavigationTargetRegistry.")
		return
	var target := NavigationTarget.new()
	target.id = target_id
	target.display_name = display_name
	target.category = category
	target.discovered = true
	target.navigation_visible = true
	if not _registry.register_node_target(target, self):
		push_error("NavigationPoiBeacon: could not register POI '%s'." % target_id)
