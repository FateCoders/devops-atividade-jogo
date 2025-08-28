# NPC.gd
extends CharacterBody2D

enum State { OCIOSO, PASSEANDO, INDO_PARA_CASA, EM_CASA, SAINDO_DE_CASA }

@export_category("Comportamento")
@export var move_speed: float = 50.0
@export var home_position: Vector2
@export var outside_position: Vector2
@export var wander_range: float = 200.0
## A que distância do alvo o NPC considera que "chegou". Ajuste se ele parar antes do destino.
@export var arrival_distance: float = 5.0

@export_category("Nós")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $Texture 

var current_state: State = State.EM_CASA
var _idle_timer = null

func _ready():
	# Garante que o NPC continue recebendo sinais mesmo quando está escondido.
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not nav_agent or not animated_sprite:
		printerr("ERRO no NPC '", self.name, "': Um nó filho (NavigationAgent2D ou AnimatedSprite2D) não foi encontrado!")
		set_physics_process(false)
		return

	WorldTimeManager.period_changed.connect(_on_world_period_changed)
	await get_tree().physics_frame
	
	if WorldTimeManager.is_day():
		global_position = home_position
		show()
		_change_state(State.SAINDO_DE_CASA)
	else:
		_change_state(State.EM_CASA)
		hide()


func _physics_process(delta):
	# Se o NPC está em um estado "parado", apenas garante que ele pare e não faz mais nada.
	if current_state == State.OCIOSO or current_state == State.EM_CASA:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)
		move_and_slide()
		_update_animation()
		return

	# --- LÓGICA DE CHEGADA CORRIGIDA ---
	# Verificamos se temos um alvo e se a distância até ele é menor que a nossa margem de chegada.
	var has_reached_target = false
	# Usamos get_final_position() que é o alvo final do caminho atual.
	var final_destination = nav_agent.get_final_position()
	if global_position.distance_to(final_destination) < arrival_distance:
		has_reached_target = true
	
	if has_reached_target:
		# Se chegou, paramos o movimento e chamamos a função de chegada.
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * delta)
		_on_target_reached()
	else:
		# Se não chegou, continua se movendo.
		var next_path_position = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_position)
		velocity = direction.normalized() * move_speed
	
	move_and_slide()
	_update_animation()


func _on_target_reached():
	match current_state:
		State.PASSEANDO: 
			_change_state(State.OCIOSO)
		State.INDO_PARA_CASA: 
			_change_state(State.EM_CASA)
		State.SAINDO_DE_CASA: 
			_change_state(State.PASSEANDO)


func _update_animation():
	if velocity.length() < 10:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	else:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")

		if velocity.x < 0:
			animated_sprite.flip_h = true
		elif velocity.x > 0:
			animated_sprite.flip_h = false


func _on_world_period_changed(period_name: String):
	if period_name == "NIGHT":
		if current_state in [State.PASSEANDO, State.OCIOSO, State.SAINDO_DE_CASA]:
			_change_state(State.INDO_PARA_CASA)
	elif period_name == "DAY":
		if current_state == State.EM_CASA:
			_change_state(State.SAINDO_DE_CASA)


func _wander():
	if current_state != State.PASSEANDO: return
	var random_offset = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	nav_agent.target_position = outside_position + random_offset
	print(self.name, " está passeando para ", nav_agent.target_position)


func _change_state(new_state: State):
	if current_state == new_state: return

	_cancel_idle_timer()

	print(self.name, " mudou do estado ", State.keys()[current_state], " para ", State.keys()[new_state])
	current_state = new_state
	
	match current_state:
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
		State.EM_CASA:
			hide()

func _on_idle_timeout():
	if current_state == State.OCIOSO:
		_change_state(State.PASSEANDO)
		
func _cancel_idle_timer():
	if _idle_timer != null:
		_idle_timer.timeout.disconnect(_on_idle_timeout)
		_idle_timer = null

# --- FUNÇÕES DE SAVE/LOAD (Opcional, mas mantido) ---
func get_save_data() -> Dictionary:
	return {"pos_x": position.x, "pos_y": position.y}
func load_data(data: Dictionary):
	var loaded_pos_x = data.get("pos_x", position.x)
	var loaded_pos_y = data.get("pos_y", position.y)
	position = Vector2(loaded_pos_x, loaded_pos_y)
