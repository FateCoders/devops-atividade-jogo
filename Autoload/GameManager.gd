# GameManager.gd
extends Node

const DAYS_TO_WIN: int = 30
@export var victory_screen_scene: PackedScene = preload("res://Scenes/UI/victory.tscn")
@export var defeat_screen_scene: PackedScene = preload("res://Scenes/UI/defeatScreen.tscn")

signal victory_achieved

# ADICIONADO: Sinal para que outros scripts possam anunciar o fim do jogo.
signal game_over(reason)

var _is_game_over: bool = false # Para evitar que o fim de jogo seja chamado várias vezes

func _ready():
	if WorldTimeManager:
		WorldTimeManager.day_passed.connect(_on_new_day_started)
	
	# ADICIONADO: Conecta o sinal de game over à função que encerra o jogo.
	game_over.connect(trigger_defeat)
	
func _on_new_day_started(day_number: int):
	print("[GameManager] Recebeu notícia do dia %d. Verificando condição de vitória..." % day_number)
	
	if day_number >= WorldTimeManager.victory_day:
		_trigger_victory()

func _trigger_victory():
	if _is_game_over: return
	_is_game_over = true
	
	print("VITÓRIA! O jogador sobreviveu por %d dias." % WorldTimeManager.victory_day)
	get_tree().paused = true
	
	emit_signal("victory_achieved")

# ADICIONADO: Função central que lida com a derrota.
func trigger_defeat(reason: String):
	# Se o jogo já acabou (por vitória ou outra derrota), não faz nada.
	if _is_game_over: return
	_is_game_over = true
	
	print("DERROTA! Motivo: ", reason)
	get_tree().paused = true
	
	if defeat_screen_scene:
		var defeat_screen = defeat_screen_scene.instantiate()
		add_child(defeat_screen)
		# Passa o motivo da derrota para a tela.
		defeat_screen.set_reason(reason)
	else:
		printerr("Cena da tela de derrota não foi definida no GameManager!")
