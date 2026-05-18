extends VBoxContainer

var dragging = false
var drag_offset = Vector2.ZERO
var note_id = 0

@onready var executor_input = $ExecutorContainer/ExecutorInput
@onready var description_input = $DescriptionContainer/DescriptionInput
@onready var type_input = $TypeContainer/TypeInput
@onready var start = $Start/StartInput
@onready var end = $End/EndInput
@onready var close_button = $Header/HBox/CloseButton

func _ready() -> void: 
	note_id = get_next_available_id()

func _on_header_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		drag_offset = get_global_mouse_position() - global_position

	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position() - drag_offset

func _on_closebut_pressed() -> void:
	hide()

func get_next_available_id() -> int:
	var id = 1
	while FileAccess.file_exists("res://note_" + str(id) + ".json"):
		id += 1
	return id

func get_note_data() -> Dictionary:
	# Безопасное получение текста (защита от null-instance)
	var exec_text = executor_input.text if executor_input else ""
	var desc_text = description_input.text if description_input else ""
	var start_text = start.text if start else ""
	var end_text = end.text if end else ""
	
	# Автоподстраховка: если узлы start или end не найдены по новым путям, ищем старые названия в сцене
	if not start and has_node("StartInput"):
		start_text = get_node("StartInput").text
	
	if not end:
		if has_node("DeadlineInput"):
			end_text = get_node("DeadlineInput").text
		elif has_node("DeadlineContainer/DeadlineInput"):
			end_text = get_node("DeadlineContainer/DeadlineInput").text

	return {
		"executor": exec_text,
		"description": desc_text,
		"start": start_text,
		"deadline": end_text,
		"position_x": position.x,
		"position_y": position.y
	}

func save_note_data():
	var data = get_note_data()
	var file = FileAccess.open("res://note_" + str(note_id) + ".json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _on_save_button_pressed() -> void:
	save_note_data()
	EventBus.note_data_changed.emit()

# Заглушки для защиты от вылетов, если сигналы изменения текста подключены через интерфейс редактора
func _on_input_changed(_new_text: String = "") -> void:
	pass

func _on_executor_input_text_changed(_new_text: String = "") -> void:
	pass
