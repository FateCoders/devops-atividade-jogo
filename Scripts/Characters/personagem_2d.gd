# NPC.gd
extends CharacterBody2D

# Define os possíveis estados do NPC
enum State { PASSEANDO, INDO_PARA_CASA, EM_CASA, SAINDO_DE_CASA }

@export var move_speed: float = 50.0

# Posição da casa do NPC (defina no Inspetor)
@export var home_position: Vector2
# Posição do lado de fora da casa para onde ele vai ao sair
@export var outside_position: Vector2
## O quão longe o NPC pode passear a partir do ponto inicial.
@export var wander_range: float = 200.0

# Referência ao agente de navegação
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var current_state: State = State.EM_CASA


func _ready():
	if not nav_agent:
		printerr("ERRO no NPC '", self.name, "': Nó filho NavigationAgent2D não encontrado! Desabilitando o NPC.")
		set_physics_process(false)
		return

	WorldTimeManager.period_changed.connect(_on_world_period_changed)
	
	# Aguarda um frame para garantir que a navegação esteja pronta
	await get_tree().physics_frame
	
	if WorldTimeManager.is_day():
		# Posição e visibilidade são ajustadas imediatamente
		global_position = home_position
		show()
		_change_state(State.SAINDO_DE_CASA)
	else:
		_change_state(State.EM_CASA)
		hide()


func _physics_process(delta):
	# Se o alvo do agente não foi definido, não faz nada.
	if nav_agent.is_target_reachable() == false:
		return

	# A máquina de estados que roda a cada frame
	match current_state:
		State.PASSEANDO:
			# Se o NPC chegou ao seu ponto de passeio...
			if nav_agent.is_navigation_finished():
				# ...espera um pouco e encontra um novo lugar para ir.
				get_tree().create_timer(randf_range(2.0, 5.0)).timeout.connect(func():
					_wander()
				)
				# Impede que a função _wander seja chamada várias vezes
				nav_agent.target_position = global_position 
		
		State.INDO_PARA_CASA:
			if nav_agent.is_navigation_finished():
				_change_state(State.EM_CASA)
				hide()

		State.EM_CASA:
			pass # Não faz nada
			
		State.SAINDO_DE_CASA:
			if nav_agent.is_navigation_finished():
				_change_state(State.PASSEANDO)

	# Lógica de movimento baseada no agente de navegação
	if not nav_agent.is_navigation_finished():
		var next_path_position = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_position)
		velocity = direction * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO


# Esta função é chamada AUTOMATICAMENTE quando o dia vira noite ou vice-versa
func _on_world_period_changed(period_name: String):
	if period_name == "NIGHT":
		# Se estiver passeando ou saindo de casa, manda ir para casa
		if current_state == State.PASSEANDO or current_state == State.SAINDO_DE_CASA:
			_change_state(State.INDO_PARA_CASA)
			
	elif period_name == "DAY":
		# Se estiver em casa, manda sair
		if current_state == State.EM_CASA:
			global_position = home_position
			show()
			_change_state(State.SAINDO_DE_CASA)


# --- NOVAS FUNÇÕES ---

# Função para encontrar um ponto aleatório para passear
func _wander():
	# Garante que ele só procure um novo ponto se ainda estiver no estado de passeio
	if current_state != State.PASSEANDO:
		return
	
	var random_offset = Vector2(randf_range(-wander_range, wander_range), randf_range(-wander_range, wander_range))
	var target_pos = outside_position + random_offset
	nav_agent.target_position = target_pos
	print(self.name, " está passeando para ", target_pos)


# Função centralizada para mudar de estado e imprimir no console
func _change_state(new_state: State):
	if current_state == new_state:
		return

	print(self.name, " mudou do estado ", State.keys()[current_state], " para ", State.keys()[new_state])
	current_state = new_state
	
	match current_state:
		State.SAINDO_DE_CASA:
			nav_agent.target_position = outside_position
		State.INDO_PARA_CASA:
			nav_agent.target_position = home_position
		State.PASSEANDO:
			_wander()
		State.EM_CASA:
			pass # Nenhuma ação de movimento necessária

## Coleta todos os dados importantes deste nó e os retorna em um dicionário.
## O SaveManager vai chamar esta função quando for salvar o jogo.
func get_save_data() -> Dictionary:
	return {
		"pos_x": position.x,
		"pos_y": position.y,
		# Adicione aqui outras variáveis que você queira salvar
		# "health": health,
		# "score": score,
	}
## Recebe um dicionário com dados e os aplica a este nó.
## O SaveManager vai chamar esta função quando for carregar um jogo.
func load_data(data: Dictionary):
	# Usamos .get() com um valor padrão para evitar erros se o dado não existir no save.
	var loaded_pos_x = data.get("pos_x", position.x)
	var loaded_pos_y = data.get("pos_y", position.y)
	position = Vector2(loaded_pos_x, loaded_pos_y)

	# Carregue as outras variáveis que você salvou
	# health = data.get("health", 100)
	# score = data.get("score", 0)
