extends Control

@onready var drop_zone1 = $DropZone1
@onready var line_edit1 = $Task1
@onready var drop_zone2 = $DropZone2
@onready var line_edit2 = $Task2
@onready var drop_zone3 = $DropZone3
@onready var line_edit3 = $Task3
@onready var drop_zone4 = $DropZone4
@onready var line_edit4 = $Task4
@onready var drop_zone5 = $DropZone5
@onready var line_edit5 = $Task5
@onready var drop_zone6 = $DropZone6
@onready var line_edit6 = $Task6
@onready var drop_zone7 = $DropZone7
@onready var line_edit7 = $Task7
@onready var drop_zone8 = $DropZone8
@onready var line_edit8 = $Task8
@onready var add_but = $"../TopPanel/AddButton2"
@onready var close_but = $"../TopPanel/AddButton3"

var zone_panels:= {}
var drop_zones: Array = []
var active_zones: Array = [] 
var line_edits: Array = []
var panel_count := 0

func _ready():
	EventBus.note_data_changed.connect(create_new_panel)
	EventBus.participant_color_changed.connect(_on_participant_color_changed)
	add_but.pressed.connect(open_next_zone)
	close_but.pressed.connect(close_last_zone)
	init_zone_panels()
	
	drop_zones = [drop_zone1, drop_zone2, drop_zone3, drop_zone4, drop_zone5, drop_zone6, drop_zone7, drop_zone8]
	line_edits = [line_edit1, line_edit2, line_edit3, line_edit4, line_edit5, line_edit6, line_edit7, line_edit8]
	
	active_zones.clear()
	zone_panels.clear()
	
	for zone in drop_zones:
		zone.z_index = 0
		zone.visible = false
	for le in line_edits:
		le.z_index = 0
		le.visible = false
		
	drop_zones[0].visible = true
	line_edits[0].visible = true
	zone_panels[drop_zones[0]] = []
	
	load_text()
	load_all_panels()

func open_next_zone():
	for i in range(drop_zones.size()):
		if !drop_zones[i].visible:
			drop_zones[i].visible = true
			zone_panels[drop_zones[i]] = []
			if i < line_edits.size():
				line_edits[i].visible = true
			return
	add_but.disabled = true

func all_zones_opened():
	for zone in drop_zones:
		if !zone.visible:
			return false
	return true

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_text()

func save_text():
	var config = ConfigFile.new()
	for i in range(line_edits.size()):
		config.set_value("ui", "lineedit_%d" % i, line_edits[i].text)
	var open_zones := []
	for i in range(drop_zones.size()):
		if drop_zones[i].visible:
			open_zones.append(i)
	config.set_value("ui", "open_zones", open_zones)
	config.save("res://settings.cfg")

func load_text():
	var config = ConfigFile.new()
	var err = config.load("res://settings.cfg")
	if err == OK:
		for i in range(line_edits.size()):
			line_edits[i].text = config.get_value("ui", "lineedit_%d" % i, "")
	
	var open_zones = config.get_value("ui", "open_zones", [])
	for i in open_zones:
		if i >= 0 and i < drop_zones.size():
			drop_zones[i].visible = true
			line_edits[i].visible = true
			# СТРОКА УДАЛЕНА: zone_panels[drop_zones[i]] = []

	init_zone_panels()
	
func load_all_panels():
	var dir = DirAccess.open("res://")
	if dir == null: return
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
					var raw_id = file_name.get_file().replace("note_", "").replace(".json", "")
					data["note_id"] = int(raw_id)
					create_new_panel(data)
		file_name = dir.get_next()
	dir.list_dir_end()

func init_zone_panels():
	for zone in drop_zones:
		if !zone_panels.has(zone):
			zone_panels[zone] = []

