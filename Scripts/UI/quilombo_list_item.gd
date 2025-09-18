# QuilomboListItem.gd
extends PanelContainer

# Sinal para avisar à lista principal que o botão de troca foi clicado
signal trade_requested(quilombo_id)

var quilombo_id: String
@onready var name_label = $MarginContainer/HBoxContainer/NameLabel
@onready var relations_label = $MarginContainer/HBoxContainer/RelationsLabel
@onready var escambo_button = $MarginContainer/HBoxContainer/EscamboButton

func _ready():
	# Conecta o clique do botão a uma função que emite nosso sinal
	escambo_button.pressed.connect(func(): emit_signal("trade_requested", quilombo_id))

# Função para receber os dados do quilombo e preencher os labels
func set_data(id, data):
	quilombo_id = id
	name_label.text = data.get("name", "??")
	relations_label.text = "Relações: %d" % data.get("relations", 0)
