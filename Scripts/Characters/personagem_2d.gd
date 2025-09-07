extends CharacterBody2D
class_name NPC

#-----------------------------------------------------------------------------
# CONSTANTES
#-----------------------------------------------------------------------------
const MIN_VELOCITY_FOR_WALK: float = 10.0
const EXIT_DISTANCE: float = 50.0
const STUCK_THRESHOLD: float = 0.5

#-----------------------------------------------------------------------------
# ESTADOS E PROPRIEDADES
#-----------------------------------------------------------------------------
enum State {
	OCIOSO,
	PASSEANDO,
	INDO_PARA_CASA,
	EM_CASA,
	SAINDO_DE_CASA,
	INDO_PARA_O_TRABALHO,
	TRABALHANDO,
	REAGINDO_AO_JOGADOR
}

@export_category("Comportamento Geral")
@export var move_speed: float = 100.0
@export var wander_range: float = 200.0

@export_category("Dança")
@export var dance_animation_speed: float = 0.7
@export var shake_intensity: float = 1.5
@export var min_turn_time: float = 1.5
@export var max_turn_time: float = 4.0

@export_category("Interação do Cursor")
@export var interaction_cursor: Texture2D
@export var cursor_hotspot: Vector2 = Vector2.ZERO

@export_category("Nós")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var work_turn_timer: Timer = $WorkTurnTimer
@onready var status_bubble = $StatusBubbleAnchor/StatusBubble

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Referências externas
var house_node: House
var work_node: Node
var assigned_work_spot: Marker2D = null

# Estado atual do NPC
# MODIFICADO: O estado inicial agora é definido dinamicamente na função _ready
var current_state: State
var _state_before_interaction: State

# Timers e variáveis de controle
var _idle_timer: SceneTreeTimer
var _schedule_check_timer: Timer
var _repath_timer: Timer

# Controle de travamento
var _stuck_check_position: Vector2 = Vector2.ZERO
var _stuck_time: float = 0.0
var _is_unstucking: bool = false

# Ruído para animação de dança
var _noise = FastNoiseLite.new()
var _time_passed: float = 0.0

#-----------------------------------------------------------------------------
# INICIALIZAÇÃO
#-----------------------------------------------------------------------------
func _ready():
	status_bubble.hide()
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.seed = randi()
	_noise.frequency = 2.0
	work_turn_timer.timeout.connect(_on_work_turn_timer_timeout)

	_schedule_check_timer = Timer.new()
	_schedule_check_timer.wait_time = 1.0
	_schedule_check_timer.timeout.connect(_update_schedule)
	add_child(_schedule_check_timer)
	_schedule_check_timer.start()

	_repath_timer = Timer.new()
	_repath_timer.wait_time = 1.0
	_repath_timer.timeout.connect(_on_repath_timer_timeout)
	add_child(_repath_timer)
	_repath_timer.start()

	# MODIFICADO: Em vez de chamar _update_schedule, chamamos nossa nova função de inicialização.
	await get_tree().physics_frame
	_initialize_state_and_position()

# ADICIONADO: Nova função para definir o estado e a posição iniciais do NPC.
func _initialize_state_and_position():
	# Garante que as referências existam antes de decidir o que fazer.
	if not is_instance_valid(house_node) or not is_instance_valid(work_node):
		printerr("NPC '%s' não possui casa ou trabalho definidos. Iniciando como OCIOSO." % name)
		_change_state(State.OCIOSO)
		return

	var current_hour = WorldTimeManager.get_current_hour()
	var work_starts = work_node.work_starts_at
	var work_ends = work_node.work_ends_at

	# 1. Prioridade: Verificar se é horário de trabalho.
	if current_hour >= work_starts and current_hour < work_ends:
		print("'%s' está nascendo no trabalho." % name)
		# Posiciona o NPC diretamente no local de trabalho.
		global_position = work_node.get_available_work_position()
		# Define o estado para TRABALHANDO.
		_change_state(State.TRABALHANDO)
	# 2. Se não, verificar se é noite.
	elif WorldTimeManager.is_night():
		print("'%s' está nascendo em casa (noite)." % name)
		# Define o estado para EM_CASA (o que o fará ficar invisível).
		_change_state(State.EM_CASA)
	# 3. Se não for nenhum dos acima, é dia e hora de passear.
	else:
		print("'%s' está nascendo fora de casa (passeando)." % name)
		# Posiciona o NPC do lado de fora da sua casa.
		global_position = house_node.get_door_position() + Vector2(0, EXIT_DISTANCE)
		# Define o estado para PASSEANDO.
		_change_state(State.PASSEANDO)


