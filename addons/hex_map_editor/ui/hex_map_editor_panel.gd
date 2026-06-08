extends MarginContainer
class_name HexMapEditorPanel

#@onready var option_button_color: OptionButton = %OptionButtonColor
@onready var spin_box_terrain_type: SpinBox = %SpinBoxTerrainType
@onready var check_box_terrain_type: CheckBox = %CheckBoxTerrainType
@onready var spin_box_elevation: SpinBox = %SpinBoxElevation
@onready var check_box_elevation: CheckBox = %CheckBoxElevation
@onready var spin_box_brush_size: SpinBox = %SpinBoxBrushSize
@onready var option_button_river: OptionButton = %OptionButtonRiver
@onready var option_button_road: OptionButton = %OptionButtonRoad
@onready var refresh_button: Button = %RefreshButton
@onready var spin_box_water: SpinBox = %SpinBoxWater
@onready var check_box_water: CheckBox = %CheckBoxWater
@onready var spin_box_urban_level: SpinBox = %SpinBoxUrbanLevel
@onready var check_box_urban_level: CheckBox = %CheckBoxUrbanLevel
@onready var spin_box_farm_level: SpinBox = %SpinBoxFarmLevel
@onready var check_box_farm_level: CheckBox = %CheckBoxFarmLevel
@onready var spin_box_plant_level: SpinBox = %SpinBoxPlantLevel
@onready var check_box_plant_level: CheckBox = %CheckBoxPlantLevel
@onready var option_button_walled: OptionButton = %OptionButtonWalled
@onready var spin_box_special: SpinBox = %SpinBoxSpecial
@onready var check_box_special: CheckBox = %CheckBoxSpecial
@onready var button_load: Button = %ButtonLoad
@onready var button_save: Button = %ButtonSave
@onready var button_new_map: Button = %ButtonNewMap

## 表现层：负责 UI 展示与交互输入，依赖 HexMapEditor 逻辑层的 API / signal
@export var editor: HexMapEditor
@export var new_map_menu : Window
@export var save_load_menu : SaveLoadMenu

var _syncing_mode_ui: bool = false

func _ready() -> void:
	if editor == null:
		return

	spin_box_terrain_type.value = editor.active_terrain_type_index
	check_box_terrain_type.button_pressed = editor.apply_terrain_type_index
	spin_box_elevation.value = editor.active_elevation
	check_box_elevation.button_pressed = not editor.disable_elevation
	spin_box_brush_size.value = editor.brush_radius
	spin_box_water.value = editor.active_water_level
	check_box_water.button_pressed = not editor.disable_water_level
	
	_syncing_mode_ui = true
	option_button_river.select(int(editor.river_mode))
	option_button_road.select(int(editor.road_mode))
	_syncing_mode_ui = false

	spin_box_urban_level.value = editor.active_urban_level
	check_box_urban_level.button_pressed = editor.apply_urban_level
	spin_box_farm_level.value = editor.active_farm_level
	check_box_farm_level.button_pressed = editor.apply_farm_level
	spin_box_plant_level.value = editor.active_plant_level
	check_box_plant_level.button_pressed = editor.apply_plant_level

	spin_box_special.value = editor.active_special_index
	check_box_special.button_pressed = editor.apply_special_index

	option_button_walled.selected = editor.walled_mode

	editor.river_mode_changed.connect(_on_editor_river_mode_changed)
	editor.road_mode_changed.connect(_on_editor_road_mode_changed)
	
	#option_button_color.item_selected.connect(
		#func(index : int) -> void:
			#if index == 0:
				#editor.set_disable_color(true)
			#else:
				#editor.set_active_color(index - 1)
	#)
	spin_box_terrain_type.value_changed.connect(
		func(value: float) -> void:
			editor.set_terrain_type_index(int(value))
	)
	check_box_terrain_type.toggled.connect(
		func(toggled_on: bool) -> void:
			editor.set_apply_terrain_type_index(toggled_on)
			spin_box_terrain_type.editable = toggled_on
	)
	spin_box_elevation.value_changed.connect(
		func(value: float) -> void:
			editor.set_active_elevation(int(value))
	)
	check_box_elevation.toggled.connect(
		func(toggled_on: bool) -> void:
			editor.set_disable_elevation(not toggled_on)
			spin_box_elevation.editable = toggled_on
	)
	spin_box_water.value_changed.connect(
		func(value: float) -> void:
			editor.set_water_level(int(value))
	)
	check_box_water.toggled.connect(
		func(toggled_on: bool) -> void:
			editor.set_disable_water_level(not toggled_on)
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
	spin_box_urban_level.value_changed.connect(
		func(value: float) -> void:
			editor.set_active_urban_level(int(value))
	)
	check_box_urban_level.toggled.connect(
		func(toggled_on: bool) -> void:
			editor.set_apply_urban_level(toggled_on)
			spin_box_urban_level.editable = toggled_on
	)
	spin_box_farm_level.value_changed.connect(
		func(value: float) -> void:
			editor.set_active_farm_level(int(value))
	)
	check_box_farm_level.toggled.connect(
		func(toggled_on: bool) -> void:
			editor.set_apply_farm_level(toggled_on)
			spin_box_farm_level.editable = toggled_on
	)
	spin_box_plant_level.value_changed.connect(
		func(value: float) -> void:
			editor.set_active_plant_level(int(value))
	)
	check_box_plant_level.toggled.connect(
		func(toggled_on: bool) -> void:
			editor.set_apply_plant_level(toggled_on)
			spin_box_plant_level.editable = toggled_on
	)
	option_button_walled.item_selected.connect(
		func(index : int) -> void:
			editor.set_walled_mode(index)
	)
	spin_box_special.value_changed.connect(
		func(value: float) -> void:
			editor.set_active_special_index(int(value))
	)
	check_box_special.toggled.connect(
		func(toggled_on: bool) -> void:
			editor.set_apply_special_index(toggled_on)
			spin_box_special.editable = toggled_on
	)
	refresh_button.pressed.connect(func() -> void:editor.refresh())
	button_save.pressed.connect(func() -> void: 
		if is_instance_valid(save_load_menu):
			save_load_menu.editor = editor
			save_load_menu.open(true)
	)
	button_load.pressed.connect(func() -> void:
		if is_instance_valid(save_load_menu):
			save_load_menu.editor = editor
			save_load_menu.open(false)
	) 
	button_new_map.pressed.connect(func() -> void:
		if is_instance_valid(new_map_menu):
			new_map_menu.editor = editor
			new_map_menu.open()
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
