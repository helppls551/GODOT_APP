extends Control

@onready var workspace: Control = $Workspace
@onready var add_button: Button = $TopPanel/AddButton
@onready var close_button: Button = $TopPanel/CloseButton
@onready var participants_panel: Panel = $ParticipantsPanel
@onready var participant_list: VBoxContainer = $ParticipantsPanel/ParticipantList

var participants = []
var note_scene = preload("res://notes.tscn")

var palette = [
	Color(1, 0, 0),       # Красный
	Color(1, 1, 0),       # Желтый
	Color(1, 0.5, 0),     # Оранжевый
	Color(0, 0, 1),       # Синий
	Color(0, 1, 0),       # Зеленый
	Color(0.5, 0, 0.5),   # Фиолетовый
	Color(0.4, 0.2, 0.1), # Коричневый
	Color(1, 0.7, 0.8)    # Розовый
]

var participant_colors = {}

func _ready():
	load_json()
	add_button.pressed.connect(_on_add_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	if EventBus.has_signal("note_data_changed"):
		EventBus.note_data_changed.connect(_on_note_data_changed)
	
	update_participants_list()
	
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func is_color_taken(color: Color) -> bool:
	return color in participant_colors.values()

func _on_note_data_changed():
	load_json()
	update_participants_list()

func update_participants_list():
	for child in participant_list.get_children():
		child.queue_free()
	
	var active_colors = {}
	for participant in participants:
		if participant_colors.has(participant):
			active_colors[participant] = participant_colors[participant]
	participant_colors = active_colors
	
	for participant in participants:
		if participant.strip_edges() == "":
			continue
			
		var row_hbox = HBoxContainer.new()
		row_hbox.add_theme_constant_override("separation", 10)
		
		var item_panel = Panel.new()
		item_panel.custom_minimum_size = Vector2(170, 35)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 1)
		style.set_corner_radius_all(5)
		item_panel.add_theme_stylebox_override("panel", style)
		
		var margin = MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		
		var scroll = ScrollContainer.new()
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		
		# Твой выбранный Вариант 2 оформления ползунка
		var h_bar = scroll.get_h_scroll_bar()
		h_bar.custom_minimum_size.y = 3
		h_bar.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
		h_bar.add_theme_stylebox_override("scroll_focus", StyleBoxEmpty.new())
		
		var grabber_style = StyleBoxFlat.new()
		grabber_style.bg_color = Color(1, 1, 1, 0.25)
		grabber_style.set_corner_radius_all(2)
		h_bar.add_theme_stylebox_override("grabber", grabber_style)
		h_bar.add_theme_stylebox_override("grabber_highlight", grabber_style)
		h_bar.add_theme_stylebox_override("grabber_pressed", grabber_style)
		
		var name_label = Label.new()
		name_label.text = participant
		name_label.custom_minimum_size.y = 35
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		scroll.add_child(name_label)
		margin.add_child(scroll)
		item_panel.add_child(margin)
		
		var circle_anchor = CenterContainer.new()
		circle_anchor.custom_minimum_size = Vector2(20, 35)
		
		var color_circle = Control.new()
		color_circle.set_script(load("res://ParticipantColor.gd"))
		
		if not participant_colors.has(participant):
			var assigned = false
			for i in range(palette.size()):
				if not is_color_taken(palette[i]):
					participant_colors[participant] = palette[i]
					assigned = true
					break
			if not assigned:
				participant_colors[participant] = palette[0]
		
		var current_idx = palette.find(participant_colors[participant])
		color_circle.setup(participant, current_idx, palette, self)
		
		color_circle.color_changed.connect(func(new_color):
			participant_colors[participant] = new_color
			EventBus.participant_color_changed.emit(participant, new_color)
		)
		
		circle_anchor.add_child(color_circle)
		row_hbox.add_child(item_panel)
		row_hbox.add_child(circle_anchor)
		
		participant_list.add_child(row_hbox)

func load_json():
	participants.clear()
	var dir = DirAccess.open("res://")
	if not dir: return
	
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		# Фильтр: сканируем строго файлы заметок note_*.json, отсекая любые левые системные конфиги
		if filename.begins_with("note_") and filename.ends_with(".json"):
			var file = FileAccess.open("res://" + filename, FileAccess.READ)
			if file:
				var data = JSON.parse_string(file.get_as_text())
				if data and typeof(data) == TYPE_DICTIONARY and data.has("executor"):
					var exec = str(data["executor"]).strip_edges()
					if exec != "" and not exec in participants:
						participants.append(exec)
				file.close()
		filename = dir.get_next()
	dir.list_dir_end()

func _on_add_button_pressed():
	var note = note_scene.instantiate()
	workspace.add_child(note)
	note.position = Vector2(100, 100)

func _on_close_button_pressed():
	get_tree().quit()