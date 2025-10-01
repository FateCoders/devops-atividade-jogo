# TrainingArea.gd
extends Node2D
class_name TrainingArea

# --- SINAIS PARA O HUD ---
signal building_hovered(building_ref)
signal building_unhovered(building_ref)
signal building_clicked(building_ref)
signal vacancy_opened(profession: NPC.Profession)

@export var building_name: String = "Área de Treinamento"
@export var max_capacity: int = 3

@export var required_profession: NPC.Profession = NPC.Profession.GUERREIRO
@export var max_instances: int = 5

@export var npc_count: int = 3
@export var possible_npc_scenes: Array[PackedScene]

@export_category("Horário de Trabalho")
@export var work_starts_at: float = 7.0
@export var work_ends_at: float = 12.0

@export var security_bonus: int = 15
@export var relations_bonus: int = 5

# ADICIONADO: Variáveis para gerenciar os locais de trabalho.
var all_work_spots: Array[Marker2D] = []
var available_work_spots: Array[Marker2D] = []

@export var cost: Dictionary = {
	"dinheiro": 100,
}

const OUTLINE_MATERIAL = preload("res://Resources/Shaders/outline_material.tres")
@onready var main_sprite = $Sprite2D
@onready var interaction_area = $InteractionArea
@onready var status_bubble = $buildingStatusBubble

var workers: Array[NPC] = []

func _ready():
	for child in get_children():
		if child is Marker2D:
			all_work_spots.append(child)
	available_work_spots = all_work_spots.duplicate()
	print("Área de Treinamento '%s' pronta. Bônus aplicados." % self.name)

	interaction_area.input_event.connect(_on_interaction_area_input_event)
	interaction_area.mouse_entered.connect(_on_interaction_area_mouse_entered)
	interaction_area.mouse_exited.connect(_on_interaction_area_mouse_exited)


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

func get_status_info() -> Dictionary:
	var workers = [] # Substitua por sua variável de trabalhadores
	var info = {
		"name": "Área de treinamento", # Você pode exportar uma variável para nomes customizados se quiser
		"details": "Área de segurança",
	}
	return info

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


func highlight_on():
	if is_instance_valid(main_sprite):
		main_sprite.material = OUTLINE_MATERIAL

func highlight_off():
	if is_instance_valid(main_sprite):
		main_sprite.material = null
		
func _on_interaction_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		emit_signal("building_clicked", self)

func _on_interaction_area_mouse_entered():
	emit_signal("building_hovered", self)

func _on_interaction_area_mouse_exited():
	emit_signal("building_unhovered", self)
