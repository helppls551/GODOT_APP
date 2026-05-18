extends Control

# Размер самого круга диаграммы
var wheel_size = 180
# Отступ безопасности со всех сторон, чтобы толщина круга не обрезалась
var padding = 20

var tasks = []

func _ready():
	# Задаем общий размер ноды с учетом отступов
	var total_size = wheel_size + padding * 2
	custom_minimum_size = Vector2(total_size, total_size)
	size = Vector2(total_size, total_size)
	
	if EventBus.has_signal("note_data_changed"):
		EventBus.note_data_changed.connect(_on_data_updated)
		
	# Подключаем смену цвета к отдельной функции обновления отрисовки
	if EventBus.has_signal("participant_color_changed"):
		EventBus.participant_color_changed.connect(_on_color_changed_signal)
		
	load_tasks_json()

func _on_data_updated():
	load_tasks_json()
	queue_redraw()

func _on_color_changed_signal(a = null, b = null, c = null):
	# Универсальные аргументы по умолчанию спасают от ошибок несовпадения сигналов
	queue_redraw()

func load_tasks_json():
	tasks.clear()
	var dir = DirAccess.open("res://")
	if not dir: return
	
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if filename.begins_with("note_") and filename.ends_with(".json"):
			var file = FileAccess.open("res://" + filename, FileAccess.READ)
			if file:
				var data = JSON.parse_string(file.get_as_text())
				if data and typeof(data) == TYPE_DICTIONARY and data.has("executor"):
					tasks.append({"executor": str(data["executor"]).strip_edges()})
				file.close()
		filename = dir.get_next()
	dir.list_dir_end()

func _draw():
	# Твои настроенные вручную координаты центра и размеры круга
	var center = Vector2(65, 65)
	var radius = 42
	var thickness = 84
	
	if tasks.size() == 0:
		draw_arc(center, radius, 0, deg_to_rad(360), 64, Color(0.6, 0.6, 0.6), thickness)
		return

	var main_node = get_tree().current_scene
	var p_colors = null
	if main_node and "participant_colors" in main_node:
		p_colors = main_node.participant_colors

	var counts = {}
	var total_valid = 0
	for task in tasks:
		var exec = task["executor"]
		if exec != "":
			counts[exec] = counts.get(exec, 0) + 1
			total_valid += 1

	if total_valid == 0:
		draw_arc(center, radius, 0, deg_to_rad(360), 64, Color(0.6, 0.6, 0.6), thickness)
		return

	var current_angle = -90.0
	var overlap = 0.6 
	
	# ИСПРАВЛЕНО: Используем встроенный метод Control вместо проблемного ThemeDB
	var default_font = get_theme_default_font()
	var font_size = 13
	
	for exec in counts.keys():
		var count = counts[exec]
		var percentage = float(count) / total_valid
		var angle_delta = percentage * 360.0
		
		var color = Color(0.5, 0.5, 0.5)
		if p_colors and p_colors.has(exec):
			color = p_colors[exec]
			
		var start_rad = deg_to_rad(current_angle - overlap)
		var end_rad = deg_to_rad(current_angle + angle_delta + overlap)
		
		# Рисуем цветной сектор диаграммы
		draw_arc(center, radius, start_rad, end_rad, 64, color, thickness)
		
		# Отображаем проценты для секторов, доля которых больше или равна 5%
		if percentage >= 0.05:
			# Вычисляем центральный угол текущего сектора
			var mid_angle_rad = deg_to_rad(current_angle + angle_delta / 2.0)
			
			# Расстояние от центра круга до текста (45 пикселей)
			var text_dist = 45.0 
			var text_pos = center + Vector2(cos(mid_angle_rad), sin(mid_angle_rad)) * text_dist
			
			# Текст процентов (например, "25%")
			var percent_text = str(round(percentage * 100)) + "%"
			
			# Расчет размера текста для центрирования
			var text_size = default_font.get_string_size(percent_text, 0, -1, font_size)
			var final_text_pos = text_pos - text_size / 2.0
			final_text_pos.y += text_size.y / 4.0
			
			# Отрисовка черной подложки (тени)
			draw_string(default_font, final_text_pos + Vector2(1, 1), percent_text, 0, -1, font_size, Color.BLACK)
			# Отрисовка основного белого текста
			draw_string(default_font, final_text_pos, percent_text, 0, -1, font_size, Color.WHITE)
		
		current_angle += angle_delta
