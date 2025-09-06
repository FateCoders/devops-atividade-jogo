extends Control
class_name MainMenu

@export_category("Interação do Cursor")
## A imagem do cursor que aparecerá ao passar o mouse sobre este NPC.
@export var interaction_cursor: Texture2D
## O "ponto quente" do cursor (onde o clique acontece). (0,0) é o canto superior esquerdo.
@export var cursor_hotspot: Vector2 = Vector2.ZERO

func _ready() -> void:	if interaction_cursor:
	if not SaveManager.save_exists():
		var continue_button = $VBoxContainer/ButtonsContainer/Continue
		continue_button.disabled = true
		
		var shadow_node = continue_button.find_child("Shadow", false)
		if shadow_node:
			shadow_node.hide()
	
	MusicManager.play_menu_music()
	
	for button in get_tree().get_nodes_in_group("button"):
		button.pressed.connect(_on_button_pressed.bind(button))

func _process(delta: float) -> void:
	Input.set_custom_mouse_cursor(interaction_cursor, Input.CURSOR_ARROW, cursor_hotspot)

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
