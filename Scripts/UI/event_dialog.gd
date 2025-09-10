# EventDialog.gd
extends CanvasLayer

# --- Referências de Nós ---
# MODIFICADO: Caminhos corrigidos e agora pegamos o container dos botões
@onready var title_label: Label = $ColorRect/CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var description_label: Label = $ColorRect/CenterContainer/Panel/VBoxContainer/ScrollContainer/DescriptionLabel
@onready var button_container: HBoxContainer = $ColorRect/CenterContainer/Panel/VBoxContainer/ChoicesContainer
@onready var custom_tooltip = $CustomTooltip
@onready var tooltip_timer: Timer = $TooltipTimer

# --- Variáveis de Estado ---
var current_event_id: String
var _tooltip_data_to_show: Dictionary
# Esta lista guardará os botões que você colocou na cena (ex: ChoiceButton1, ChoiceButton2)
var choice_buttons: Array[Button] = []

func _ready():
	# Pega todos os botões que são filhos do ButtonContainer e os guarda na lista
	for child in button_container.get_children():
		if child is Button:
			choice_buttons.append(child)
			
	# Conecta o sinal do timer uma única vez
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)

func start_event(event_id: String, data: Dictionary):
	current_event_id = event_id
	
	title_label.text = data.get("title", "Evento")
	description_label.text = data.get("description", "...")
	
	# Esconde todos os botões para começar com um estado limpo
	for button in choice_buttons:
		button.visible = false
		# Desconecta quaisquer sinais antigos para evitar bugs
		if button.is_connected("pressed", _on_choice_button_pressed):
			button.pressed.disconnect(_on_choice_button_pressed)
		if button.is_connected("mouse_entered", _on_button_mouse_entered):
			button.mouse_entered.disconnect(_on_button_mouse_entered)
		if button.is_connected("mouse_exited", _on_button_mouse_exited):
			button.mouse_exited.disconnect(_on_button_mouse_exited)

	var choices = data.get("choices", {})
	var button_index = 0
	
	# Lógica universal que funciona para QUALQUER evento
	for choice_id in choices.keys():
		# Garante que temos um botão na cena para esta escolha
		if button_index < choice_buttons.size():
			var button = choice_buttons[button_index]
			var choice_data = choices[choice_id]
			
			# Configura o botão
			button.text = choice_data.get("label", "...")
			
			# Conecta os sinais com os dados corretos para esta escolha
			button.pressed.connect(_on_choice_button_pressed.bind(choice_id))
			button.mouse_entered.connect(_on_button_mouse_entered.bind(choice_data))
			button.mouse_exited.connect(_on_button_mouse_exited)
			
			button.visible = true
			button_index += 1

# UMA ÚNICA função para lidar com o clique de qualquer botão
func _on_choice_button_pressed(choice_id: String):
	EventManager.emit_signal("event_choice_made", current_event_id, choice_id)
	queue_free() # Destrói o diálogo e suas conexões

# --- Funções de Controle do Tooltip ---
func _on_button_mouse_entered(data: Dictionary):
	_tooltip_data_to_show = data
	tooltip_timer.start()

func _on_button_mouse_exited():
	tooltip_timer.stop()
	custom_tooltip.hide_tooltip()

func _on_tooltip_timer_timeout():
	custom_tooltip.show_tooltip(_tooltip_data_to_show)
