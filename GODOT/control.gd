extends Control # ИСПРАВЛЕНО: Теперь расширяем обычный Control, который можно двигать

var dragging = false
var drag_offset = Vector2.ZERO

# По умолчанию ID равен 0. Если он 0, значит заметка абсолютно новая
var note_id = 0

# ИСПРАВЛЕНО: Добавлен путь через VBoxContainer, так как скрипт теперь на корневом узле
@onready var executor_input = $VBoxContainer/ExecutorContainer/ExecutorInput
@onready var description_input = $VBoxContainer/DescriptionContainer/DescriptionInput
@onready var type_input = $VBoxContainer/TypeContainer/TypeInput
@onready var start = $VBoxContainer/Start/StartInput
@onready var end = $VBoxContainer/End/EndInput
@onready var close_button = $VBoxContainer/Header/HBox/CloseButton

func _ready() -> void: 
	# Если ID не был передан из воркспейса при загрузке, 
	# значит кнопка "Добавить" создала новую заметку — генерируем для неё свободный ID
	if note_id == 0:
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
	var exec_text = executor_input.text if executor_input else ""
	var desc_text = description_input.text if description_input else ""
	var start_text = start.text if start else ""
	var end_text = end.text if end else ""
	
	if not start and has_node("VBoxContainer/StartInput"):
		start_text = get_node("VBoxContainer/StartInput").text
	
	if not end:
		if has_node("VBoxContainer/DeadlineInput"):
			end_text = get_node("VBoxContainer/DeadlineInput").text
		elif has_node("VBoxContainer/DeadlineContainer/DeadlineInput"):
			end_text = get_node("VBoxContainer/DeadlineContainer/DeadlineInput").text

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
	# Теперь файл перезаписывает строго СВОЙ собственный ID
	var file = FileAccess.open("res://note_" + str(note_id) + ".json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _on_save_button_pressed() -> void:
	save_note_data()
	var updated_data = get_note_data()
	updated_data["__file"] = "res://note_" + str(note_id) + ".json"
	EventBus.note_data_changed.emit(updated_data)

# Заглушки для защиты от вылетов
func _on_input_changed(_new_text: String = "") -> void:
	pass

func _on_executor_input_text_changed(_new_text: String = "") -> void:
	pass
