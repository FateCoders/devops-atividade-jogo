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
				button.set_text("Pacifista", "Tem mais facilidade em construir relações.")
			GameManager.LeaderType.DEFENSIVO:
				button.set_text("Defensivo", "Esconderijos são mais baratos.")
			GameManager.LeaderType.GUERREIRO:
				button.set_text("Guerreiro", "Ganha uma área de treinamento no início do jogo.")
			GameManager.LeaderType.LIVRE:
				button.set_text("Livre", "Não possui benefícios.")

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
