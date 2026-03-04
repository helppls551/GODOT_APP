extends TextEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_note()
# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass
	
func save_note():
	var file = FileAccess.open("res://note.txt",FileAccess.WRITE)
	file.store_string($".".text)
	file.close()

func load_note():
	if FileAccess.file_exists("res://note.txt"):
		var file = FileAccess.open("res://note.txt", FileAccess.READ)
		$".".text = file.get_as_text()
		file.close()

func _on_text_changed():
	save_note()
