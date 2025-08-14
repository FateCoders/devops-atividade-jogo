extends Control
class_name MainMenu

var _save: SaveGame
var _has_save: bool = _save.save_exists()

func _ready() -> void:
	if !_has_save:
		$VBoxContainer/ButtonsContainer/Continue.disabled = true
		$VBoxContainer/ButtonsContainer/Continue/Shadow.hide()
	
	for _button in get_tree().get_nodes_in_group("button"):
		_button.pressed.connect(_on_button_pressed.bind(_button))
		
func _on_button_pressed(_button: Button) -> void:
	match _button.name:
		"NewGame":
			_save.write_savegame()
			get_tree().change_scene_to_file("res://Scenes/Levels/level.tscn")
		"Continue":
			_save.load_savegame()
			get_tree().change_scene_to_file("res://Scenes/Levels/level_loaded.tscn")
		"Quit":
			get_tree().quit()
