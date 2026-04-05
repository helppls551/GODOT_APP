extends VBoxContainer

var dragging = false
var drag_offset = Vector2.ZERO
var note_id = 0
@onready var executor_input = $ExecutorContainer/ExecutorInput
@onready var description_input = $DescriptionContainer/DescriptionInput
@onready var type_input = $TypeContainer/TypeInput
@onready var deadline_input = $DeadlineContainer/DeadlineInput
@onready var close_button = $Header/HBox/CloseButton

func _ready() -> void: 
	note_id = get_next_available_id()
	#load_note_data()
	
	# Подключаем сигналы изменения текста
#	executor_input.text_changed.connect(_on_input_changed)
#	description_input.text_changed.connect(_on_input_changed)
#	type_input.text_changed.connect(_on_input_changed)
#	deadline_input.text_changed.connect(_on_input_changed)

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
	# Ищем максимальный существующий ID
	while FileAccess.file_exists("res://note_" + str(id) + ".json"):
		id += 1
	return id

func get_note_data() -> Dictionary:
	return {
		"executor": executor_input.text,
		"description": description_input.text,
		"type": type_input.text,
		"start": deadline_input.text.substr(0,10),
		"deadline": deadline_input.text.substr(11,21),
		"position_x": position.x,
		"position_y": position.y
	}

func save_note_data():
	var data = get_note_data()
	var file = FileAccess.open("res://note_" + str(note_id) + ".json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

#func load_note_data():
	#var filename = "res://note_" + str(note_id) + ".json"
	#if FileAccess.file_exists(filename):
		#var file = FileAccess.open(filename, FileAccess.READ)
		#var data = JSON.parse_string(file.get_as_text())
		#file.close()
		#
		#if data:
			#executor_input.text = data.get("executor", "")
			#description_input.text = data.get("description", "")
			#type_input.text = data.get("type", "")
			#deadline_input.text = data.get("deadline", "")
			#position.x = data.get("position_x", position.x)
			#position.y = data.get("position_y", position.y)


func _on_save_button_pressed() -> void:
	save_note_data()
	EventBus.note_data_changed.emit()
