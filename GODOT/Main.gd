extends Control

@onready var workspace: Control = $Workspace
@onready var add_button: Button = $TopPanel/AddButton
@onready var close_button: Button = $TopPanel/CloseButton
@onready var participants_panel: Panel = $ParticipantsPanel
@onready var participant_list: VBoxContainer = $ParticipantsPanel/ParticipantList

var participants = []  # Пустой список участников
var notes_scene = preload("res://notes.tscn")

func _ready():
	# Подключаем сигналы кнопок верхней панели
	add_button.pressed.connect(_on_add_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Загружаем список участников
	update_participants_list()
	
	# Растягиваем окно на весь экран при запуске
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func update_participants_list():
	# Очищаем список
	for child in participant_list.get_children():
		child.queue_free()
	
	# Добавляем участников (если есть)
	for participant in participants:
		var participant_item = Panel.new()
		participant_item.custom_minimum_size = Vector2(0, 30)
		participant_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		participant_item.color = Color(0.25, 0.25, 0.25, 1)
		
		var name_label = Label.new()
		name_label.text = participant
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		name_label.position = Vector2(5, 5)
		name_label.size = Vector2(165, 20)
		
		participant_item.add_child(name_label)
		participant_list.add_child(participant_item)

func _on_add_button_pressed():
	# Здесь будет создание новой заметки
	pass

func _on_close_button_pressed():
	get_tree().quit()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_RIGHT \
	and event.pressed:
		
		var note = notes_scene.instantiate()
		add_child(note)
		note.position = get_global_mouse_position()
