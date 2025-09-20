# StatusBubble.gd
extends Control

@onready var label: Label = $NinePatchRect/HBoxContainer/StatusLabel
@onready var icon: TextureRect = $NinePatchRect/HBoxContainer/StatusIcon

# Dicionário que mapeia o estado para um texto e um ícone
const STATUS_DATA = {
	# Estados que já existiam
	NPC.State.PASSEANDO: {"text": "Passeando...", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.INDO_PARA_CASA: {"text": "Indo para casa.", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.TRABALHANDO: {"text": "Trabalhando...", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.OCIOSO: {"text": "Descansando.", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	
	# --- NOVOS ESTADOS ADICIONADOS ---
	NPC.State.SAINDO_DE_CASA: {"text": "Saindo de casa...", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.INDO_PARA_O_TRABALHO: {"text": "A caminho do trabalho.", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.REAGINDO_AO_JOGADOR: {"text": "Interagindo!", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	
}

func update_status(npc_ref: NPC):
	# Pega o estado do NPC que foi passado como referência
	var npc_state = npc_ref.current_state

	if STATUS_DATA.has(npc_state):
		var data = STATUS_DATA[npc_state]
		var status_text = data.get("text", "")
		
		# Formata o texto para incluir o nome do NPC
		label.text = "%s - %s" % [npc_ref.npc_name, status_text]
		
		icon.texture = load(data.get("icon", ""))
		show()
	else:
		hide()
