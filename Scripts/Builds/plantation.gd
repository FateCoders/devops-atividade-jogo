# Plantation.gd
extends Node2D
class_name Plantation

enum ProductionType { ALIMENTOS, REMEDIOS }
@export var production_type: ProductionType = ProductionType.ALIMENTOS
@export var daily_yield: int = 10

signal vacancy_opened(profession: NPC.Profession)

@export var required_profession: NPC.Profession = NPC.Profession.AGRICULTOR
@export var max_instances: int = 5

@export var possible_npc_scenes: Array[PackedScene]
@export var npc_count: int = 2

@export_category("Horário de Trabalho")
@export var work_starts_at: float = 8.0  # 8 AM
@export var work_ends_at: float = 17.0 # 5 PM

var is_functional: bool = false
@export var upkeep_resource: String = "ferramentas"
@export var upkeep_amount: int = 1

@export var cost: Dictionary = {
	"dinheiro": 20,
}

@onready var status_bubble = $buildingStatusBubble

var workers: Array[Node] = []
var all_work_spots: Array[Marker2D] = []
var available_work_spots: Array[Marker2D] = []

func _ready():
	print("Plantação '%s' pronta." % self.name)
	for child in get_children():
		if child is Marker2D:
			all_work_spots.append(child)
	
	available_work_spots = all_work_spots.duplicate()
	
	add_to_group("functional_buildings")

func confirm_construction():
	update_functionality()
	
func update_functionality():
	var required_resources = {upkeep_resource: upkeep_amount}
	if StatusManager.has_enough_resources(required_resources):
		StatusManager.spend_resources(required_resources)
		if not is_functional:
			is_functional = true
			print("Plantação '%s' agora está funcional." % name)
		
		_produce_resources()
	else:
		if is_functional:
			is_functional = false
			print("Plantação '%s' parou de funcionar por falta de ferramentas." % name)

func claim_available_work_spot() -> Marker2D:
	if available_work_spots.is_empty():
		return null
	
	var spot = available_work_spots.pick_random()
	available_work_spots.erase(spot)
	
	print("Local '%s' foi reivindicado. Locais restantes: %d" % [spot.name, available_work_spots.size()])
	
	# A linha 'add_worker(1)' foi REMOVIDA.
	
	return spot
	
func _produce_resources():
	if workers.is_empty():
		return

	var resource_to_produce: String
	
	match production_type:
		ProductionType.ALIMENTOS:
			resource_to_produce = "alimentos"
		ProductionType.REMEDIOS:
			resource_to_produce = "remedios"
	
	# A produção pode ser influenciada pelo número de trabalhadores.
	# Exemplo: Produção = rendimento_diario * número_de_trabalhadores
	var amount_produced = daily_yield * workers.size()
	
	StatusManager.mudar_status(resource_to_produce, amount_produced)
	print("Plantação '%s' produziu %d de %s." % [name, amount_produced, resource_to_produce])

func set_production_type(new_type: ProductionType):
	production_type = new_type
	
	# (Opcional) Você pode mudar a aparência da plantação aqui.
	# if new_type == ProductionType.ALIMENTOS:
	#	 $Sprite2D.texture = load("res://path/to/food_sprite.png")
	# else:
	#	 $Sprite2D.texture = load("res://path/to/remedy_sprite.png")
		
	print("Plantação '%s' foi configurada para produzir %s." % [self.name, ProductionType.keys()[new_type]])

# ADICIONADO: Uma função para que o NPC "devolva" o local quando terminar.
func release_work_spot(spot: Marker2D):
	if is_instance_valid(spot) and not available_work_spots.has(spot):
		available_work_spots.append(spot)
		print("Local '%s' foi devolvido. Locais disponíveis: %d" % [spot.name, available_work_spots.size()])

func add_worker(npc: NPC):
	if not workers.has(npc):
		workers.append(npc)
		print("'%s' começou a trabalhar em '%s'. Trabalhadores atuais: %d" % [npc.name, self.name, workers.size()])

func remove_worker(npc: NPC):
	if workers.has(npc):
		workers.erase(npc)
		print("'%s' parou de trabalhar em '%s'. Trabalhadores atuais: %d" % [npc.name, self.name, workers.size()])
		print("'%s' foi adicionado como trabalhador em '%s'. Total: %d" % [npc.name, self.name, workers.size()])
	
		emit_signal("vacancy_opened", required_profession)

func get_status_info() -> Dictionary:
	var details_text = "Trabalhadores: %d/%d" % [workers.size(), npc_count]
	
	if not is_functional:
		details_text += "\n(Faltam Ferramentas!)"
	return { "name": "Plantação", "details": details_text }

func _on_interaction_area_mouse_entered() -> void:
	var info = get_status_info()
	status_bubble.show_info(info)

func _on_interaction_area_mouse_exited() -> void:
	status_bubble.hide_info()
