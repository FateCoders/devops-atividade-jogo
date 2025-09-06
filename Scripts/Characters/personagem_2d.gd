# NPC.gd
extends CharacterBody2D
class_name NPC 

#-----------------------------------------------------------------------------
# ESTADOS E PROPRIEDADES
#-----------------------------------------------------------------------------

enum State { OCIOSO, PASSEANDO, INDO_PARA_CASA, EM_CASA, SAINDO_DE_CASA, INDO_PARA_O_TRABALHO, TRABALHANDO, REAGINDO_AO_JOGADOR }

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

# Variáveis dinâmicas (atribuídas pelo QuilomboManager)
var house_node: House
var work_node: Node 

# Variáveis internas
var current_state: State = State.EM_CASA
var _state_before_interaction: State
var _idle_timer = null
var _schedule_check_timer: Timer
var _noise = FastNoiseLite.new()
var _time_passed: float = 0.0

# Novas variáveis para recalcular o caminho
var _repath_timer: Timer
var _stuck_check_position: Vector2 = Vector2.ZERO
var _stuck_time: float = 0.0
const STUCK_THRESHOLD: float = 0.5 # Meio segundo parado é considerado "preso"
var _is_unstucking: bool = false # Nova variável de controle

#-----------------------------------------------------------------------------
# FUNÇÕES PRINCIPAIS (INICIALIZAÇÃO E LOOP)
#-----------------------------------------------------------------------------

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.seed = randi()
	_noise.frequency = 2.0
	work_turn_timer.timeout.connect(_on_work_turn_timer_timeout)

	# Timer que funciona como o "cérebro", checando a rotina a cada segundo
	_schedule_check_timer = Timer.new()
	_schedule_check_timer.wait_time = 1.0 
	_schedule_check_timer.timeout.connect(_update_schedule)
	add_child(_schedule_check_timer)
	_schedule_check_timer.start()

	# Timer que força o NPC a recalcular seu caminho periodicamente
	_repath_timer = Timer.new()
	_repath_timer.wait_time = 1.0 # Recalcula a cada 1 segundo
	_repath_timer.autostart = true
	_repath_timer.timeout.connect(_on_repath_timer_timeout)
	add_child(_repath_timer)

	await get_tree().physics_frame
	_update_schedule()

func _physics_process(delta):
	# Se o NPC está em um estado "parado", ele não deve se mover.
	if current_state in [State.OCIOSO, State.EM_CASA, State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		_stuck_time = 0.0 # Reseta o detector de "preso"
		if current_state in [State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
			_perform_dance_shake(delta)
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)
	
	# Se o NPC está em um estado de movimento...
	else:
		# PRIMEIRO, verifica se ele está preso e se precisa de um teletransporte.
		var just_unstuck = _check_if_stuck(delta)
		
		# SE ele acabou de ser teletransportado, zera a velocidade para "fixar" a nova posição.
		if just_unstuck:
			velocity = Vector2.ZERO
		# SENÃO, continua o movimento normal.
		elif nav_agent.is_navigation_finished():
			velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)
			_on_target_reached()
		else:
			var next_path_position = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_path_position)
			velocity = direction.normalized() * move_speed
	
	move_and_slide()
	_update_animation()
	# Estados "parados" ou com lógica especial têm prioridade
	if current_state in [State.OCIOSO, State.EM_CASA, State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		_stuck_time = 0.0 # Reseta o detector de "preso"
		if current_state in [State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
			_perform_dance_shake(delta)
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)
	# Lógica para todos os estados de movimento
	else:
		if nav_agent.is_navigation_finished():
			velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)
			_on_target_reached()
		else:
			_check_if_stuck(delta) # Verifica se o NPC está preso
			var next_path_position = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_path_position)
			velocity = direction.normalized() * move_speed
	
	move_and_slide()
	_update_animation()

#-----------------------------------------------------------------------------
# LÓGICA DE ESTADOS E NAVEGAÇÃO DINÂMICA
#-----------------------------------------------------------------------------

