# TrainingArea.gd
extends Node2D
class_name TrainingArea

signal vacancy_opened(profession: NPC.Profession)

@export var required_profession: NPC.Profession = NPC.Profession.GUERREIRO
@export var max_instances: int = 5

@export var npc_count: int = 3
@export var possible_npc_scenes: Array[PackedScene]

@export_category("Horário de Trabalho")
@export var work_starts_at: float = 7.0
@export var work_ends_at: float = 12.0

@export var security_bonus: int = 15
@export var relations_bonus: int = 5

var is_functional: bool = false
@export var upkeep_resource: String = "ferramentas" # Recurso de manutenção
@export var upkeep_amount: int = 2 # Custo por dia para funcionar

# ADICIONADO: Variáveis para gerenciar os locais de trabalho.
var all_work_spots: Array[Marker2D] = []
var available_work_spots: Array[Marker2D] = []

@export var cost: Dictionary = {
	"dinheiro": 100,
}

@onready var status_bubble = $buildingStatusBubble

var workers: Array[NPC] = []

func _ready():
	for child in get_children():
		if child is Marker2D:
			all_work_spots.append(child)
	available_work_spots = all_work_spots.duplicate()
	print("Área de Treinamento '%s' pronta. Bônus aplicados." % self.name)
	
	add_to_group("functional_buildings")

func confirm_construction():
	# A lógica de mudar os status agora vive aqui!
	StatusManager.mudar_status("seguranca", security_bonus)
	StatusManager.mudar_status("relacoes", relations_bonus)
	print("Área de Treinamento '%s' CONFIRMADA. Bônus aplicados." % self.name)
	
	update_functionality()

# ADICIONADO: A função _notification para lidar com eventos do nó.
#func _notification(what):
	# Verificamos se a notificação é de que o nó está prestes a ser deletado.
#	if what == NOTIFICATION_PREDELETE:
		# Se for, revertemos os bônus que aplicamos.
#		StatusManager.mudar_status("seguranca", -security_bonus)
#		StatusManager.mudar_status("relacoes", -relations_bonus)
#		print("Área de Treinamento '%s' destruída. Bônus removidos." % self.name)

func add_worker(npc: NPC):
	if not workers.has(npc):
		workers.append(npc)
		print("'%s' começou a trabalhar em '%s'. Trabalhadores atuais: %d" % [npc.name, self.name, workers.size()])

func remove_worker(npc: NPC):
	if workers.has(npc):
		workers.erase(npc)
		print("'%s' parou de trabalhar em '%s'. Trabalhadores atuais: %d" % [npc.name, self.name, workers.size()])

func update_functionality():
	var required_resources = {upkeep_resource: upkeep_amount}
	if StatusManager.has_enough_resources(required_resources):
		StatusManager.spend_resources(required_resources)
		if not is_functional:
			is_functional = true
			StatusManager.mudar_status("seguranca", security_bonus)
			StatusManager.mudar_status("relacoes", relations_bonus)
			print("Área de Treinamento '%s' agora está funcional." % name)
	else:
		if is_functional:
			is_functional = false
			StatusManager.mudar_status("seguranca", -security_bonus)
			StatusManager.mudar_status("relacoes", -relations_bonus)
			print("Área de Treinamento '%s' parou de funcionar por falta de ferramentas/armas." % name)

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

func get_status_info() -> Dictionary:
	var details_text = "Guerreiros: %d/%d" % [workers.size(), npc_count]
	if not is_functional:
		details_text += "\n(Faltam Ferramentas!)"
	return { "name": "Área de Treinamento", "details": details_text }

func _on_interaction_area_mouse_entered() -> void:
	var info = get_status_info()
	status_bubble.show_info(info)


func _on_interaction_area_mouse_exited() -> void:
	status_bubble.hide_info()

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
