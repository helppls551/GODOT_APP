extends Control

signal color_changed(new_color)

var participant_name: String = ""
var current_color_index: int = 0
var palette: Array = []
var parent_main = null

func setup(p_name: String, start_index: int, p_palette: Array, main_ref):
	participant_name = p_name
	current_color_index = start_index
	palette = p_palette
	parent_main = main_ref
	custom_minimum_size = Vector2(20, 20) # Размер круга
	queue_redraw()

func _draw():
	# Рисуем круг в центре области 20x20
	draw_circle(Vector2(10, 10), 10, palette[current_color_index])

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_next_available_color()

func select_next_available_color():
	var next_index = (current_color_index + 1) % palette.size()
	
	var attempts = 0
	while parent_main.is_color_taken(palette[next_index]) and attempts < palette.size():
		next_index = (next_index + 1) % palette.size()
		attempts += 1
	
	current_color_index = next_index
	queue_redraw()
	color_changed.emit(palette[current_color_index])