# SpiritualCenter.gd
extends Node2D
class_name SpiritualCenter

@export var npc_count: int = 1
@export var npc_scene_to_spawn: PackedScene

@export_category("Horário de Trabalho")
@export var work_starts_at: float = 10.0
@export var work_ends_at: float = 16.0

# ADICIONADO: Variáveis para gerenciar os locais de trabalho.
var all_work_spots: Array[Marker2D] = []
var available_work_spots: Array[Marker2D] = []

@export var relations_bonus: int = 10
@export var health_bonus: int = 5

func _ready():
	# ADICIONADO: Lógica para encontrar e inicializar os work_spots.
	for child in get_children():
		if child is Marker2D:
			all_work_spots.append(child)
	available_work_spots = all_work_spots.duplicate()

func confirm_construction():
	# A lógica de mudar os status agora vive aqui!
	StatusManager.mudar_status("relacoes", relations_bonus)
	StatusManager.mudar_status("saude", health_bonus)
	print("Igreja '%s' CONFIRMADA. Bônus aplicados." % self.name)

# ADICIONADO: Função para que NPCs reivindiquem um local.
func claim_available_work_spot() -> Marker2D:
	if available_work_spots.is_empty():
		return null
	
	var spot = available_work_spots.pick_random()
	available_work_spots.erase(spot)
	
	print("Local '%s' foi reivindicado em '%s'. Locais restantes: %d" % [spot.name, self.name, available_work_spots.size()])
	return spot

# ADICIONADO: Função para que NPCs devolvam um local.
func release_work_spot(spot: Marker2D):
	if is_instance_valid(spot) and not available_work_spots.has(spot):
		available_work_spots.append(spot)
		print("Local '%s' foi devolvido para '%s'. Locais disponíveis: %d" % [spot.name, self.name, available_work_spots.size()])
