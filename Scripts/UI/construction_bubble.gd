# BuildingStatusBubble.gd
extends Control

@onready var name_label: Label = $NinePatchRect/VBoxContainer/NameLabel
@onready var details_label: Label = $NinePatchRect/VBoxContainer/DetailsLabel

# Esta função recebe um dicionário com as informações e atualiza o balão.
func show_info(info: Dictionary):
	# ADICIONE ESTE PRINT para ver o que está chegando
	print("Balão de Status recebeu as seguintes informações: ", info)
	
	name_label.text = info.get("name", "Desconhecido")
	details_label.text = info.get("details", "")
	
	details_label.visible = not details_label.text.is_empty()
	
	show()

func hide_info():
	hide() 
