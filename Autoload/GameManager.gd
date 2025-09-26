# GameManager.gd
extends Node

const DAYS_TO_WIN: int = 30
@export var victory_screen_scene: PackedScene = preload("res://Scenes/UI/victory.tscn")
@export var defeat_screen_scene: PackedScene = preload("res://Scenes/UI/defeatScreen.tscn")

signal victory_achieved
signal game_paused
signal game_resumed

# ADICIONADO: Sinal para que outros scripts possam anunciar o fim do jogo.
signal game_over(reason)

var _is_game_over: bool = false # Para evitar que o fim de jogo seja chamado várias vezes
var is_camera_paused: bool = false

# ADICIONADO: Variáveis para controlar o estado do tutorial
var tutorial_active: bool = true
var current_tutorial_step: int = -1 
var hud_node = null

const LeadersHouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/leaders_house.tscn")
const HouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/tall_house.tscn")
const PlantationScene = preload("res://Scenes/UI/Assets/Sprites/Builds/plowed.tscn")
const TrainingAreaScene = preload("res://Scenes/UI/Assets/Sprites/Builds/trainingArea.tscn")
#const HidingPlaceScene = preload("res://Scenes/UI/Assets/Sprites/Builds/hiding_place.tscn")
#const InfirmaryScene = preload("res://Scenes/UI/Assets/Sprites/Builds/infirmary.tscn")
#const ChurchScene = preload("res://Scenes/UI/Assets/Sprites/Builds/church.tscn")


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
#	{ # ADICIONADO: Etapa 3 - Esconderijo
#		"dialog": {0: {"title": "Líder", "dialog": "A segurança é vital. Construa um Esconderijo para que nosso povo tenha um lugar seguro durante ataques."}},
#		"required_build": HidingPlaceScene,
#		"enabled_builds": [HidingPlaceScene]
#	},
	{ # ADICIONADO: Etapa 4 - Área de Treinamento
		"dialog": {0: {"title": "Líder", "dialog": "A defesa passiva não é o bastante. Construa uma Área de Treinamento para formar guerreiros e proteger ativamente nosso lar."}},
		"required_build": TrainingAreaScene,
		"enabled_builds": [TrainingAreaScene]
	},
#	{ # ADICIONADO: Etapa 5 - Enfermaria
#		"dialog": {0: {"title": "Líder", "dialog": "Conflitos e doenças podem nos enfraquecer. Construa uma Enfermaria para cuidar da Saúde de nossa comunidade."}},
#		"required_build": InfirmaryScene,
#		"enabled_builds": [InfirmaryScene, HouseScene]
#	},
#	{ # ADICIONADO: Etapa 6 - Centro Espiritual
#		"dialog": {0: {"title": "Líder", "dialog": "Um corpo forte precisa de um espírito forte. Construa um Centro Espiritual para fortalecer nossas Relações e o bem-estar de todos."}},
#		"required_build": ChurchScene,
#		"enabled_builds": [ChurchScene]
#	},
	{ # Etapa 7: Mensagem Final
		"dialog": {0: {"title": "Líder", "dialog": "Você proveu liderança, abrigo, sustento e segurança. O quilombo está estabelecido, mas fique atento: eventos ocorrerão ao longo do jogo. Prepare-se para os desafios."}},
		"required_build": null,
		"enabled_builds": [] # Habilita todos os botões
	},
]

signal tutorial_step_changed(step_data)

func _ready():
	if WorldTimeManager:
		WorldTimeManager.day_passed.connect(_on_new_day_started)
		
	game_over.connect(trigger_defeat)
	
	# ADICIONADO: Conecta o sinal de game over à função que encerra o jogo.
	game_over.connect(trigger_defeat)

func end_tutorial():
	# Se o tutorial já terminou, não faz nada.
	if not tutorial_active: 
		return
	
	tutorial_active = false
	print("TUTORIAL FINALIZADO (pulado pelo jogador)!")
	# Emite o sinal com uma lista vazia, o que reativa todos os botões no Hud.
	emit_signal("tutorial_step_changed", {"enabled_builds": []})

func _on_new_day_started(day_number: int):
	if day_number >= WorldTimeManager.victory_day:
		# Agora chama a função com o tipo correto.
		_trigger_victory("survival")
		
func _trigger_victory(victory_type: String = "survival"): # "survival" é o padrão
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

# ADICIONADO: Função central que lida com a derrota.
func trigger_defeat(reason: String):
	# Se o jogo já acabou (por vitória ou outra derrota), não faz nada.
	if _is_game_over: return
	_is_game_over = true
	
	print("DERROTA! Motivo: ", reason)
	pause_game()
	
	if defeat_screen_scene:
		var defeat_screen = defeat_screen_scene.instantiate()
		add_child(defeat_screen)
		# Passa o motivo da derrota para a tela.
		defeat_screen.set_reason(reason)
	else:
		printerr("Cena da tela de derrota não foi definida no GameManager!")
	 	
func start_tutorial():
	# ADICIONADO: A busca pelo Hud agora acontece aqui, no momento certo.
	if hud_node == null: # Procura apenas se ainda não tiver a referência
		hud_node = get_tree().get_first_node_in_group("hud_main")
		if hud_node == null:
			printerr("TUTORIAL FALHOU: GameManager não conseguiu encontrar o Hud no grupo 'hud_main'!")
			tutorial_active = false # Desativa o tutorial se a UI não for encontrada
			return

	if tutorial_active:
		advance_tutorial()

# Avança para a próxima etapa do tutorial
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
	
	# Emite o sinal para a GameUI/Hud atualizar os botões
	emit_signal("tutorial_step_changed", step_data)

# Chamada pelo QuilomboManager sempre que uma construção é finalizada
func check_tutorial_progress(built_structure_scene: PackedScene):
	if not tutorial_active:
		return
	
	var required_build = tutorial_data[current_tutorial_step].get("required_build")
	
	# Se a construção finalizada é a que o tutorial pedia...
	if built_structure_scene == required_build:
		print("Etapa %d do tutorial concluída!" % current_tutorial_step)
		advance_tutorial() # ...avança para a próxima etapa.

func restart_tutorial():
	if _is_game_over: return
	
	print("[GameManager] Reiniciando o tutorial.")
	tutorial_active = true
	current_tutorial_step = -1 
	advance_tutorial() 

func pause_game():
	if _is_game_over: return
	emit_signal("game_paused")
	# REMOVIDO: get_tree().paused = true

	print("[GameManager] Pausando o processamento dos personagens.")
	for npc in get_tree().get_nodes_in_group("personagens"):
		npc.process_mode = Node.PROCESS_MODE_DISABLED

	WorldTimeManager.process_mode = Node.PROCESS_MODE_DISABLED


func resume_game():
	# REMOVIDO: get_tree().paused = false
	emit_signal("game_resumed")
	print("[GameManager] Retomando o processamento dos personagens.")
	for npc in get_tree().get_nodes_in_group("personagens"):
		npc.process_mode = Node.PROCESS_MODE_INHERIT
		
	WorldTimeManager.process_mode = Node.PROCESS_MODE_INHERIT

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

func show_settings_menu():
	var pause_menu = get_tree().root.get_node_or_null("world/pause_menu")
	
	if is_instance_valid(pause_menu) and pause_menu.has_method("open_menu"):
		pause_menu.open_menu()
	else:
		printerr("GameManager não conseguiu encontrar o nó do Menu de Pausa ou a função 'open_menu'. Verifique o nome e o caminho do nó.")
