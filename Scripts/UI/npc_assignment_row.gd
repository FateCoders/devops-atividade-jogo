# NPCAssignmentRow.gd
class_name NPCAssignmentRow

extends HBoxContainer

# Guardamos uma referência ao NPC que esta "ficha" representa.
var npc_ref: NPC

# Variáveis dos nós, declaradas mas ainda não atribuídas.
@onready var texture_rect: TextureRect = $TextureRect
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
		label.text = "Nome: " + npc.npc_name
		
	if is_instance_valid(texture_rect) and is_instance_valid(npc_ref):
		texture_rect.texture = npc_ref.get_idle_sprite_texture()
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func get_selected_profession() -> NPC.Profession:
	var selected_index = option_button.selected
	return selected_index + 1

func set_selected_profession(profession_id: NPC.Profession):
	var button_index = profession_id - 1
	if button_index >= 0 and button_index < option_button.item_count:
		option_button.select(button_index)
