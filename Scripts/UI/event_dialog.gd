# EventDialog.gd
extends CanvasLayer

# MODIFICADO: Referências para os nós existentes na cena
@onready var title_label: Label = $ColorRect/Panel/VBoxContainer/TitleLabel
@onready var description_label: Label = $ColorRect/Panel/VBoxContainer/DescriptionLabel
@onready var accept_button: Button = $ColorRect/Panel/VBoxContainer/ChoicesContainer/AcceptButton
@onready var reject_button: Button = $ColorRect/Panel/VBoxContainer/ChoicesContainer/RejectButton
@onready var background_panel = $ColorRect/Panel

var current_event_id: String

func _ready():
	# ADICIONADO: Conectamos os sinais dos botões fixos no _ready()
	accept_button.pressed.connect(_on_accept_button_pressed)
	reject_button.pressed.connect(_on_reject_button_pressed)

func start_event(event_id: String, data: Dictionary):
	current_event_id = event_id
	
	title_label.text = data.get("title", "Evento")
	description_label.text = data.get("description", "...")
	
	var choices = data.get("choices", {})
	
	if choices.has("accept"):
		accept_button.text = choices["accept"]
		accept_button.visible = true
	else:
		accept_button.visible = false

	if choices.has("reject"):
		reject_button.text = choices["reject"]
		reject_button.visible = true
	else:
		reject_button.visible = false

	# ADICIONADO: Espera um frame para que o motor da UI calcule o novo tamanho da caixa.
	await get_tree().process_frame
	# ADICIONADO: Chama a função para recentralizar.
	_recenter_dialog()

func _recenter_dialog():
	# CORRIGIDO: Usamos get_viewport().get_visible_rect().size para pegar o tamanho da tela
	# quando estamos em um CanvasLayer.
	var viewport_size = get_viewport().get_visible_rect().size
	background_panel.position = (viewport_size - background_panel.size) / 2.0

# ADICIONADO: Funções separadas para cada botão
func _on_accept_button_pressed():
	# Emite o sinal com a escolha "accept"
	EventManager.emit_signal("event_choice_made", current_event_id, "accept")
	queue_free()

func _on_reject_button_pressed():
	# Emite o sinal com a escolha "reject"
	EventManager.emit_signal("event_choice_made", current_event_id, "reject")
	queue_free()

# A função _on_choice_button_pressed(choice_id) pode ser removida.
