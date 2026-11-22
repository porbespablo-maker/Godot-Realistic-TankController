@tool
class_name TankBody3D
extends RigidBody3D

enum VehicleMode { TANK, CAR }

@export_category("Vehicle Setup")
@export var vehicle_mode: VehicleMode = VehicleMode.TANK
@export var left_track_marker: Marker3D
@export var right_track_marker: Marker3D

@export_category("Physics")
@export var tank_mass: float = 45000.0
@export var gravity: float = 9.81
@export var sideways_grip: float = 15.0

@export_category("Engine & Drivetrain")
@export var engine_max_rpm: float = 3000.0
@export var engine_idle_rpm: float = 600.0
@export var horsepower: float = 700.0
@export var max_forward_speed: float = 15.0
@export var max_reverse_speed: float = 6.0
@export var braking_acceleration: float = 6.0
@export var has_neutral_steering: bool = false
@export var engine_multi: float = 1.5
@export var max_car_steer_angle_deg: float = 30.0

@export_category("Controls")
@export var use_input: bool = true
@export var action_forward: StringName = &"ui_up"
@export var action_backward: StringName = &"ui_down"
@export var action_left: StringName = &"ui_left"
@export var action_right: StringName = &"ui_right"


var throttle_input: float = 0.0
var steer_input: float = 0.0
var is_disabled: bool = false
var engine_power_mult: float = 1.0


var current_engine_rpm: float = 600.0
var current_gear: int = 2
var left_track_speed: float = 0.0
var right_track_speed: float = 0.0

var wheels: Array[TankWheel3D] = []
var _left_track_local_pos: Vector3 = Vector3(-1.5, 0.0, 0.0)
var _right_track_local_pos: Vector3 = Vector3(1.5, 0.0, 0.0)
var _lpw: float = 1.0
var _shift_cooldown: float = 0.0
var _smoothed_forward_input: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	mass = tank_mass
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3.ZERO
	linear_damp = 0.05
	angular_damp = 0.05

	_setup_wheels()

func _setup_wheels() -> void:
	wheels.clear()
	for child in get_children():
		if child is TankWheel3D:
			wheels.append(child)

	var wheel_count: int = max(wheels.size(), 1)
	_lpw = (tank_mass * gravity) / float(wheel_count)

	var left_sum := Vector3.ZERO
	var left_count := 0
	var right_sum := Vector3.ZERO
	var right_count := 0

	for wheel in wheels:
		wheel.setup_wheel(self, _lpw)
		if wheel.resolved_side == TankWheel3D.TrackSide.LEFT:
			left_sum += wheel.position
			left_count += 1
		else:
			right_sum += wheel.position
			right_count += 1

	if left_track_marker:
		_left_track_local_pos = to_local(left_track_marker.global_position)
	elif left_count > 0:
		_left_track_local_pos = left_sum / float(left_count)

	if right_track_marker:
		_right_track_local_pos = to_local(right_track_marker.global_position)
	elif right_count > 0:
		_right_track_local_pos = right_sum / float(right_count)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or is_disabled:
		return

	if use_input:
		throttle_input = _read_axis(action_backward, action_forward)
		steer_input = _read_axis(action_left, action_right)

	_apply_suspension(delta)
	_apply_movement(delta)

