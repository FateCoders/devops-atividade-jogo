# InventoryItem.gd
extends HBoxContainer

@onready var icon: TextureRect = $Icon
@onready var name_label: Label = $NameLabel
@onready var amount_label: Label = $AmountLabel

# Dicionário para mapear o nome do recurso ao seu ícone
const RESOURCE_ICONS = {
	"dinheiro": preload("res://Assets/Sprites/Exported/HUD/Icons/gold-coin-icon.png"),
	"madeira": preload("res://Assets/Sprites/Exported/HUD/Icons/sururu-icon.png"),
	"alimentos": preload("res://Assets/Sprites/Exported/HUD/Icons/chicken-icon.png"),
	"remedios": preload("res://Assets/Sprites/Exported/HUD/Icons/health-icon.png"),
	"ferramentas": preload("res://Assets/Sprites/Exported/HUD/Icons/sururu-icon.png")
}

# Função para receber os dados e configurar a aparência
func set_data(resource_name: String, amount: int):
	name_label.text = resource_name.capitalize()
	amount_label.text = str(amount)

	# Define o ícone correto
	if RESOURCE_ICONS.has(resource_name):
		icon.texture = RESOURCE_ICONS[resource_name]
