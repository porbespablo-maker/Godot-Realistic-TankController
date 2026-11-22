@tool
class_name TankWheel3D
extends Node3D

enum TrackSide { AUTO, LEFT, RIGHT }

@export_category("Wheel & Suspension")
@export var track_side: TrackSide = TrackSide.AUTO
@export var wheel_radius: float = 0.45:
	set(value):
		wheel_radius = value
		update_gizmos()
@export var suspension_rest_distance: float = 0.3:
	set(value):
		suspension_rest_distance = value
		update_gizmos()
@export var stiffness_multiplier: float = 2.5
@export var damping_ratio: float = 2.5

var raycast: RayCast3D
var mesh_pivot: Node3D
var mesh_start_pos: Vector3 = Vector3.ZERO
var smoothed_compression: float = 0.0
var resolved_side: TrackSide = TrackSide.LEFT
var spring_strength: float = 0.0
var damping_strength: float = 0.0

func setup_wheel(body: RigidBody3D, load_per_wheel: float) -> void:

	raycast = RayCast3D.new()
	raycast.target_position = Vector3.DOWN * (suspension_rest_distance + wheel_radius)
	raycast.enabled = true
	raycast.add_exception(body)
	add_child(raycast)

	
	mesh_pivot = Node3D.new()
	add_child(mesh_pivot)
	for child in get_children():
		if child != raycast and child != mesh_pivot and child is Node3D:
			child.reparent(mesh_pivot, true)
	mesh_start_pos = mesh_pivot.position


	if track_side == TrackSide.AUTO:
		resolved_side = TrackSide.LEFT if position.x <= 0.0 else TrackSide.RIGHT
	else:
		resolved_side = track_side

	var safe_rest: float = max(suspension_rest_distance, 0.01)
	spring_strength = (load_per_wheel / (safe_rest * 0.5)) * stiffness_multiplier
	var wheel_mass := 75.0
	damping_strength = (2.0 * sqrt(spring_strength * wheel_mass)) * damping_ratio

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not get_parent() is TankBody3D:
		warnings.append("TankWheel3D must be a direct child of a TankBody3D node.")
	return warnings
