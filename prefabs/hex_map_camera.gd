extends Node3D
class_name HexMapCamera

@onready var swivel: Node3D = %Swivel
@onready var spring_arm: SpringArm3D = %SpringArm3D

@export var grid: HexGrid

@export var length_max_zoom := 250.0
@export var length_min_zoom := 45.0
@export var swivel_angle_far := -90.0   # 最远时俯仰（度，负=向下）
@export var swivel_angle_near := -45.0  # 最近时俯仰

@export var move_speed_min_zoom := 400.0
@export var move_speed_max_zoom := 100.0
@export var rotation_speed := 72.0
@export var zoom_wheel_step := 0.06
@export var zoom_sensitivity := 1.0
@export var zoom_middle_drag_scale := 0.002

var _zoom := 1.0
var _rotation_angle := 0.0
var _middle_zoom_dragging := false

func _ready() -> void:
	_center_on_grid()
	_apply_zoom()

func _process(delta: float) -> void:
	var rotation_delta := Input.get_axis("ui_rotate_left", "ui_rotate_right")
	if rotation_delta != 0.0:
		_adjust_rotation(rotation_delta, delta)
	var x_delta := Input.get_axis("ui_left", "ui_right")
	var z_delta := Input.get_axis("ui_up", "ui_down")

	if x_delta != 0.0 or z_delta != 0.0:
		_adjust_position(x_delta, z_delta, delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_middle_zoom_dragging = event.pressed
			get_viewport().set_input_as_handled()
		elif event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_adjust_zoom(zoom_wheel_step * zoom_sensitivity)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_adjust_zoom(-zoom_wheel_step * zoom_sensitivity)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _middle_zoom_dragging:
		# 上移拉近（_zoom↑）、下移拉远；与多数 RTS 相反时可改符号
		_adjust_zoom(-event.relative.y * zoom_middle_drag_scale * zoom_sensitivity)
		get_viewport().set_input_as_handled()

func _adjust_position(x_delta: float, z_delta: float, dt: float) -> void:
	var direction := (transform.basis * Vector3(x_delta, 0.0, z_delta)).normalized()
	var damping : float = max(abs(x_delta), abs(z_delta))
	var speed : float = lerp(move_speed_min_zoom, move_speed_max_zoom, _zoom)
	var local_position := global_position + direction * speed * damping * dt
	global_position = _clamp_position(local_position)

func _clamp_position(local_position: Vector3) -> Vector3:
	if not is_instance_valid(grid):
		return local_position
	var x_max := (grid.chunk_count_x * HexMetrics.CHUNK_SIZE_X - 0.5) * (HexMetrics.INNER_RADIUS * 2.0)
	var z_max := (grid.chunk_count_z * HexMetrics.CHUNK_SIZE_Z - 1.0) * (HexMetrics.OUTER_RADIUS * 1.5)
	local_position.x = clamp(local_position.x, 0.0, x_max)
	local_position.z = clamp(local_position.z, 0.0, z_max)
	return local_position

func _adjust_rotation(delta: float, dt: float) -> void:
	_rotation_angle += delta * rotation_speed * dt
	if _rotation_angle < 0.0:
		_rotation_angle += 360.0
	elif _rotation_angle >= 360.0:
		_rotation_angle -= 360.0
	rotation_degrees.y = _rotation_angle

func _adjust_zoom(delta: float) -> void:
	_zoom = clamp(_zoom + delta, 0.0, 1.0)
	_apply_zoom()

func _apply_zoom() -> void:
	spring_arm.spring_length = lerp(length_max_zoom, length_min_zoom, _zoom)
	swivel.rotation_degrees.x = lerp(swivel_angle_far, swivel_angle_near, _zoom)

func _center_on_grid() -> void:
	if not is_instance_valid(grid):
		return
	var x_max := (grid.chunk_count_x * HexMetrics.CHUNK_SIZE_X - 0.5) * (HexMetrics.INNER_RADIUS * 2.0)
	var z_max := (grid.chunk_count_z * HexMetrics.CHUNK_SIZE_Z - 1.0) * (HexMetrics.OUTER_RADIUS * 1.5)
	global_position = Vector3(x_max * 0.5, 0.0, z_max * 0.5)
