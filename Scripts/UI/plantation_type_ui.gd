# PlantationTypeUI.gd
extends Control

signal type_selected(production_type)

@onready var food_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/FoodButton
@onready var remedy_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RemedyButton

var target_plantation: Plantation

func _ready():
	food_button.pressed.connect(func(): _on_choice_made(Plantation.ProductionType.ALIMENTOS))
	remedy_button.pressed.connect(func(): _on_choice_made(Plantation.ProductionType.REMEDIOS))

func set_target_plantation(plantation: Plantation):
	target_plantation = plantation

func _on_choice_made(choice):
	if is_instance_valid(target_plantation):
		target_plantation.set_production_type(choice)

	queue_free()
