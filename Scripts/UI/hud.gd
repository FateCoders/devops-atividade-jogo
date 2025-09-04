extends Control

@onready var health_bar = $StatusPanel/VBoxContainer/HealthContainer/ProgressBar
@onready var hunger_bar = $StatusPanel/VBoxContainer/HungerContainer/ProgressBar
@onready var security_bar = $StatusPanel/VBoxContainer/SecurityContainer/ProgressBar
@onready var relations_bar = $StatusPanel/VBoxContainer/RelationsContainer/ProgressBar
@onready var money_label = $StatusPanel/VBoxContainer/MoneyContainer/MoneyLabel

func _ready():
	StatusManager.status_updated.connect(_on_status_updated)
	_on_status_updated()

func _on_status_updated():
	health_bar.value = StatusManager.saude
	hunger_bar.value = StatusManager.fome
	security_bar.value = StatusManager.seguranca
	relations_bar.value = StatusManager.relacoes
	
	money_label.text = str(StatusManager.dinheiro)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_space") and visible == false:
		visible = true
	elif event.is_action_pressed("ui_space") and visible == true:
		visible = false
