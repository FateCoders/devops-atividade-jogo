# Plantation.gd
extends Node2D
class_name Plantation

@export var npc_scene_to_spawn: PackedScene
@export var npc_count: int = 2

var workers: Array[Node] = []
@onready var work_spots: Array[Marker2D] = _get_work_spots()

# --- ADICIONADO: FUNÇÃO DE AUTO-RELATÓRIO ---
func _ready():
	print("--- RELATÓRIO DA PLANTAÇÃO ---")
	print("Eu sou: ", self.name)
	print("Meu script é: ", get_script().resource_path)
	if npc_scene_to_spawn:
		print("Minha cena de NPC para gerar é: ", npc_scene_to_spawn.resource_path)
	else:
		print("Minha cena de NPC para gerar é: NULA (VAZIA)")
	
	print("Minha contagem de NPCs é: ", npc_count)
	print("---------------------------------")


func _get_work_spots() -> Array[Marker2D]:
	var spots: Array[Marker2D] = []
	for child in get_children():
		if child is Marker2D:
			spots.append(child)
	return spots

func get_available_work_position() -> Vector2:
	if not work_spots.is_empty():
		return work_spots.pick_random().global_position
	return global_position

func add_worker(npc: Node):
	workers.append(npc)
