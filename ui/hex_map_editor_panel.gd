extends MarginContainer

@onready var option_button_color: OptionButton = %OptionButtonColor
@onready var spin_box_elevation: SpinBox = %SpinBoxElevation
@onready var check_box_elevation: CheckBox = %CheckBoxElevation
@onready var spin_box_brush_size: SpinBox = %SpinBoxBrushSize
@onready var option_button_river: OptionButton = %OptionButtonRiver
@onready var option_button_road: OptionButton = %OptionButtonRoad
@onready var refresh_button: Button = %RefreshButton
@onready var spin_box_water: SpinBox = %SpinBoxWater
@onready var check_box_water: CheckBox = %CheckBoxWater

## 表现层：负责 UI 展示与交互输入，依赖 HexMapEditor 逻辑层的 API / signal
@export var editor: HexMapEditor

var _syncing_mode_ui: bool = false

func _ready() -> void:
	if editor == null:
		return

	# 1）初始化 UI 为逻辑层当前状态
	option_button_color.clear()
	option_button_color.add_item("忽略")
	for color_name in editor.colors:
		option_button_color.add_item(color_name)
	if editor.disable_color:
		option_button_color.selected = 0
	else:
		option_button_color.selected = editor.active_color + 1
	spin_box_elevation.value = editor.active_elevation
	check_box_elevation.button_pressed = not editor.disable_elevation
	spin_box_brush_size.value = editor.brush_radius
	spin_box_water.value = editor.active_water_level
	check_box_water.button_pressed = not editor.disable_water_level
	
	_syncing_mode_ui = true
	option_button_river.select(int(editor.river_mode))
	option_button_road.select(int(editor.road_mode))
	_syncing_mode_ui = false

	editor.river_mode_changed.connect(_on_editor_river_mode_changed)
	editor.road_mode_changed.connect(_on_editor_road_mode_changed)
	
	option_button_color.item_selected.connect(
		func(index : int) -> void:
			if index == 0:
				editor.set_disable_color(true)
			else:
				editor.set_active_color(index - 1)
	)
	spin_box_elevation.value_changed.connect(
		func(value: float) -> void:
			editor.set_active_elevation(int(value))
	)
	check_box_elevation.toggled.connect(
		func(toggled_on: bool) -> void:
			editor.set_disable_elevation(toggled_on)
			spin_box_elevation.editable = toggled_on
	)
	spin_box_water.value_changed.connect(
		func(value: float) -> void:
			editor.set_water_level(int(value))
	)
	check_box_water.toggled.connect(
		func(toggled_on: bool) -> void:
			editor.set_disable_water_level(toggled_on)
			spin_box_water.editable = toggled_on
	)
	spin_box_brush_size.value_changed.connect(
		func(value: float) -> void:
			editor.set_brush_radius(int(value))
	)
	option_button_river.item_selected.connect(
		func(index : int) -> void:
			if _syncing_mode_ui or not is_instance_valid(editor):
				return
			#editor.river_mode = index as HexMapEditor.RiverMode
			editor.set_river_mode(index as HexMapEditor.RiverMode)
	)
	option_button_road.item_selected.connect(
		func(index : int) -> void:
			if _syncing_mode_ui or not is_instance_valid(editor):
				return
			#editor.road_mode = index as HexMapEditor.RoadMode
			editor.set_road_mode(index as HexMapEditor.RoadMode)
	)
	refresh_button.pressed.connect(
		func() -> void:
			editor.refresh()
	)

func _on_editor_river_mode_changed(_mode: HexMapEditor.RiverMode) -> void:
	if not is_instance_valid(editor):
		return
	_syncing_mode_ui = true
	option_button_river.select(int(editor.river_mode))
	_syncing_mode_ui = false

func _on_editor_road_mode_changed(_mode: HexMapEditor.RoadMode) -> void:
	if not is_instance_valid(editor):
		return
	_syncing_mode_ui = true
	option_button_road.select(int(editor.road_mode))
	_syncing_mode_ui = false
