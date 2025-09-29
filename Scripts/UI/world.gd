extends Node2D

@export_category("Interação do Cursor")
## A imagem do cursor que aparecerá ao passar o mouse sobre este NPC.
@export var interaction_cursor: Texture2D
@export var move_cursor: Texture2D
## O "ponto quente" do cursor (onde o clique acontece). (0,0) é o canto superior esquerdo.
@export var cursor_hotspot: Vector2 = Vector2.ZERO

@onready var hud = $HUD/Hud

var is_dragging_world: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hud.placement_preview_started.connect(hud.show_preview)
	hud.placement_preview_ended.connect(hud.clear_preview)
	
	Input.set_custom_mouse_cursor(interaction_cursor, Input.CURSOR_ARROW, cursor_hotspot)
	MusicManager.play_game_music()
	GameManager.start_tutorial()

func _process(delta: float) -> void:
	pass


# Em world.gd

func _unhandled_input(event: InputEvent):
	if hud.is_in_placement_mode:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			is_dragging_world = true
			Input.set_custom_mouse_cursor(move_cursor, Input.CURSOR_ARROW, cursor_hotspot)
		else:
			is_dragging_world = false
			Input.set_custom_mouse_cursor(interaction_cursor, Input.CURSOR_ARROW, cursor_hotspot)

	if event is InputEventMouseMotion and is_dragging_world:
		Input.set_custom_mouse_cursor(move_cursor, Input.CURSOR_ARROW, cursor_hotspot)
