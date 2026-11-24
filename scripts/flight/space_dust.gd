class_name SpaceDust
extends MultiMeshInstance3D
## Camera-relative dust that makes speed and direction readable in empty space.
## The wrapping is done in assets/materials/space/space_dust.gdshader; this script only creates
## the point pool and feeds the shader the ship position and velocity every frame.

@export var ship_path: NodePath
@export_range(50, 4000, 10) var point_count: int = 700
@export_range(100.0, 3000.0, 10.0) var box_size: float = 500.0
@export var random_seed: int = 7

var _ship: Spaceship
var _material: ShaderMaterial


func _ready() -> void:
	_ship = get_node_or_null(ship_path) as Spaceship
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Vertex positions are rewritten in the shader, so the node AABB is meaningless: never cull.
	custom_aabb = AABB(Vector3(-1.0e6, -1.0e6, -1.0e6), Vector3(2.0e6, 2.0e6, 2.0e6))

	_material = ShaderMaterial.new()
	_material.shader = load("res://assets/materials/space/space_dust.gdshader") as Shader
	_material.set_shader_parameter("box_size", box_size)

	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	quad.material = _material

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = quad
	multimesh.instance_count = point_count
	for i in point_count:
		var position_in_box := Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5)) * box_size
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, position_in_box))


func _process(_delta: float) -> void:
	if _ship == null or _material == null:
		return
	_material.set_shader_parameter("anchor", _ship.get_global_transform_interpolated().origin)
	_material.set_shader_parameter("velocity", _ship.velocity)
