# LeadersHouse.gd
extends Node2D
class_name LeadersHouse

# --- SINAIS PARA O HUD ---
signal building_hovered(building_ref)
signal building_unhovered(building_ref)
signal building_clicked(building_ref)

@export var building_name: String = "Casa do Líder"
@export var max_capacity: int = 0

@export var max_instances: int = 1

# A Casa do Líder é única e não gera NPCs aleatórios.
@export var npc_count: int = 0

const OUTLINE_MATERIAL = preload("res://Resources/Shaders/outline_material.tres")
@onready var main_sprite = $Sprite
@onready var interaction_area = $InteractionArea
@onready var status_bubble = $buildingStatusBubble

func _ready():
	print("Casa do Líder construída.")

	interaction_area.input_event.connect(_on_interaction_area_input_event)
	interaction_area.mouse_entered.connect(_on_interaction_area_mouse_entered)
	interaction_area.mouse_exited.connect(_on_interaction_area_mouse_exited)

func confirm_construction():
	pass

# Esta função será chamada por um botão na sua UI para abrir o menu de diplomacia.
func abrir_menu_interacao_quilombos():
	print("Abrindo menu para interagir com outros quilombos...")
	# Aqui você colocaria a lógica para mostrar a interface de aliança/ataque/escambo.

func get_status_info() -> Dictionary:
	var workers = [] # Substitua por sua variável de trabalhadores
	var info = {
		"name": "Casa do Líder", # Você pode exportar uma variável para nomes customizados se quiser
		"details": "Centro do Quilombp",
	}
	return info

func highlight_on():
	if is_instance_valid(main_sprite):
		main_sprite.material = OUTLINE_MATERIAL

func highlight_off():
	if is_instance_valid(main_sprite):
		main_sprite.material = null

func _on_interaction_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		emit_signal("building_clicked", self)
		print("Casa do Líder clicada. Abrindo menu de quilombos...")
		
		# Agora, pedimos ao Hud para abrir a tela de listagem.
		# Assumimos que o seu Hud principal está no grupo "hud_main".
		var hud = get_tree().get_first_node_in_group("hud_main")
		
		# Verificação de segurança para garantir que o Hud foi encontrado.
		if is_instance_valid(hud):
			hud.show_quilombo_list()

func _on_interaction_area_mouse_entered():
	emit_signal("building_hovered", self)

func _on_interaction_area_mouse_exited():
	emit_signal("building_unhovered", self)
