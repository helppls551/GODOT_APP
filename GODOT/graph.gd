extends Control

# Список дат всех задач (можно потом подставлять динамически)
var task_dates: Array = [
	"2026-01-01",
	"2026-02-03",
	"2026-03-05",
	"2026-04-08",
	"2026-05-09",
]

func _ready():
	pass

func _draw():
	var w = size.x
	var h = size.y
	var margin = 30
	var line_y = h - 10  # линия прямо у нижней границы

	# Рисуем горизонтальную линию таймлайна
	draw_line(Vector2(margin, line_y), Vector2(w - margin, line_y), Color(0.7,0.7,0.7), 2)

	# Преобразуем даты в Unix timestamp
	var timestamps = []
	for d_str in task_dates:
		var parts = d_str.split("-")
		var dt = {
			"year": int(parts[0]),
			"month": int(parts[1]),
			"day": int(parts[2]),
			"hour": 12,
			"minute": 0,
			"second": 0
		}
		timestamps.append(Time.get_unix_time_from_datetime_dict(dt))

	# Находим мин и макс дату
	var min_time = timestamps[0]
	var max_time = timestamps[0]
	for t in timestamps:
		if t < min_time: min_time = t
		if t > max_time: max_time = t

	var total_time = max_time - min_time
	var usable_width = w - margin * 2

	# Рисуем точки и даты
	for i in range(task_dates.size()):
		var t = timestamps[i]
		var ratio = 0
		if total_time > 0:
			ratio = float(t - min_time) / float(total_time)

		var x = margin + ratio * usable_width
		var point_pos = Vector2(x, line_y)
		
		# Даты сверху точки
		var parts = task_dates[i].split("-")
		var day = parts[2]
		var month = parts[1]
		var date_text = day + "." + month

		# Рисуем точку на линии
		draw_circle(point_pos, 6, Color.WHITE)

		# Позиция текста над точкой
		var text_pos = point_pos + Vector2(-15, -15)
		var font = get_theme_default_font()  # безопасный способ получить шрифт
		draw_string(font, text_pos , date_text,HORIZONTAL_ALIGNMENT_FILL,-1,10,Color(1,1,1))
