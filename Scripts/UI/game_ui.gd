# GameUI.gd
extends CanvasLayer

signal placement_preview_started(bonuses: Dictionary)
signal placement_preview_ended()

# --- Referências de Cenas (seu método com preload é ótimo!) ---
const PlantationScene = preload("res://Scenes/UI/Assets/Sprites/Builds/plowed.tscn")
const HouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/tall_house.tscn")
const HidingPlaceScene = preload("res://Scenes/UI/Assets/Sprites/Builds/hiding_place.tscn")
const InfirmaryScene = preload("res://Scenes/UI/Assets/Sprites/Builds/infirmary.tscn")
const TrainingAreaScene = preload("res://Scenes/UI/Assets/Sprites/Builds/trainingArea.tscn")
const ChurchScene = preload("res://Scenes/UI/Assets/Sprites/Builds/church.tscn")
const LeadersHouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/leaders_house.tscn")

# --- Variáveis de Modo de Construção ---
var is_in_placement_mode: bool = false
var scene_to_place: PackedScene = null
var placement_preview = null # O "fantasma" que segue o mouse

@onready var notification_container: VBoxContainer = $NotificationContainer
@onready var notification_label: Label = $NotificationContainer/NotificationLabel
@onready var timer_bar: ColorRect = $NotificationContainer/TimerBar
@onready var notification_timer: Timer = $NotificationTimer

var _timer_bar_full_width: float = 0.0

# --- Outras Referências ---
@onready var day_label: Label = $DayLabel

func _ready():

	$VBoxContainer/BuildPlantetionButton.pressed.connect(_on_any_build_button_pressed.bind(PlantationScene))
	$VBoxContainer/BuildHouseButton.pressed.connect(_on_any_build_button_pressed.bind(HouseScene))
	$VBoxContainer/BuildHidingPlaceButton.pressed.connect(_on_any_build_button_pressed.bind(HidingPlaceScene))
	$VBoxContainer/BuildInfirmaryButton.pressed.connect(_on_any_build_button_pressed.bind(InfirmaryScene))
	$VBoxContainer/BuildTrainingAreaButton.pressed.connect(_on_any_build_button_pressed.bind(TrainingAreaScene))
	$VBoxContainer/BuildChurchButton.pressed.connect(_on_any_build_button_pressed.bind(ChurchScene))
	$VBoxContainer/BuildLeadersHouseButton.pressed.connect(_on_any_build_button_pressed.bind(LeadersHouseScene))
	
	notification_timer.timeout.connect(_on_notification_timer_timeout)
	notification_container.modulate.a = 0
	await get_tree().process_frame 

func _process(delta: float):
	# Se não estivermos no modo de construção, não faz nada
	if not is_in_placement_mode or not is_instance_valid(placement_preview):
		return

	# CORRIGIDO: Usa a fórmula correta para converter a posição do mouse da tela para o mundo do jogo
	placement_preview.global_position = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	
	# Colore o fantasma para indicar se a posição é válida
	var is_valid_position = _check_valid_placement()
	if is_valid_position:
		placement_preview.modulate = Color(0.5, 1, 0.5, 0.7) # Verde
	else:
		placement_preview.modulate = Color(1, 0.5, 0.5, 0.7) # Vermelho
		

func show_notification(message: String, duration: float = 3.0):
	if notification_timer.time_left > 0:
		return

	notification_label.text = message
	notification_timer.wait_time = duration
	notification_timer.start()
	
	# Reseta a barra para o tamanho máximo antes de animar
	timer_bar.size.x = notification_container.size.x

	var tween = create_tween()
	tween.tween_property(notification_container, "modulate:a", 1.0, 0.3)
	tween.tween_property(timer_bar, "size:x", 0, duration)

func _on_notification_timer_timeout():
	# Anima o container inteiro para desaparecer (fade-out)
	var tween = create_tween()
	tween.tween_property(notification_container, "modulate:a", 0.0, 0.5)

