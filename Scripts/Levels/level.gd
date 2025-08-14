extends Node2D
class_name Level

const _DIALOG_SCREEN: PackedScene = preload("res://Scenes/UI/dialog_screen.tscn")
var _dialog_data: Dictionary = {
	0:{
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"dialog": "Ufa... a Luz nos deu forças mais uma vez. Os camponeses agora podem dormir em paz.",
		"title": "Paladino"
	},
	
	1: {
		"faceset": "res://Scenes/UI/Assets/Sprites/warrior_faceset.png",
		"dialog": "Paz... por enquanto. Mais dessas pragas sairão das tocas em uma semana. É sempre assim.",
		"title": "Guerreiro"
	},

	2:{
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"dialog": "Sua fé é tão afiada quanto sua lâmina, vejo. Tenha esperança! Cada ato de justiça fortalece o bem.",
		"title": "Paladino"
	},
	
	3: {
		"faceset": "res://Scenes/UI/Assets/Sprites/warrior_faceset.png",
		"dialog": "Esperança não enche a barriga nem conserta uma armadura. O que fortalece o bem é um machado bem manejado.",
		"title": "Guerreiro"
	},

	4:{
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"dialog": "Talvez. Mas é a esperança que nos move a empunhar esse machado pela causa certa. Um não vive sem o outro.",
		"title": "Paladino"
	},
	
	5: {
		"faceset": "res://Scenes/UI/Assets/Sprites/warrior_faceset.png",
		"dialog": "Hmpf. Fale por você. Eu luto pelo tilintar do ouro. Mas admito... ver aqueles desgraçados correndo faz o trabalho valer a pena.",
		"title": "Guerreiro"
	},

	6:{
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"dialog": "Ainda há nobreza em seu coração, amigo. Vamos, a recompensa nos aguarda, e você poderá comprar todo o hidromel que desejar.",
		"title": "Paladino"
	},
	
	7: {
		"faceset": "res://Scenes/UI/Assets/Sprites/warrior_faceset.png",
		"dialog": "Agora você falou a minha língua! Vamos logo, antes que a taverna feche.",
		"title": "Guerreiro"
	}
}

@export_category("Objects")
@export var _hud: CanvasLayer = null

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_select"):
		var _new_dialog: DialogScreen = _DIALOG_SCREEN.instantiate()
		_new_dialog.data = _dialog_data
		_hud.add_child(_new_dialog)
