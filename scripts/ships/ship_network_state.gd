class_name ShipNetworkState
extends Node
## Ownership and replicated-state placeholder for one ship ("MultiplayerSyncRoot").
##
## NO networking happens here. It exists so that later a MultiplayerSynchronizer can be added as a
## sibling/child and be pointed at this node's properties, without touching visuals or physics.
##
## Separation of state (see docs/PHASE_02_LIGHT_FIGHTER.md):
##   - Transform state : the ship root's transform and velocity (captured by capture_state()).
##   - Gameplay state  : thrust, later health/shields/ammo (kept in this node's variables).
##   - Visual state    : derived locally from gameplay state (engine glow); never replicated itself.
##   - Ownership       : owner_peer_id. 1 is the server/host in Godot multiplayer and is also the
##                       local peer when no network peer exists, so single-player is just "owner 1".

@export var owner_peer_id: int = 1

## Gameplay state placeholder (0..1). Phase 03 drives this from the flight system.
var thrust: float = 0.0


## True when this peer owns the ship. Works offline: multiplayer.get_unique_id() returns 1.
func is_owned_locally() -> bool:
	return owner_peer_id == multiplayer.get_unique_id()


## Gives a peer ownership and marks the ship root as that peer's multiplayer authority.
func assign_owner(peer_id: int) -> void:
	owner_peer_id = peer_id
	var ship: Node = get_parent()
	if ship != null:
		ship.set_multiplayer_authority(peer_id)


## Snapshot of everything a remote peer needs to show this ship.
func capture_state() -> Dictionary:
	var ship := get_parent() as Node3D
	var state: Dictionary = {"thrust": thrust}
	if ship != null:
		state["transform"] = ship.global_transform
		var body := ship as CharacterBody3D
		if body != null:
			state["velocity"] = body.velocity
	return state


func apply_state(state: Dictionary) -> void:
	thrust = state.get("thrust", thrust)
	var ship := get_parent() as Node3D
	if ship == null:
		return
	if state.has("transform"):
		ship.global_transform = state["transform"]
	var body := ship as CharacterBody3D
	if body != null and state.has("velocity"):
		body.velocity = state["velocity"]
