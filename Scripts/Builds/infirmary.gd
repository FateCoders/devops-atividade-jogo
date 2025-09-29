# Infirmary.gd
extends Node2D
class_name Infirmary

# --- SINAIS PARA O HUD ---
signal building_hovered(building_ref)
signal building_unhovered(building_ref)
signal building_clicked(building_ref)

signal vacancy_opened(profession: NPC.Profession)

@export var building_name: String = "Enfermaria"
@export var max_capacity: int = 1

@export var required_profession: NPC.Profession = NPC.Profession.ENFERMEIRO
@export var max_instances: int = 3

@export var npc_count: int = 1
@export var possible_npc_scenes: Array[PackedScene]

@export_category("Horário de Trabalho")
@export var work_starts_at: float = 9.0
@export var work_ends_at: float = 18.0

@export var health_bonus: int = 20

@export var cost: Dictionary = {
	"dinheiro": 100,
}

const OUTLINE_MATERIAL = preload("res://Resources/Shaders/outline_material.tres")
@onready var main_sprite = $Sprite
@onready var interaction_area = $InteractionArea
@onready var status_bubble = $buildingStatusBubble

# ADICIONADO: Variáveis para gerenciar os locais de trabalho.
var all_work_spots: Array[Marker2D] = []
var available_work_spots: Array[Marker2D] = []

var workers: Array[NPC] = []

func _ready():
	# ADICIONADO: Lógica para encontrar e inicializar os work_spots.
	for child in get_children():
		if child is Marker2D:
			all_work_spots.append(child)
	available_work_spots = all_work_spots.duplicate()

	interaction_area.input_event.connect(_on_interaction_area_input_event)
	interaction_area.mouse_entered.connect(_on_interaction_area_mouse_entered)
	interaction_area.mouse_exited.connect(_on_interaction_area_mouse_exited)

func confirm_construction():
	StatusManager.mudar_status("saude", health_bonus)
	print("Enfermaria '%s' CONFIRMADA. Bônus aplicados." % self.name)

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
		"name": "Enfermaria", # Você pode exportar uma variável para nomes customizados se quiser
		"details": "Área da enfermaria",
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
