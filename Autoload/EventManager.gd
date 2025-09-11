# EventManager.gd
extends Node

# Sinal que será emitido quando o jogador fizer uma escolha em um evento.
signal event_choice_made(event_id, choice_id)

@export var daily_event_chance: float = 100.0

var populationIcon = "res://Assets/Sprites/Exported/HUD/Icons/population-icon.png"
var chickenIcon = "res://Assets/Sprites/Exported/HUD/Icons/population-icon.png"
var goldIcon = "res://Assets/Sprites/Exported/HUD/Icons/population-icon.png"
var healthIcon = "res://Assets/Sprites/Exported/HUD/Icons/population-icon.png"
var negativeIcon = "res://Assets/Sprites/Exported/HUD/Icons/population-icon.png"
var boneIcon = "res://Assets/Sprites/Exported/HUD/Icons/population-icon.png"
var positiveIcon = "res://Assets/Sprites/Exported/HUD/Icons/population-icon.png"
var unhealthIcon = "res://Assets/Sprites/Exported/HUD/Icons/population-icon.png"
var defaultIcon = "res://Assets/Sprites/Exported/HUD/Icons/sururu-icon.png"

# Dicionário para guardar todos os eventos possíveis do jogo.
var all_events = {
	"fugitives_arrive": {
		"title": "Fugitivos na Mata",
		"description": "Um grupo de fugitivos encontrou nosso quilombo, pedindo por abrigo.\n\n- Acolher: Adiciona 3 novos moradores ao quilombo. Eles precisarão de casas.\n- Negar Abrigo: Os fugitivos seguirão seu caminho.",
		"choices": {
			"accept": { "label": "Acolher", "tooltip": "+3 Moradores", "icon": populationIcon },
			"reject": { "label": "Negar Abrigo", "tooltip": "Nenhum efeito", "icon": defaultIcon }
		}
	},
	
	"capitao_do_mato_attack": {
		"title": "Ataque Iminente!",
		"description": "Um capitão-do-mato e seus homens foram avistados se aproximando do quilombo! Eles exigem nossos recursos em troca de paz.\n\n- Lutar: Nossa segurança será testada, mas podemos proteger nossos bens.\n- Entregar Recursos: Perderemos recursos, mas evitaremos o conflito direto.",
		"choices": {
			"fight": { "label": "Lutar!", "tooltip": "-10 Segurança", "icon": boneIcon },
			"surrender": { "label": "Entregar Recursos", "tooltip": "-50 Dinheiro", "icon": goldIcon }
		}
	},
	
	"epidemic_spreads": {
		"title": "Epidemia se Espalha",
		"description": "Uma doença desconhecida está se espalhando pelo quilombo, enfraquecendo nossos moradores.\n\n- Usar Remédios: Se tivermos uma enfermaria e remédios, podemos conter a doença.\n- Ignorar: A saúde do quilombo vai piorar drasticamente.",
		"choices": {
			"treat": { "label": "Usar Remédios", "tooltip": "-10 Remédios, +10 Saúde", "icon": healthIcon },
			"ignore": { "label": "Ignorar", "tooltip": "-20 Saúde", "icon": negativeIcon }
		}
	},
	
	"village_party": {
		"title": "Noite de Festa",
		"description": "Os moradores estão com o espírito elevado e sugerem uma festa para celebrar a comunidade e aliviar o estresse.\n\n- Realizar Festa: Gastaremos alimentos, mas a alegria fortalecerá a todos.\n- Manter o Foco: Economizaremos recursos, mas perderemos a chance de melhorar o ânimo.",
		"choices": {
			"celebrate": { "label": "Realizar Festa!", "tooltip": "-20 Alimentos, +10 Saúde", "icon": chickenIcon },
			"focus": { "label": "Manter o Foco", "tooltip": "Nenhum efeito", "icon": defaultIcon }
		}
	}
}
# Pré-carrega a cena da nossa caixa de diálogo (que faremos no próximo passo).
const EventDialogScene = preload("res://Scenes/UI/EventDialog.tscn")

func _ready():
	WorldTimeManager.day_passed.connect(_on_new_day_started)
	
	# Conecta este manager ao seu próprio sinal para processar as escolhas.
	event_choice_made.connect(_on_event_choice_made)

func _on_new_day_started(day_number):
	print("[EventManager] Novo dia! Verificando se um evento ocorre...")
	
	# Garante que um evento não aconteça se uma caixa de diálogo já estiver aberta.
	if get_tree().root.find_child("EventDialog", true, false) != null:
		print("[EventManager] Evento adiado, pois uma janela já está aberta.")
		return

	# Sorteia um número entre 0 e 100.
	var random_chance = randf() * 30.0
	
	# Se o número sorteado for menor que a nossa chance, um evento acontece.
	if random_chance < daily_event_chance:
		# Pega a lista de todos os eventos possíveis e sorteia um.
		var event_id = all_events.keys().pick_random()
		trigger_event(event_id)
	else:
		print("[EventManager] Nenhum evento hoje.")

# Função principal que inicia um evento.
func trigger_event(event_id: String):
	if not all_events.has(event_id):
		printerr("Tentativa de iniciar um evento desconhecido: ", event_id)
		return

	print("Disparando evento: ", event_id)
	var event_data = all_events[event_id]
	
	# Cria a caixa de diálogo e passa os dados do evento para ela.
	var dialog = EventDialogScene.instantiate()
	get_tree().root.add_child(dialog)
	dialog.start_event(event_id, event_data)

# Função que processa a escolha do jogador.
func _on_event_choice_made(event_id, choice_id):
	print("Jogador escolheu '%s' para o evento '%s'" % [choice_id, event_id])
	
	# Evento de Fugitivos (já existente)
	if event_id == "fugitives_arrive":
		if choice_id == "accept":
			QuilomboManager.spawn_new_fugitives(3)
	
	# ADICIONADO: Consequências do Evento de Ataque
	elif event_id == "capitao_do_mato_attack":
		if choice_id == "fight":
			StatusManager.mudar_status("seguranca", -10)
			# (No futuro, aqui poderia chamar uma cena de batalha)
		elif choice_id == "surrender":
			StatusManager.mudar_status("dinheiro", -50)
			
	if StatusManager.seguranca <= 0 or StatusManager.saude <= 0:
			GameManager.game_over.emit("O quilombo foi destruído em um ataque.")

	# ADICIONADO: Consequências do Evento de Epidemia
	elif event_id == "epidemic_spreads":
		if choice_id == "treat":
			# Verifica se o jogador tem os recursos para tratar
			if StatusManager.dinheiro >= 10:
				#StatusManager.mudar_status("remedios", -10)
				StatusManager.mudar_status("dinheiro", -10)
				StatusManager.mudar_status("saude", 10)
			else:
				# Penalidade por não ter remédios
				get_tree().root.get_node("GameUI").show_notification("Faltam remédios! A saúde piorou.")
				StatusManager.mudar_status("saude", -10)
		elif choice_id == "ignore":
			StatusManager.mudar_status("saude", -20)

	# ADICIONADO: Consequências do Evento de Festa
	elif event_id == "village_party":
		if choice_id == "celebrate":
			if StatusManager.dinheiro >= 20:
				# StatusManager.mudar_status("alimentos", -20)
				StatusManager.mudar_status("dinheiro", -20)
				StatusManager.mudar_status("saude", 10)
			else:
				get_tree().root.get_node("GameUI").show_notification("Faltam alimentos para a festa!")
		elif choice_id == "focus":
			# Nenhuma consequência
			pass
