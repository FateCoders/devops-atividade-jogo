extends CharacterBody2D
class_name NPC

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
@export var move_speed: float = 50.0
@export var wander_range: float = 200.0
@export var arrival_distance: float = 5.0

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

# Referências externas
var house_node: House
var work_node: Node

# Estado atual do NPC
var current_state: State = State.EM_CASA
var _state_before_interaction: State

# Timers e variáveis de controle
var _idle_timer: SceneTreeTimer
var _schedule_check_timer: Timer
var _repath_timer: Timer

# Controle de travamento
var _stuck_check_position: Vector2 = Vector2.ZERO
var _stuck_time: float = 0.0
const STUCK_THRESHOLD: float = 0.5 # 0.5 segundos preso
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

	# Timer que checa a rotina do NPC
	_schedule_check_timer = Timer.new()
	_schedule_check_timer.wait_time = 1.0
	_schedule_check_timer.timeout.connect(_update_schedule)
	add_child(_schedule_check_timer)
	_schedule_check_timer.start()

	# Timer para recalcular caminho automaticamente
	_repath_timer = Timer.new()
	_repath_timer.wait_time = 1.0
	_repath_timer.timeout.connect(_on_repath_timer_timeout)
	add_child(_repath_timer)
	_repath_timer.start()

	await get_tree().physics_frame
	_update_schedule()

#-----------------------------------------------------------------------------
# LOOP PRINCIPAL
#-----------------------------------------------------------------------------
func _physics_process(delta):
	# Se está parado, só anima ou reseta timers
	if current_state in [State.OCIOSO, State.EM_CASA, State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		_handle_idle_states(delta)
	else:
		# Verifica se está preso
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

#-----------------------------------------------------------------------------
# LÓGICA DE ESTADOS
#-----------------------------------------------------------------------------
func _handle_idle_states(delta):
	_stuck_time = 0.0
	velocity = Vector2.ZERO
	if current_state in [State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		_perform_dance_shake(delta)

func _update_schedule():
	if current_state == State.REAGINDO_AO_JOGADOR:
		return
	if not house_node or not work_node:
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
		_change_state(State.PASSEANDO)

func _change_state(new_state: State):
	if current_state == State.TRABALHANDO:
		StatusManager.mudar_status('dinheiro', 10)
	if current_state == new_state: return
	
	current_state = new_state
	# status_bubble.update_status(current_state)
	
	if current_state in [State.TRABALHANDO]:
		work_turn_timer.stop()
		animated_sprite.position = Vector2.ZERO
		animated_sprite.speed_scale = 1.0
		
	_cancel_idle_timer()
	current_state = new_state

	match current_state:
		State.SAINDO_DE_CASA:
			if house_node and is_instance_valid(house_node):
				show()
				global_position = house_node.get_door_position()
				nav_agent.target_position = house_node.get_door_position() + Vector2(0, 50)
		State.INDO_PARA_CASA:
			if house_node and is_instance_valid(house_node):
				nav_agent.target_position = house_node.get_door_position()
		State.INDO_PARA_O_TRABALHO:
			if work_node and is_instance_valid(work_node):
				show()
				nav_agent.target_position = work_node.get_available_work_position()
		State.PASSEANDO:
			_set_new_random_destination()
		State.TRABALHANDO:
			animated_sprite.play("walk")
			animated_sprite.speed_scale = dance_animation_speed
			_on_work_turn_timer_timeout()
		State.OCIOSO:
			_idle_timer = get_tree().create_timer(randf_range(2.0, 5.0))
			_idle_timer.timeout.connect(_on_idle_timeout)
		State.EM_CASA:
			hide()

func _on_target_reached():
	match current_state:
		State.PASSEANDO: _change_state(State.OCIOSO)
		State.INDO_PARA_CASA: _change_state(State.EM_CASA)
		State.SAINDO_DE_CASA: _change_state(State.PASSEANDO)
		State.INDO_PARA_O_TRABALHO: _change_state(State.TRABALHANDO)

#-----------------------------------------------------------------------------
# FUNÇÕES DE CAMINHO DINÂMICO
#-----------------------------------------------------------------------------
func _on_repath_timer_timeout():
	if not nav_agent.is_navigation_finished() and current_state not in [State.OCIOSO, State.EM_CASA, State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		nav_agent.target_position = nav_agent.get_final_position()

func _check_if_stuck(delta) -> bool:
	if _is_unstucking:
		return false

	if global_position.distance_to(_stuck_check_position) < 1.0:
		_stuck_time += delta
	else:
		_stuck_time = 0.0
		_stuck_check_position = global_position

	if _stuck_time > STUCK_THRESHOLD:
		_stuck_time = 0.0
		_is_unstucking = true

		# Primeiro tenta recalcular o caminho
		_on_repath_timer_timeout()

		# Se ainda estiver sem caminho, teleporta para um ponto válido
		if nav_agent.is_navigation_finished():
			var nav_map = get_tree().get_root().get_world_2d().navigation_map
			var safe_pos = NavigationServer2D.map_get_closest_point(nav_map, global_position)
			global_position = safe_pos

		get_tree().create_timer(1.0).timeout.connect(func(): _is_unstucking = false)
		return true

	return false

#-----------------------------------------------------------------------------
# FUNÇÕES DE INTERAÇÃO E ANIMAÇÃO
#-----------------------------------------------------------------------------
func _on_area_2d_mouse_entered():
	if current_state in [State.EM_CASA, State.INDO_PARA_CASA]:
		return
		
	status_bubble.update_status(current_state)
	
	if interaction_cursor:
		Input.set_custom_mouse_cursor(interaction_cursor, Input.CURSOR_ARROW, cursor_hotspot)
	
	if current_state in [State.EM_CASA, State.INDO_PARA_CASA]: return
	_state_before_interaction = current_state

func _on_area_2d_mouse_exited():
	status_bubble.hide()
		# Reseta o cursor para o padrão do sistema.
	Input.set_custom_mouse_cursor(null)

func _perform_dance_shake(delta):
	_time_passed += delta
	var offset_x = _noise.get_noise_2d(_time_passed * 5.0, 0) * shake_intensity
	var offset_y = _noise.get_noise_2d(0, _time_passed * 5.0) * shake_intensity
	animated_sprite.position = Vector2(offset_x, offset_y)

func _on_work_turn_timer_timeout():
	var random_direction = randi() % 2
	animated_sprite.flip_h = random_direction == 0
	work_turn_timer.wait_time = randf_range(min_turn_time, max_turn_time)
	work_turn_timer.start()

func _update_animation():
	if not animated_sprite:
		return
	if velocity.length() < 10:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	else:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
		animated_sprite.flip_h = velocity.x < -1

#-----------------------------------------------------------------------------
# FUNÇÕES DE MOVIMENTAÇÃO ALEATÓRIA
#-----------------------------------------------------------------------------
func _set_new_random_destination():
	if not house_node:
		return
	var wander_base_pos = house_node.get_door_position() + Vector2(0, 50)
	var random_offset = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	var destination = wander_base_pos + random_offset
	nav_agent.target_position = destination

func _on_idle_timeout():
	if current_state == State.OCIOSO:
		_change_state(State.PASSEANDO)

func _cancel_idle_timer():
	if _idle_timer != null:
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
