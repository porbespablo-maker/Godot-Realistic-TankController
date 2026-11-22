
@tool
extends EditorPlugin

const WheelGizmoPlugin = preload("res://addons/realistic_vehicles/tank_wheel_gizmo.gd")
var _gizmo_plugin: EditorNode3DGizmoPlugin

func _enter_tree() -> void:
	_gizmo_plugin = WheelGizmoPlugin.new()
	add_node_3d_gizmo_plugin(_gizmo_plugin)

func _exit_tree() -> void:
	if _gizmo_plugin:
		remove_node_3d_gizmo_plugin(_gizmo_plugin)
		_gizmo_plugin = null
