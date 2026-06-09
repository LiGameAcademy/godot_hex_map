@tool
extends Window
class_name SaveLoadMenu

@onready var _label_title: Label = %LabelTitle
@onready var _line_edit: LineEdit = %LineEdit
@onready var _item_list: ItemList = %ItemList
@onready var _button_delete: Button = %ButtonDelete
@onready var _button_action: Button = %ButtonAction

@export var editor: HexMapEditor
var _save_mode: bool = true

func _ready() -> void:
	hide()
	close_requested.connect(close)
	_button_action.pressed.connect(
		func() -> void:
			if not is_instance_valid(editor):
				return
			if _save_mode:
				if editor.save_map_to_stem(_line_edit.text):
					_refresh_list()
					close()
			else:
				_try_load_and_close()
	)
	_button_delete.pressed.connect(
		func() -> void:
			if not is_instance_valid(editor):
				return
			var selected := _item_list.get_selected_items()
			if selected.is_empty():
				return
			var stem := _item_list.get_item_text(selected[0])
			if editor.delete_map_stem(stem):
				_refresh_list()
				_line_edit.clear()
				_update_delete_enabled()
	)
	_item_list.item_selected.connect(
		func(_index : int) -> void:
			var selected := _item_list.get_selected_items()
			if not selected.is_empty():
				_line_edit.text = _item_list.get_item_text(selected[0])
			_update_delete_enabled()
	)
	_item_list.item_activated.connect(
		func(index: int) -> void:
			_line_edit.text = _item_list.get_item_text(index)
			if not _save_mode:
				_try_load_and_close()
	)
	_line_edit.text_changed.connect(func(_t: String) -> void: _update_delete_enabled())

func open(save_mode : bool) -> void:
	_save_mode = save_mode
	_line_edit.clear()
	_apply_mode_ui()
	_refresh_list()
	_lock_camera(true)
	popup_centered()

func close() -> void:
	_lock_camera(false)
	hide()

func _lock_camera(locked: bool) -> void:
	var camera : HexMapCamera = get_tree().get_first_node_in_group("Camera")
	if is_instance_valid(camera):
		camera.set_camera_locked(locked)

func _apply_mode_ui() -> void:
	if _save_mode:
		title = "保存地图"
		_label_title.text = "保存地图"
		_button_action.text = "保存"
		_line_edit.placeholder_text = "输入文件名（无需 .map）"
	else:
		title = "加载地图"
		_label_title.text = "加载地图"
		_button_action.text = "加载"
		_line_edit.placeholder_text = "从列表选择或输入文件名"

func _refresh_list() -> void:
	_item_list.clear()
	for stem in _list_map_stems():
		_item_list.add_item(stem)
	_update_delete_enabled()

func _list_map_stems() -> PackedStringArray:
	var out: PackedStringArray = []
	var dir := DirAccess.open("user://")
	if dir == null:
		return out
	dir.list_dir_begin()
	var fn := dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.ends_with(".map"):
			out.append(fn.get_basename())
		fn = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out

func _try_load_and_close() -> void:
	if not is_instance_valid(editor):
		return
	if editor.load_map_from_stem(_line_edit.text):
		close()

func _update_delete_enabled() -> void:
	_button_delete.disabled = _item_list.get_selected_items().is_empty()
