# HidingPlace.gd
extends Node2D
class_name HidingPlace

# Esconderijos não geram novos NPCs, apenas abrigam os existentes[cite: 20].
@export var npc_count: int = 0
@export var security_bonus: int = 10

# Você pode definir a capacidade do esconderijo aqui.
@export var capacity: int = 10
var npcs_escondidos: Array[NPC] = []

func _ready():
	pass

func confirm_construction():
	# A lógica de mudar os status agora vive aqui!
	StatusManager.mudar_status("seguranca", security_bonus)
	print("Esconderijo '%s' CONFIRMADA. Bônus aplicados." % self.name)

# No futuro, você pode criar funções para os NPCs usarem durante um ataque.
# func abrigar_npc(npc: NPC):
#     if npcs_escondidos.size() < capacity:
#         npcs_escondidos.append(npc)
#         npc.hide()
