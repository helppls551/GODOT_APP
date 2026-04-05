extends Control
var tasks = [
	{"start": "2026-01-01", "deadline": "2026-01-10"}
]
func _ready():
	EventBus.note_data_changed.connect(_on_note_data_changed)
	load_json()
	queue_redraw()

func _on_note_data_changed():
	print("Получен сигнал об изменении данных")
	load_json()
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
		if filename.ends_with(".json"):
			var file = FileAccess.open("res://" + filename, FileAccess.READ)
			if file:
				var content = file.get_as_text()
				var data = JSON.parse_string(content)
				
				if data != null and data.has("start") and data.has("deadline"):
					# Добавляем только start и end
					tasks.append({
						"start": data["start"],
						"end": data["deadline"]
					})
					print("Загружена задача: ", data["start"], " -> ", data["deadline"])
				else:
					print("Неверный формат JSON в файле: ", filename)
				file.close()
		
		filename = dir.get_next()
	
	dir.list_dir_end()
	print("Всего загружено задач: ", tasks.size())
	print("tasks: ", tasks)  # Для отладки
func date_to_unix(d_str):
	var parts = d_str.split(".")
	var dt = {
		"year": int(parts[2]),
		"month": int(parts[1]),
		"day": int(parts[0]),
		"hour": 12,
		"minute": 0,
		"second": 0
	}
	return Time.get_unix_time_from_datetime_dict(dt)

func _draw():
	var w = size.x
	var h = size.y
	var margin = 10
	var line_y = h - 20
	
	# --- собираем все даты ---
	
	var all_times = []
	for t in tasks:
		all_times.append(date_to_unix(t.start))
		all_times.append(date_to_unix(t.end))
	
	var min_time = all_times[0]
	var max_time = all_times[0]
	for t in all_times:
		if t < min_time: min_time = t
		if t > max_time: max_time = t
	
	var total_time = max_time - min_time
	var usable_width = w - margin * 2
	
	# --- линия снизу ---
	draw_line(Vector2(margin, line_y), Vector2(w - margin, line_y), Color(0.7,0.7,0.7), 2)
	
	# --- рисуем задачи ---
	var task_height = 12
	var spacing = 8
	
	for i in range(tasks.size()):
		var task = tasks[i]
		
		var start_t = date_to_unix(task.start)
		var end_t = date_to_unix(task.end)
		
		var start_ratio = float(start_t - min_time) / total_time
		var end_ratio = float(end_t - min_time) / total_time
		
		var x1 = margin + start_ratio * usable_width
		var x2 = margin + end_ratio * usable_width
		
		var y = line_y - 30 - i * (task_height + spacing)
		
		var rect = Rect2(Vector2(x1, y), Vector2(x2 - x1, task_height))
		
		# цвет (просто разные)
		var color = Color.from_hsv(float(i) / tasks.size(), 0.7, 0.9)
		draw_rect(rect, color)
	var ticks = 12  # количество делений

	for i in range(ticks + 1):
		var x = margin + i*(usable_width/ticks)
		var height = 10
		draw_line(
			Vector2(x,line_y),
			Vector2(x,line_y - height),
			Color.WHITE,
			2
		)
