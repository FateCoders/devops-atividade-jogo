@tool 
extends Button

@export var button_text: String = "Button Text":
	set(value):
		button_text = value
		if has_node("PanelContainer/HBoxContainer/Text"):
			$PanelContainer/HBoxContainer/Text.text = button_text

@export var button_icon: Texture2D:
	set(value):
		button_icon = value
		if has_node("PanelContainer/HBoxContainer/Icon"):
			$PanelContainer/HBoxContainer/Icon.texture = button_icon

@onready var cost_label = $PanelContainer/HBoxContainer/CostLabel
@onready var cost_icon = $PanelContainer/HBoxContainer/CostIcon

func _ready():
	$PanelContainer/HBoxContainer/Text.text = button_text
	$PanelContainer/HBoxContainer/Icon.texture = button_icon
	set_cost_visible(false)

func set_cost_visible(is_visible: bool):
	cost_label.visible = is_visible
	cost_icon.visible = is_visible

func set_cost_value(amount: int):
	cost_label.text = str(amount)
