@tool
class_name styledButton
extends PanelContainer

signal pressed

const RESOURCE_ICONS = {
	"dinheiro": preload("res://Assets/Sprites/Exported/HUD/Icons/gold-coin-icon.png"),
	"madeira": preload("res://Assets/Sprites/Exported/HUD/Icons/log-icon.png"),
	"ferramentas": preload("res://Assets/Sprites/Exported/HUD/Icons/tools-icon.png"),
	"alimentos": preload("res://Assets/Sprites/Exported/HUD/Icons/chicken-icon.png"),
	"remedios": preload("res://Assets/Sprites/Exported/Plantation/beans.png")
}

@export var button_text: String = "Button Text":
	set(value):
		button_text = value
		if has_node("HBoxContainer/Text"):
			var text_label = $HBoxContainer/Text
			text_label.text = button_text
			text_label.visible = not button_text.is_empty()

@export var button_icon: Texture2D:
	set(value):
		button_icon = value
		if has_node("HBoxContainer/Icon"):
			var icon_sprite = $HBoxContainer/Icon
			icon_sprite.texture = button_icon
			icon_sprite.visible = (button_icon != null)

@onready var costs_container = $HBoxContainer/CostsContainer
@onready var cost_template = $HBoxContainer/CostsContainer/CostTemplate
@onready var internal_button = $Button

@export var disabled: bool = false:
	set(value):
		disabled = value
		if is_instance_valid(internal_button):
			internal_button.disabled = value
		if disabled:
			self.modulate = Color(1, 1, 1, 0.5)
		else:
			self.modulate = Color.WHITE

func _ready():
	internal_button.pressed.connect(_on_internal_button_pressed)
	self.button_text = button_text
	self.button_icon = button_icon
	display_costs({})

func _on_internal_button_pressed():
	pressed.emit()

func display_costs(costs: Dictionary):
	for child in costs_container.get_children():
		if child != cost_template:
			child.queue_free()

	if costs.is_empty():
		return

	for resource_name in costs:
		var amount = costs[resource_name]
		
		# Certifica que o nome do recurso existe no nosso dicionário de ícones
		if not RESOURCE_ICONS.has(resource_name):
			printerr("Ícone para o recurso '%s' não encontrado!" % resource_name)
			continue

		var new_cost_display = cost_template.duplicate()
		new_cost_display.get_node("Icon").texture = RESOURCE_ICONS[resource_name]
		new_cost_display.get_node("Amount").text = "x" + str(amount)
		costs_container.add_child(new_cost_display)
		new_cost_display.visible = true
