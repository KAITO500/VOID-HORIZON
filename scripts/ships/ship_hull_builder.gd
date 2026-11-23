@tool
class_name ShipHullBuilder
extends RefCounted
## Procedural, flat-shaded geometry for the Light Fighter placeholder model.
##
## SHIP SPACE CONVENTION (all future ships): origin = ship center, forward = -Z, up = +Y,
## right = +X, 1 unit = 1 meter. Nose points to -Z, engines are at +Z.
## All meshes returned here are authored directly in ship space, so they can be swapped for an
## imported model that follows the same convention without moving any attachment point.
##
## Each public function returns one ArrayMesh (one surface, one draw call).
## Parts are built from lofted rings (convex cross-sections) and extruded convex polygons.

const NACELLE_X: float = 2.9
const NACELLE_Y: float = -0.3
const NACELLE_REAR_Z: float = 8.8
const WING_DROOP_DEG: float = 5.0
const FIN_CANT_DEG: float = 18.0


## Central body, nose at z = -10, tail at z = +8.2.
static func fuselage() -> ArrayMesh:
	var st: SurfaceTool = _begin()
	_loft_into(st, [
		_hex_ring(-10.0, 0.06, 0.06, 0.06),
		_hex_ring(-7.5, 0.55, 0.45, 0.35),
		_hex_ring(-4.0, 1.15, 0.85, 0.55),
		_hex_ring(0.0, 1.55, 1.05, 0.70),
		_hex_ring(4.0, 1.60, 1.00, 0.70),
		_hex_ring(7.2, 1.35, 0.85, 0.65),
		_hex_ring(8.2, 1.10, 0.70, 0.55),
	], true)
	return st.commit()


## Cockpit canopy bubble on top of the fuselage.
static func canopy() -> ArrayMesh:
	var st: SurfaceTool = _begin()
	_loft_into(st, [
		_hex_ring(-6.2, 0.08, 0.08, 0.0, 0.55),
		_hex_ring(-4.5, 0.55, 0.50, 0.0, 0.65),
		_hex_ring(-2.0, 0.70, 0.70, 0.0, 0.85),
		_hex_ring(1.0, 0.70, 0.60, 0.0, 0.95),
		_hex_ring(3.2, 0.45, 0.22, 0.0, 0.95),
		_hex_ring(4.2, 0.20, 0.06, 0.0, 0.90),
	], true)
	return st.commit()


## Main swept wings (both sides, one mesh). Span about 15.2 m, slight droop.
static func wings() -> ArrayMesh:
	var st: SurfaceTool = _begin()
	for side: float in [1.0, -1.0]:
		var polygon := PackedVector2Array([
			Vector2(1.3 * side, -1.5), Vector2(7.6 * side, 3.0),
			Vector2(7.6 * side, 5.2), Vector2(1.3 * side, 6.2)])
		_extrude_into(st, polygon, -0.12, 0.12, _wing_transform(side))
	return st.commit()


## Small forward canards near the nose.
static func canards() -> ArrayMesh:
	var st: SurfaceTool = _begin()
	for side: float in [1.0, -1.0]:
		var polygon := PackedVector2Array([
			Vector2(0.7 * side, -6.8), Vector2(3.4 * side, -5.4),
			Vector2(3.4 * side, -4.6), Vector2(0.7 * side, -4.4)])
		_extrude_into(st, polygon, -0.06, 0.06, Transform3D(Basis.IDENTITY, Vector3(0.0, -0.05, 0.0)))
	return st.commit()


## Two canted tail fins.
static func fins() -> ArrayMesh:
	var st: SurfaceTool = _begin()
	for side: float in [1.0, -1.0]:
		# Polygon x = height along the fin, y = ship Z. Rotated about Z so local X becomes "up",
		# canted outward by FIN_CANT_DEG.
		var polygon := PackedVector2Array([
			Vector2(0.0, 3.0), Vector2(2.9, 5.6), Vector2(2.9, 7.4), Vector2(0.0, 7.9)])
		var angle: float = deg_to_rad(90.0 - FIN_CANT_DEG * side)
		var xform := Transform3D(Basis(Vector3.BACK, angle), Vector3(side * 1.0, 0.8, 0.0))
		_extrude_into(st, polygon, -0.07, 0.07, xform)
	return st.commit()


## Engine nacelles mounted on the wings. Rear caps are at z = NACELLE_REAR_Z.
static func nacelles() -> ArrayMesh:
	var st: SurfaceTool = _begin()
	for side: float in [1.0, -1.0]:
		var x: float = NACELLE_X * side
		_loft_into(st, [
			_circle_ring(x, NACELLE_Y, 0.8, 0.30),
			_circle_ring(x, NACELLE_Y, 2.5, 0.55),
			_circle_ring(x, NACELLE_Y, 6.5, 0.66),
			_circle_ring(x, NACELLE_Y, 8.3, 0.60),
			_circle_ring(x, NACELLE_Y, NACELLE_REAR_Z, 0.52),
		], true)
	return st.commit()


