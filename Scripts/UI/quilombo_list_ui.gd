# QuilomboListUI.gd
extends Control

const ListItemScene = preload("res://Scenes/UI/QuilomboListItem.tscn")

@onready var list_container = $ColorRect/Panel/MarginContainer/VBoxContainer/ScrollContainer/QuilomboListContainer
@onready var close_button = $ColorRect/Panel/MarginContainer/VBoxContainer/CloseButton

func _ready():
	close_button.pressed.connect(queue_free)
	populate_list()

# Preenche a lista com os dados do QuilombosManager
func populate_list():
	# Limpa a lista antiga, se houver
	for child in list_container.get_children():
		child.queue_free()

	var all_quilombos = QuilombosManager.get_all_quilombos()
	for quilombo_id in all_quilombos.keys():
		var data = all_quilombos[quilombo_id]
		var item = ListItemScene.instantiate()
		list_container.add_child(item)
		item.set_data(quilombo_id, data)
		# Conecta o sinal do item a uma função que lidará com o escambo
		item.trade_requested.connect(_on_trade_requested)

func _on_trade_requested(quilombo_id: String):
	print("Jogador quer fazer escambo com: ", quilombo_id)
	get_parent().show_escambo_ui(quilombo_id) # Ajuste o get_parent()
	queue_free() # Por enquanto, apenas fecha a lista
