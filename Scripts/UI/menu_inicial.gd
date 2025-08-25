extends Control
class_name MainMenu

# Não precisamos mais da variável _save, pois vamos usar o autoload SaveManager.

func _ready() -> void:
	# --- LÓGICA ATUALIZADA ---
	# Verificamos se o save existe usando nosso gerenciador global.
	if not SaveManager.save_exists():
		var continue_button = $VBoxContainer/ButtonsContainer/Continue
		continue_button.disabled = true
		
		# Procura pelo nó de sombra de forma segura
		var shadow_node = continue_button.find_child("Shadow", false) # O 'false' impede a busca recursiva
		if shadow_node:
			shadow_node.hide()
	
	# A conexão dos botões permanece igual.
	for button in get_tree().get_nodes_in_group("button"):
		button.pressed.connect(_on_button_pressed.bind(button))


func _on_button_pressed(button: Button) -> void:
	match button.name:
		"NewGame":
			# AÇÃO: Apenas inicia um novo jogo.
			# Não criamos um save aqui. O primeiro save será feito pelo jogador dentro do jogo.
			# Se quiser, pode deletar um save antigo ao iniciar um novo jogo.
			# SaveManager.delete_save() # -> Função opcional para criar no SaveManager
			get_tree().change_scene_to_file("res://Scenes/Levels/level.tscn")
			
		"Continue":
			# AÇÃO: Carrega os dados e DEPOIS muda de cena.
			# O SaveManager vai guardar os dados carregados, e a cena do jogo
			# vai usá-los quando for iniciada.
			if SaveManager.load_game():
				get_tree().change_scene_to_file("res://Scenes/Levels/level.tscn")
			else:
				print("Falha ao carregar o jogo a partir do menu.")
				
		"Quit":
			get_tree().quit()
