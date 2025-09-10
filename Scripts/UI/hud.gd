# Hud.gd
extends Control

@onready var health_bar = $MainContainer/StatusPanel/VBoxContainer/HealthContainer/Control/ProgressBar
@onready var hunger_bar = $MainContainer/StatusPanel/VBoxContainer/HungerContainer/Control/ProgressBar
@onready var security_bar = $MainContainer/StatusPanel/VBoxContainer/SecurityContainer/Control/ProgressBar
@onready var relations_bar = $MainContainer/StatusPanel/VBoxContainer/RelationsContainer/Control/ProgressBar
@onready var money_label = $MainContainer/StatusPanel/VBoxContainer/VBoxContainer/MoneyContainer/MoneyLabel
@onready var population_label = $MainContainer/StatusPanel/VBoxContainer/VBoxContainer/PopulationContainer/PopulationLabel

@onready var health_preview_bar = $MainContainer/StatusPanel/VBoxContainer/HealthContainer/Control/PreviewBar
@onready var hunger_preview_bar = $MainContainer/StatusPanel/VBoxContainer/HungerContainer/Control/PreviewBar
@onready var security_preview_bar = $MainContainer/StatusPanel/VBoxContainer/SecurityContainer/Control/PreviewBar
@onready var relations_preview_bar = $MainContainer/StatusPanel/VBoxContainer/RelationsContainer/Control/PreviewBar

@onready var status_panel = $MainContainer/StatusPanel
@onready var build_button = $MainContainer/ButtonsPanel/SectionsPanel/ButtonOptions/BuildButton
@onready var build_button_icon = $MainContainer/ButtonsPanel/SectionsPanel/ButtonOptions/BuildButton/TextureRect
@onready var game_ui = get_tree().get_first_node_in_group("game_ui")

@onready var button_builds = $MainContainer/ButtonsPanel/SectionsPanel/ButtonBuildsOptions

@onready var health_icon = $MainContainer/StatusPanel/VBoxContainer/HealthContainer/HealthIcon
@onready var hunger_icon = $MainContainer/StatusPanel/VBoxContainer/HungerContainer/HungerIcon
@onready var relations_icon = $MainContainer/StatusPanel/VBoxContainer/RelationsContainer/RelationsIcon

const BUILD_TEXTURE = preload("res://Assets/Sprites/Exported/Buttons/button-base.png")
const CLOSE_TEXTURE = preload("res://Assets/Sprites/Exported/Buttons/close-button.png")

const BUILD_CURSOR = preload("res://Assets/Sprites/Exported/HUD/Cursors/build_cursor-menor.png") 
const CURSOR_HOTSPOT = Vector2(16, 16) 
const DEFAULT_CURSOR = preload("res://Assets/Sprites/Exported/HUD/Cursors/default_cursor-menor.png") 
const DEFAULT_CURSOR_HOTSPOT = Vector2(4, 4)

const LOW_RELATIONS_COLOR = Color("#ff163f") 
const DEFAULT_RELATIONS_COLOR = Color("#309cff") 

const HEALTH_ICON_NORMAL = preload("res://Assets/Sprites/Exported/HUD/Icons/health-icon.png")
const HEALTH_ICON_LOW = preload("res://Assets/Sprites/Exported/HUD/Icons/unhealth-icon.png")
const HUNGER_ICON_NORMAL = preload("res://Assets/Sprites/Exported/HUD/Icons/chicken-icon.png")
const HUNGER_ICON_LOW = preload("res://Assets/Sprites/Exported/HUD/Icons/bone-icon.png")
const RELATIONS_ICON_NORMAL = preload("res://Assets/Sprites/Exported/HUD/Icons/positive-relation-icon.png")
const RELATIONS_ICON_LOW = preload("res://Assets/Sprites/Exported/HUD/Icons/negative-relation-icon.png")

