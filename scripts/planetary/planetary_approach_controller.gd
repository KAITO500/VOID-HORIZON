class_name PlanetaryApproachController
extends Node
## Samples planetary scale against navigation telemetry; never changes the ship or camera.

signal approach_state_changed(planet_id: StringName, previous_state: int, new_state: int)
signal approach_updated(snapshot: PlanetaryApproachSnapshot)

enum State { SPACE, PLANET_APPROACH, ORBITAL_REGION, ATMOSPHERE_ENTRY, ATMOSPHERE_TRANSITION, ATMOSPHERE_ACTIVE }
const STATE_NAMES: PackedStringArray = ["SPACE", "PLANET APPROACH", "ORBITAL REGION", "ATMOSPHERE ENTRY", "ATMOSPHERE TRANSITION", "ATMOSPHERE ACTIVE"]

@export var telemetry_path: NodePath
@export var target_manager_path: NodePath
@export var space_environment_path: NodePath
@export_range(0.01, 2.0, 0.01) var update_interval: float = 0.033

var snapshot: PlanetaryApproachSnapshot
var _telemetry: NavigationTelemetry
var _target_manager: NavigationTargetManager
var _space_environment: SpaceEnvironment
var _last_position: Vector3
var _has_last_position: bool = false
var _elapsed: float = 0.0
var _active_planet: PlanetaryBody


func _ready() -> void:
	_telemetry = get_node_or_null(telemetry_path) as NavigationTelemetry
	_target_manager = get_node_or_null(target_manager_path) as NavigationTargetManager
	_space_environment = get_node_or_null(space_environment_path) as SpaceEnvironment
	if _telemetry == null:
		push_error("PlanetaryApproachController: telemetry_path must resolve to NavigationTelemetry.")
		set_physics_process(false)
		return
	var initial := _telemetry.snapshot
	if initial != null and initial.position != null:
		_last_position = initial.position.coordinates
		_has_last_position = true


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < update_interval:
		return
	_elapsed = 0.0
	capture_now()


func capture_now() -> PlanetaryApproachSnapshot:
	if _telemetry == null:
		return null
	var sample := _telemetry.capture_now()
	if sample == null or sample.position == null:
		return null
	var ship_position: Vector3 = sample.position.coordinates
	var planet := _resolve_planet(ship_position)
	if planet == null or planet.profile == null or not planet.profile.available:
		_set_planet_blend(_active_planet, 0.0)
		_active_planet = null
		if _space_environment != null:
			_space_environment.set_atmosphere_transition(Color.WHITE, 0.0)
		var old_state: int = snapshot.state if snapshot != null else State.SPACE
		if old_state != State.SPACE:
			approach_state_changed.emit(snapshot.planet_id, old_state, State.SPACE)
		snapshot = null
		_last_position = ship_position
		_has_last_position = true
		return null
	if planet != _active_planet:
		_set_planet_blend(_active_planet, 0.0)
		if snapshot != null and snapshot.state != State.SPACE:
			approach_state_changed.emit(snapshot.planet_id, snapshot.state, State.SPACE)
		_active_planet = planet
		_has_last_position = false
		if _space_environment != null:
			_space_environment.set_atmosphere_transition(Color.WHITE, 0.0)

	var profile: PlanetProfile = planet.profile
	var offset: Vector3 = planet.global_position - ship_position
	var distance_m: float = offset.length()
	var altitude_m: float = distance_m - profile.radius_m
	var previous_state: int = snapshot.state if snapshot != null and snapshot.planet_id == profile.planet_id else State.SPACE
	var previous_distance: float = _last_position.distance_to(planet.global_position) if _has_last_position else distance_m
	var desired_state: int = _classify(distance_m, profile, previous_distance)
	var old_position: Vector3 = _last_position if _has_last_position else ship_position
	var crossed_states: Array[int] = _swept_states(old_position, ship_position, planet.global_position, profile, previous_state, desired_state)
	for next_state: int in crossed_states:
		approach_state_changed.emit(profile.planet_id, previous_state, next_state)
		previous_state = next_state

	var result := PlanetaryApproachSnapshot.new()
	result.planet_id = profile.planet_id
	result.planet_name = profile.display_name
	result.distance_to_center_m = distance_m
	result.altitude_m = altitude_m
	result.distance_to_atmosphere_m = altitude_m - profile.atmosphere_height_m
	result.direction_to_planet = offset.normalized() if distance_m > 0.001 else Vector3.ZERO
	result.atmosphere_progress = clampf((profile.get_atmosphere_radius_m() - distance_m) / maxf(profile.atmosphere_height_m, 1.0), 0.0, 1.0)
	result.approach_progress = clampf(1.0 - distance_m / maxf(profile.get_approach_radius_m(), 1.0), 0.0, 1.0)
	result.state = desired_state
	result.state_name = STATE_NAMES[desired_state]
	snapshot = result
	var visual_blend: float = smoothstep(0.0, profile.get_approach_radius_m(), maxf(0.0, profile.get_approach_radius_m() - distance_m))
	_set_planet_blend(planet, visual_blend)
	if _space_environment != null:
		_space_environment.set_atmosphere_transition(profile.atmosphere_color, result.atmosphere_progress * profile.sky_blend_strength)
	_last_position = ship_position
	_has_last_position = true
	approach_updated.emit(snapshot)
	return snapshot