func create_new_panel(data = {}):
	# --- ЗАЩИТА ОТ СОЗДАНИЯ ПУСТЫХ ПАНЕЛЕЙ ПРИ УДАЛЕНИИ ---
	# Если data пустая (сигнал прилетел просто как уведомление об обновлении),
	# мы ничего не создаем, а просто выходим из функции.
	if data.is_empty():
		return
	# -----------------------------------------------------

	var file_path = data.get("__file", "")
	var exec = data.get("executor", "").strip_edges()

	# --- УМНАЯ ПРОВЕРКА И ОБНОВЛЕНИЕ СУЩЕСТВУЮЩЕЙ ПАНЕЛИ ---
	if file_path != "":
		for child in get_children():
			if child is Panel:
				if child.has_meta("file") and child.get_meta("file") == file_path:
					child.set_meta("executor", exec)
					child.set_meta("data", data)
					
					if exec != "" and EventBus.active_colors.has(exec):
						var existing_style = child.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
						if existing_style:
							existing_style.bg_color = EventBus.active_colors[exec]
							child.add_theme_stylebox_override("panel", existing_style)
							data["panel_color"] = EventBus.active_colors[exec].to_html()
							save_panel(child)
					return 
	# ------------------------------------------------------------

	# ЕСЛИ ПАНЕЛИ НЕТ НА ЭКРАНЕ, СОЗДАЕМ ЕЕ С НУЛЯ (Вызовется только при реальном добавлении ноты)
	panel_count += 1
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(200, 25)
	panel.size = Vector2(200, 25)

	var style = StyleBoxFlat.new()
	style.border_color = Color(0.5, 0.5, 0.5, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	panel.set_meta("executor", exec)
	
	var final_color : Color
	if data.has("panel_color") and data["panel_color"] != "":
		final_color = Color.from_string(data["panel_color"], Color(0.3, 0.3, 0.3))
	elif exec != "" and EventBus.active_colors.has(exec):
		final_color = EventBus.active_colors[exec]
		data["panel_color"] = final_color.to_html()
	else:
		final_color = Color.from_hsv(randf(), 0.7, 0.9)
		data["panel_color"] = final_color.to_html()
		if exec != "":
			EventBus.active_colors[exec] = final_color
	
	style.bg_color = final_color
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)

	panel.set_meta("file", file_path)
	panel.set_meta("in_zone", data.get("in_zone", false))
	panel.set_meta("zone_name", data.get("zone_name", ""))
	panel.set_meta("data", data)

	# --- НАДЕЖНЫЙ БЛОК КООРДИНАТ ---
	# Проверяем, есть ли в переданном словаре ЧЕТКИЕ, ПРАВИЛЬНЫЕ координаты из файла
	if data.has("position_x") and float(data["position_x"]) != 0.0:
		panel.position = Vector2(float(data["position_x"]), float(data["position_y"]))
	else:
		# Если это первое создание (координат нет или они равны 0), рассчитываем позицию в правой верхней части
		var current_width = size.x if size.x > 0 else 1152.0
		var current_height = size.y if size.y > 0 else 648.0
		
		var min_x = current_width / 2.0
		var max_x = current_width - 250.0 
		if max_x < min_x: max_x = min_x + 100.0
		
		var min_y = current_height * 0.1
		var max_y = current_height * 0.5
		
		panel.position = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)
	# -------------------------------

	add_child(panel)

	if panel.get_meta("in_zone"):
		var zone_name = panel.get_meta("zone_name", "")
		for zone in drop_zones:
			if zone.name == zone_name:
				_move_to_zone(panel, zone, false)
				break
	else:
		if zone_panels.has(panel):
			zone_panels.erase(panel)
		# ИСПРАВЛЕНИЕ: Сохраняем позицию, только если она не перенеслась в зону
		if file_path != "":
			save_panel(panel)

	_setup_dragging(panel)

func _on_participant_color_changed(participant_name: String, new_color: Color):
	var target_exec = participant_name.strip_edges()
	for child in get_children():
		if child is Panel and child.has_meta("executor") and child.get_meta("executor") == target_exec:
			var style = child.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if style:
				style.bg_color = new_color
				child.add_theme_stylebox_override("panel", style)
				save_panel(child)
					
	for zone in drop_zones:
		for child in zone.get_children():
			if child is Panel and child.has_meta("executor") and child.get_meta("executor") == target_exec:
				var style = child.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
				if style:
					style.bg_color = new_color
					child.add_theme_stylebox_override("panel", style)
					save_panel(child)

