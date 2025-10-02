# EventManager.gd
extends Node

signal event_choice_made(event_id, choice_id)
signal leader_died

@export var daily_event_chance: float = 30.0

var populationIcon = "res://Assets/Sprites/Exported/HUD/Icons/population-icon.png"
var chickenIcon = "res://Assets/Sprites/Exported/HUD/Icons/chicken-icon.png"
var goldIcon = "res://Assets/Sprites/Exported/HUD/Icons/gold-coin-icon.png"
var healthIcon = "res://Assets/Sprites/Exported/HUD/Icons/health-icon.png"
var negativeIcon = "res://Assets/Sprites/Exported/HUD/Icons/negative-relation-icon.png"
var boneIcon = "res://Assets/Sprites/Exported/HUD/Icons/bone-icon.png"
var positiveIcon = "res://Assets/Sprites/Exported/HUD/Icons/positive-relation-icon.png"
var unhealthIcon = "res://Assets/Sprites/Exported/HUD/Icons/unhealth-icon.png"
var defaultIcon = "res://Assets/Sprites/Exported/HUD/Icons/sururu-icon.png"
var securityIcon = "res://Assets/Sprites/Exported/HUD/Icons/security-icon.png"
var toolsIcon = "res://Assets/Sprites/Exported/HUD/Icons/tools-icon.png"


# --- DICIONÁRIOS DE EVENTOS ---

var attack_events = {
	"reinforce_watch": {
		"title": "Ataque Iminente?",
		"description": "Boatos dizem que capitães do mato rondam nossas terras. Devemos soar o alerta e reforçar as vigílias, mesmo que isso deixe a comunidade nervosa?",
		"choices": {
			"reinforce": { "label": "Reforçar Vigilância", "tooltip": "+15 Segurança, -10 Saúde, -10 Fome", "icon": securityIcon },
			"normal_routine": { "label": "Manter a Rotina", "tooltip": "-15 Segurança, +5 Saúde", "icon": unhealthIcon }
		}
	},
	"traitor_discovered": {
		"title": "Um Traidor Entre Nós",
		"description": "Um de nossos moradores foi pego entregando informações para os colonizadores. Se o punirmos com severidade, daremos um exemplo. Se perdoarmos, podemos manter a união, ainda que arriscando nova traição.",
		"choices": {
			"punish": { "label": "Punir o Traidor", "tooltip": "+15 Segurança, -10 Relações", "icon": securityIcon },
			"forgive": { "label": "Perdoar", "tooltip": "-15 Segurança, +10 Relações", "icon": positiveIcon }
		}
	},
	# NOVO EVENTO ADICIONADO
	"leader_assassination_attempt": {
		"title": "Emboscada para o Líder!",
		"description": "Batedores relatam uma movimentação hostil focada na captura da nossa liderança. É um ataque direto e pessoal!\n\n- Proteger o Líder: Usaremos nossa força total para defendê-lo. O resultado dependerá da nossa segurança.\n- Pagar Resgate: Uma opção covarde, mas que pode evitar o pior... a um custo altíssimo.",
		"choices": {
			"protect": { "label": "Proteger com a vida!", "tooltip": "Teste Crítico de Segurança!", "icon": unhealthIcon },
			"pay_ransom": { "label": "Pagar para que recuem", "tooltip": "Muito caro: -150 Dinheiro", "icon": goldIcon }
		}
	}
}

var peaceful_events = {
	"expand_agriculture": {
		"title": "Sobre a Agricultura",
		"description": "A mandioca e o milho têm sustentado nossa gente. Se ampliarmos a plantação, teremos comida de sobra para todos e para negociar. Mas isso exigirá mais esforço da comunidade.",
		"choices": {
			"expand": { "label": "Expandir Plantações", "tooltip": "+20 Alimentos, +20 Dinheiro, -10 Saúde", "icon": chickenIcon },
			"maintain": { "label": "Manter Produção", "tooltip": "+5 Saúde, -5 Relações", "icon": healthIcon }
		}
	},
	"trade_decision": {
		"title": "Decisão de Comércio",
		"description": "Temos fardos de tabaco prontos. Poderíamos guardá-los, mas se trocarmos com nossos vizinhos, conseguiremos ferramentas que podem melhorar nossa vida.",
		"choices": {
			"trade": { "label": "Trocar por Ferramentas", "tooltip": "+10 Ferramentas, +10 Relações", "icon": toolsIcon },
			"keep": { "label": "Manter o Tabaco", "tooltip": "-10 Relações, -5 Saúde", "icon": negativeIcon }
		}
	},
	"hide_crops": {
		"title": "Estratégia de Plantação",
		"description": "Podemos esconder parte das plantações em áreas mais afastadas. Isso vai dar mais trabalho, mas não perderemos tudo se houver um ataque.",
		"choices": {
			"hide": { "label": "Esconder Plantações", "tooltip": "+10 Segurança, -15 Alimentos", "icon": securityIcon },
			"keep_visible": { "label": "Manter Visíveis", "tooltip": "-10 Segurança, +15 Alimentos", "icon": chickenIcon }
		}
	},
	"new_fugitives_shelter": {
		"title": "Novos Foragidos Buscam Abrigo",
		"description": "Um grupo de foragidos chegou pedindo proteção. Eles dizem que podem ajudar no trabalho, mas teremos mais bocas para alimentar e maior risco de sermos descobertos.",
		"choices": {
			"accept": { "label": "Aceitar Foragidos", "tooltip": "+3 Moradores, +10 Relações, -10 Segurança", "icon": populationIcon },
			"refuse": { "label": "Recusar Foragidos", "tooltip": "-10 Relações", "icon": negativeIcon }
		}
	}
}

