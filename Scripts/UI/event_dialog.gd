# EventDialog.gd
extends CanvasLayer

# Referências para os nós na nova estrutura de cena
# !!! ATENÇÃO: Verifique se estes caminhos correspondem à sua nova estrutura !!!
@onready var title_label: Label = $ColorRect/CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var description_label: Label = $ColorRect/CenterContainer/Panel/VBoxContainer/ScrollContainer/DescriptionLabel
@onready var accept_button: Button = $ColorRect/CenterContainer/Panel/VBoxContainer/ChoicesContainer/AcceptButton
@onready var reject_button: Button = $ColorRect/CenterContainer/Panel/VBoxContainer/ChoicesContainer/RejectButton

var current_event_id: String

func _ready():
	# Conecta os sinais dos botões uma única vez
	accept_button.pressed.connect(_on_accept_button_pressed)
	reject_button.pressed.connect(_on_reject_button_pressed)

func start_event(event_id: String, data: Dictionary):
	current_event_id = event_id
	
	title_label.text = data.get("title", "Evento")
	description_label.text = data.get("description", "...")
	
	var choices = data.get("choices", {})
	
	# MODIFICADO: A lógica agora lê o dicionário interno de cada escolha.
	# Configura o botão de aceitar
	if choices.has("accept"):
		var choice_data = choices["accept"] # Pega o dicionário {"label": ..., "tooltip": ...}
		accept_button.text = choice_data.get("label", "Sim")
		accept_button.tooltip_text = choice_data.get("tooltip", "") # <-- A mágica acontece aqui!
		accept_button.visible = true
	else:
		accept_button.visible = false

	# Configura o botão de rejeitar
	if choices.has("reject"):
		var choice_data = choices["reject"]
		reject_button.text = choice_data.get("label", "Não")
		reject_button.tooltip_text = choice_data.get("tooltip", "") # <-- E aqui também!
		reject_button.visible = true
	else:
		reject_button.visible = false

func _on_accept_button_pressed():
	EventManager.emit_signal("event_choice_made", current_event_id, "accept")
	queue_free()

func _on_reject_button_pressed():
	EventManager.emit_signal("event_choice_made", current_event_id, "reject")
	queue_free()
