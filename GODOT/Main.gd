extends Control

@onready var workspace: Control = $Workspace
@onready var add_button: Button = $TopPanel/AddButton
@onready var clear_button: Button = $TopPanel/ClearButton

var note_window_scene: PackedScene
var notes_scene = preload("res://notes.tscn")
var notes_activ = null


func _ready():
	note_window_scene = preload("res://NoteWindow.tscn")
	notes_activ = notes_scene.instantiate()
	add_child(notes_activ)
	notes_activ.visible = false
	
	add_button.pressed.connect(_on_add_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	
	_create_demo_windows()

func _create_demo_windows():
	for i in range(3):	
		var window = note_window_scene.instantiate()
		var base_position = Vector2(100 + i * 40, 80 + i * 40)
		workspace.add_child(window)
		window.position = base_position
		window.window_closed.connect(_on_window_closed.bind(window))

func _on_add_button_pressed():
	var window = note_window_scene.instantiate()
	var random_x = randi_range(50, 600)
	var random_y = randi_range(50, 400)
	
	workspace.add_child(window)
	window.position = Vector2(random_x, random_y)
	window.window_closed.connect(_on_window_closed.bind(window))

func _on_clear_button_pressed():
	for child in workspace.get_children():
		child.queue_free()

func _on_window_closed(window):
	if is_instance_valid(window):
		window.queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			notes_activ.visible = !notes_activ.visible
