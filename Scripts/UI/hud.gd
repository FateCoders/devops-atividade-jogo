# Hud.gd
extends Control

@onready var health_bar = $MainContainer/StatusPanel/VBoxContainer/HealthContainer/Control/ProgressBar
@onready var hunger_bar = $MainContainer/StatusPanel/VBoxContainer/HungerContainer/Control/ProgressBar
@onready var security_bar = $MainContainer/StatusPanel/VBoxContainer/SecurityContainer/Control/ProgressBar
@onready var relations_bar = $MainContainer/StatusPanel/VBoxContainer/RelationsContainer/Control/ProgressBar
@onready var money_label = $MainContainer/StatusPanel/VBoxContainer/MoneyContainer/MoneyLabel

@onready var health_preview_bar = $MainContainer/StatusPanel/VBoxContainer/HealthContainer/Control/PreviewBar
@onready var hunger_preview_bar = $MainContainer/StatusPanel/VBoxContainer/HungerContainer/Control/PreviewBar
@onready var security_preview_bar = $MainContainer/StatusPanel/VBoxContainer/SecurityContainer/Control/PreviewBar
@onready var relations_preview_bar = $MainContainer/StatusPanel/VBoxContainer/RelationsContainer/Control/PreviewBar

@onready var status_panel = $MainContainer/StatusPanel
@onready var build_button = $MainContainer/ButtonsPanel/BuildButton
@onready var build_button_icon = $MainContainer/ButtonsPanel/BuildButton/TextureRect
@onready var game_ui = get_tree().get_first_node_in_group("game_ui")

const BUILD_TEXTURE = preload("res://Assets/Sprites/Exported/Buttons/button-base.png")
const CLOSE_TEXTURE = preload("res://Assets/Sprites/Exported/Buttons/close-button.png")

const BUILD_CURSOR = preload("res://Assets/Sprites/Exported/HUD/Cursors/build_cursor-menor.png") 
const CURSOR_HOTSPOT = Vector2(16, 16) 

const DEFAULT_CURSOR = preload("res://Assets/Sprites/Exported/HUD/Cursors/default_cursor-menor.png") 
const DEFAULT_CURSOR_HOTSPOT = Vector2(4, 4)

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

func _on_button_pressed():
	game_ui.visible = !game_ui.visible
	
	if game_ui.visible:
		build_button_icon.visible = false
		build_button.texture_normal = CLOSE_TEXTURE
		Input.set_custom_mouse_cursor(BUILD_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	else:
		# status_panel.show()
		build_button_icon.visible = true
		build_button.texture_normal = BUILD_TEXTURE
		Input.set_custom_mouse_cursor(DEFAULT_CURSOR, Input.CURSOR_ARROW, DEFAULT_CURSOR_HOTSPOT)

		if game_ui.is_in_placement_mode:
			game_ui._exit_placement_mode()
