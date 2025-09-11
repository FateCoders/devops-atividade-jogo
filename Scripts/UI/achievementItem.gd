# AchievementItem.gd
extends HBoxContainer

@onready var check_icon: TextureRect = $CheckIcon
@onready var title_label: Label = $TitleLabel

# Carregue aqui os ícones de "check" e "não-check".
const ICON_UNLOCKED = preload("res://Assets/Sprites/Exported/HUD/Icons/negative-relation-icon.png")
const ICON_LOCKED = preload("res://Assets/Sprites/Exported/HUD/Icons/positive-relation-icon.png")

func set_data(data: Dictionary):
	title_label.text = data.get("title", "...")

	if data.get("unlocked", false):
		check_icon.texture = ICON_UNLOCKED
		# (Opcional) Mude a cor do texto para indicar que foi concluído.
		title_label.modulate = Color.WHITE
	else:
		check_icon.texture = ICON_LOCKED
		# (Opcional) Deixa o texto meio apagado.
		title_label.modulate = Color(1, 1, 1, 0.5)
