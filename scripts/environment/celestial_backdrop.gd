class_name CelestialBackdrop
extends SkyAnchor
## Container for distant celestial bodies (planets, moons, stars, asteroid fields, stations).
##
## Follows the camera (see SkyAnchor) so its children read as effectively infinitely far away.
## Add CelestialBody nodes as children, in the scene or with add_body().
## Real, approachable planets are a later phase and will not live here.


func add_body(body: CelestialBody) -> void:
	add_child(body)


func get_bodies() -> Array[CelestialBody]:
	var bodies: Array[CelestialBody] = []
	for child in get_children():
		var body := child as CelestialBody
		if body != null:
			bodies.append(body)
	return bodies


## Largest body distance in this backdrop; the camera far plane must exceed it.
func get_max_distance() -> float:
	var max_distance: float = 0.0
	for body in get_bodies():
		max_distance = maxf(max_distance, body.distance + body.get_radius())
	return max_distance
