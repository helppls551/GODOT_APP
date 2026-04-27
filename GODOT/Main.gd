extends Control

@onready var workspace: Control = $Workspace
@onready var add_button: Button = $TopPanel/AddButton
@onready var close_button: Button = $TopPanel/CloseButton
@onready var participants_panel: Panel = $ParticipantsPanel
@onready var participant_list: VBoxContainer = $ParticipantsPanel/ParticipantList

var participants = []
var note_scene = preload("res://notes.tscn")

func _ready():
	load_json()
	# Подключаем сигналы кнопок верхней панели
	add_button.pressed.connect(_on_add_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	EventBus.note_data_changed.connect(_on_note_data_changed)
	# Загружаем список участников
	update_participants_list()
	
	# Растягиваем окно на весь экран при запуске
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_note_data_changed():
	print("Получен сигнал об изменении данных")
	load_json()
	update_participants_list()

func update_participants_list():
	# Очищаем список
	for child in participant_list.get_children():
		child.queue_free()
	
	# Добавляем участников (если есть)
	for participant in participants:
		var participant_item = Panel.new()
		participant_item.custom_minimum_size = Vector2(0, 30)
		participant_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.25, 0.25, 0.25, 1)
		participant_item.add_theme_stylebox_override("panel", style)
		
		var name_label = Label.new()
		name_label.text = participant
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		name_label.position = Vector2(5, 5)
		name_label.size = Vector2(165, 20)
		
		participant_item.add_child(name_label)
		participant_list.add_child(participant_item)

func load_json():
	participants.clear()
	
	var dir = DirAccess.open("res://")
	if not dir:
		print("Ошибка открытия директории res://")
		return
	
	dir.list_dir_begin()
	var filename = dir.get_next()
	
	while filename != "":
		if filename.ends_with(".json"):
			var file = FileAccess.open("res://" + filename, FileAccess.READ)
			if file:
				var content = file.get_as_text()
				var data = JSON.parse_string(content)
				if data and data.has("executor"):
					participants.append(data["executor"])
				file.close()
		
		filename = dir.get_next()
	
	dir.list_dir_end()
	print("Всего загружено участников: ", participants.size())
	print("participants: ", participants)

func _on_add_button_pressed():
	# Создаём новую заметку при нажатии на кнопку "+"
	var note = note_scene.instantiate()
	workspace.add_child(note)
	# Позиционируем в центре видимой области
	note.position = Vector2(100, 100)

func _on_close_button_pressed():
	get_tree().quit()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_RIGHT \
	and event.pressed:
		
		var note = note_scene.instantiate()
		add_child(note)
		note.position = get_global_mouse_position()