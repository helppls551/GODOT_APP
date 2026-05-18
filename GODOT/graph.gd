extends Control
var tasks = []

func _ready():
	# Слушаем изменение данных в заметках (если добавили новую задачу или сменили исполнителя)
	EventBus.note_data_changed.connect(_on_note_data_changed)
	
	# Слушаем клики по цветным кружкам в списке участников!
	EventBus.participant_color_changed.connect(_on_participant_color_changed)
	
	load_json()
	queue_redraw()

func _on_note_data_changed():
	print("График: Обновление данных из заметок")
	load_json()
	queue_redraw()

func _on_participant_color_changed(_participant_name, _new_color):
	print("График: Цвет участника изменился, перерисовываем полоски")
	# Нам не нужно заново читать файлы, достаточно просто обновить картинку
	queue_redraw()

func load_json():
	tasks.clear()
	
	var dir = DirAccess.open("res://")
	if not dir:
		print("Ошибка открытия директории res://")
		return
	
	dir.list_dir_begin()
	var filename = dir.get_next()
	
	while filename != "":
		# Читаем строго файлы заметок
		if filename.begins_with("note_") and filename.ends_with(".json"):
			var file = FileAccess.open("res://" + filename, FileAccess.READ)
			if file:
				var content = file.get_as_text()
				var data = JSON.parse_string(content)
				
				if data != null and data.has("start") and data.has("deadline"):
					tasks.append({
						"start": data["start"],
						"end": data["deadline"],
						# Обязательно сохраняем имя исполнителя, убирая лишние пробелы
						"executor": str(data.get("executor", "")).strip_edges()
					})
				file.close()
		filename = dir.get_next()
	dir.list_dir_end()

func date_to_unix(d_str):
	var parts = d_str.split(".")
	if parts.size() < 3: return 0
	var dt = {
		"year": int(parts[2]),
		"month": int(parts[1]),
		"day": int(parts[0]),
		"hour": 12, "minute": 0, "second": 0
	}
	return Time.get_unix_time_from_datetime_dict(dt)

func _draw():
	var w = size.x
	var h = size.y
	var margin = 10
	var line_y = h - 5
	
	var all_times = []
	for t in tasks:
		all_times.append(date_to_unix(t.start))
		all_times.append(date_to_unix(t.end))
		
	var min_time = 0
	var max_time = 0
	if len(all_times) == 0:
		var current_date = Time.get_datetime_dict_from_system()
		var date_string = "%02d.%02d.%04d" % [current_date.day, current_date.month, current_date.year]
		max_time = date_to_unix(date_string)
	else:
		min_time = all_times[0]
		max_time = all_times[0]
		for t in all_times:
			if t < min_time: min_time = t
			if t > max_time: max_time = t
	
	var total_time = max_time - min_time
	var usable_width = w - margin * 2
	
	# Рисуем временную шкалу (базовую линию)
	draw_line(Vector2(margin, line_y), Vector2(w - margin, line_y), Color(0.7,0.7,0.7), 2)
	
	var task_height = 12
	var spacing = 10
	
	# Пытаемся найти корневой узел Main, чтобы брать цвета оттуда
	var main_node = get_tree().current_scene
	
	for i in range(tasks.size()):
		var task = tasks[i]
		
		var start_t = date_to_unix(task.start)
		var end_t = date_to_unix(task.end)
		
		var start_ratio = float(start_t - min_time) / total_time if total_time > 0 else 0.0
		var end_ratio = float(end_t - min_time) / total_time if total_time > 0 else 0.0
		
		var x1 = margin + start_ratio * usable_width
		var x2 = margin + end_ratio * usable_width
		var y = line_y - 30 - i * (task_height + spacing)
		
		var rect = Rect2(Vector2(x1, y), Vector2(x2 - x1, task_height))
		
		# --- АВТОМАТИЧЕСКИЙ ВЫБОР ЦВЕТА ---
		var current_color = Color(0.6, 0.6, 0.6) # Серый по умолчанию, если исполнитель пустой
		var exec = task["executor"]
		
		if exec != "":
			# Если Main доступен и у него сохранен цвет для этого человека — берем его!
			if main_node && "participant_colors" in main_node && main_node.participant_colors.has(exec):
				current_color = main_node.participant_colors[exec]
			else:
				# Если цвет еще не создался в Main, сгенерируем временный от имени
				current_color = Color.from_hsv(float(exec.hash() % 100) / 100.0, 0.7, 0.9)
		
		draw_rect(rect, current_color)

	# Засечки времени
	var ticks = 12
	for i in range(ticks + 1):
		var x = margin + i*(usable_width/ticks)
		draw_line(Vector2(x,line_y), Vector2(x,line_y - 10), Color.WHITE, 2)