func _update_schedule():
	if current_state == State.REAGINDO_AO_JOGADOR: return
	if not house_node or not work_node:
		if current_state != State.OCIOSO: _change_state(State.OCIOSO)
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
	if current_state == new_state: return
	
	if current_state in [State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		work_turn_timer.stop()
		animated_sprite.position = Vector2.ZERO
		animated_sprite.speed_scale = 1.0
		
	_cancel_idle_timer()
	print(self.name, " mudou do estado ", State.keys()[current_state], " para ", State.keys()[new_state])
	
	if current_state == State.TRABALHANDO and new_state == State.PASSEANDO:
		StatusManager.mudar_status("dinheiro", 10)
		print(self.name, " terminou o trabalho e ganhou 10 de dinheiro.")
	
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
			_wander()
		State.TRABALHANDO:
			animated_sprite.play("walk")
			animated_sprite.speed_scale = dance_animation_speed
			_on_work_turn_timer_timeout()
		State.REAGINDO_AO_JOGADOR:
			animated_sprite.play("dance")
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

## Comando recebido da casa para entrar.
func enter_house():
	if current_state == State.INDO_PARA_CASA:
		_change_state(State.EM_CASA)

# --- FUNÇÕES PARA CAMINHO DINÂMICO ---

func _on_repath_timer_timeout():
	if not nav_agent.is_navigation_finished() and current_state not in [State.OCIOSO, State.EM_CASA, State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		nav_agent.target_position = nav_agent.get_final_position()

# Em NPC.gd

func _check_if_stuck(delta) -> bool:
	# Se já estamos no cooldown, avisa que nada aconteceu e para.
	if _is_unstucking:
		return false # <-- CORREÇÃO APLICADA AQUI

	if global_position.distance_to(_stuck_check_position) < 1.0:
		_stuck_time += delta
	else:
		_stuck_time = 0.0
		_stuck_check_position = global_position
	
	if _stuck_time > STUCK_THRESHOLD:
		print(self.name, " está preso! Forçando um recálculo e reposicionamento...")
		_stuck_time = 0.0
		_is_unstucking = true

		var nav_map = get_tree().get_root().get_world_2d().navigation_map
		var safe_pos = NavigationServer2D.map_get_closest_point(nav_map, global_position)
		
		global_position = safe_pos
		
		_on_repath_timer_timeout()
		
		get_tree().create_timer(1.0).timeout.connect(func(): _is_unstucking = false)
		
		return true

	return false
#-----------------------------------------------------------------------------
# FUNÇÕES DE INTERAÇÃO, ANIMAÇÃO E COMPORTAMENTO
#-----------------------------------------------------------------------------

func _on_area_2d_mouse_entered():
	if interaction_cursor:
		Input.set_custom_mouse_cursor(interaction_cursor, Input.CURSOR_ARROW, cursor_hotspot)
	
	if current_state in [State.EM_CASA, State.INDO_PARA_CASA]: return
	_state_before_interaction = current_state
	_change_state(State.REAGINDO_AO_JOGADOR)

func _on_area_2d_mouse_exited():
		# Reseta o cursor para o padrão do sistema.
	Input.set_custom_mouse_cursor(null)
	
	if current_state == State.REAGINDO_AO_JOGADOR:
		_change_state(_state_before_interaction)

func _perform_dance_shake(delta):
	_time_passed += delta
	var offset_x = _noise.get_noise_2d(_time_passed * 5.0, 0) * shake_intensity
	var offset_y = _noise.get_noise_2d(0, _time_passed * 5.0) * shake_intensity
	animated_sprite.position = Vector2(offset_x, offset_y)

func _on_work_turn_timer_timeout():
	var random_direction = randi() % 2
	if random_direction == 0: animated_sprite.flip_h = true
	else: animated_sprite.flip_h = false
	work_turn_timer.wait_time = randf_range(min_turn_time, max_turn_time)
	work_turn_timer.start()

func _update_animation():
	if not animated_sprite: return
	if velocity.length() < 10:
		if animated_sprite.animation != "idle": animated_sprite.play("idle")
	else:
		if animated_sprite.animation != "walk": animated_sprite.play("walk")
		if velocity.x < -1: animated_sprite.flip_h = true
		elif velocity.x > 1: animated_sprite.flip_h = false

func _wander():
	if current_state != State.PASSEANDO or not house_node: return
	var wander_base_pos = house_node.get_door_position() + Vector2(0, 50)
	var random_offset = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	nav_agent.target_position = wander_base_pos + random_offset

func _on_idle_timeout():
	if current_state == State.OCIOSO:
		_change_state(State.PASSEANDO)

func _cancel_idle_timer():
	if _idle_timer != null:
		_idle_timer.timeout.disconnect(_on_idle_timeout)
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
