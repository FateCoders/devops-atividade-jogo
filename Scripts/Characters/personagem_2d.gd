# NPC.gd
extends CharacterBody2D
class_name NPC 

enum State { OCIOSO, PASSEANDO, INDO_PARA_CASA, EM_CASA, SAINDO_DE_CASA, INDO_PARA_O_TRABALHO, TRABALHANDO, REAGINDO_AO_JOGADOR }

@export_category("Comportamento Geral")
@export var move_speed: float = 50.0
@export var wander_range: float = 200.0
@export var arrival_distance: float = 5.0

@export_category("Dança de Trabalho")
@export var dance_animation_speed: float = 0.7
@export var shake_intensity: float = 1.5
@export var min_turn_time: float = 1.5
@export var max_turn_time: float = 4.0

@export_category("Nós")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var work_turn_timer: Timer = $WorkTurnTimer

# Variáveis dinâmicas (atribuídas pelo QuilomboManager)
var house_node: House
var work_node: Node 

var current_state: State = State.EM_CASA
var _state_before_interaction: State
var _idle_timer = null
var _schedule_check_timer: Timer
var _noise = FastNoiseLite.new()
var _time_passed: float = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.seed = randi()
	_noise.frequency = 2.0
	work_turn_timer.timeout.connect(_on_work_turn_timer_timeout)

	_schedule_check_timer = Timer.new()
	_schedule_check_timer.wait_time = 1.0 
	_schedule_check_timer.timeout.connect(_update_schedule)
	add_child(_schedule_check_timer)
	_schedule_check_timer.start()

	await get_tree().physics_frame
	_update_schedule()

func _physics_process(delta):
	if current_state in [State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		_perform_dance_shake(delta)
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if current_state in [State.OCIOSO, State.EM_CASA]:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)
		move_and_slide()
		_update_animation()
		return

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

	if current_state in [State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		work_turn_timer.stop()
		animated_sprite.position = Vector2.ZERO
		animated_sprite.speed_scale = 1.0

	_cancel_idle_timer()
	print(self.name, " mudou do estado ", State.keys()[current_state], " para ", State.keys()[new_state])
	current_state = new_state
	
	match current_state:
		State.SAINDO_DE_CASA:
			if house_node:
				global_position = house_node.get_door_position()
				show()
				nav_agent.target_position = house_node.get_door_position() + Vector2(0, 50)
		State.INDO_PARA_CASA:
			if house_node:
				nav_agent.target_position = house_node.get_door_position()
		State.INDO_PARA_O_TRABALHO:
			if work_node:
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
			if house_node:
				global_position = house_node.get_door_position()
			hide()


# --- FUNÇÕES DE INTERAÇÃO ---
func _on_area_2d_mouse_entered():
	if current_state in [State.EM_CASA, State.INDO_PARA_CASA]: return
	_state_before_interaction = current_state
	_change_state(State.REAGINDO_AO_JOGADOR)

func _on_area_2d_mouse_exited():
	if current_state == State.REAGINDO_AO_JOGADOR:
		_change_state(_state_before_interaction)

# --- FUNÇÕES DE COMPORTAMENTO E AUXILIARES ---
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

func _update_schedule():
	if current_state == State.REAGINDO_AO_JOGADOR: return
	if not house_node or not work_node:
		_change_state(State.OCIOSO)
		return

	var current_hour = WorldTimeManager.get_current_hour()
	
	if WorldTimeManager.is_night():
		if current_state not in [State.EM_CASA, State.INDO_PARA_CASA]:
			_change_state(State.INDO_PARA_CASA)
		return

	# Aqui, assumimos que as variáveis de horário de trabalho vêm do nó 'work_node'
	if work_node.has_method("get_work_schedule"):
		var schedule = work_node.get_work_schedule() # Exemplo
		if current_hour >= schedule.start and current_hour < schedule.end:
			if current_state not in [State.TRABALHANDO, State.INDO_PARA_O_TRABALHO]:
				_change_state(State.INDO_PARA_O_TRABALHO)
			return
	
	if current_state == State.EM_CASA:
		_change_state(State.SAINDO_DE_CASA)
	elif current_state == State.TRABALHANDO:
		_change_state(State.PASSEANDO)

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

func get_save_data() -> Dictionary:
	return {"pos_x": position.x, "pos_y": position.y}

func load_data(data: Dictionary):
	var loaded_pos_x = data.get("pos_x", position.x)
	var loaded_pos_y = data.get("pos_y", position.y)
	position = Vector2(loaded_pos_x, loaded_pos_y)
