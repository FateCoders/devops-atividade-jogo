extends Node2D

@export_category("Interação do Cursor")
## A imagem do cursor que aparecerá ao passar o mouse sobre este NPC.
@export var interaction_cursor: Texture2D
## O "ponto quente" do cursor (onde o clique acontece). (0,0) é o canto superior esquerdo.
@export var cursor_hotspot: Vector2 = Vector2.ZERO

@onready var hud = $HUD/Hud

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# A conexão correta:
	# O sinal 'placement_preview_started' do objeto 'hud'
	# está sendo conectado à função 'show_preview' do objeto 'hud'.
	hud.placement_preview_started.connect(hud.show_preview)
	
	# O mesmo para o outro sinal:
	# O sinal 'placement_preview_ended' do 'hud'
	# conecta-se à função 'clear_preview' do 'hud'.
	hud.placement_preview_ended.connect(hud.clear_preview)
	
	Input.set_custom_mouse_cursor(interaction_cursor, Input.CURSOR_ARROW, cursor_hotspot)
	MusicManager.play_game_music()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
