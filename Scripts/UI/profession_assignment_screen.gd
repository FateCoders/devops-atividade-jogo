# ProfessionAssignmentScreen.gd
extends PanelContainer

@export var npc_row_scene: PackedScene

# --- NOVAS VARIÁVEIS PARA GERENCIAR A PAGINAÇÃO ---
var all_npcs: Array[NPC] = []
var current_index: int = 0
# Dicionário para guardar as escolhas: {npc_ref: profession_id}
var npc_choices: Dictionary = {}
# ---------------------------------------------------

@onready var npc_list_container: VBoxContainer = $VBoxContainer/NPCListContainer
@onready var confirm_button: Button = $VBoxContainer/Button
# --- NOVAS REFERÊNCIAS AOS NÓS DA UI ---
@onready var anterior_button: Button = $VBoxContainer/HBoxContainer/AnteriorButton
@onready var proximo_button: Button = $VBoxContainer/HBoxContainer/ProximoButton
@onready var counter_label: Label = $VBoxContainer/HBoxContainer/CounterLabel
# ----------------------------------------

func _ready():
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	# --- CONECTAR SINAIS DOS NOVOS BOTÕES ---
	anterior_button.pressed.connect(_on_anterior_button_pressed)
	proximo_button.pressed.connect(_on_proximo_button_pressed)
	# -----------------------------------------

func show_panel(npcs: Array):
	# Guarda a lista de NPCs e reseta o estado
	self.all_npcs = npcs
	self.current_index = 0
	self.npc_choices.clear()
	
	# Inicializa as escolhas com a primeira profissão da lista para cada NPC
	for npc in all_npcs:
		npc_choices[npc] = 1 # 1 = ENFERMEIRO (primeira profissão após NENHUMA)

	# Atualiza a tela para mostrar o primeiro NPC
	_update_view()

	self.show()
	GameManager.pause_game()

# Função central que atualiza qual NPC é mostrado
func _update_view():
	# 1. Limpa a ficha do NPC anterior
	for child in npc_list_container.get_children():
		child.queue_free()

	if all_npcs.is_empty():
		# Lida com o caso de uma lista vazia, se necessário
		counter_label.text = "0/0"
		return

	# 2. Pega o NPC atual
	var current_npc = all_npcs[current_index]

	# 3. Cria e configura a nova ficha
	var row = npc_row_scene.instantiate()
	npc_list_container.add_child(row)
	row.setup(current_npc, current_index)
	# Restaura a escolha do jogador para este NPC, se já houver uma
	row.set_selected_profession(npc_choices[current_npc])

	# 4. Atualiza o contador
	counter_label.text = "%d/%d" % [current_index + 1, all_npcs.size()]

	# 5. Habilita/desabilita os botões de navegação
	anterior_button.disabled = (current_index == 0)
	proximo_button.disabled = (current_index == all_npcs.size() - 1)

func _on_anterior_button_pressed():
	# Guarda a escolha da ficha atual antes de mudar
	_save_current_choice()
	
	if current_index > 0:
		current_index -= 1
		_update_view()

func _on_proximo_button_pressed():
	# Guarda a escolha da ficha atual antes de mudar
	_save_current_choice()

	if current_index < all_npcs.size() - 1:
		current_index += 1
		_update_view()

# Nova função para salvar a escolha do dropdown
func _save_current_choice():
	if all_npcs.is_empty(): return

	var current_npc = all_npcs[current_index]
	var current_row = npc_list_container.get_child(0) as NPCAssignmentRow
	if is_instance_valid(current_row):
		npc_choices[current_npc] = current_row.get_selected_profession()

func _on_confirm_button_pressed():
	# Garante que a escolha do último NPC visualizado seja salva
	_save_current_choice()
	
	# Agora, itera sobre o nosso dicionário de escolhas guardado
	for npc_ref in npc_choices:
		var chosen_profession = npc_choices[npc_ref]
		
		if is_instance_valid(npc_ref):
			npc_ref.set_profession(chosen_profession)

	self.hide()
	GameManager.resume_game()
