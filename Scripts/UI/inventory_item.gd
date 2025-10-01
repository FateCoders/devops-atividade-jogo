# InventoryItem.gd
extends NinePatchRect

@onready var icon: TextureRect = $Icon
@onready var quantity_label: Label = $QuantityLabel

const ENABLED_COLOR = Color(1, 1, 1, 1)
const DISABLED_COLOR = Color(0.4, 0.4, 0.4, 0.6) 

const RESOURCE_DATA = {
	"madeira": {
		"display_name": "Madeira",
		"icon": preload("res://Assets/Sprites/Exported/HUD/Icons/log-icon.png")
	},
	"alimentos": {
		"display_name": "Alimentos",
		"icon": preload("res://Assets/Sprites/Exported/HUD/Icons/chicken-icon.png")
	},
	"remedios": {
		"display_name": "Remédios",
		"icon": preload("res://Assets/Sprites/Exported/Plantation/beans.png")
	},
	"ferramentas": {
		"display_name": "Ferramentas",
		"icon": preload("res://Assets/Sprites/Exported/HUD/Icons/tools-icon.png")
	},
	"default": {
		"display_name": "Sururu",
		"icon": preload("res://Assets/Sprites/Exported/HUD/Icons/sururu-icon.png")
	},
}

func set_data(resource_name: String, amount: int):
	var data = RESOURCE_DATA[resource_name] if RESOURCE_DATA.has(resource_name) else RESOURCE_DATA["default"]
	icon.texture = data.icon
	quantity_label.text = "x" + str(amount)
	self.tooltip_text = data.display_name + " x" + str(amount)
	
	if amount == 0:
		icon.modulate = DISABLED_COLOR
		quantity_label.modulate = DISABLED_COLOR
	else:
		icon.modulate = ENABLED_COLOR
		quantity_label.modulate = ENABLED_COLOR
