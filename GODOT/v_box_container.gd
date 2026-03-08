extends VBoxContainer

var dragging = false
var drag_offset = Vector2.ZERO
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
func _on_closebut_pressed() -> void:	
	$".".hide()


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		drag_offset = get_global_mouse_position() - global_position

	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - drag_offset
