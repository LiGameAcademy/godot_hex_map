extends Window

@onready var button_small: Button = %ButtonSmall
@onready var button_medium: Button = %ButtonMedium
@onready var button_large: Button = %ButtonLarge

@export var editor: HexMapEditor

func _ready() -> void:
	hide()
	close_requested.connect(close)
	button_small.pressed.connect(func() -> void: _create_map(20, 15))
	button_medium.pressed.connect(func() -> void: _create_map(40, 30))
	button_large.pressed.connect(func() -> void: _create_map(80, 60))

func open() -> void:
	var camera : HexMapCamera = get_tree().get_first_node_in_group("Camera")
	if is_instance_valid(camera):
		camera.set_camera_locked(true)
	popup_centered()

func close() -> void:
	var camera : HexMapCamera = get_tree().get_first_node_in_group("Camera")
	if is_instance_valid(camera):
		camera.set_camera_locked(false)
	hide()

func _create_map(cell_x: int, cell_z: int) -> void:
	if is_instance_valid(editor):
		editor.create_map_sized(cell_x, cell_z)
	var camera : HexMapCamera = get_tree().get_first_node_in_group("Camera")
	if is_instance_valid(camera):
		camera.validate_position()
