# NPCAssignmentRow.gd
extends HBoxContainer

# Guardamos uma referência ao NPC que esta "ficha" representa.
var npc_ref: NPC

# Variáveis dos nós, declaradas mas ainda não atribuídas.
@onready var label: Label = $VBoxContainer/Label
@onready var option_button: OptionButton = $VBoxContainer/OptionButton

func _ready():
	# Atribuição Manual: Pegamos os nós diretamente.
	# Verificação de Segurança Imediata:
	if option_button == null:
		printerr("ERRO FATAL: O script não conseguiu encontrar o nó filho 'OptionButton' na cena NPCAssignmentRow!")
		return # Interrompe a execução para evitar o crash.

	option_button.clear()

	var professions = NPC.Profession.keys()
	for profession_name in professions:
		if profession_name != "NENHUMA":
			option_button.add_item(profession_name)

	if option_button.item_count > 0:
		option_button.select(0)

# Função para a tela principal configurar esta ficha
func setup(npc: NPC, index: int):
	self.npc_ref = npc
	if is_instance_valid(label):
		label.text = "Recém-chegado %d" % (index + 1)

# Função para a tela principal pegar a escolha do jogador
func get_selected_profession() -> NPC.Profession:
	# Pega o índice do item selecionado no dropdown (0, 1, 2...).
	var selected_index = option_button.selected
	
	# Converte o índice do botão para o valor correto da enum.
	# Como pulamos "NENHUMA" (valor 0), o primeiro item do botão (índice 0)
	# corresponde à profissão de valor 1 (ENFERMEIRO), e assim por diante.
	return selected_index + 1
