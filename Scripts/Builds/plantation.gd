# Plantation.gd
extends Node2D
class_name Plantation

@export var npc_scene_to_spawn: PackedScene
@export var npc_count: int = 2

@export_category("Horário de Trabalho")
@export var work_starts_at: float = 8.0  # 8 AM
@export var work_ends_at: float = 17.0 # 5 PM

var workers: Array[Node] = []
@onready var work_spots: Array[Marker2D] = _get_work_spots()

func _ready():
	print("Plantação '", self.name, "' pronta.")

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
