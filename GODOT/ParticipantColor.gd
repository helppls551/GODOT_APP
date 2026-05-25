extends Control

signal color_changed(new_color: Color)

var participant_name: String = ""
var current_color: Color = Color(1, 0, 0)
var current_idx: int = 0
var palette: Array = []
var main_script = null


func setup(p_name: String, p_color: Color, p_palette: Array, main_ref):
	participant_name = p_name
	current_color = p_color
	palette = p_palette
	main_script = main_ref

	# Ищем индекс текущего цвета
	current_idx = 0

	for i in range(palette.size()):
		if palette[i].is_equal_approx(current_color):
			current_idx = i
			break

	custom_minimum_size = Vector2(20, 20)
	queue_redraw()


func _draw():
	draw_circle(Vector2(10, 10), 10, current_color)


func _gui_input(event):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:

		if palette.size() == 0:
			return

		var start_idx = current_idx

		# Перебираем цвета пока не найдём свободный
		while true:

			current_idx = (current_idx + 1) % palette.size()

			var candidate_color = palette[current_idx]
			var color_is_used = false

			# Проверяем занят ли цвет другим участником
			for participant in EventBus.active_colors.keys():

				# СВОЙ цвет можно использовать
				if participant == participant_name:
					continue

				var used_color = EventBus.active_colors[participant]

				if used_color.is_equal_approx(candidate_color):
					color_is_used = true
					break

			# Если цвет свободен — выбираем его
			if not color_is_used:
				current_color = candidate_color

				# Сохраняем новый цвет
				EventBus.active_colors[participant_name] = current_color

				color_changed.emit(current_color)
				queue_redraw()
				return

			# Если вернулись к началу — свободных цветов нет
			if current_idx == start_idx:
				return