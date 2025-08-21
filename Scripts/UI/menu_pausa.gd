extends Control
class_name PauseMenu

func _ready() -> void:
	hide() 
	
	for _button in get_tree().get_nodes_in_group("button"):
		_button.pressed.connect(_on_button_pressed.bind(_button))

func _on_button_pressed(_button: Button) -> void:
	match _button.name:
		"ResumeButton":
			get_tree().paused = false
			hide()
			
		"MenuButton":
			get_tree().paused = false
			get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")
