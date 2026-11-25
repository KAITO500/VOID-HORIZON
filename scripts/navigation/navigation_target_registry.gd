class_name NavigationTargetRegistry
extends Node
## Scene-local registry for discoverable points of interest and other navigation targets.

signal target_registered(target: NavigationTarget)
signal target_unregistered(target_id: StringName)

var _targets: Dictionary = {}


func register_target(target: NavigationTarget) -> bool:
	if target == null or target.id == &"" or _targets.has(target.id) or not target.is_available():
		return false
	_targets[target.id] = target
	target_registered.emit(target)
	return true


func register_node_target(target: NavigationTarget, node: Node3D) -> bool:
	if target == null or node == null:
		return false
	target.bind_node(node)
	return register_target(target)


func unregister_target(target_id: StringName) -> bool:
	if not _targets.has(target_id):
		return false
	_targets.erase(target_id)
	target_unregistered.emit(target_id)
	return true


func get_target(target_id: StringName) -> NavigationTarget:
	return _targets.get(target_id) as NavigationTarget


func get_targets(category: int = -1, visible_only: bool = true, discovered_only: bool = true) -> Array[NavigationTarget]:
	var result: Array[NavigationTarget] = []
	for value: Variant in _targets.values():
		var target := value as NavigationTarget
		if target == null or not target.is_available():
			continue
		if category >= 0 and target.category != category:
			continue
		if visible_only and not target.navigation_visible:
			continue
		if discovered_only and not target.discovered:
			continue
		result.append(target)
	result.sort_custom(func(a: NavigationTarget, b: NavigationTarget) -> bool: return String(a.id) < String(b.id))
	return result


func get_target_count() -> int:
	return _targets.size()
