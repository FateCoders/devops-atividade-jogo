# LeadersHouse.gd
extends Node2D
class_name LeadersHouse

@export var max_instances: int = 1

# A Casa do Líder é única e não gera NPCs aleatórios.
@export var npc_count: int = 0

@onready var status_bubble = $buildingStatusBubble

func _ready():
	print("Casa do Líder construída.")

func confirm_construction():
	pass

# Esta função será chamada por um botão na sua UI para abrir o menu de diplomacia.
func abrir_menu_interacao_quilombos():
	print("Abrindo menu para interagir com outros quilombos...")
	# Aqui você colocaria a lógica para mostrar a interface de aliança/ataque/escambo.

func get_status_info() -> Dictionary:
	var workers = [] # Substitua por sua variável de trabalhadores
	var info = {
		"name": "Casa do Líder", # Você pode exportar uma variável para nomes customizados se quiser
		"details": "Centro do Quilombp",
	}
	return info

func _on_interaction_area_mouse_entered() -> void:
	var info = get_status_info()
	status_bubble.show_info(info)


func _on_interaction_area_mouse_exited() -> void:
	status_bubble.hide_info()
