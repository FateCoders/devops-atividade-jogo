# TrainingArea.gd
extends Node2D
class_name TrainingArea

@export var npc_count: int = 3
@export var npc_scene_to_spawn: PackedScene

@export_category("Horário de Trabalho")
@export var work_starts_at: float = 7.0
@export var work_ends_at: float = 12.0

@export var security_bonus: int = 15
@export var relations_bonus: int = 5

# ADICIONADO: Variáveis para gerenciar os locais de trabalho.
var all_work_spots: Array[Marker2D] = []
var available_work_spots: Array[Marker2D] = []

func _ready():
	for child in get_children():
		if child is Marker2D:
			all_work_spots.append(child)
	available_work_spots = all_work_spots.duplicate()
	print("Área de Treinamento '%s' pronta. Bônus aplicados." % self.name)

func confirm_construction():
	# A lógica de mudar os status agora vive aqui!
	StatusManager.mudar_status("seguranca", security_bonus)
	StatusManager.mudar_status("relacoes", relations_bonus)
	print("Área de Treinamento '%s' CONFIRMADA. Bônus aplicados." % self.name)

# ADICIONADO: A função _notification para lidar com eventos do nó.
#func _notification(what):
	# Verificamos se a notificação é de que o nó está prestes a ser deletado.
#	if what == NOTIFICATION_PREDELETE:
		# Se for, revertemos os bônus que aplicamos.
#		StatusManager.mudar_status("seguranca", -security_bonus)
#		StatusManager.mudar_status("relacoes", -relations_bonus)
#		print("Área de Treinamento '%s' destruída. Bônus removidos." % self.name)

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
