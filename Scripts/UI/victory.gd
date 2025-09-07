# VictoryScreen.gd
extends CanvasLayer

# As variáveis de cursor não são necessárias aqui, então foram removidas para limpeza.

func _ready():
	# 1. A tela começa invisível.
	visible = false
	
	# 2. Conecta-se ao sinal de vitória do WorldTimeManager para "escutar" o anúncio.
	WorldTimeManager.victory_achieved.connect(_on_victory_achieved)



# A função _process agora pode ficar vazia.
func _process(delta: float):
	pass


# --- NOVA FUNÇÃO ---
# Esta função é chamada AUTOMATICAMENTE quando o WorldTimeManager emite o sinal de vitória.
func _on_victory_achieved():
	# 3. Torna a tela de vitória visível.
	visible = true
	# 4. Pausa o jogo.
	get_tree().paused = true


# --- FUNÇÕES DOS BOTÕES ---

# Chamada quando o botão "Sair" ou "Voltar ao Menu" é pressionado.
func _on_sair_btn_pressed():
	# É uma boa prática resetar os managers antes de voltar ao menu.
	SaveManager.save_game() # Salva o progresso final (opcional)
	QuilomboManager.reset_quilombo_state()

	# Garante que o jogo esteja despausado antes de mudar de cena.
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/menu_inicial.tscn")


func _on_continuar_btn_pressed():
	get_tree().paused = false
	visible = false