func _ready():
	StatusManager.status_updated.connect(_on_status_updated)
	QuilomboManager.npc_count_changed.connect(_on_npc_count_changed)
	_on_status_updated()
	
	button_builds.get_node("Col1/BuildOptions/BuildLeadersHouseButton").pressed.connect(
		game_ui._on_any_build_button_pressed.bind(game_ui.LeadersHouseScene))
	button_builds.get_node("Col1/BuildOptions/BuildHouseButton").pressed.connect(
		game_ui._on_any_build_button_pressed.bind(game_ui.HouseScene))
	button_builds.get_node("Col1/BuildOptions/BuildHidingPlaceButton").pressed.connect(
		game_ui._on_any_build_button_pressed.bind(game_ui.HidingPlaceScene))

	button_builds.get_node("Col2/BuildOptions/BuildPlantetionButton").pressed.connect(
		game_ui._on_any_build_button_pressed.bind(game_ui.PlantationScene))
	button_builds.get_node("Col2/BuildOptions/BuildInfirmaryButton").pressed.connect(
		game_ui._on_any_build_button_pressed.bind(game_ui.InfirmaryScene))
	button_builds.get_node("Col2/BuildOptions/BuildTrainingAreaButton").pressed.connect(
		game_ui._on_any_build_button_pressed.bind(game_ui.TrainingAreaScene))
	button_builds.get_node("Col2/BuildOptions/BuildChurchButton").pressed.connect(
		game_ui._on_any_build_button_pressed.bind(game_ui.ChurchScene))

func _on_status_updated():
	health_bar.value = StatusManager.saude
	hunger_bar.value = StatusManager.fome
	security_bar.value = StatusManager.seguranca
	relations_bar.value = StatusManager.relacoes
	money_label.text = str(StatusManager.dinheiro)
	population_label.text = str(QuilomboManager.all_npcs.size())
	
	health_icon.texture = HEALTH_ICON_LOW if StatusManager.saude < 50 else HEALTH_ICON_NORMAL
	hunger_icon.texture = HUNGER_ICON_LOW if StatusManager.fome < 50 else HUNGER_ICON_NORMAL
	relations_icon.texture = RELATIONS_ICON_LOW if StatusManager.relacoes < 50 else RELATIONS_ICON_NORMAL

	var base_color = LOW_RELATIONS_COLOR if StatusManager.relacoes < 50 else DEFAULT_RELATIONS_COLOR
	_set_bar_color(relations_bar, base_color)
	
	var preview_color = base_color
	preview_color.a = 127 / 255.0
	_set_bar_color(relations_preview_bar, preview_color)
	
	clear_preview();

func show_preview(bonuses: Dictionary):
	clear_preview();

	if bonuses.has("seguranca") and bonuses.seguranca:
		security_preview_bar.value = security_bar.value + bonuses.seguranca
	if bonuses.has("saude") and bonuses.saude:
		health_preview_bar.value = health_bar.value + bonuses.saude
	if bonuses.has("relacoes") and bonuses.relacoes:
		relations_preview_bar.value = relations_bar.value + bonuses.relacoes
	if bonuses.has("fome") and bonuses.fome:
		hunger_preview_bar.value = hunger_bar.value + bonuses.hunger

func clear_preview():
	health_preview_bar.value = security_bar.value
	hunger_preview_bar.value = health_bar.value
	security_preview_bar.value = relations_bar.value
	relations_preview_bar.value = hunger_bar.value

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_space") and visible == false:
		visible = true
	elif event.is_action_pressed("ui_space") and visible == true:
		visible = false

func _on_button_pressed():
	game_ui.visible = !game_ui.visible
	button_builds.visible = game_ui.visible
	
	if game_ui.visible:
		build_button_icon.visible = false
		build_button.texture_normal = CLOSE_TEXTURE
		Input.set_custom_mouse_cursor(BUILD_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	else:
		#status_panel.show()
		build_button_icon.visible = true
		build_button.texture_normal = BUILD_TEXTURE
		Input.set_custom_mouse_cursor(DEFAULT_CURSOR, Input.CURSOR_ARROW, DEFAULT_CURSOR_HOTSPOT)

		if game_ui.is_in_placement_mode:
			game_ui._exit_placement_mode()

func _set_bar_color(bar: ProgressBar, new_color: Color):
	var stylebox = bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	stylebox.bg_color = new_color
	bar.add_theme_stylebox_override("fill", stylebox)

func _on_npc_count_changed(new_count: int):
	population_label.text = str(new_count)
