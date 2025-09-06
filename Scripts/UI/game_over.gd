extends CanvasLayer

@export_category("Interação do Cursor")
## A imagem do cursor que aparecerá ao passar o mouse sobre este NPC.
@export var interaction_cursor: Texture2D
## O "ponto quente" do cursor (onde o clique acontece). (0,0) é o canto superior esquerdo.
@export var cursor_hotspot: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_quit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/menu_inicial.tscn")
