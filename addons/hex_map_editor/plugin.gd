@tool
extends EditorPlugin

const PANEL_SCENE := preload("res://addons/hex_map_editor/ui/hex_map_editor_panel.tscn")
const TOOL_MENU_TOGGLE_PAINT_MODE := "Hex Map/切换笔刷模式"

var _dock: HexMapEditorPanel
var _editor_logic: HexMapEditor
var _last_scene_root: Node = null
var _paint_mode_enabled: bool = true
var _panel_visible_in_spatial: bool = false

func _enter_tree() -> void:
	_editor_logic = HexMapEditor.new()
	_editor_logic.name = "HexMapEditorPluginRuntime"
	var undo_redo: EditorUndoRedoManager = null
	if is_instance_valid(EditorInterface) and EditorInterface.has_method("get_editor_undo_redo"):
		undo_redo = EditorInterface.get_editor_undo_redo()
	elif has_method("get_undo_redo"):
		undo_redo = get_undo_redo()
	_editor_logic.set_undo_redo(undo_redo)
	add_child(_editor_logic)

	_dock = PANEL_SCENE.instantiate() as HexMapEditorPanel
	_dock.editor = _editor_logic
	_dock.custom_minimum_size = Vector2(340, 0)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, _dock)
	_set_spatial_panel_visible(false)
	add_tool_menu_item(TOOL_MENU_TOGGLE_PAINT_MODE, _on_toggle_paint_mode)
	set_input_event_forwarding_always_enabled()

	set_process(true)
	_rebind_scene_hex_grid()

func _exit_tree() -> void:
	set_process(false)
	if is_instance_valid(_dock):
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, _dock)
		_dock.queue_free()
	_dock = null
	remove_tool_menu_item(TOOL_MENU_TOGGLE_PAINT_MODE)

	if is_instance_valid(_editor_logic):
		_editor_logic.queue_free()
	_editor_logic = null
	_last_scene_root = null

func _process(_delta: float) -> void:
	_rebind_scene_hex_grid()
	_sync_spatial_panel_visibility()

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if not _paint_mode_enabled or not _panel_visible_in_spatial:
		return AFTER_GUI_INPUT_PASS
	if not is_instance_valid(_editor_logic) or not is_instance_valid(_editor_logic.hex_grid):
		return AFTER_GUI_INPUT_PASS
	if _editor_logic.handle_editor_viewport_input(viewport_camera, event):
		return AFTER_GUI_INPUT_STOP
	return AFTER_GUI_INPUT_PASS

func _handles(object: Object) -> bool:
	return object is HexGrid

func _edit(object: Object) -> void:
	if object is HexGrid and is_instance_valid(_editor_logic):
		_editor_logic.hex_grid = object as HexGrid
		_set_spatial_panel_visible(true)
		if is_instance_valid(_dock) and _dock.is_node_ready() and _dock.has_method("_sync_terrain_type_controls_from_editor"):
			_dock._sync_terrain_type_controls_from_editor()
	else:
		_set_spatial_panel_visible(false)

func _sync_spatial_panel_visibility() -> void:
	var selected_is_hex_grid := false
	var selection := EditorInterface.get_selection()
	if is_instance_valid(selection):
		for node in selection.get_selected_nodes():
			if node is HexGrid:
				selected_is_hex_grid = true
				if is_instance_valid(_editor_logic):
					_editor_logic.hex_grid = node as HexGrid
				break
	_set_spatial_panel_visible(selected_is_hex_grid)

func _set_spatial_panel_visible(visible: bool) -> void:
	_panel_visible_in_spatial = visible
	if is_instance_valid(_dock):
		_dock.visible = visible

func _rebind_scene_hex_grid() -> void:
	if not is_instance_valid(_editor_logic):
		return

	var root := EditorInterface.get_edited_scene_root()
	if root == _last_scene_root:
		return
	_last_scene_root = root
	_editor_logic.hex_grid = _find_hex_grid(root)
	if is_instance_valid(_dock) and _dock.is_node_ready() and _dock.has_method("_sync_terrain_type_controls_from_editor"):
		_dock._sync_terrain_type_controls_from_editor()

func _find_hex_grid(root: Node) -> HexGrid:
	if not is_instance_valid(root):
		return null
	if root is HexGrid:
		return root as HexGrid
	for child in root.get_children():
		var found := _find_hex_grid(child)
		if is_instance_valid(found):
			return found
	return null

func _on_toggle_paint_mode() -> void:
	_paint_mode_enabled = not _paint_mode_enabled
	var tip := "Hex Map 笔刷模式：%s（开启后可在 3D 视口左键绘制）" % ("开启" if _paint_mode_enabled else "关闭")
	print(tip)
