# NPC.gd
extends CharacterBody2D

# ESTADOS ATUALIZADOS
enum State { OCIOSO, PASSEANDO, INDO_PARA_CASA, EM_CASA, SAINDO_DE_CASA, INDO_PARA_O_TRABALHO, TRABALHANDO }

@export_category("Comportamento")
@export var move_speed: float = 50.0
@export var home_position: Vector2
@export var outside_position: Vector2
@export var wander_range: float = 200.0
@export var arrival_distance: float = 5.0

@export_category("Trabalho")
@export var work_position: Vector2
@export var work_starts_at: float = 8.0  # 8 AM
@export var work_ends_at: float = 17.0 # 5 PM

# --- LÓGICA DE DANÇA: VARIÁVEIS IMPORTADAS ---
@export_category("Dança de Trabalho")
@export var dance_animation_speed: float = 0.7
@export var shake_intensity: float = 1.5
@export var min_turn_time: float = 1.5
@export var max_turn_time: float = 4.0

@export_category("Nós")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $Texture
# --- LÓGICA DE DANÇA: NOVA REFERÊNCIA DE NÓ ---
@onready var work_turn_timer: Timer = $WorkTurnTimer

var current_state: State = State.EM_CASA
var _idle_timer = null
var _schedule_check_timer: Timer

# --- LÓGICA DE DANÇA: NOVAS VARIÁVEIS ---
var _noise = FastNoiseLite.new()
var _time_passed: float = 0.0


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# --- LÓGICA DE DANÇA: INICIALIZAÇÃO ---
	_noise.seed = randi()
	_noise.frequency = 2.0
	work_turn_timer.timeout.connect(_on_work_turn_timer_timeout)

	# ... (resto do _ready permanece o mesmo)
	_schedule_check_timer = Timer.new()
	_schedule_check_timer.wait_time = 1.0 
	_schedule_check_timer.timeout.connect(_update_schedule)
	add_child(_schedule_check_timer)
	_schedule_check_timer.start()
	await get_tree().physics_frame
	_update_schedule()


func _physics_process(delta):
	# --- LÓGICA DE DANÇA: EXECUÇÃO ---
	# Se o estado for TRABALHANDO, executa a lógica da dança.
	if current_state == State.TRABALHANDO:
		# Lógica de tremor (shake)
		_time_passed += delta
		var offset_x = _noise.get_noise_2d(_time_passed * 5.0, 0) * shake_intensity
		var offset_y = _noise.get_noise_2d(0, _time_passed * 5.0) * shake_intensity
		animated_sprite.position = Vector2(offset_x, offset_y)
		
		# Garante que o NPC não se mova enquanto dança
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Estados "parados"
	if current_state in [State.OCIOSO, State.EM_CASA]:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)
		move_and_slide()
		_update_animation()
		return

	# Lógica de chegada e movimento (inalterada)
	var final_destination = nav_agent.get_final_position()
	if global_position.distance_to(final_destination) < arrival_distance:
		_on_target_reached()
	else:
		var next_path_position = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_position)
		velocity = direction.normalized() * move_speed
	
	move_and_slide()
	_update_animation()

func _change_state(new_state: State):
	if current_state == new_state: return

	# --- LÓGICA DE DANÇA: DESLIGAR ---
	# Se o estado anterior era TRABALHANDO, paramos a dança.
	if current_state == State.TRABALHANDO:
		work_turn_timer.stop()
		animated_sprite.position = Vector2.ZERO # Reseta a posição do sprite
		animated_sprite.speed_scale = 1.0 # Volta a velocidade da animação ao normal

	_cancel_idle_timer()
	print(self.name, " mudou do estado ", State.keys()[current_state], " para ", State.keys()[new_state])
	current_state = new_state
	
	match current_state:
		# ... (outros estados)
		State.INDO_PARA_O_TRABALHO:
			show() 
			nav_agent.target_position = work_position
		
		# --- LÓGICA DE DANÇA: LIGAR ---
		State.TRABALHANDO:
			# Ao chegar no trabalho, começa a dançar.
			animated_sprite.play("walk") # Ou "dance", se você tiver essa animação
			animated_sprite.speed_scale = dance_animation_speed
			_on_work_turn_timer_timeout() # Chama uma vez para definir a direção inicial

		State.EM_CASA:
			hide()
		# ... (o resto dos estados permanece o mesmo)
		State.SAINDO_DE_CASA:
			global_position = home_position
			show()
			nav_agent.target_position = outside_position
		State.INDO_PARA_CASA:
			nav_agent.target_position = home_position
		State.PASSEANDO:
			_wander()
		State.OCIOSO:
			_idle_timer = get_tree().create_timer(randf_range(2.0, 5.0))
			_idle_timer.timeout.connect(_on_idle_timeout)


# --- LÓGICA DE DANÇA: NOVAS FUNÇÕES ---
func _on_work_turn_timer_timeout() -> void:
	# Lógica para virar o personagem aleatoriamente
	var random_direction = randi() % 2
	if random_direction == 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	work_turn_timer.wait_time = randf_range(min_turn_time, max_turn_time)
	work_turn_timer.start()


# --- O resto das funções permanece o mesmo ---
# (Cole aqui as suas funções _update_schedule, _on_target_reached, _update_animation,
# _wander, _on_idle_timeout, _cancel_idle_timer e as de save/load)
func _update_schedule():
	var current_hour = WorldTimeManager.get_current_hour()
	if WorldTimeManager.is_night():
		if current_state != State.EM_CASA and current_state != State.INDO_PARA_CASA: _change_state(State.INDO_PARA_CASA)
		return
	if current_hour >= work_starts_at and current_hour < work_ends_at:
		if current_state != State.TRABALHANDO and current_state != State.INDO_PARA_O_TRABALHO: _change_state(State.INDO_PARA_O_TRABALHO)
		return
	if current_state == State.EM_CASA: _change_state(State.SAINDO_DE_CASA)
	elif current_state == State.TRABALHANDO: _change_state(State.PASSEANDO)
func _on_target_reached():
	match current_state:
		State.PASSEANDO: _change_state(State.OCIOSO)
		State.INDO_PARA_CASA: _change_state(State.EM_CASA)
		State.SAINDO_DE_CASA: _change_state(State.PASSEANDO)
		State.INDO_PARA_O_TRABALHO: _change_state(State.TRABALHANDO)
func _update_animation():
	if velocity.length() < 10:
		if animated_sprite.animation != "idle": animated_sprite.play("idle")
	else:
		if animated_sprite.animation != "walk": animated_sprite.play("walk")
		if velocity.x < 0: animated_sprite.flip_h = true
		elif velocity.x > 0: animated_sprite.flip_h = false
func _wander():
	if current_state != State.PASSEANDO: return
	var random_offset = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	nav_agent.target_position = outside_position + random_offset
func _on_idle_timeout():
	if current_state == State.OCIOSO: _change_state(State.PASSEANDO)
func _cancel_idle_timer():
	if _idle_timer != null:
		_idle_timer.timeout.disconnect(_on_idle_timeout)
		_idle_timer = null
func get_save_data() -> Dictionary:
	return {"pos_x": position.x, "pos_y": position.y}
func load_data(data: Dictionary):
	var loaded_pos_x = data.get("pos_x", position.x)
	var loaded_pos_y = data.get("pos_y", position.y)
	position = Vector2(loaded_pos_x, loaded_pos_y)