var all_events = {}
const EventDialogScene = preload("res://Scenes/UI/EventDialog.tscn")

func _ready():
	all_events.merge(attack_events)
	all_events.merge(peaceful_events)
	WorldTimeManager.day_passed.connect(_on_new_day_started)
	event_choice_made.connect(_on_event_choice_made)

func _on_new_day_started(day_number):
	if get_tree().root.find_child("EventDialog", true, false) != null:
		return

	var random_chance = randf() * 100.0
	
	if random_chance < daily_event_chance:
		var event_id: String

		if GameManager.chosen_leader_type == GameManager.LeaderType.PACIFISTA:
			if randf() < 0.1:
				event_id = attack_events.keys().pick_random()
			else:
				event_id = peaceful_events.keys().pick_random()
		else:
			event_id = all_events.keys().pick_random()

		if not event_id.is_empty():
			trigger_event(event_id)

func trigger_event(event_id: String):
	if not all_events.has(event_id):
		printerr("Tentativa de iniciar um evento desconhecido: ", event_id)
		return
		
	GameManager.pause_game()
	MusicManager.play_decision_music()
	
	var event_data = all_events[event_id]
	var dialog = EventDialogScene.instantiate()
	get_tree().root.add_child(dialog)
	dialog.start_event(event_id, event_data)

func _on_event_choice_made(event_id, choice_id):
	GameManager.resume_game()
	MusicManager.play_game_music()
	
	print("Jogador escolheu '%s' para o evento '%s'" % [choice_id, event_id])
	
	match event_id:
		"expand_agriculture":
			if choice_id == "expand":
				StatusManager.mudar_recurso("alimentos", 20)
				StatusManager.mudar_recurso("dinheiro", 20)
				StatusManager.mudar_status("saude", -10)
			elif choice_id == "maintain":
				StatusManager.mudar_status("saude", 5)
				StatusManager.mudar_status("relacoes", -5)

		"trade_decision":
			if choice_id == "trade":
				StatusManager.mudar_recurso("ferramentas", 10)
				StatusManager.mudar_status("relacoes", 10)
			elif choice_id == "keep":
				StatusManager.mudar_status("relacoes", -10)
				StatusManager.mudar_status("saude", -5)

		"reinforce_watch":
			if choice_id == "reinforce":
				StatusManager.mudar_status("seguranca", 15)
				StatusManager.mudar_status("saude", -10)
				StatusManager.mudar_status("fome", -10)
			elif choice_id == "normal_routine":
				StatusManager.mudar_status("saude", 5)
				StatusManager.mudar_status("fome", 5)
				StatusManager.mudar_status("seguranca", -15)

		"hide_crops":
			if choice_id == "hide":
				StatusManager.mudar_status("seguranca", 10)
				StatusManager.mudar_recurso("alimentos", -15)
			elif choice_id == "keep_visible":
				StatusManager.mudar_status("seguranca", -10)
				StatusManager.mudar_recurso("alimentos", 15)

		"traitor_discovered":
			if choice_id == "punish":
				StatusManager.mudar_status("seguranca", 15)
				StatusManager.mudar_status("relacoes", -10)
				StatusManager.mudar_status("saude", -5)
				StatusManager.mudar_recurso("libertos", 1)
				QuilomboManager.remove_random_npc()
			elif choice_id == "forgive":
				StatusManager.mudar_status("seguranca", -15)
				StatusManager.mudar_status("relacoes", 10)

		"new_fugitives_shelter":
			if choice_id == "accept":
				QuilomboManager.spawn_new_fugitives(3)
				StatusManager.mudar_status("relacoes", 10)
				StatusManager.mudar_status("seguranca", -10)
			elif choice_id == "refuse":
				StatusManager.mudar_status("relacoes", -10)
		
		# CONSEQUÊNCIAS DO NOVO EVENTO
		"leader_assassination_attempt":
			if choice_id == "protect":
				# Se a segurança for menor que 50, o líder morre.
				if StatusManager.seguranca < 50:
					var hud = get_tree().root.get_node("GameUI")
					if is_instance_valid(hud):
						hud.show_notification("Nossa defesa não foi forte o suficiente! O líder caiu.")
					
					var leader_node = get_tree().get_first_node_in_group("leader")
					if is_instance_valid(leader_node):
						leader_node.die() # Chama a função que encerra o jogo
				else:
					# Se a segurança for alta, o líder sobrevive mas há perdas.
					var hud = get_tree().root.get_node("GameUI")
					if is_instance_valid(hud):
						hud.show_notification("O líder foi protegido, mas o quilombo sofreu no ataque!")
					StatusManager.mudar_recurso("dinheiro", -50)
					StatusManager.mudar_recurso("alimentos", -30)
					StatusManager.mudar_status("seguranca", -10) # A segurança diminui após um grande ataque
			
			elif choice_id == "pay_ransom":
				StatusManager.mudar_recurso("dinheiro", -150)
