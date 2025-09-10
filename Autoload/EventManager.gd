# EventManager.gd
extends Node

# Sinal que será emitido quando o jogador fizer uma escolha em um evento.
signal event_choice_made(event_id, choice_id)

var icon_test = "res://Assets/Sprites/Exported/HUD/Icons/positive-relation-icon.png"

# Dicionário para guardar todos os eventos possíveis do jogo.
# Estrutura: ID do Evento -> Dados do Evento
var all_events = {
	"fugitives_arrive": {
		"title": "Fugitivos na Mata",
		
		# MODIFICADO: A descrição agora contém todos os detalhes das consequências.
		"description": "Um pequeno grupo de escravizados fugitivos encontrou nosso quilombo, pedindo por abrigo.
		
- Acolher: Adiciona 3 novos moradores ao quilombo. Eles precisarão de casas para se abrigar.
- Negar Abrigo: Os fugitivos seguirão seu caminho.",
		
		# MODIFICADO: Os botões e tooltips agora são simples e diretos.
		"choices": {
			"accept": {
				"label": "Acolher",
				"tooltip": "🙂 +3 Moradores" # Tooltip simples e icônico
			},
			"reject": {
				"label": "Negar Abrigo",
				"tooltip": "Nenhum efeito imediato."
			}
		}
	}
	# ... adicione outros eventos seguindo este mesmo modelo.
}

# Pré-carrega a cena da nossa caixa de diálogo (que faremos no próximo passo).
const EventDialogScene = preload("res://Scenes/UI/EventDialog.tscn") # !!! AJUSTE O CAMINHO !!!

func _ready():
	# Conecta este manager ao sinal de "novo dia" do WorldTimeManager.
	WorldTimeManager.day_passed.connect(_on_new_day_started)
	
	# Conecta este manager ao seu próprio sinal para processar as escolhas.
	event_choice_made.connect(_on_event_choice_made)

# Função chamada todo novo dia.
func _on_new_day_started(day_number):
	print("[EventManager] Novo dia! Verificando se um evento ocorre...")
	
	# Lógica para decidir se um evento acontece.
	# Por enquanto, vamos fazer o evento dos fugitivos acontecer sempre no dia 3 para testar.
	if day_number == 2:
		trigger_event("fugitives_arrive")

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
	
	if event_id == "fugitives_arrive":
		if choice_id == "accept":
			# A consequência: Pede ao QuilomboManager para gerar 3 NPCs sem casa/trabalho.
			# Precisaremos criar esta função no QuilomboManager.
			QuilomboManager.spawn_new_fugitives(3)
		elif choice_id == "reject":
			# Nenhuma consequência por enquanto.
			pass
