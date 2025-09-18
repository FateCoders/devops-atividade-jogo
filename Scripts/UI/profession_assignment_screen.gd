# ProfessionAssignmentScreen.gd
extends PanelContainer

# Arraste a cena NPCAssignmentRow.tscn para este campo no Inspetor.
@export var npc_row_scene: PackedScene

@onready var npc_list_container: VBoxContainer = $VBoxContainer/ScrollContainer/NPCListContainer # Usando % para mais segurança
@onready var confirm_button: Button = $VBoxContainer/Button # Assumindo que o botão se chama "Button"

func _ready():
	# Conecta o sinal 'pressed' do botão à nossa função de confirmação.
	confirm_button.pressed.connect(_on_confirm_button_pressed)

# Função chamada pelo Hud para iniciar o processo
func show_panel(npcs: Array):
	# 1. Limpa a lista de qualquer atribuição anterior
	for child in npc_list_container.get_children():
		child.queue_free()

	# 2. Popula a lista com os novos NPCs
	if not npc_row_scene:
		printerr("ERRO: A cena da ficha do NPC (Npc Row Scene) não foi definida no inspetor do ProfessionAssignmentScreen!")
		return
		
	for i in range(npcs.size()):
		var npc = npcs[i]
		var row = npc_row_scene.instantiate()
		npc_list_container.add_child(row)
		row.setup(npc, i)

	# 3. Mostra o painel e pausa o jogo
	self.show()
	GameManager.pause_game()

# Função executada quando o jogador clica em "Confirmar"
func _on_confirm_button_pressed():
	# 1. Itera sobre cada "ficha" na lista da UI
	for row in npc_list_container.get_children():
		# Pega a referência do NPC real e a profissão escolhida
		var npc_ref = row.npc_ref
		var chosen_profession = row.get_selected_profession()
		
		# 2. Chama a função no script do NPC para definir sua profissão
		if is_instance_valid(npc_ref):
			npc_ref.set_profession(chosen_profession)

	# 3. Esconde o painel e despausa o jogo
	self.hide()
	GameManager.resume_game()
