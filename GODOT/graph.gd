extends Control

var tasks = [
	{"start": "2026-01-01", "end": "2026-01-10"},
	{"start": "2026-01-01", "end": "2026-02-15"},
	{"start": "2026-01-01", "end": "2026-04-01"},
]

func _ready():
	queue_redraw()

func date_to_unix(d_str):
	var parts = d_str.split("-")
	var dt = {
		"year": int(parts[0]),
		"month": int(parts[1]),
		"day": int(parts[2]),
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
