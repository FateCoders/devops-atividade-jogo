# HidingPlace.gd
extends Node2D
class_name HidingPlace

# --- SINAIS PARA O HUD ---
signal building_hovered(building_ref)
signal building_unhovered(building_ref)
signal building_clicked(building_ref)

@export var building_name: String = "Escnderijo"
@export var max_capacity: int = 0

@export var max_instances: int = 3

# Esconderijos não geram novos NPCs, apenas abrigam os existentes[cite: 20].
@export var npc_count: int = 0
@export var security_bonus: int = 10

# Você pode definir a capacidade do esconderijo aqui.
@export var capacity: int = 10
var npcs_escondidos: Array[NPC] = []

@export var cost: Dictionary = {
	"dinheiro": 20,
}

const OUTLINE_MATERIAL = preload("res://Resources/Shaders/outline_material.tres")
@onready var main_sprite = $Sprite
@onready var interaction_area = $InteractionArea
@onready var status_bubble = $buildingStatusBubble

func _ready():
	interaction_area.input_event.connect(_on_interaction_area_input_event)
	interaction_area.mouse_entered.connect(_on_interaction_area_mouse_entered)
	interaction_area.mouse_exited.connect(_on_interaction_area_mouse_exited)

func confirm_construction():
	# A lógica de mudar os status agora vive aqui!
	StatusManager.mudar_status("seguranca", security_bonus)
	print("Esconderijo '%s' CONFIRMADA. Bônus aplicados." % self.name)

func get_status_info() -> Dictionary:
	var workers = [] # Substitua por sua variável de trabalhadores
	var info = {
		"name": "Esconderijo", # Você pode exportar uma variável para nomes customizados se quiser
		"details": "Área do esconderijo",
	}
	return info

func highlight_on():
	if is_instance_valid(main_sprite):
		main_sprite.material = OUTLINE_MATERIAL

func highlight_off():
	if is_instance_valid(main_sprite):
		main_sprite.material = null
		
func _on_interaction_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		emit_signal("building_clicked", self)

func _on_interaction_area_mouse_entered():
	emit_signal("building_hovered", self)

func _on_interaction_area_mouse_exited():
	emit_signal("building_unhovered", self)


# No futuro, você pode criar funções para os NPCs usarem durante um ataque.
# func abrigar_npc(npc: NPC):
#     if npcs_escondidos.size() < capacity:
#         npcs_escondidos.append(npc)
#         npc.hide()
