# level.gd
extends Node2D # Ou o tipo do seu nó raiz (Node, Control, etc.)

# Pega uma referência à instância do PauseMenu que você adicionou na cena.
# @onready garante que a variável será preenchida apenas quando o nó estiver pronto.
@onready var pause_menu = $PauseMenu

# Esta função especial do Godot escuta por inputs que não foram "consumidos"
# pelo jogo, como cliques em botões. É o lugar perfeito para a lógica de pause.
func _unhandled_input(event: InputEvent) -> void:
	# 1. Verifica se a tecla pressionada corresponde à nossa ação "ui_pause" (o ESC).
	if event.is_action_pressed("ui_pause"):
		
		# 2. Inverte o estado de "pausado" da árvore de cenas do jogo.
		# Se estava 'false', vira 'true'. Se estava 'true', vira 'false'.
		get_tree().paused = not get_tree().paused
		
		# 3. Mostra ou esconde o menu de acordo com o novo estado.
		if get_tree().paused:
			pause_menu.show()
		else:
			pause_menu.hide()
