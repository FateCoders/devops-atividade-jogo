# HidingPlace.gd
extends Node2D
class_name HidingPlace

@export var max_instances: int = 3

# Esconderijos não geram novos NPCs, apenas abrigam os existentes[cite: 20].
@export var npc_count: int = 0
@export var security_bonus: int = 10

# Você pode definir a capacidade do esconderijo aqui.
var workers: Array[Node] = []
@export var capacity: int = 10
var npcs_escondidos: Array[NPC] = []

@export var cost: Dictionary = {
	"dinheiro": 20,
}

@onready var status_bubble = $buildingStatusBubble

var is_functional: bool = false
@export var upkeep_resource: String = "alimentos"
@export var upkeep_amount: int = 5

func _ready():
	add_to_group("functional_buildings")

func add_worker(npc: NPC):
	if not workers.has(npc):
		workers.append(npc)
		print("'%s' começou a trabalhar em '%s'. Trabalhadores atuais: %d" % [npc.name, self.name, workers.size()])

func remove_worker(npc: NPC):
	if workers.has(npc):
		workers.erase(npc)
		print("'%s' parou de trabalhar em '%s'. Trabalhadores atuais: %d" % [npc.name, self.name, workers.size()])

func confirm_construction():
	# A lógica de mudar os status agora vive aqui!
	StatusManager.mudar_status("seguranca", security_bonus)
	print("Esconderijo '%s' CONFIRMADA. Bônus aplicados." % self.name)
	
	update_functionality()
	
func update_functionality():
	var required_resources = {upkeep_resource: upkeep_amount}
	if StatusManager.has_enough_resources(required_resources):
		StatusManager.spend_resources(required_resources)
		if not is_functional:
			is_functional = true
			StatusManager.mudar_status("seguranca", security_bonus)
			print("Esconderijo '%s' agora está funcional." % name)
	else:
		if is_functional:
			is_functional = false
			StatusManager.mudar_status("seguranca", -security_bonus)
			print("Esconderijo '%s' parou de funcionar por falta de ferramentas/armas." % name)

func get_status_info() -> Dictionary:
	var details_text = "Esconderijo: %d/%d" % [workers.size(), npc_count]
	if not is_functional:
		details_text += "\n(Faltam Alimentos!)"
	return { "name": "Esconderijo", "details": details_text }


func _on_interaction_area_mouse_entered() -> void:
	var info = get_status_info()
	status_bubble.show_info(info)


func _on_interaction_area_mouse_exited() -> void:
	status_bubble.hide_info()


# No futuro, você pode criar funções para os NPCs usarem durante um ataque.
# func abrigar_npc(npc: NPC):
#     if npcs_escondidos.size() < capacity:
#         npcs_escondidos.append(npc)
#         npc.hide()
