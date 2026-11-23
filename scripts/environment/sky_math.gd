class_name SkyMath
extends RefCounted
## Shared, stateless helpers for sky-direction math. No scene dependencies.
##
## Direction convention: yaw 0 / pitch 0 points along -Z (the default camera forward).
## Positive yaw turns toward +X (right), positive pitch toward +Y (up).


static func direction_from_angles(yaw_deg: float, pitch_deg: float) -> Vector3:
	var yaw: float = deg_to_rad(yaw_deg)
	var pitch: float = deg_to_rad(pitch_deg)
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))


## Rotation that tilts the "galactic band" plane (default plane = XZ) around the X axis.
static func band_basis(tilt_deg: float) -> Basis:
	return Basis(Vector3.RIGHT, deg_to_rad(tilt_deg))


## Normal of the tilted band plane. Stars and nebulae use the same tilt to stay aligned.
static func band_normal(tilt_deg: float) -> Vector3:
	return band_basis(tilt_deg) * Vector3.UP