# ADICIONE ESTA FUNÇÃO COMPLETA NO LUGAR DA _input QUE VOCÊ DELETOU
func _unhandled_input(event: InputEvent):
	# Parte 1: Lógica para abrir/fechar a UI com a tecla "Enter"
	# (Esta é a parte que eu tinha esquecido de incluir)
	if Input.is_action_just_pressed("ui_enter"):
		visible = not visible
		get_tree().paused = visible
		# Se fecharmos a UI enquanto estamos no modo de construção, cancela a construção.
		if not visible and is_in_placement_mode:
			_exit_placement_mode()

	# Parte 2: Lógica do modo de construção
	# Só executa se estivermos no modo de construção.
	if is_in_placement_mode:
		# Clique esquerdo para construir
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if _check_valid_placement():
				var build_pos = placement_preview.global_position
				QuilomboManager.build_structure(scene_to_place, build_pos)
				_exit_placement_mode()
		
		# Clique direito para cancelar
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			_exit_placement_mode()


# --- Funções de Modo de Construção ---

# UMA ÚNICA FUNÇÃO para lidar com o clique de QUALQUER botão de construção
func _on_any_build_button_pressed(scene: PackedScene):
	if is_in_placement_mode:
		_exit_placement_mode() # Sai do modo anterior se já estiver em um	
		return
	
	# 1. Criamos uma instância temporária da construção apenas para ler suas propriedades.
	var temp_instance = scene.instantiate()
	
	var max_allowed = temp_instance.get("max_instances")
	if max_allowed != null and max_allowed > 0: # > 0 significa que há um limite
		# MODIFICADO: Passamos o caminho do arquivo da cena para a verificação
		var current_count = QuilomboManager.get_build_count_for_type(scene.resource_path)
		if current_count >= max_allowed:
			show_notification("Limite de construções deste tipo atingido!")
			temp_instance.queue_free()
			return
	
	var npcs_needed = temp_instance.get("npc_count")
	var build_cost = temp_instance.get("cost")
	
	
	temp_instance.queue_free()
	
	if npcs_needed == null:
		printerr("AVISO: A cena '%s' não possui a propriedade 'npc_count'. Assumindo 0." % scene.resource_path)
		npcs_needed = 0 

	if npcs_needed > 0:
		var available_space = QuilomboManager.get_available_housing_space()
		
		if available_space < npcs_needed:
			print("CASAS INSUFICIENTES! Necessário: %d, Disponível: %d" % [npcs_needed, available_space])
			# (Opcional) Aqui você pode adicionar uma notificação visual para o jogador
			show_notification("Casas insuficientes para novos moradores!")
			return # Impede a entrada no modo de construção
			
	if build_cost:
		if not StatusManager.has_enough_resources(build_cost):
			# Se não tiver recursos, chama a sua snackbar e para a função.
			show_notification("Recursos insuficientes para construir!")
			return
	
	is_in_placement_mode = true
	scene_to_place = scene
	
	# Cria o "fantasma" para pré-visualização
	placement_preview = scene.instantiate()
	get_tree().current_scene.add_child(placement_preview)
	
	_disable_physics(placement_preview) # Desabilita colisões do fantasma
	
	var bonuses = {
		"seguranca": placement_preview.get("security_bonus"),
		"saude": placement_preview.get("health_bonus"),
		"fome": placement_preview.get("hunger_bonus"),
		"relacoes": placement_preview.get("relations_bonus")
		# Adicione outros bônus que suas construções possam ter
	}
	emit_signal("placement_preview_started", bonuses)

func _exit_placement_mode():
	if is_instance_valid(placement_preview):
		placement_preview.queue_free()
	
	is_in_placement_mode = false
	scene_to_place = null
	placement_preview = null
	print("Modo de construção finalizado.")
	
	emit_signal("placement_preview_ended")

# --- Funções Auxiliares ---

func _check_valid_placement() -> bool:
	var area: Area2D = placement_preview.get_node_or_null("Area2D")
	if not area:
		return true # Se a construção não tem uma área de checagem, permite construir
	# Verifica se a área do fantasma está colidindo com algo
	return area.get_overlapping_bodies().is_empty() and area.get_overlapping_areas().is_empty()

func _disable_physics(node: Node):
	# Função recursiva para desligar a física do fantasma e de todos os seus filhos
	if node is CollisionObject2D:
		node.collision_layer = 0
		node.collision_mask = 0
	if node is NavigationObstacle2D:
		# CORRIGIDO: A propriedade correta é 'avoidance_enabled'
		node.avoidance_enabled = false
		
	for child in node.get_children():
		_disable_physics(child)

# ... suas outras funções de UI, como _on_day_passed, continuam aqui ...
func _on_day_passed(new_day: int):
	day_label.text = "Dia: %d" % new_day
