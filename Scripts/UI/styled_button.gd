# styledButton.gd
@tool
class_name styledButton
extends PanelContainer

signal pressed

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

@onready var cost_label = $HBoxContainer/CostLabel
@onready var cost_icon = $HBoxContainer/CostIcon
@onready var cost_spacer = $HBoxContainer/Spacer
@onready var internal_button = $Button

@export var disabled: bool = false:
	set(value):
		disabled = value
		if is_instance_valid(internal_button):
			internal_button.disabled = value
		
		# Efeito visual opcional: deixa o botão cinza quando desabilitado
		if disabled:
			self.modulate = Color(1, 1, 1, 0.5) # Cinza e um pouco transparente
		else:
			self.modulate = Color.WHITE

func _ready():
	internal_button.pressed.connect(_on_internal_button_pressed)

	self.button_text = button_text
	self.button_icon = button_icon
	set_cost_visible(false)

func _on_internal_button_pressed():
	pressed.emit()

func set_cost_visible(is_visible: bool):
	cost_spacer.visible = is_visible
	cost_label.visible = is_visible
	cost_icon.visible = is_visible

func set_cost_value(amount: int):
	cost_label.text = str(amount)
