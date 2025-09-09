# HidingPlace.gd
extends Node2D
class_name HidingPlace

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

@onready var status_bubble = $buildingStatusBubble

func _ready():
	pass

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

func _on_interaction_area_mouse_entered() -> void:
	var info = get_status_info()
	status_bubble.show_info(info)


func _on_interaction_area_mouse_exited() -> void:
	status_bubble.hide_info()


# No futuro, você pode criar funções para os NPCs usarem durante um ataque.
# func abrigar_npc(npc: NPC):
#     if npcs_escondidos.size() < capacity:
#         npcs_escondidos.append(npc)
#         npc.hide()
