extends CharacterBody2D
class_name NPC

signal npc_clicked(npc_ref: NPC)
signal state_changed(npc_ref: NPC)

#-----------------------------------------------------------------------------
# CONSTANTES
#-----------------------------------------------------------------------------
const MIN_VELOCITY_FOR_WALK: float = 20.0
const EXIT_DISTANCE: float = 100.0
const STUCK_THRESHOLD: float = 0.5
const OUTLINE_MATERIAL = preload("res://Resources/Shaders/outline_material.tres")

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
	REAGINDO_AO_JOGADOR,
	DESABRIGADO,
	DESEMPREGADO
}

enum Profession {
	NENHUMA,
	ENFERMEIRO,
	RELIGIOSO,
	AGRICULTOR,
	GUERREIRO
}

const PROFESSION_NAMES = {
	Profession.NENHUMA: "Desempregado",
	Profession.ENFERMEIRO: "Enfermeiro(a)",
	Profession.RELIGIOSO: "Líder Espiritual",
	Profession.AGRICULTOR: "Agricultor(a)",
	Profession.GUERREIRO: "Guerreiro(a)"
}

@export_category("Comportamento Geral")
@export var npc_name: String = "Morador"
@export var profession: Profession = Profession.NENHUMA
@export var move_speed: float = 200.0
@export var wander_range: float = 250.0

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
var work_node: Node:
	set(new_work_node):
		if is_instance_valid(work_node) and work_node.has_method("remove_worker"):
			work_node.remove_worker(self)
			
		work_node = new_work_node
		
		if is_instance_valid(work_node) and work_node.has_method("add_worker"):
			work_node.add_worker(self)
var assigned_work_spot: Marker2D = null
var house: House = null # Referência à casa atual do NPC

# Estado atual do NPC
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

# ADICIONADO: Variáveis para a mecânica de ceder passagem
const STUCK_ON_NPC_YIELD_TIME: float = 2.0 # Segundos até pedir para passar
var is_yielding: bool = false # O NPC está cedendo passagem no momento?
var _stuck_on_npc: NPC = null # Em qual NPC estamos presos?
var _stuck_on_npc_timer: float = 0.0 # Há quanto tempo estamos presos nele?

var hud_node: Hud = null

var _original_move_speed: float
var days_homeless: int = 0
#-----------------------------------------------------------------------------
# INICIALIZAÇÃO
#-----------------------------------------------------------------------------
func _ready():
	status_bubble.hide()
	
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

	await get_tree().physics_frame
	_initialize_state_and_position()
	hud_node = get_tree().get_first_node_in_group("hud_main") as Hud
	
	nav_agent.velocity_computed.connect(on_velocity_computed)
	WorldTimeManager.day_passed.connect(_on_day_passed)

func _on_day_passed(day_number):
	if current_state == State.DESABRIGADO:
		days_homeless += 1
		print("'%s' está desabrigado por %d dias." % [npc_name, days_homeless])
		if days_homeless >= 5:
			_flee_quilombo()

func _flee_quilombo():
	print("'%s' está desabrigado há muito tempo e decidiu fugir!" % npc_name)
	StatusManager.mudar_status("relacoes", -5)
	QuilomboManager.unregister_npc(self)

func on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	WorldTimeManager.time_scale_changed.connect(_on_time_scale_changed)
	_original_move_speed = move_speed
	_on_time_scale_changed()

func _initialize_state_and_position():
	if not is_instance_valid(house_node):
		print("'%s' nasceu sem casa. Estado inicial: DESABRIGADO." % name)
		_change_state(State.DESABRIGADO)
		return

	var current_hour = WorldTimeManager.get_current_hour()
	
	if WorldTimeManager.is_night():
		_change_state(State.EM_CASA)
	else:
		global_position = house_node.get_door_position() + Vector2(0, EXIT_DISTANCE)
		
		if is_instance_valid(work_node):
			var work_starts = work_node.work_starts_at
			var work_ends = work_node.work_ends_at
			if current_hour >= work_starts and current_hour < work_ends:
				_change_state(State.INDO_PARA_O_TRABALHO)
			else:
				_change_state(State.SAINDO_DE_CASA)
		else:
			print("'%s' tem casa mas não tem trabalho. Estado inicial: DESEMPREGADO." % name)
			_change_state(State.DESEMPREGADO)

