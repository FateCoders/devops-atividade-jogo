# Plantation.gd
extends Node2D
class_name Plantation

@export var npc_scene_to_spawn: PackedScene
@export var npc_count: int = 2

@export_category("Horário de Trabalho")
@export var work_starts_at: float = 8.0  # 8 AM
@export var work_ends_at: float = 17.0 # 5 PM

var workers: Array[Node] = []
var all_work_spots: Array[Marker2D] = []
# ADICIONADO: Uma lista separada apenas para os locais que estão livres.
var available_work_spots: Array[Marker2D] = []

func _ready():
	print("Plantação '%s' pronta." % self.name)
	# Pega todos os work_spots da cena.
	for child in get_children():
		if child is Marker2D:
			all_work_spots.append(child)
	
	# Inicializa a lista de locais disponíveis como uma cópia de todos os locais.
	available_work_spots = all_work_spots.duplicate()

func confirm_construction():
	pass

# MODIFICADO: Esta função agora "reserva" um local e o retorna.
func claim_available_work_spot() -> Marker2D:
	# Se não houver locais disponíveis, retorna nulo.
	if available_work_spots.is_empty():
		return null
	
	# Pega um local aleatório da lista de DISPONÍVEIS.
	var spot = available_work_spots.pick_random()
	# Remove o local escolhido da lista de disponíveis para que ninguém mais o pegue.
	available_work_spots.erase(spot)
	
	print("Local '%s' foi reivindicado. Locais restantes: %d" % [spot.name, available_work_spots.size()])
	return spot

# ADICIONADO: Uma função para que o NPC "devolva" o local quando terminar.
func release_work_spot(spot: Marker2D):
	if is_instance_valid(spot) and not available_work_spots.has(spot):
		available_work_spots.append(spot)
		print("Local '%s' foi devolvido. Locais disponíveis: %d" % [spot.name, available_work_spots.size()])

func add_worker(npc: Node):
	workers.append(npc)

# A função get_available_work_position() não é mais necessária, pois foi substituída
# pela lógica mais inteligente de claim_available_work_spot().
