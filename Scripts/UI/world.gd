extends Node2D

@export_category("Interação do Cursor")
## A imagem do cursor que aparecerá ao passar o mouse sobre este NPC.
@export var interaction_cursor: Texture2D
## O "ponto quente" do cursor (onde o clique acontece). (0,0) é o canto superior esquerdo.
@export var cursor_hotspot: Vector2 = Vector2.ZERO

@onready var game_ui = $GameUI
@onready var hud = $HUD/Hud

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# A conexão correta:
	# O sinal 'placement_preview_started' do objeto 'game_ui'
	# está sendo conectado à função 'show_preview' do objeto 'hud'.
	if SaveManager.save_exists():
		if SaveManager.load_game():
			QuilomboManager.load_buildings()
		else:
			print("Falha ao carrregar o jogo em word.gd")
	else:
		print("🆕 Nenhum save encontrado. Criando novo mundo...")
		_start_new_game()
		
	
	game_ui.placement_preview_started.connect(hud.show_preview)
	
	# O mesmo para o outro sinal:
	# O sinal 'placement_preview_ended' do 'game_ui'
	# conecta-se à função 'clear_preview' do 'hud'.
	game_ui.placement_preview_ended.connect(hud.clear_preview)
	
	Input.set_custom_mouse_cursor(interaction_cursor, Input.CURSOR_ARROW, cursor_hotspot)
	MusicManager.play_game_music()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _start_new_game():
	# Posiciona a câmera no centro inicial (ajuste a posição conforme necessário)
	$Camera2D.global_position = Vector2(640, 360)  # Exemplo de centro da tela

	await get_tree().create_timer(1.0).timeout
	SaveManager.save_game()