#-----------------------------------------------------------------------------
# LOOP PRINCIPAL
#-----------------------------------------------------------------------------
func _physics_process(delta):
	# O resto do código permanece o mesmo...
	if current_state in [State.OCIOSO, State.EM_CASA, State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		_handle_idle_states(delta)
	else:
		var just_unstuck = _check_if_stuck(delta)
		if just_unstuck:
			velocity = Vector2.ZERO
		elif nav_agent.is_navigation_finished():
			velocity = Vector2.ZERO
			_on_target_reached()
		else:
			var next_path_position = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_path_position)
			velocity = direction.normalized() * move_speed

	move_and_slide()
	_update_animation()

# ... (O restante do seu script a partir daqui não precisa de alterações)
# Cole o resto do seu código (a partir de _handle_idle_states) aqui.
# A única mudança necessária foi no início do script.
#-----------------------------------------------------------------------------
# LÓGICA DE ESTADOS
#-----------------------------------------------------------------------------
func _handle_idle_states(delta):
	_stuck_time = 0.0
	velocity = Vector2.ZERO

func _update_schedule():
	if current_state == State.REAGINDO_AO_JOGADOR:
		return
	
	if not is_instance_valid(house_node) or not is_instance_valid(work_node):
		if current_state != State.OCIOSO:
			_change_state(State.OCIOSO)
		return

	var current_hour = WorldTimeManager.get_current_hour()

	if WorldTimeManager.is_night():
		if current_state not in [State.EM_CASA, State.INDO_PARA_CASA]:
			_change_state(State.INDO_PARA_CASA)
		return

	var work_starts = work_node.work_starts_at
	var work_ends = work_node.work_ends_at

	if current_hour >= work_starts and current_hour < work_ends:
		if current_state not in [State.TRABALHANDO, State.INDO_PARA_O_TRABALHO]:
			_change_state(State.INDO_PARA_O_TRABALHO)
		return

	if current_state == State.EM_CASA:
		_change_state(State.SAINDO_DE_CASA)
	elif current_state == State.TRABALHANDO:
		if is_instance_valid(work_node) and is_instance_valid(assigned_work_spot):
			work_node.release_work_spot(assigned_work_spot)
			assigned_work_spot = null # Limpa a referência
		
		_change_state(State.PASSEANDO)

func _change_state(new_state: State):
	if current_state == new_state:
		return
	
	if current_state == State.TRABALHANDO:
		StatusManager.mudar_status('dinheiro', 10)
	
	current_state = new_state
	
	if new_state != State.TRABALHANDO:
		work_turn_timer.stop()
		animated_sprite.position = Vector2.ZERO
		animated_sprite.speed_scale = 1.0
		
	_cancel_idle_timer()

	match current_state:
		State.SAINDO_DE_CASA:
			if is_instance_valid(house_node):
				# MODIFICADO: Garante que o NPC volte a ter um corpo físico ao sair
				if collision_shape:
					collision_shape.disabled = false
				
				show()
				global_position = house_node.get_door_position()
				var exit_point = house_node.get_door_position() + Vector2(0, EXIT_DISTANCE)
				nav_agent.target_position = exit_point

		State.INDO_PARA_CASA:
			if is_instance_valid(house_node):
				show()
				var door_position = house_node.get_door_position()
				var random_offset = Vector2(randf_range(-25.0, 25.0), 0) 
				nav_agent.target_position = door_position + random_offset

		State.INDO_PARA_O_TRABALHO:
			if is_instance_valid(work_node):
				show()
				# MODIFICADO: O NPC agora pede um local de trabalho vago.
				assigned_work_spot = work_node.claim_available_work_spot()
				
				# Se conseguiu um local, vai para lá.
				if is_instance_valid(assigned_work_spot):
					nav_agent.target_position = assigned_work_spot.global_position
				else:
					# Se não conseguiu (lotação máxima), ele fica ocioso por um tempo.
					print("'%s' não encontrou local de trabalho, ficará ocioso." % self.name)
					_change_state(State.OCIOSO)

		State.PASSEANDO:
			# MODIFICADO: Garante que o NPC tenha colisão ao passear (caso spawne nesse estado)
			if collision_shape:
				collision_shape.disabled = false
			_set_new_random_destination()

		State.TRABALHANDO:
			animated_sprite.play("walk")
			_on_work_turn_timer_timeout()

		State.OCIOSO:
			_idle_timer = get_tree().create_timer(randf_range(2.0, 5.0))
			_idle_timer.timeout.connect(_on_idle_timeout)

		State.EM_CASA:
			velocity = Vector2.ZERO
			hide()
			# MODIFICADO: Desabilita a colisão, tornando o NPC um "fantasma"
			if collision_shape:
				collision_shape.disabled = true

