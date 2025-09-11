# GameManager.gd
extends Node

const DAYS_TO_WIN: int = 30
@export var victory_screen_scene: PackedScene = preload("res://Scenes/UI/victory.tscn")
@export var defeat_screen_scene: PackedScene = preload("res://Scenes/UI/defeatScreen.tscn")

signal victory_achieved

# ADICIONADO: Sinal para que outros scripts possam anunciar o fim do jogo.
signal game_over(reason)

var _is_game_over: bool = false # Para evitar que o fim de jogo seja chamado várias vezes

# ADICIONADO: Variáveis para controlar o estado do tutorial
var tutorial_active: bool = true
var current_tutorial_step: int = -1 

const LeadersHouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/leaders_house.tscn")
const HouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/tall_house.tscn")
const PlantationScene = preload("res://Scenes/UI/Assets/Sprites/Builds/plowed.tscn")


var tutorial_data = [
	{ # Etapa 0
		"dialog": {0: {"title": "Líder", "dialog": "Bem-vindo ao nosso refúgio. Para começarmos a nos organizar, por favor, construa uma Casa do Líder."}},
		"required_build": LeadersHouseScene,
		"enabled_builds": [LeadersHouseScene]
	},
	{ # Etapa 1
		"dialog": {0: {"title": "Líder", "dialog": "Excelente! Agora, precisamos de um lugar para nossos irmãos descansarem. Construa uma Casa para abrigá-los."}},
		"required_build": HouseScene,
		"enabled_builds": [HouseScene]
	},
	{ # Etapa 2
		"dialog": {0: {"title": "Líder", "dialog": "Com um teto sobre suas cabeças, agora eles precisam de sustento. Construa uma Plantação para garantir nossos recursos."}},
		"required_build": PlantationScene,
		"enabled_builds": [PlantationScene]
	},
	{ # Etapa 3
		"dialog": {0: {"title": "Líder", "dialog": "Esse é o espírito! Você tem a fibra de um grande líder. Lembre-se de cuidar do nosso povo e expandir com sabedoria."}},
		"required_build": null, # Nenhuma construção necessária, apenas um diálogo
		"enabled_builds": [] # Habilita todos os botões
	},
]

signal tutorial_step_changed(step_data)

func _ready():
	if WorldTimeManager:
		WorldTimeManager.day_passed.connect(_on_new_day_started)
	
	# ADICIONADO: Conecta o sinal de game over à função que encerra o jogo.
	game_over.connect(trigger_defeat)
	
func _on_new_day_started(day_number: int):
	print("[GameManager] Recebeu notícia do dia %d. Verificando condição de vitória..." % day_number)
	
	if day_number >= WorldTimeManager.victory_day:
		_trigger_victory()

func _trigger_victory():
	if _is_game_over: return
	_is_game_over = true
	
	print("VITÓRIA! O jogador sobreviveu por %d dias." % WorldTimeManager.victory_day)
	get_tree().paused = true
	
	emit_signal("victory_achieved")

# ADICIONADO: Função central que lida com a derrota.
func trigger_defeat(reason: String):
	# Se o jogo já acabou (por vitória ou outra derrota), não faz nada.
	if _is_game_over: return
	_is_game_over = true
	
	print("DERROTA! Motivo: ", reason)
	get_tree().paused = true
	
	if defeat_screen_scene:
		var defeat_screen = defeat_screen_scene.instantiate()
		add_child(defeat_screen)
		# Passa o motivo da derrota para a tela.
		defeat_screen.set_reason(reason)
	else:
		printerr("Cena da tela de derrota não foi definida no GameManager!")
		
func start_tutorial():
	if tutorial_active:
		advance_tutorial()

# Avança para a próxima etapa do tutorial
func advance_tutorial():
	current_tutorial_step += 1
	if current_tutorial_step >= tutorial_data.size():
		tutorial_active = false
		print("TUTORIAL FINALIZADO!")
		emit_signal("tutorial_step_changed", {"enabled_builds": []}) # Envia sinal final
		return
	
	var step_data = tutorial_data[current_tutorial_step]
	
	# Mostra o diálogo da etapa atual
	var dialog_scene = preload("res://Scenes/UI/dialog.tscn")
	var dialog = dialog_scene.instantiate()
	get_tree().root.add_child(dialog)
	dialog.setup_dialog(step_data["dialog"])
	
	# Emite o sinal para a GameUI atualizar os botões
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