func _apply_suspension(delta: float) -> void:
	if wheels.is_empty():
		return

	var left_speed_sum := 0.0
	var left_wheels_count := 0
	var right_speed_sum := 0.0
	var right_wheels_count := 0

	for wheel in wheels:
		var ray := wheel.raycast
		var rest := wheel.suspension_rest_distance
		var radius := wheel.wheel_radius
		ray.force_raycast_update()

		var wheel_center: Vector3 = ray.global_position
		var force_position: Vector3 = wheel_center - global_position
		var point_velocity: Vector3 = linear_velocity + angular_velocity.cross(force_position)
		var rolling_speed: float = point_velocity.dot(-global_transform.basis.z)

		if wheel.resolved_side == TankWheel3D.TrackSide.LEFT:
			left_speed_sum += rolling_speed
			left_wheels_count += 1
		else:
			right_speed_sum += rolling_speed
			right_wheels_count += 1

		if not ray.is_colliding():
			wheel.smoothed_compression = lerp(wheel.smoothed_compression, 0.0, 25.0 * delta)
			if wheel.mesh_pivot:
				var target_pos := wheel.mesh_start_pos + (Vector3.UP * wheel.smoothed_compression)
				wheel.mesh_pivot.position = wheel.mesh_pivot.position.lerp(target_pos, 15.0 * delta)
			continue

		var ground_point: Vector3 = ray.get_collision_point()
		var distance: float = wheel_center.distance_to(ground_point)
		var raw_compression: float = rest - (distance - radius)
		var compression: float = clamp(raw_compression, 0.0, rest)

		wheel.smoothed_compression = lerp(wheel.smoothed_compression, compression, 25.0 * delta)

		if wheel.mesh_pivot:
			var target_pivot_pos := wheel.mesh_start_pos + (Vector3.UP * wheel.smoothed_compression)
			wheel.mesh_pivot.position = wheel.mesh_pivot.position.lerp(target_pivot_pos, 20.0 * delta)

			if vehicle_mode == VehicleMode.CAR and wheel.position.z < 0.0:
				wheel.rotation.y = lerp_angle(wheel.rotation.y, -steer_input * deg_to_rad(max_car_steer_angle_deg), 15.0 * delta)

			var wheel_rot_delta: float = (rolling_speed / max(radius, 0.01)) * delta
			wheel.mesh_pivot.rotate_object_local(Vector3.RIGHT, wheel_rot_delta)

		if compression <= 0.0:
			continue

		var suspension_velocity: float = point_velocity.dot(Vector3.UP)
		var spring_force: float = compression * wheel.spring_strength
		var damping_force: float = suspension_velocity * wheel.damping_strength
		var total_force: float = spring_force - damping_force

		apply_force(Vector3.UP * total_force, force_position)

		var tank_right: Vector3 = global_transform.basis.x.normalized()
		var lateral_speed: float = point_velocity.dot(tank_right)
		var lateral_grip_force: Vector3 = -tank_right * lateral_speed * (sideways_grip * 200.0) * (total_force / max(_lpw, 1.0))
		apply_force(lateral_grip_force, force_position)

	if left_wheels_count > 0:
		left_track_speed = left_speed_sum / float(left_wheels_count)
	if right_wheels_count > 0:
		right_track_speed = right_speed_sum / float(right_wheels_count)

