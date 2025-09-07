# HidingPlace.gd
extends Node2D
class_name HidingPlace

# Esconderijos não geram novos NPCs, apenas abrigam os existentes[cite: 20].
@export var npc_count: int = 0

# Você pode definir a capacidade do esconderijo aqui.
@export var capacity: int = 10
var npcs_escondidos: Array[NPC] = []

func _ready():
	# Ao ser construído, o esconderijo aumenta a Segurança do quilombo[cite: 6].
	StatusManager.mudar_status("seguranca", 10)
	print("Esconderijo construído. Segurança aumentada.")

# No futuro, você pode criar funções para os NPCs usarem durante um ataque.
# func abrigar_npc(npc: NPC):
#     if npcs_escondidos.size() < capacity:
#         npcs_escondidos.append(npc)
#         npc.hide()
