class_name NavigationTargetManager
extends Node
## Player selection state, separated from the registry and world scenes.

signal selected_target_changed(target: NavigationTarget)

@export var registry_path: NodePath

var selected_target_id: StringName = &""
var _registry: NavigationTargetRegistry


func _ready() -> void:
	_registry = get_node_or_null(registry_path) as NavigationTargetRegistry
	if _registry == null:
		push_error("NavigationTargetManager: registry_path must resolve to NavigationTargetRegistry.")
		return
	_registry.target_unregistered.connect(_on_target_unregistered)


func select_target(target_id: StringName) -> bool:
	if _registry == null:
		return false
	var target := _registry.get_target(target_id)
	if target == null or not target.is_available() or not target.discovered or not target.navigation_visible:
		return false
	selected_target_id = target_id
	selected_target_changed.emit(target)
	return true


func cycle_target(step: int = 1) -> bool:
	if _registry == null:
		return false
	var targets := _registry.get_targets()
	if targets.is_empty():
		clear_target()
		return false
	var current_index := -1
	for index in targets.size():
		if targets[index].id == selected_target_id:
			current_index = index
			break
	var next_index := posmod(current_index + (1 if step >= 0 else -1), targets.size())
	return select_target(targets[next_index].id)


func clear_target() -> void:
	if selected_target_id == &"":
		return
	selected_target_id = &""
	selected_target_changed.emit(null)


func get_selected_target() -> NavigationTarget:
	if _registry == null or selected_target_id == &"":
		return null
	var target := _registry.get_target(selected_target_id)
	if target == null or not target.is_available() or not target.navigation_visible or not target.discovered:
		clear_target()
		return null
	return target


func _on_target_unregistered(target_id: StringName) -> void:
	if target_id == selected_target_id:
		clear_target()
