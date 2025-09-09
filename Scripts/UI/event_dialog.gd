# EventDialog.gd
extends CanvasLayer

@onready var title_label: Label = $ColorRect/Panel/VBoxContainer/TitleLabel
@onready var description_label: Label = $ColorRect/Panel/VBoxContainer/DescriptionLabel
@onready var choices_container: VBoxContainer = $ColorRect/Panel/VBoxContainer/ChoicesContainer

var current_event_id: String

func start_event(event_id: String, data: Dictionary):
	current_event_id = event_id
	
	# Preenche a UI com os dados do evento.
	title_label.text = data.get("title", "Evento")
	description_label.text = data.get("description", "...")
	
	# Limpa quaisquer botões antigos.
	for child in choices_container.get_children():
		child.queue_free()
	
	# Cria um botão para cada escolha disponível.
	for choice_id in data.get("choices", {}).keys():
		var choice_text = data["choices"][choice_id]
		var button = Button.new()
		button.text = choice_text
		choices_container.add_child(button)
		
		# Conecta o sinal 'pressed' do botão à nossa função de escolha.
		# Usamos .bind() para saber qual escolha foi clicada.
		button.pressed.connect(_on_choice_button_pressed.bind(choice_id))

func _on_choice_button_pressed(choice_id: String):
	# "Anuncia" para o EventManager qual escolha foi feita.
	EventManager.emit_signal("event_choice_made", current_event_id, choice_id)
	
	# Destrói a caixa de diálogo após a escolha.
	queue_free()