func _on_target_reached():
	match current_state:
		State.PASSEANDO:
			_change_state(State.OCIOSO)
		State.INDO_PARA_O_TRABALHO:
			_change_state(State.TRABALHANDO)

#=============================================================================
# FUNÇÕES DE INTERAÇÃO COM A CASA
#=============================================================================
func enter_house():
	if current_state == State.INDO_PARA_CASA:
		print("'%s' está entrando na casa." % name)
		_change_state(State.EM_CASA)

func exit_house_complete():
	if current_state == State.SAINDO_DE_CASA:
		print("'%s' completou a saída da casa." % name)
		_change_state(State.PASSEANDO)
#=============================================================================

#-----------------------------------------------------------------------------
# FUNÇÕES DE CAMINHO DINÂMICO
#-----------------------------------------------------------------------------
func _on_repath_timer_timeout():
	if not nav_agent.is_navigation_finished() and current_state not in [State.OCIOSO, State.EM_CASA, State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		nav_agent.target_position = nav_agent.get_final_position()
		
func _check_if_stuck(delta) -> bool:
	if _is_unstucking or velocity.is_zero_approx():
		_stuck_time = 0.0 
		return false

	if global_position.distance_to(_stuck_check_position) < 1.0:
		_stuck_time += delta
	else:
		_stuck_time = 0.0
		_stuck_check_position = global_position

	if _stuck_time > STUCK_THRESHOLD:
		_perform_unstuck()
		return true

	return false

func _perform_unstuck():
	if _is_unstucking: return
	
	print("'%s' está preso! Iniciando procedimento para destravar." % name)
	_is_unstucking = true
	_stuck_time = 0.0

	_on_repath_timer_timeout()

	await get_tree().physics_frame
	
	if nav_agent.is_navigation_finished():
		var nav_map = get_world_2d().navigation_map
		var safe_pos = NavigationServer2D.map_get_closest_point(nav_map, global_position)
		global_position = safe_pos
		print("'%s' foi teleportado para uma posição segura." % name)

	get_tree().create_timer(1.0).timeout.connect(func(): _is_unstucking = false)

#-----------------------------------------------------------------------------
# FUNÇÕES DE INTERAÇÃO E ANIMAÇÃO
#-----------------------------------------------------------------------------
func _on_area_2d_mouse_entered():
	if current_state in [State.EM_CASA, State.INDO_PARA_CASA]:
		return
		
	status_bubble.update_status(current_state)
	
	if interaction_cursor:
		Input.set_custom_mouse_cursor(interaction_cursor, Input.CURSOR_ARROW, cursor_hotspot)
	
	_state_before_interaction = current_state

func _on_area_2d_mouse_exited():
	status_bubble.hide()
	Input.set_custom_mouse_cursor(null)

func _on_work_turn_timer_timeout():
	var random_direction = randi() % 2
	work_turn_timer.wait_time = randf_range(min_turn_time, max_turn_time)
	work_turn_timer.start()

func _update_animation():
	if not is_instance_valid(animated_sprite):
		return
		
	if velocity.length() < MIN_VELOCITY_FOR_WALK:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	else:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
		animated_sprite.flip_h = velocity.x < 0

#-----------------------------------------------------------------------------
# FUNÇÕES DE MOVIMENTAÇÃO ALEATÓRIA
#-----------------------------------------------------------------------------
func _set_new_random_destination():
	if not is_instance_valid(house_node):
		return
	var wander_base_pos = house_node.get_door_position() + Vector2(0, EXIT_DISTANCE)
	var random_offset = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	var destination = wander_base_pos + random_offset
	nav_agent.target_position = destination

func _on_idle_timeout():
	if current_state == State.OCIOSO:
		_change_state(State.PASSEANDO)

func _cancel_idle_timer():
	if _idle_timer != null and not _idle_timer.is_queued_for_deletion():
		_idle_timer = null

#-----------------------------------------------------------------------------
# FUNÇÕES DE SAVE/LOAD
#-----------------------------------------------------------------------------
func get_save_data() -> Dictionary:
	return {"pos_x": position.x, "pos_y": position.y}

func load_data(data: Dictionary):
	var loaded_pos_x = data.get("pos_x", position.x)
	var loaded_pos_y = data.get("pos_y", position.y)
	position = Vector2(loaded_pos_x, loaded_pos_y)
