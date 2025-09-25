# GameManager.gd
extends Node

const DAYS_TO_WIN: int = 30
const LIBERTOS_TO_WIN: int = 4  # ← NOVO: Quantidade de libertos necessária para vitória "liberdade"

@export var victory_screen_scene: PackedScene = preload("res://Scenes/UI/victory.tscn")
@export var defeat_screen_scene: PackedScene = preload("res://Scenes/UI/defeatScreen.tscn")

signal victory_achieved
signal game_over(reason)

var _is_game_over: bool = false 
var is_camera_paused: bool = false

# Tutorial
var tutorial_active: bool = true
var current_tutorial_step: int = -1 
var hud_node = null

# NOVO: contador de libertos
var libertos: int = 0

const LeadersHouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/leaders_house.tscn")
const HouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/tall_house.tscn")
const PlantationScene = preload("res://Scenes/UI/Assets/Sprites/Builds/plowed.tscn")
const TrainingAreaScene = preload("res://Scenes/UI/Assets/Sprites/Builds/trainingArea.tscn")

var tutorial_data = [
	{ # Etapa 0: Casa do Líder
		"dialog": {0: {"title": "Líder", "dialog": "Bem-vindo ao nosso refúgio. Para começarmos a nos organizar, por favor, construa uma Casa do Líder."}},
		"required_build": LeadersHouseScene,
		"enabled_builds": [LeadersHouseScene]
	},
	{ # Etapa 1: Casa
		"dialog": {0: {"title": "Líder", "dialog": "Excelente! Agora, precisamos de um lugar para nossos irmãos descansarem. Construa uma Casa para abrigá-los."}},
		"required_build": HouseScene,
		"enabled_builds": [HouseScene]
	},
	{ # Etapa 2: Plantação
		"dialog": {0: {"title": "Líder", "dialog": "Com um teto sobre suas cabeças, agora eles precisam de sustento. Construa uma Plantação para garantir nossos recursos."}},
		"required_build": PlantationScene,
		"enabled_builds": [PlantationScene]
	},
	{ # Etapa 4 - Área de Treinamento
		"dialog": {0: {"title": "Líder", "dialog": "A defesa passiva não é o bastante. Construa uma Área de Treinamento para formar guerreiros e proteger ativamente nosso lar."}},
		"required_build": TrainingAreaScene,
		"enabled_builds": [TrainingAreaScene]
	},
	{ # Etapa Final
		"dialog": {0: {"title": "Líder", "dialog": "Você proveu liderança, abrigo, sustento e segurança. O quilombo está estabelecido, mas fique atento: eventos ocorrerão ao longo do jogo. Prepare-se para os desafios."}},
		"required_build": null,
		"enabled_builds": [] 
	},
]

signal tutorial_step_changed(step_data)

func _ready():
	if WorldTimeManager:
		WorldTimeManager.day_passed.connect(_on_new_day_started)
		
	game_over.connect(trigger_defeat)

# ===========================
#  FINAL LIBERDADE
# ===========================
func add_libertos(qtd: int = 1):
	if _is_game_over:
		return
	libertos += qtd
	print("Libertos atuais: %d" % libertos)
	if libertos >= LIBERTOS_TO_WIN:
		_trigger_victory("liberdade")

# ===========================
#  CONDIÇÕES DE VITÓRIA/DERROTA
# ===========================
func _on_new_day_started(day_number: int):
	if day_number >= WorldTimeManager.victory_day:
		_trigger_victory("survival")
		
func _trigger_victory(victory_type: String = "survival"):
	if _is_game_over: return
	_is_game_over = true
	
	print("VITÓRIA! O jogador venceu por: ", victory_type)
	pause_game()
	
	if victory_screen_scene:
		var victory_screen = victory_screen_scene.instantiate()
		add_child(victory_screen)
		if victory_screen.has_method("set_victory_type"):
			victory_screen.set_victory_type(victory_type)
	else:
		printerr("A cena da tela de vitória não foi definida no GameManager!")

func trigger_defeat(reason: String):
	if _is_game_over: return
	_is_game_over = true
	
	print("DERROTA! Motivo: ", reason)
	pause_game()
	
	if defeat_screen_scene:
		var defeat_screen = defeat_screen_scene.instantiate()
		add_child(defeat_screen)
		defeat_screen.set_reason(reason)
	else:
		printerr("Cena da tela de derrota não foi definida no GameManager!")

# ===========================
#  TUTORIAL
# ===========================
func end_tutorial():
	if not tutorial_active: 
		return
	
	tutorial_active = false
	print("TUTORIAL FINALIZADO (pulado pelo jogador)!")
	emit_signal("tutorial_step_changed", {"enabled_builds": []})

func start_tutorial():
	if hud_node == null: 
		hud_node = get_tree().get_first_node_in_group("hud_main")
		if hud_node == null:
			printerr("TUTORIAL FALHOU: Hud não encontrado!")
			tutorial_active = false 
			return

	if tutorial_active:
		advance_tutorial()

func advance_tutorial():
	current_tutorial_step += 1
	if current_tutorial_step >= tutorial_data.size():
		tutorial_active = false
		print("TUTORIAL FINALIZADO!")
		emit_signal("tutorial_step_changed", {"enabled_builds": []})
		return
	
	var step_data = tutorial_data[current_tutorial_step]
	
	hud_node.show_tutorial_dialog(step_data["dialog"])
	
	if is_instance_valid(hud_node):
		var dialog = hud_node.show_tutorial_dialog(step_data["dialog"])
		if is_instance_valid(dialog):
			dialog.tutorial_dialog_skipped.connect(end_tutorial)
	
	emit_signal("tutorial_step_changed", step_data)

func check_tutorial_progress(built_structure_scene: PackedScene):
	if not tutorial_active:
		return
	
	var required_build = tutorial_data[current_tutorial_step].get("required_build")
	if built_structure_scene == required_build:
		print("Etapa %d do tutorial concluída!" % current_tutorial_step)
		advance_tutorial()

# ===========================
#  CONTROLE DE JOGO
# ===========================
func pause_game():
	if not _is_game_over:
		get_tree().paused = true

func resume_game():
	get_tree().paused = false

func pause_camera():
	is_camera_paused = true

func resume_camera():
	is_camera_paused = false

func toggle_pause():
	if get_tree().paused and not _is_game_over:
		resume_game()
	elif not get_tree().paused:
		pause_game()

func is_game_paused() -> bool:
	return get_tree().paused

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel") and not hud_node.dialog_screen.visible:
		toggle_pause()