## Thin accent strips on the wing tops and the tail spine (controlled accent color).
static func accents() -> ArrayMesh:
	var st: SurfaceTool = _begin()
	for side: float in [1.0, -1.0]:
		var strip := PackedVector2Array([
			Vector2(3.2 * side, 0.5), Vector2(7.0 * side, 3.3),
			Vector2(7.0 * side, 3.7), Vector2(3.2 * side, 0.9)])
		_extrude_into(st, strip, 0.11, 0.16, _wing_transform(side))
	var spine := PackedVector2Array([
		Vector2(-0.12, 4.4), Vector2(0.12, 4.4), Vector2(0.12, 7.4), Vector2(-0.12, 7.4)])
	_extrude_into(st, spine, 0.80, 1.10, Transform3D.IDENTITY)
	return st.commit()


static func _wing_transform(side: float) -> Transform3D:
	# Positive side = right wing; droop makes the tips sag slightly (anhedral).
	return Transform3D(
		Basis(Vector3.BACK, deg_to_rad(-WING_DROOP_DEG * side)), Vector3(0.0, -0.1, 0.0))


# --- ring helpers -----------------------------------------------------------------------

## Hexagonal cross-section at z. hw = half width at y0, ht/hb = height above/below y0.
static func _hex_ring(z: float, hw: float, ht: float, hb: float, y0: float = 0.0) -> PackedVector3Array:
	return PackedVector3Array([
		Vector3(hw, y0, z),
		Vector3(hw * 0.6, y0 + ht, z),
		Vector3(-hw * 0.6, y0 + ht, z),
		Vector3(-hw, y0, z),
		Vector3(-hw * 0.6, y0 - hb, z),
		Vector3(hw * 0.6, y0 - hb, z),
	])


static func _circle_ring(cx: float, cy: float, z: float, radius: float, sides: int = 8) -> PackedVector3Array:
	var ring := PackedVector3Array()
	for i in sides:
		var angle: float = TAU * float(i) / float(sides)
		ring.append(Vector3(cx + radius * cos(angle), cy + radius * sin(angle), z))
	return ring


# --- mesh building ----------------------------------------------------------------------

static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


## Extrudes a convex 2D polygon (x, z) between two heights, then transforms it.
static func _extrude_into(st: SurfaceTool, polygon: PackedVector2Array, y_bottom: float, y_top: float, xform: Transform3D) -> void:
	var bottom := PackedVector3Array()
	var top := PackedVector3Array()
	for p in polygon:
		bottom.append(xform * Vector3(p.x, y_bottom, p.y))
		top.append(xform * Vector3(p.x, y_top, p.y))
	_loft_into(st, [bottom, top], true)


## Connects consecutive rings (same point count, convex) with quads; optionally caps both ends.
static func _loft_into(st: SurfaceTool, rings: Array, capped: bool) -> void:
	var count: int = rings.size()
	for i in range(count - 1):
		var a: PackedVector3Array = rings[i]
		var b: PackedVector3Array = rings[i + 1]
		var n: int = a.size()
		var center: Vector3 = (_centroid(a) + _centroid(b)) * 0.5
		for j in n:
			var k: int = (j + 1) % n
			_add_tri(st, a[j], a[k], b[k], center)
			_add_tri(st, a[j], b[k], b[j], center)
	if capped and count >= 2:
		var first: PackedVector3Array = rings[0]
		var second: PackedVector3Array = rings[1]
		var last: PackedVector3Array = rings[count - 1]
		var before_last: PackedVector3Array = rings[count - 2]
		_add_cap(st, first, _centroid(second))
		_add_cap(st, last, _centroid(before_last))


static func _add_cap(st: SurfaceTool, ring: PackedVector3Array, inside_hint: Vector3) -> void:
	var c: Vector3 = _centroid(ring)
	for j in ring.size():
		_add_tri(st, c, ring[j], ring[(j + 1) % ring.size()], inside_hint)


static func _centroid(points: PackedVector3Array) -> Vector3:
	var sum := Vector3.ZERO
	for p in points:
		sum += p
	return sum / float(maxi(points.size(), 1))


## Adds one flat-shaded triangle. `inside_hint` is a point inside the solid, used to decide which
## way is outward. Godot front faces wind clockwise, so the winding is fixed here.
static func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, inside_hint: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	var outward: Vector3 = (a + b + c) / 3.0 - inside_hint
	if n.dot(outward) > 0.0:
		# Counter-clockwise seen from outside: normal is already outward, swap to clockwise.
		var swap: Vector3 = b
		b = c
		c = swap
	else:
		n = -n
	var normal: Vector3 = n.normalized()
	st.set_normal(normal)
	st.add_vertex(a)
	st.set_normal(normal)
	st.add_vertex(b)
	st.set_normal(normal)
	st.add_vertex(c)
