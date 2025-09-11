# CustomTooltip.gd
extends Control

@onready var icon: TextureRect = $Panel/MarginContainer/HBoxContainer/TextureRect
@onready var label: Label = $Panel/MarginContainer/HBoxContainer/Label

func show_tooltip(data: Dictionary):
	# Carrega o ícone e o texto do dicionário
	label.text = data.get("tooltip", "")

	var icon_path = data.get("icon", "")
	if not icon_path.is_empty():
		icon.texture = load(icon_path)
		icon.visible = true
	else:
		icon.visible = false
		
	# "Liberta" o tooltip para que ele seja desenhado na frente de tudo.
	top_level = true

	# Posiciona o tooltip perto do mouse e o torna visível
	global_position = get_viewport().get_mouse_position() + Vector2(40, 40)
	show()

func hide_tooltip():
	top_level = false
	hide()
