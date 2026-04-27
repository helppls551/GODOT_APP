extends Control

# Размер круга
var wheel_size = 120

# Цвета секторов (5 штук)
var colors = [
	Color(1, 0, 0, 1),      # 🔴 Красный
	Color(0, 1, 0, 1),      # 🟢 Зелёный
	Color(1, 1, 0, 1),      # 🟡 Жёлтый
	Color(0, 0, 1, 1),      # 🔵 Синий
	Color(1, 0.5, 0, 1)     # 🟠 Оранжевый
]

func _ready():
	# Устанавливаем размер
	custom_minimum_size = Vector2(wheel_size, wheel_size)
	size = Vector2(wheel_size, wheel_size)
	queue_redraw()

func _draw():
	var center = Vector2(wheel_size / 2, wheel_size / 2)
	var radius = wheel_size / 2 - 2
	
	var angle_per_sector = 360.0 / colors.size()
	
	# Рисуем каждый сектор (без белых границ)
	for i in range(colors.size()):
		var start_angle = deg_to_rad(i * angle_per_sector - 90)
		var end_angle = deg_to_rad((i + 1) * angle_per_sector - 90)
		
		# Рисуем закрашенный сектор
		draw_arc(center, radius, start_angle, end_angle, 30, colors[i], radius, true)