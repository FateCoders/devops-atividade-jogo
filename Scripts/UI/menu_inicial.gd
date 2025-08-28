extends Control
class_name MainMenu

func _ready() -> void:
	
	if not SaveManager.save_exists():
		var continue_button = $VBoxContainer/ButtonsContainer/Continue
		continue_button.disabled = true
		
		var shadow_node = continue_button.find_child("Shadow", false)
		if shadow_node:
			shadow_node.hide()
	
	MusicManager.play_menu_music()
	
	for button in get_tree().get_nodes_in_group("button"):
		button.pressed.connect(_on_button_pressed.bind(button))


func _on_button_pressed(button: Button) -> void:
	match button.name:
		"NewGame":
			get_tree().change_scene_to_file("res://Scenes/World/world.tscn")
			
		"Continue":
			if SaveManager.load_game():
				get_tree().change_scene_to_file("res://Scenes/World/world.tscn")
			else:
				print("Falha ao carregar o jogo a partir do menu.")
				
		"Quit":
			get_tree().quit()