#-----------------------------------------------------------------------------
# LOOP PRINCIPAL
#-----------------------------------------------------------------------------
func _physics_process(delta):
	if current_state in [State.OCIOSO, State.EM_CASA, State.TRABALHANDO, State.REAGINDO_AO_JOGADOR]:
		_handle_idle_states(delta)
		nav_agent.set_velocity(Vector2.ZERO)
	else:
		if not nav_agent.is_navigation_finished():
			var next_path_position = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_path_position)
			nav_agent.set_velocity(direction * move_speed)
		else:
			nav_agent.set_velocity(Vector2.ZERO)
			velocity = Vector2.ZERO
			_on_target_reached()

	move_and_slide()
	_update_animation()
	_handle_npc_collision(delta)

func _handle_npc_collision(delta: float):
	if velocity.is_zero_approx():
		_stuck_on_npc = null
		_stuck_on_npc_timer = 0.0
		return

	var collision = get_last_slide_collision()
	
	if not collision or not collision.get_collider() is NPC:
		_stuck_on_npc = null
		_stuck_on_npc_timer = 0.0
		return
	
	var other_npc: NPC = collision.get_collider()

	if other_npc == _stuck_on_npc:
		_stuck_on_npc_timer += delta
	else:
		_stuck_on_npc = other_npc
		_stuck_on_npc_timer = 0.0
	
	if _stuck_on_npc_timer >= STUCK_ON_NPC_YIELD_TIME:
		print("'%s' está preso em '%s' por %.1f segundos. Pedindo passagem..." % [self.name, other_npc.name, _stuck_on_npc_timer])
		other_npc.request_to_yield_path()
		_stuck_on_npc_timer = 0.0

func request_to_yield_path():
	if is_yielding or State.EM_CASA:
		return
	
	print("--> '%s' ACEITOU o pedido e está cedendo a passagem!" % self.name)
	is_yielding = true
	collision_shape.disabled = true
	
	get_tree().create_timer(1.5).timeout.connect(func():
		print("'%s' voltou a ser sólido." % self.name)
		is_yielding = false
		collision_shape.disabled = false
	)

#-----------------------------------------------------------------------------
# LÓGICA DE ESTADOS
#-----------------------------------------------------------------------------
func _handle_idle_states(delta):
	_stuck_time = 0.0
	velocity = Vector2.ZERO

func _update_schedule():
	if current_state == State.REAGINDO_AO_JOGADOR:
		return

	if not is_instance_valid(house_node):
		_change_state(State.DESABRIGADO)
		return

	if not is_instance_valid(work_node):
		if current_state not in [State.DESEMPREGADO, State.OCIOSO, State.PASSEANDO, State.SAINDO_DE_CASA, State.EM_CASA]:
			_change_state(State.DESEMPREGADO)
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
			assigned_work_spot = null
			if work_node.has_method("remove_worker"):
				work_node.remove_worker(self)
		_change_state(State.PASSEANDO)

