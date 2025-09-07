# LeadersHouse.gd
extends Node2D
class_name LeadersHouse

# A Casa do Líder é única e não gera NPCs aleatórios.
@export var npc_count: int = 0

func _ready():
	print("Casa do Líder construída.")

# Esta função será chamada por um botão na sua UI para abrir o menu de diplomacia.
func abrir_menu_interacao_quilombos():
	print("Abrindo menu para interagir com outros quilombos...")
	# Aqui você colocaria a lógica para mostrar a interface de aliança/ataque/escambo.
