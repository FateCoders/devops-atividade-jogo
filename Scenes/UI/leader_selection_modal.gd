extends PanelContainer

@onready var leader_choices_container = $VBoxContainer/HBoxContainer
@onready var continue_button: Button = $VBoxContainer/PanelContainer/ContinueButton

var leader_buttons: Array[Node]
var selected_type: GameManager.LeaderType = GameManager.LeaderType.LIVRE 

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	hide()

	leader_buttons = leader_choices_container.get_children()
	for button in leader_buttons:
		button.chosen.connect(_on_leader_type_chosen)

		match button.leader_type:
			GameManager.LeaderType.PACIFISTA:
				button.set_text("Pacifista", "Tem facilidade em criar relações e\n menos chances de ataques no quilombo.")
			GameManager.LeaderType.GUERREIRO:
				button.set_text("Guerreiro", "Esconderijos e Áreas de\n Treinamento são mais baratas.")
			GameManager.LeaderType.AGRICULTOR:
				button.set_text("Agricultor", "Ganha mais dinheiro em turnos\n de trabalho com plantações.")
			GameManager.LeaderType.LIVRE:
				button.set_text("Livre", "Não possui benefícios.\n Jogue livremente.")

	_on_leader_type_chosen(selected_type)


func _on_leader_type_chosen(type: GameManager.LeaderType):
	selected_type = type
	for button in leader_buttons:
		if button.leader_type == selected_type:
			button.select()
		else:
			button.deselect()


func _on_continue_pressed():
	print("Líder escolhido: ", GameManager.LeaderType.keys()[selected_type])
	GameManager.chosen_leader_type = selected_type
	get_tree().change_scene_to_file("res://Scenes/World/world.tscn")