func _change_state(new_state: State):
	if current_state == new_state:
		return

	var old_state = current_state

	if old_state == State.TRABALHANDO:
		var money_gain = 10
		if GameManager.chosen_leader_type == GameManager.LeaderType.AGRICULTOR:
			if is_instance_valid(work_node) and work_node is Plantation:
				money_gain = int(money_gain * 1.5)
				print("'%s' (Agricultor) ganhou um bônus de dinheiro na plantação!" % npc_name)
		StatusManager.mudar_recurso('dinheiro', money_gain)

	if old_state == State.DESABRIGADO:
		StatusManager.remove_persistent_debuff("homeless_health_%d" % get_instance_id())
		StatusManager.remove_persistent_debuff("homeless_relations_%d" % get_instance_id())
	
	if old_state == State.DESEMPREGADO:
		StatusManager.remove_persistent_debuff(self.get_instance_id())

	current_state = new_state
	emit_signal("state_changed", self)

	if new_state != State.TRABALHANDO:
		work_turn_timer.stop()

	_cancel_idle_timer()

	match current_state:
		State.SAINDO_DE_CASA:
			if is_instance_valid(house_node):
				show()
				if collision_shape:
					collision_shape.disabled = false
				global_position = house_node.get_door_position()
				var base_exit_point = house_node.get_door_position() + Vector2(0, EXIT_DISTANCE)
				var random_offset = Vector2(randf_range(-40.0, 40.0), randf_range(-10.0, 10.0))
				nav_agent.target_position = base_exit_point + random_offset
		State.INDO_PARA_CASA:
			if is_instance_valid(house_node):
				collision_shape.disabled = false
				show()
				var door_position = house_node.get_door_position()
				var random_offset = Vector2(randf_range(-25.0, 25.0), 0)
				nav_agent.target_position = door_position + random_offset
		State.INDO_PARA_O_TRABALHO:
			if is_instance_valid(work_node):
				show()
				nav_agent.target_position = work_node.get_arrival_position()
			else:
				print("'%s' não encontrou local de trabalho, ficará ocioso." % self.name)
				_change_state(State.OCIOSO)
		State.PASSEANDO:
			collision_shape.disabled = false
			var interest_points = get_tree().get_nodes_in_group("locais_de_interesse")
			var visited_point = false
			if not interest_points.is_empty():
				if randf() < 0.5:
					var destination_node = interest_points.pick_random()
					if destination_node.has_method("claim_available_work_spot"):
						var spot = destination_node.claim_available_work_spot()
						if is_instance_valid(spot):
							nav_agent.target_position = spot.global_position
							print("'%s' decidiu visitar '%s'." % [name, destination_node.name])
							assigned_work_spot = spot
							visited_point = true
			if not visited_point:
				print("'%s' decidiu passear aleatoriamente." % name)
				_set_new_random_destination()
		State.TRABALHANDO:
			if collision_shape:
				collision_shape.disabled = false
			animated_sprite.play("walk")
			_on_work_turn_timer_timeout()
		State.OCIOSO:
			if collision_shape:
				collision_shape.disabled = false
			_idle_timer = get_tree().create_timer(randf_range(2.0, 5.0))
			_idle_timer.timeout.connect(_on_idle_timeout)
		State.EM_CASA:
			velocity = Vector2.ZERO
			collision_shape.disabled = true
			hide()
		State.DESABRIGADO:
			StatusManager.add_persistent_debuff("homeless_health_%d" % get_instance_id(), "saude", -5)
			StatusManager.add_persistent_debuff("homeless_relations_%d" % get_instance_id(), "relacoes", -5)
			# As linhas abaixo foram movidas do if gigante para cá
			velocity = Vector2.ZERO
			show()
			if collision_shape:
				collision_shape.disabled = false
			print("'%s' está no estado DESABRIGADO." % name)
		State.DESEMPREGADO:
			show()
			if collision_shape:
				collision_shape.disabled = false
			print("'%s' está desempregado e vai passear." % name)
			_set_new_random_destination()

	# Este if era redundante, a lógica foi movida para dentro do 'match'
	#if current_state == State.DESABRIGADO:
	#	StatusManager.add_persistent_debuff(self.get_instance_id(), "saude", -5)
	
func _on_target_reached():
	match current_state:
		State.DESEMPREGADO:
			_change_state(State.OCIOSO)
		State.PASSEANDO:
			if is_instance_valid(assigned_work_spot):
				var location_node = assigned_work_spot.get_owner()
				if is_instance_valid(location_node) and location_node.has_method("release_work_spot"):
					location_node.release_work_spot(assigned_work_spot)
					assigned_work_spot = null
			_change_state(State.OCIOSO)
		State.INDO_PARA_O_TRABALHO:
			_change_state(State.TRABALHANDO)

#=============================================================================
# FUNÇÕES DE INTERAÇÃO COM A CASA
#=============================================================================
func enter_house():
	if current_state == State.INDO_PARA_CASA:
		print("'%s' está entrando na casa." % name)
		hide()
		if collision_shape:
			collision_shape.disabled = true
		_change_state(State.EM_CASA)

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
		if not _is_unstucking:
			_perform_unstuck()
		return true

	return false

func _perform_unstuck():
	if _is_unstucking or current_state in [State.EM_CASA, State.SAINDO_DE_CASA]: return
	
	collision_shape.disabled = true
	_is_unstucking = true
	print("'%s' está preso! Iniciando procedimento para destravar." % self.name)
	_stuck_time = 0.0

	_on_repath_timer_timeout()

	var escape_target = global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
	var nav_map = get_world_2d().navigation_map
	var safe_pos = NavigationServer2D.map_get_closest_point(nav_map, escape_target)
	
	print("--> Teleportando '%s' de %s para uma posição de fuga segura em %s" % [self.name, global_position.round(), safe_pos.round()])
	global_position = safe_pos

	get_tree().create_timer(1.0).timeout.connect(func():
		print("--> Procedimento de destravar para '%s' finalizado." % self.name)
		collision_shape.disabled = false
		_is_unstucking = false
	)

