# Scripts/UI/LeaderChoiceButton.gd
extends PanelContainer

signal chosen(leader_type)

@onready var click_button: Button = $ClickButton

@export var leader_type: GameManager.LeaderType

var default_style: StyleBox
@export var selected_style: StyleBox

func _ready():
	click_button.pressed.connect(_on_button_pressed)
	default_style = get("theme_override_styles/panel")
	click_button.mouse_filter = Control.MOUSE_FILTER_PASS

func set_text(title: String, description: String):
	click_button.text = title
	self.tooltip_text = description

func _on_button_pressed():
	emit_signal("chosen", leader_type)

func select():
	add_theme_stylebox_override("panel", selected_style)

func deselect():
	add_theme_stylebox_override("panel", default_style)
