extends Panel

signal window_closed

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

@onready var close_button: Button = $Header/CloseButton
@onready var header: Panel = $Header

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)
	header.gui_input.connect(_on_header_gui_input)

func _on_header_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = get_global_mouse_position() - global_position
			z_index = 1
		else:
			dragging = false
			z_index = 0
	
	elif event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - drag_offset

func _on_close_button_pressed():
	window_closed.emit()
