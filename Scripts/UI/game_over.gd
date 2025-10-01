# DefeatScreen.gd
extends CanvasLayer

@onready var reason_label: Label = $VBoxContainer/Panel/ReasonLabel
@onready var restart_button: Button = $VBoxContainer/Panel/quit_button

func _ready():
	restart_button.pressed.connect(_on_restart_button_pressed)
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_reason(reason_text: String):
	reason_label.text = reason_text

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/menu_inicial.tscn")
