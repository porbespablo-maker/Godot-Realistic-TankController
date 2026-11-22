@tool
extends EditorNode3DGizmoPlugin

func _init() -> void:
	create_material("suspension_line", Color(0.2, 0.9, 0.4), false, true)
	create_material("wheel_circle", Color(1.0, 0.7, 0.2), false, true)

func _get_gizmo_name() -> String:
	return "TankWheel3DGizmo"

func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is TankWheel3D

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var wheel := gizmo.get_node_3d() as TankWheel3D
	if not wheel:
		return

	var rest := wheel.suspension_rest_distance
	var radius := wheel.wheel_radius

	var lines := PackedVector3Array([
		Vector3.ZERO,
		Vector3.DOWN * (rest + radius),
		Vector3(-0.08, -rest, 0.0),
		Vector3(0.08, -rest, 0.0)
	])
	gizmo.add_lines(lines, get_material("suspension_line", gizmo), false)

	var circle_lines := PackedVector3Array()
	var segments := 24
	for i in segments:
		var a0 := (float(i) / segments) * TAU
		var a1 := (float(i + 1) / segments) * TAU
		circle_lines.append(Vector3(0.0, cos(a0) * radius, sin(a0) * radius))
		circle_lines.append(Vector3(0.0, cos(a1) * radius, sin(a1) * radius))
	gizmo.add_lines(circle_lines, get_material("wheel_circle", gizmo), false)
