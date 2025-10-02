extends PanelContainer

signal chosen(leader_type)

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var click_button: Button = $ClickButton
@export var leader_type: GameManager.LeaderType

var default_style: StyleBox
@export var selected_style: StyleBox

func _ready():
	click_button.pressed.connect(_on_button_pressed)
	default_style = get("theme_override_styles/panel")

func set_text(title: String, description: String):
	title_label.text = title
	description_label.text = description

func _on_button_pressed():
	emit_signal("chosen", leader_type)

func select():
	add_theme_stylebox_override("panel", selected_style)

func deselect():
	add_theme_stylebox_override("panel", default_style)