func get_current_snapshot() -> PlanetaryApproachSnapshot:
	return snapshot


func get_state_name(value: int) -> String:
	return STATE_NAMES[clampi(value, 0, STATE_NAMES.size() - 1)]


func _resolve_planet(ship_position: Vector3) -> PlanetaryBody:
	if _target_manager != null:
		var target := _target_manager.get_selected_target()
		if target != null and target.category == NavigationTarget.Category.PLANET:
			for node: Node in get_tree().get_nodes_in_group("navigation_planets"):
				var candidate := node as PlanetaryBody
				if candidate != null and candidate.profile != null and candidate.profile.planet_id == target.id and candidate.profile.available:
					return candidate
	var nearest: PlanetaryBody
	var nearest_distance: float = INF
	for node: Node in get_tree().get_nodes_in_group("navigation_planets"):
		var candidate := node as PlanetaryBody
		if candidate == null or candidate.profile == null or not candidate.profile.available:
			continue
		var distance: float = ship_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	return nearest


func _classify(distance_m: float, profile: PlanetProfile, previous_distance: float) -> int:
	var hysteresis: float = profile.boundary_hysteresis_m
	var threshold_offset: float = hysteresis if distance_m >= previous_distance else -hysteresis
	var progress_entry_radius: float = profile.radius_m + profile.atmosphere_height_m * (1.0 - profile.transition_start_progress)
	var progress_active_radius: float = profile.radius_m + profile.atmosphere_height_m * (1.0 - profile.active_start_progress)
	if distance_m > profile.get_approach_radius_m() + threshold_offset: return State.SPACE
	if distance_m > profile.get_orbital_radius_m() + threshold_offset: return State.PLANET_APPROACH
	if distance_m > profile.get_atmosphere_radius_m() + threshold_offset: return State.ORBITAL_REGION
	if distance_m > progress_entry_radius + threshold_offset: return State.ATMOSPHERE_ENTRY
	if distance_m > progress_active_radius + threshold_offset: return State.ATMOSPHERE_TRANSITION
	return State.ATMOSPHERE_ACTIVE


func _swept_states(start: Vector3, finish: Vector3, center: Vector3, profile: PlanetProfile, old_state: int, new_state: int) -> Array[int]:
	var result: Array[int] = []
	var direction: Vector3 = finish - start
	if direction.length_squared() < 0.000001:
		if old_state != new_state:
			_append_state_sequence(result, old_state, new_state)
		return result
	var radii: PackedFloat64Array = PackedFloat64Array([
		profile.get_approach_radius_m(), profile.get_orbital_radius_m(),
		profile.get_atmosphere_radius_m(),
		profile.radius_m + profile.atmosphere_height_m * (1.0 - profile.transition_start_progress),
		profile.radius_m + profile.atmosphere_height_m * (1.0 - profile.active_start_progress),
	])
	var intersections: Array[float] = [0.0, 1.0]
	var relative: Vector3 = start - center
	var a: float = direction.dot(direction)
	for radius_m: float in radii:
		var b: float = 2.0 * relative.dot(direction)
		var c: float = relative.dot(relative) - radius_m * radius_m
		var discriminant: float = b * b - 4.0 * a * c
		if discriminant < 0.0:
			continue
		var root: float = sqrt(discriminant)
		var t0: float = (-b - root) / (2.0 * a)
		var t1: float = (-b + root) / (2.0 * a)
		if t0 > 0.0 and t0 < 1.0: intersections.append(t0)
		if t1 > 0.0 and t1 < 1.0: intersections.append(t1)
	intersections.sort()
	var path_state: int = old_state
	for index: int in range(intersections.size() - 1):
		var midpoint: float = (intersections[index] + intersections[index + 1]) * 0.5
		var point: Vector3 = start + direction * midpoint
		var radius_at_midpoint: float = point.distance_to(center)
		var segment_state: int = _classify(radius_at_midpoint, profile, radius_at_midpoint - 0.01)
		if segment_state != path_state:
			_append_state_sequence(result, path_state, segment_state)
			path_state = segment_state
	if path_state != new_state:
		_append_state_sequence(result, path_state, new_state)
	return result


func _append_state_sequence(result: Array[int], from_state: int, to_state: int) -> void:
	var step: int = 1 if to_state > from_state else -1
	for state_index: int in range(from_state + step, to_state + step, step):
		if result.is_empty() or result.back() != state_index:
			result.append(state_index)


func _set_planet_blend(planet: PlanetaryBody, value: float) -> void:
	if planet != null and is_instance_valid(planet):
		planet.set_approach_blend(value)
