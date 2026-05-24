extends Control

signal color_changed(new_color: Color)

var participant_name: String = ""
var current_color: Color = Color(1, 0, 0) # Настоящий цвет, который мы рисуем
var current_idx: int = 0
var palette: Array = []
var main_script = null

# ИСПРАВЛЕНИЕ: Мы ушли от индексов. Теперь этот метод принимает объект цвета (p_color)
func setup(p_name: String, p_color: Color, p_palette: Array, main_ref):
	participant_name = p_name
	current_color = p_color # Запоминаем НАСТОЯЩИЙ цвет
	palette = p_palette
	main_script = main_ref
	
	# Вычисляем индекс в палитре приблизительно (для совместимости при клике)
	current_idx = 0
	for i in range(palette.size()):
		if palette[i].is_equal_approx(current_color):
			current_idx = i
			break
			
	custom_minimum_size = Vector2(20, 20)
	queue_redraw()

func _draw():
	# МЫ РИСУЕМ НАСТОЯЩИЙ ЦВЕТ, а не индекс
	draw_circle(Vector2(10, 10), 10, current_color)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if palette.size() == 0: return
		
		# Переключение палитры по кругу по клику
		current_idx = (current_idx + 1) % palette.size()
		# Обновляем НАСТОЯЩИЙ цвет
		current_color = palette[current_idx]
		
		color_changed.emit(current_color)
		queue_redraw()