#-----------------------------------------------------------------------------
# FUNÇÕES DE INTERAÇÃO E ANIMAÇÃO
#-----------------------------------------------------------------------------
func _on_area_2d_mouse_entered():
	if is_instance_valid(hud_node):
		hud_node.report_npc_hover(self)

func _on_area_2d_mouse_exited():
	if is_instance_valid(hud_node):
		hud_node.report_npc_unhover(self)

func _on_work_turn_timer_timeout():
	var random_direction = randi() % 2
	work_turn_timer.wait_time = randf_range(min_turn_time, max_turn_time)
	work_turn_timer.start()
	
func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		emit_signal("npc_clicked", self)

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
	var nav_map_rid = get_world_2d().navigation_map
	var random_point = NavigationServer2D.map_get_random_point(nav_map_rid, 1, true)
	
	if random_point != Vector2.ZERO:
		nav_agent.target_position = random_point
	else:
		if is_instance_valid(house_node):
			var wander_base_pos = house_node.get_door_position() + Vector2(0, EXIT_DISTANCE)
			var random_offset = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
			nav_agent.target_position = wander_base_pos + random_offset

func _on_idle_timeout():
	if current_state == State.OCIOSO:
		_change_state(State.PASSEANDO)

func _cancel_idle_timer():
	if _idle_timer != null and not _idle_timer.is_queued_for_deletion():
		_idle_timer = null

# --- NPC PEDINDO PARA SAIR ---
func request_exit_house():
	if house:
		house.request_exit(self)

# --- NPC RECEBE AUTORIZAÇÃO PARA SAIR ---
func start_exit():
	current_state = State.SAINDO_DE_CASA
	if house:
		nav_agent.target_position = house.get_door_position()
	print("%s está saindo da casa..." % name)

func exit_house_complete():
	current_state = State.PASSEANDO
	if house:
		house.notify_exit_done()
	print("%s terminou de sair da casa." % name)

#-----------------------------------------------------------------------------
# FUNÇÕES DE SAVE/LOAD
#-----------------------------------------------------------------------------
func get_save_data() -> Dictionary:
	return {"pos_x": position.x, "pos_y": position.y}

func load_data(data: Dictionary):
	var loaded_pos_x = data.get("pos_x", position.x)
	var loaded_pos_y = data.get("pos_y", position.y)
	position = Vector2(loaded_pos_x, loaded_pos_y)

func assign_house(new_house: House):
	if not is_instance_valid(new_house): return
	print("'%s' recebeu uma casa! Deixando de ser desabrigado." % name)
	self.house_node = new_house
	new_house.add_resident(self)
	_initialize_state_and_position()

func assign_work(new_workplace):
	if not is_instance_valid(new_workplace): return
	print("'%s' recebeu um trabalho! Deixando de ser desempregado." % name)
	self.work_node = new_workplace
	_initialize_state_and_position()
	
func set_profession(new_profession: Profession):
	if self.profession == new_profession: return
	self.profession = new_profession
	print("'%s' agora tem a profissão de %s." % [name, Profession.keys()[profession]])
	QuilomboManager.find_work_for_npc(self)
	QuilomboManager._debug_print_all_npc_status("Após Atribuir Profissão")

func get_idle_sprite_texture() -> Texture2D:
	if not is_instance_valid(animated_sprite):
		return null

	var sprite_frames = animated_sprite.sprite_frames
	var anim_name = "idle"

	if sprite_frames.has_animation(anim_name) and sprite_frames.get_frame_count(anim_name) > 0:
		return sprite_frames.get_frame_texture(anim_name, 0)
	return null

func highlight_on():
	if is_instance_valid(animated_sprite):
		animated_sprite.material = OUTLINE_MATERIAL

func highlight_off():
	if is_instance_valid(animated_sprite):
		animated_sprite.material = null

func _on_time_scale_changed():
	var current_time_scale = WorldTimeManager.time_scale
	move_speed = _original_move_speed * current_time_scale
	if is_instance_valid(animated_sprite):
		animated_sprite.speed_scale = current_time_scale
