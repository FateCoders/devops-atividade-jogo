# styledButton.gd
@tool
class_name styledButton
extends PanelContainer

signal pressed

@export var button_text: String = "Button Text":
	set(value):
		button_text = value
		if has_node("HBoxContainer/Text"):
			$HBoxContainer/Text.text = button_text

@export var button_icon: Texture2D:
	set(value):
		button_icon = value
		if has_node("HBoxContainer/Icon"):
			$HBoxContainer/Icon.texture = button_icon

@onready var cost_label = $HBoxContainer/CostLabel
@onready var cost_icon = $HBoxContainer/CostIcon
@onready var internal_button = $Button

func _ready():
	internal_button.pressed.connect(_on_internal_button_pressed)

	$HBoxContainer/Text.text = button_text
	$HBoxContainer/Icon.texture = button_icon
	set_cost_visible(false)

func _on_internal_button_pressed():
	pressed.emit()

func set_cost_visible(is_visible: bool):
	cost_label.visible = is_visible
	cost_icon.visible = is_visible

func set_cost_value(amount: int):
	cost_label.text = str(amount)