func _setup_dragging(panel):
	panel.set_meta("dragging", false)
	panel.set_meta("drag_offset", Vector2.ZERO)
	panel.set_meta("base_size", Vector2(200, 25))

	panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			
			# --- ДВОЙНОЙ КЛИК: ОТКРЫТИЕ / ЗАКРЫТИЕ ПАНЕЛИ ОПИСАНИЯ ---
			if event.double_click:
				var details_panel = panel.get_node_or_null("DetailsPanel")
				var delete_btn = panel.get_node_or_null("DeleteIconButton")
				
				# Если уже открыто — сворачиваем обратно и удаляем кнопку крестика
				if details_panel or delete_btn:
					if details_panel: details_panel.queue_free()
					if delete_btn: delete_btn.queue_free()
					panel.custom_minimum_size = Vector2(200, 25)
					panel.size = Vector2(200, 25)
					return

				var data = panel.get_meta("data", {})
				
				# --- 1. СОЗДАНИЕ МАЛЕНЬКОЙ КНОПКИ УДАЛЕНИЯ (КРЕСТИКА) ЧЕРЕЗ BUTTON ---
				var texture_path = "res://frame 4.png"
				if ResourceLoader.exists(texture_path):
					var btn = Button.new()
					btn.name = "DeleteIconButton"
					
					# Загружаем frame 4.png как иконку для обычной кнопки
					btn.icon = load(texture_path)
					btn.expand_icon = true # Обязательно: разрешаем иконке сжиматься/растягиваться под размер кнопки
					
					# Задаем кнопке небольшой аккуратный размер (например, 20x20 или 25x25)
					# Слишком маленький размер (вроде 10x10) сделает иконку невидимой или по ней будет сложно попасть
					var btn_size = 20
					btn.custom_minimum_size = Vector2(btn_size, btn_size)
					btn.size = Vector2(btn_size, btn_size)
					
					# Позиционируем в правый верхний угол развернутой панели (300 - btn_size)
					# Центрируем по вертикали (высота панели 25 - высота кнопки btn_size) / 2
					btn.position = Vector2(300 - btn_size - 2, (25 - btn_size) / 2)
					
					# Делаем обычную кнопку прозрачной, чтобы была видна ТОЛЬКО твоя иконка крестика
					var empty_style = StyleBoxEmpty.new()
					btn.add_theme_stylebox_override("normal", empty_style)
					btn.add_theme_stylebox_override("hover", empty_style)
					btn.add_theme_stylebox_override("pressed", empty_style)
					btn.add_theme_stylebox_override("focus", empty_style)
					
					# Кнопка должна перехватывать клики на себя, чтобы не срабатывал драг панели
					btn.mouse_filter = Control.MOUSE_FILTER_STOP
					
					# Логика удаления файла при нажатии на кнопку
					# Логика удаления файла при нажатии на кнопку
					btn.pressed.connect(func():
						var file_path = panel.get_meta("file", "")
						if file_path != "" and FileAccess.file_exists(file_path):
							DirAccess.remove_absolute(file_path)
							print("Файл удален через кнопку: ", file_path)
						
						# Очищаем из структуры зон
						for zone in zone_panels.keys():
							if zone_panels[zone].has(panel):
								zone_panels[zone].erase(panel)
						
						# --- ВОТ ЭТА СТРОЧКА ОПЯТЬ НУЖНА ТУТ ---
						# Она заставит обновиться участников и графики,
						# а первая строчка 'if data.is_empty()' защитит от появления пустой панели.
						EventBus.note_data_changed.emit()
						# ---------------------------------------
						
						panel.queue_free()
					)
					
					panel.add_child(btn)
				else:
					print("Предупреждение: Иконка удаления не найдена: ", texture_path)

				# --- 2. СОЗДАНИЕ ПАНЕЛИ ОПИСАНИЯ ---
				details_panel = Panel.new()
				details_panel.name = "DetailsPanel"
				details_panel.position = Vector2(0, 25)
				details_panel.size = Vector2(300, 10)

				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.15, 0.15, 0.2)
				details_panel.add_theme_stylebox_override("panel", style)
				
				# Пропускаем клики сквозь темную панель, чтобы можно было тащить за неё
				details_panel.mouse_filter = Control.MOUSE_FILTER_PASS
				panel.add_child(details_panel)

				# --- 3. ТЕКСТ ОПИСАНИЯ ---
				var label = Label.new()
				label.text = "Описание: " + data.get("description", "") + "\n" + "Начало: " + data.get("start", "") + "\n" + "Конец: " + data.get("deadline", "") 
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.custom_minimum_size = Vector2(290, 0)
				label.mouse_filter = Control.MOUSE_FILTER_PASS
				details_panel.add_child(label)
				
				# Просчет высоты текста
				await get_tree().process_frame
				var height = label.get_combined_minimum_size().y + 10
				details_panel.size = Vector2(300, height)
				panel.custom_minimum_size = Vector2(300, 25)
				panel.size = Vector2(300, 25)
				return

			# --- ОБЫЧНЫЙ КЛИК ПО ПАНЕЛИ (НАЧАЛО ПЕРЕТАСКИВАНИЯ) ---
			if event.pressed:
				panel.set_meta("dragging", true)
				panel.set_meta("drag_offset", get_global_mouse_position() - panel.global_position)
				if !(panel in zone_panels):
					move_child(panel, -1)
			else:
				# ОТПУСКАНИЕ МЫШИ (КОНЕЦ ПЕРЕТАСКИВАНИЯ)
				panel.set_meta("dragging", false)
				var zone = get_drop_zone(panel)
				if zone:
					_move_to_zone(panel, zone, true)
				else:
					_remove_from_zone(panel)
				save_panel(panel)
		
		# ПЕРЕМЕЩЕНИЕ МЫШИ (ДРАГ)
		elif event is InputEventMouseMotion and panel.get_meta("dragging"):
			var offset = panel.get_meta("drag_offset")
			panel.global_position = get_global_mouse_position() - offset
	)
