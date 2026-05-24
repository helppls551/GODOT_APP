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
		EventBus.note_data_changed.connect(func(_data = {}): _on_note_data_changed())
	
	update_participants_list()
	
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func is_color_taken(color: Color) -> bool:
	return color in participant_colors.values()

func _on_note_data_changed():
	# Даем файловой системе микросекунду завершить запись, чтобы избежать конфликтов чтения
	await get_tree().process_frame
	load_json()
	update_participants_list()

func update_participants_list():
	if not is_inside_tree(): return
	
	for child in participant_list.get_children():
		child.queue_free()
	
	# Синхронизируем локальные цвета с глобальной шиной
	for participant in participants:
		if EventBus.active_colors.has(participant):
			participant_colors[participant] = EventBus.active_colors[participant]
	
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
		
		# --- НАДЕЖНАЯ ПРОВЕРКА ЦВЕТА ---
		if not participant_colors.has(participant):
			if EventBus.active_colors.has(participant):
				participant_colors[participant] = EventBus.active_colors[participant]
			else:
				var assigned = false
				for i in range(palette.size()):
					if not is_color_taken(palette[i]):
						participant_colors[participant] = palette[i]
						EventBus.active_colors[participant] = palette[i]
						assigned = true
						break
				if not assigned:
					participant_colors[participant] = palette[0]
					EventBus.active_colors[participant] = palette[0]
		var actual_color = participant_colors[participant]
		color_circle.setup(participant, actual_color, palette, self)
		
		color_circle.color_changed.connect(func(new_color):
			participant_colors[participant] = new_color
			EventBus.active_colors[participant] = new_color
			EventBus.participant_color_changed.emit(participant, new_color)
			_save_color_to_all_participant_files(participant, new_color)
			
			if color_circle.has_method("queue_redraw"):
				color_circle.queue_redraw()
		)
		# ----------------------------------
		
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
		if filename.begins_with("note_") and filename.ends_with(".json"):
			var path = "res://" + filename
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close() 
				
				var data = JSON.parse_string(text)
				if data and typeof(data) == TYPE_DICTIONARY and data.has("executor"):
					var exec = str(data["executor"]).strip_edges()
					if exec != "":
						if not exec in participants:
							participants.append(exec)
						
						# Если цвет для этой сессии уже сохранен в глобальной шине, берем его приоритетно
						if EventBus.active_colors.has(exec):
							participant_colors[exec] = EventBus.active_colors[exec]
						# Если в шине пусто, но цвет есть внутри файла JSON задачи
						elif data.has("panel_color") and str(data["panel_color"]) != "":
							var restored_color = Color.from_string(data["panel_color"], palette[0])
							participant_colors[exec] = restored_color
							EventBus.active_colors[exec] = restored_color
						# Если цвета нет нигде, подбираем из палитры
						elif not participant_colors.has(exec):
							var assigned = false
							for i in range(palette.size()):
								if not is_color_taken(palette[i]):
									participant_colors[exec] = palette[i]
									EventBus.active_colors[exec] = palette[i]
									assigned = true
									break
							if not assigned:
								participant_colors[exec] = palette[0]
								EventBus.active_colors[exec] = palette[0]
						
		filename = dir.get_next()
	dir.list_dir_end()
	
	# ИСПРАВЛЕНИЕ: Мы убрали отсюда автоматический спам сигналом participant_color_changed.
	# Вместо этого мы точечно обновляем интерфейс Workspace, если цвета обновились при загрузке.
	for participant in participant_colors:
		if EventBus.active_colors.has(participant):
			EventBus.participant_color_changed.emit(participant, participant_colors[participant])

func _save_color_to_all_participant_files(target_participant: String, new_color: Color):
	var target = target_participant.strip_edges()
	var dir = DirAccess.open("res://")
	if not dir: return
	
	dir.list_dir_begin()
	var filename = dir.get_next()
	
	while filename != "":
		if filename.begins_with("note_") and filename.ends_with(".json"):
			var path = "res://" + filename
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				
				var data = JSON.parse_string(text)
				if data and typeof(data) == TYPE_DICTIONARY and str(data.get("executor", "")).strip_edges() == target:
					data["panel_color"] = new_color.to_html()
					
					var write_file = FileAccess.open(path, FileAccess.WRITE)
					if write_file:
						write_file.store_string(JSON.stringify(data))
						write_file.close()
						
		filename = dir.get_next()
	dir.list_dir_end()

func _on_add_button_pressed():
	var note = note_scene.instantiate()
	workspace.add_child(note)
	note.position = Vector2(100, 100)

func _on_close_button_pressed():
	get_tree().quit()
