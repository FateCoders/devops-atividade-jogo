# Hud.gd
extends Control

@onready var health_bar = $StatusPanel/VBoxContainer/HealthContainer/Control/ProgressBar
@onready var hunger_bar = $StatusPanel/VBoxContainer/HungerContainer/Control/ProgressBar
@onready var security_bar = $StatusPanel/VBoxContainer/SecurityContainer/Control/ProgressBar
@onready var relations_bar = $StatusPanel/VBoxContainer/RelationsContainer/Control/ProgressBar
@onready var money_label = $StatusPanel/VBoxContainer/MoneyContainer/MoneyLabel

@onready var health_preview_bar = $StatusPanel/VBoxContainer/HealthContainer/Control/PreviewBar
@onready var hunger_preview_bar = $StatusPanel/VBoxContainer/HungerContainer/Control/PreviewBar
@onready var security_preview_bar = $StatusPanel/VBoxContainer/SecurityContainer/Control/PreviewBar
@onready var relations_preview_bar = $StatusPanel/VBoxContainer/RelationsContainer/Control/PreviewBar


func _ready():
	StatusManager.status_updated.connect(_on_status_updated)
	_on_status_updated()

func _on_status_updated():
	health_bar.value = StatusManager.saude
	hunger_bar.value = StatusManager.fome
	security_bar.value = StatusManager.seguranca
	relations_bar.value = StatusManager.relacoes
	money_label.text = str(StatusManager.dinheiro)
	
	clear_preview()

func show_preview(bonuses: Dictionary):
	clear_preview()
	
	if bonuses.has("seguranca") and bonuses.seguranca:
		security_preview_bar.value = security_bar.value + bonuses.seguranca
		security_preview_bar.visible = true
	if bonuses.has("saude") and bonuses.saude:
		health_preview_bar.value = health_bar.value + bonuses.saude
		health_preview_bar.visible = true
	if bonuses.has("relacoes") and bonuses.relacoes:
		relations_preview_bar.value = relations_bar.value + bonuses.relacoes
		relations_preview_bar.visible = true
	if bonuses.has("fome") and bonuses.fome:
		hunger_preview_bar.value = hunger_bar.value + bonuses.hunger
		hunger_preview_bar.visible = true

func clear_preview():
	health_preview_bar.visible = false
	hunger_preview_bar.visible = false
	security_preview_bar.visible = false
	relations_preview_bar.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_space") and visible == false:
		visible = true
	elif event.is_action_pressed("ui_space") and visible == true:
		visible = false
