extends Control

@onready var drop_zone = $DropZone

var zone_panels: Array = []
var panel_count := 0


func _ready():
	EventBus.note_data_changed.connect(create_new_panel)
	load_all_panels()


func load_all_panels():
	var dir = DirAccess.open("res://")
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.begins_with("note_") and file_name.ends_with(".json"):
			var path = "res://" + file_name
			var file = FileAccess.open(path, FileAccess.READ)

			if file:
				var data = JSON.parse_string(file.get_as_text())
				file.close()

				if typeof(data) == TYPE_DICTIONARY:
					data["__file"] = path
					create_new_panel(data)
		file_name = dir.get_next()

	dir.list_dir_end()


func create_new_panel(data ={}):
	panel_count += 1

	var panel = Panel.new()
	panel.size = Vector2(200, 25)

	var style = StyleBoxFlat.new()
	style.bg_color = Color.from_hsv(randf(), 0.7, 0.9)
	panel.add_theme_stylebox_override("panel", style)

	panel.set_meta("file", data.get("__file", ""))
	panel.set_meta("in_zone", data.get("in_zone", false))

	panel.global_position = Vector2(
		data.get("position_x", randf_range(0, size.x - 200)),
		data.get("position_y", randf_range(0, size.y - 150))
	)
	add_child(panel)

	if panel.get_meta("in_zone"):
		_move_to_zone(panel, false)
	else:
		zone_panels.erase(panel)

	_setup_dragging(panel)


func _setup_dragging(panel):
	panel.set_meta("dragging", false)
	panel.set_meta("drag_offset", Vector2.ZERO)

	panel.gui_input.connect(func(event):

		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:
				panel.set_meta("dragging", true)
				panel.set_meta("drag_offset", get_global_mouse_position() - panel.global_position)
				move_child(panel, -1)

			else:
				panel.set_meta("dragging", false)

				if is_inside_drop_zone(panel):
					_move_to_zone(panel, true)
				else:
					_remove_from_zone(panel)
				save_panel(panel)

		elif event is InputEventMouseMotion and panel.get_meta("dragging"):
			var offset = panel.get_meta("drag_offset")
			panel.global_position = get_global_mouse_position() - offset
	)


func is_inside_drop_zone(panel):
	var rect = drop_zone.get_global_rect()
	return rect.has_point(panel.global_position)


func _move_to_zone(panel, save: bool):
	if panel.get_parent() != drop_zone:
		panel.reparent(drop_zone, true) # keep global position

	panel.set_meta("in_zone", true)

	if !zone_panels.has(panel):
		zone_panels.append(panel)

	update_zone_layout()

	if save:
		save_panel(panel)


func _remove_from_zone(panel):
	zone_panels.erase(panel)
	panel.set_meta("in_zone", false)

	if panel.get_parent() != self:
		panel.reparent(self, true)


func update_zone_layout():
	for i in range(zone_panels.size()):
		var p = zone_panels[i]
		p.position = Vector2(i * 25, 0)  # локально внутри drop_zone


func save_panel(panel):
	var path = panel.get_meta("file")
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		data = {}
	
	data["position_x"] = panel.global_position.x
	data["position_y"] = panel.global_position.y
	data["in_zone"] = panel.get_meta("in_zone", false)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
