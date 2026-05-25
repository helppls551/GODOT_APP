extends Control

var tasks = []

func _ready():
	# Принимаем данные из сигнала
	EventBus.note_data_changed.connect(func(data = {}): _on_note_data_changed())

	# Слушаем изменение цветов участников
	EventBus.participant_color_changed.connect(_on_participant_color_changed)

	load_json()
	queue_redraw()

func _on_note_data_changed():
	print("График: Обновление данных из заметок")
	load_json()
	queue_redraw()

func _on_participant_color_changed(_participant_name, _new_color):
	print("График: Цвет участника изменился, перерисовываем полоски")
	queue_redraw()

func load_json():
	tasks.clear()

	var participant_tasks = {}

	var dir = DirAccess.open("res://")
	if not dir:
		print("Ошибка открытия директории res://")
		return

	dir.list_dir_begin()
	var filename = dir.get_next()

	while filename != "":
		if filename.begins_with("note_") and filename.ends_with(".json"):
			var file = FileAccess.open("res://" + filename, FileAccess.READ)

			if file:
				var content = file.get_as_text()
				var data = JSON.parse_string(content)
				file.close()

				if data != null \
				and data.has("start") \
				and data.has("deadline") \
				and data.has("executor"):

					var start_date = str(data["start"]).strip_edges()
					var end_date = str(data["deadline"]).strip_edges()
					var executor = str(data["executor"]).strip_edges()

					if start_date != "" and end_date != "" and executor != "":

						var start_unix = date_to_unix(start_date)
						var end_unix = date_to_unix(end_date)

						if start_unix > 0 and end_unix > 0:

							# Новый участник
							if not participant_tasks.has(executor):
								participant_tasks[executor] = {
									"start": start_unix,
									"end": end_unix,
									"executor": executor
								}
							else:
								# Самая ранняя дата начала
								if start_unix < participant_tasks[executor]["start"]:
									participant_tasks[executor]["start"] = start_unix

								# Самая поздняя дата окончания
								if end_unix > participant_tasks[executor]["end"]:
									participant_tasks[executor]["end"] = end_unix

		filename = dir.get_next()

	dir.list_dir_end()

	# Переносим данные в tasks
	for executor in participant_tasks.keys():
		tasks.append(participant_tasks[executor])

func date_to_unix(d_str):
	if d_str == "":
		return 0

	var parts = d_str.split(".")

	if parts.size() < 3:
		return 0

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
	var line_y = h - 5

	if tasks.is_empty():
		draw_line(Vector2(margin, line_y), Vector2(w - margin, line_y), Color(0.4, 0.4, 0.4), 2)
		return

	var all_times = []

	for t in tasks:
		if t["start"] > 0:
			all_times.append(t["start"])

		if t["end"] > 0:
			all_times.append(t["end"])

	var min_time = 0
	var max_time = 0

	if all_times.size() == 0:
		var current_date = Time.get_datetime_dict_from_system()
		var date_string = "%02d.%02d.%04d" % [current_date.day, current_date.month, current_date.year]

		max_time = date_to_unix(date_string)
		min_time = max_time - 86400
	else:
		min_time = all_times[0]
		max_time = all_times[0]

		for t in all_times:
			if t < min_time:
				min_time = t

			if t > max_time:
				max_time = t

	if min_time == max_time:
		max_time += 86400

	var total_time = max_time - min_time
	var usable_width = w - margin * 2

	# Основная линия
	draw_line(Vector2(margin, line_y), Vector2(w - margin, line_y), Color(0.7, 0.7, 0.7), 2)

	var task_height = 14
	var spacing = 14

	for i in range(tasks.size()):
		var task = tasks[i]

		var start_t = task["start"]
		var end_t = task["end"]

		var start_ratio = float(start_t - min_time) / total_time if total_time > 0 else 0.0
		var end_ratio = float(end_t - min_time) / total_time if total_time > 0 else 0.0

		var x1 = margin + start_ratio * usable_width
		var x2 = margin + end_ratio * usable_width
		var y = line_y - 35 - i * (task_height + spacing)

		var rect_width = max(x2 - x1, 5.0)
		var rect = Rect2(Vector2(x1, y), Vector2(rect_width, task_height))

		# Цвет участника
		var current_color = Color(0.5, 0.5, 0.5)
		var exec = task["executor"]

		if exec != "":
			if EventBus.active_colors.has(exec):
				current_color = EventBus.active_colors[exec]
			else:
				current_color = Color.from_hsv(float(exec.hash() % 100) / 100.0, 0.7, 0.9)

		# Рисуем полоску
		draw_rect(rect, current_color)

	# Засечки времени
	var ticks = 12

	for i in range(ticks + 1):
		var x = margin + i * (usable_width / ticks)
		draw_line(Vector2(x, line_y), Vector2(x, line_y - 10), Color.WHITE, 2)