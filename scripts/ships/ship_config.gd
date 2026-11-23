class_name ShipConfig
extends Resource
## Data describing one ship type. One .tres per ship under res://resources/ships/.
##
## IMPORTANT: every "_ref" value is a PLACEHOLDER reference, not final gameplay balance.
## Phase 03 (Flight System) decides what these numbers actually mean and replaces them.

enum ShipClass { UNSPECIFIED, LIGHT_FIGHTER }

@export var ship_id: StringName = &""
@export var display_name: String = ""
@export var ship_class: ShipClass = ShipClass.UNSPECIFIED
## Optional replacement visual (imported model scene). Empty = use the built-in placeholder model.
@export var visual_scene: PackedScene

@export_group("Reference values (PLACEHOLDERS, not balance)")
@export var is_placeholder_balance: bool = true
@export var mass_ref: float = 1000.0
@export var max_speed_ref: float = 300.0
@export var acceleration_ref: float = 100.0
@export var rotation_responsiveness_ref: float = 1.0

@export_group("Attachment points (names of Marker3D nodes on the ship root)")
@export var engine_point_names: PackedStringArray = PackedStringArray(["EngineLeft", "EngineRight"])
@export var weapon_point_names: PackedStringArray = PackedStringArray(["WeaponLeft", "WeaponRight"])

@export_group("Camera reference (PLACEHOLDERS for the future third-person camera)")
@export var camera_distance_ref: float = 28.0
@export var camera_height_ref: float = 6.0
@export var camera_base_fov_ref: float = 70.0