func get_drop_zone(panel):
	for zone in drop_zones:
		if zone.visible:
			var rect = zone.get_global_rect()
			if rect.has_point(panel.global_position):
				return zone
	return null

func _move_to_zone(panel, zone, save: bool):
	if panel.get_parent() != zone:
		panel.reparent(zone)
	panel.set_meta("in_zone", true)
	panel.set_meta("zone_name", zone.name)

	if !zone_panels.has(zone):
		zone_panels[zone] = []
	if !zone_panels[zone].has(panel):
		zone_panels[zone].append(panel)

	update_zone_layout(zone)
	if save:
		save_panel(panel)

func _remove_from_zone(panel):
	panel.set_meta("in_zone", false)
	panel.set_meta("zone_name", "")
	for zone in zone_panels.keys():
		zone_panels[zone].erase(panel)
	if panel.get_parent() != self:
		panel.reparent(self)

func update_zone_layout(zone):
	if !zone_panels.has(zone): return
	for i in range(zone_panels[zone].size()):
		var p = zone_panels[zone][i]
		p.position = Vector2(i * 25, 0)

func save_panel(panel):
	var path = panel.get_meta("file")
	if path == "": return
	var data = {}
	if FileAccess.file_exists(path):
		data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) != TYPE_DICTIONARY:
			data = {}

	var local_pos = panel.position
	if panel.get_parent() != self:
		local_pos = get_global_transform().affine_inverse() * panel.global_position

	data["position_x"] = local_pos.x
	data["position_y"] = local_pos.y
	data["in_zone"] = panel.get_meta("in_zone", false)
	data["zone_name"] = panel.get_meta("zone_name", "")
	
	var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		data["panel_color"] = style.bg_color.to_html()

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func close_last_zone():
	for i in range(drop_zones.size() - 1, -1, -1):
		if i == 0: return # Зону №1 не закрываем
		
		if drop_zones[i].visible:
			var zone_to_close = drop_zones[i]
			var line_edit_to_clear = line_edits[i]
			
			if zone_panels.has(zone_to_close):
				var panels_in_zone = zone_panels[zone_to_close].duplicate()
				for panel in panels_in_zone:
					# 1. Удаляем из списка зоны
					zone_panels[zone_to_close].erase(panel)
					
					# 2. Возвращаем панель в главный Workspace
					if panel.get_parent() != self:
						panel.reparent(self) 
					
					# 3. Сбрасываем метаданные зоны
					panel.set_meta("in_zone", false)
					panel.set_meta("zone_name", "")
					
					# 4. Устанавливаем случайную позицию в видимой области
					panel.position = Vector2(
						randf_range(200, size.x - 200),
						randf_range(100, size.y - 50)
					)
					
					# 5. ВАЖНО: делаем панель активной и сохраняем
					panel.visible = true
					save_panel(panel)
				
				zone_panels[zone_to_close].clear()

			line_edit_to_clear.text = ""
			zone_to_close.visible = false
			line_edit_to_clear.visible = false
			add_but.disabled = false
			save_text()
			return