func _apply_movement(delta: float) -> void:
	_smoothed_forward_input = move_toward(_smoothed_forward_input, throttle_input, delta * 4.0)
	var forward_input := _smoothed_forward_input
	var turn_input := steer_input

	var forward_direction: Vector3 = (-global_transform.basis.z).normalized()
	var forward_speed: float = linear_velocity.dot(forward_direction)
	var right_direction: Vector3 = global_transform.basis.x
	var lateral_speed: float = linear_velocity.dot(right_direction)
	apply_central_force(-right_direction * lateral_speed * mass * 4.0)

	var gears: Array[float] = [-1.0, 0.0, 2.0, 3.5, 5.5, 7.5, 9.5, 11.5, 13.0]
	var gear_torque_mults: Array[float] = [0.8, 0.0, 1.6, 1.45, 1.3, 1.15, 1.05, 0.95, 0.9]

	if _shift_cooldown > 0.0:
		_shift_cooldown -= delta

	if forward_input < -0.1:
		current_gear = 0
	elif abs(forward_input) < 0.01 and abs(forward_speed) < 0.5:
		current_gear = 2 if abs(turn_input) > 0.05 else 1
	else:
		if current_gear <= 1 and forward_input > 0.1:
			current_gear = 2
		var min_speed_for_upshift := gears[current_gear] * 0.65
		if forward_input > 0.1 and current_gear < gears.size() - 1 and _shift_cooldown <= 0.0:
			if current_engine_rpm >= engine_max_rpm * 0.75 and forward_speed >= min_speed_for_upshift:
				current_gear += 1
				_shift_cooldown = 0.5
		elif current_gear > 2 and _shift_cooldown <= 0.0:
			var lower_speed_threshold := gears[current_gear - 1] * 0.55
			if current_engine_rpm <= engine_idle_rpm + 200.0 or forward_speed < lower_speed_threshold:
				current_gear -= 1
				_shift_cooldown = 0.4

	var throttle := absf(forward_input)
	var target_engine_rpm := engine_idle_rpm + (throttle * (engine_max_rpm - engine_idle_rpm))
	current_engine_rpm = clamp(move_toward(current_engine_rpm, target_engine_rpm, delta * 1200.0), engine_idle_rpm, engine_max_rpm)

	var power_watts := horsepower * 745.7 * engine_power_mult
	var current_speed_ms: float = max(abs(forward_speed), 1.0)
	var available_drive_force := (power_watts / current_speed_ms) * clampf(current_engine_rpm / engine_max_rpm, 0.5, 1.0) * gear_torque_mults[current_gear]
	available_drive_force = minf(available_drive_force, tank_mass * engine_multi)

	if (current_gear == 0 and forward_speed < -max_reverse_speed) or (forward_input > 0.0 and forward_speed > max_forward_speed):
		available_drive_force = 0.0

	var left_track_offset := global_transform.basis * _left_track_local_pos
	var right_track_offset := global_transform.basis * _right_track_local_pos

	if vehicle_mode == VehicleMode.CAR:
		if abs(forward_input) > 0.001 and engine_power_mult > 0.0:
			apply_central_force(forward_direction * forward_input * available_drive_force)
			if abs(forward_speed) > 0.2:
				apply_torque(Vector3.UP * -turn_input * sign(forward_speed) * mass * 1.5)
		else:
			var brake_amount: float = min(abs(forward_speed), braking_acceleration * delta)
			if abs(forward_speed) > 0.001:
				apply_central_force(-forward_direction * sign(forward_speed) * brake_amount * mass / delta)
		return


	var left_power: float = forward_input
	var right_power: float = forward_input

	if has_neutral_steering:
		left_power += turn_input
		right_power -= turn_input
	else:
		if abs(forward_input) < 0.001:
			if turn_input > 0.0:
				left_power = 1.0
				right_power = 0.0
				apply_force(-forward_direction * forward_speed * (mass * 0.2), right_track_offset)
			elif turn_input < 0.0:
				left_power = 0.0
				right_power = 1.0
				apply_force(-forward_direction * forward_speed * (mass * 0.2), left_track_offset)
		else:
			if turn_input > 0.0:
				right_power *= (1.0 - abs(turn_input))
				apply_force(-forward_direction * forward_speed * abs(turn_input) * (mass * 0.1), right_track_offset)
			elif turn_input < 0.0:
				left_power *= (1.0 - abs(turn_input))
				apply_force(-forward_direction * forward_speed * abs(turn_input) * (mass * 0.1), left_track_offset)

	if (abs(forward_input) > 0.001 or abs(turn_input) > 0.001) and engine_power_mult > 0.0:
		var power_scalar := 0.65 if (abs(forward_input) < 0.001 and abs(turn_input) > 0.001) else 0.5
		if abs(forward_input) > 0.001 and abs(turn_input) > 0.001:
			apply_central_force(-forward_direction * forward_speed * abs(turn_input) * (mass * 0.15))

		apply_force(forward_direction * left_power * available_drive_force * power_scalar, left_track_offset)
		apply_force(forward_direction * right_power * available_drive_force * power_scalar, right_track_offset)
	else:
		var brake_amount: float = min(abs(forward_speed), braking_acceleration * delta)
		if abs(forward_speed) > 0.001:
			apply_central_force(-forward_direction * sign(forward_speed) * brake_amount * mass / delta)

	if abs(turn_input) < 0.05:
		angular_velocity.y = move_toward(angular_velocity.y, 0.0, delta * 1.5)
		if abs(forward_input) < 0.01:
			apply_central_force(-forward_direction * forward_speed * (mass * 0.5))
	else:
		angular_velocity.y = clamp(angular_velocity.y, -2.0, 2.0)

func _read_axis(neg_action: StringName, pos_action: StringName) -> float:
	if InputMap.has_action(neg_action) and InputMap.has_action(pos_action):
		return Input.get_axis(neg_action, pos_action)
	return 0.0

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	var has_wheel := false
	var has_collider := false
	for child in get_children():
		if child is TankWheel3D:
			has_wheel = true
		elif child is CollisionShape3D or child is CollisionPolygon3D:
			has_collider = true
	if not has_collider:
		warnings.append("TankBody3D needs a CollisionShape3D child to collide with the world.")
	if not has_wheel:
		warnings.append("Add TankWheel3D child nodes for suspension and movement.")
	return warnings
