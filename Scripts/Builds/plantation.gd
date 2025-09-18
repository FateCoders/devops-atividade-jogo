# Plantation.gd
extends Node2D
class_name Plantation

signal vacancy_opened(profession: NPC.Profession)

@export var required_profession: NPC.Profession = NPC.Profession.AGRICULTOR
@export var max_instances: int = 5

@export var npc_scene_to_spawn: PackedScene
@export var npc_count: int = 2

@export_category("Horário de Trabalho")
@export var work_starts_at: float = 8.0  # 8 AM
@export var work_ends_at: float = 17.0 # 5 PM

@export var cost: Dictionary = {
	"dinheiro": 20,
}

@onready var status_bubble = $buildingStatusBubble

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

func add_worker(npc: NPC):
	if not workers.has(npc):
		workers.append(npc)
		print("'%s' foi adicionado como trabalhador em '%s'. Total: %d" % [npc.name, self.name, workers.size()])

func remove_worker(npc_leaving: NPC):
	# 1. Verifica se o NPC realmente trabalha aqui antes de tentar remover
	if workers.has(npc_leaving):
		# 2. Remove o NPC da lista de trabalhadores
		workers.erase(npc_leaving)
		print("'%s' deixou o trabalho em '%s'. Vaga aberta!" % [npc_leaving.name, self.name])
		
		# 3. Emite o sinal para o QuilomboManager saber que há uma vaga!
		emit_signal("vacancy_opened", required_profession)

func get_status_info() -> Dictionary:
	var workers = [] # Substitua por sua variável de trabalhadores
	var info = {
		"name": "Plantação", # Você pode exportar uma variável para nomes customizados se quiser
		"details": "Área de plantação",
	}
	return info

func _on_interaction_area_mouse_entered() -> void:
	var info = get_status_info()
	status_bubble.show_info(info)


func _on_interaction_area_mouse_exited() -> void:
	status_bubble.hide_info()
