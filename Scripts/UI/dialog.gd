# DialogScreen.gd
extends Control
class_name DialogScreen

# --- Referências de Nós ---
# MODIFICADO: Corrigido os caminhos para corresponder à sua estrutura de cena (baseado na imagem)
@onready var name_label: Label = $bg/HContainer/VContainer/Name
@onready var dialog_label: RichTextLabel = $bg/HContainer/VContainer/Dialog
@onready var faceset_rect: TextureRect = $bg/HContainer/Border/Faceset
@onready var next_button: Button = $ButtonContainer/NextButton
@onready var skip_button: Button = $ButtonContainer/SkipButton

# --- Variáveis de Controle ---
var _step: float = 0.05
var _id: int = 0
var _current_tween: Tween
var data: Dictionary

func _ready() -> void:
	# Conecta os botões às suas respectivas funções de ação.
	next_button.pressed.connect(advance_dialog)
	skip_button.pressed.connect(skip_dialog)
	
func setup_dialog(dialog_data: Dictionary):
	self.data = dialog_data
	if not self.data.is_empty():
		_initialize_dialog()
	else:
		printerr("DialogScreen recebeu dados vazios! Fechando...")
		queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		advance_dialog()
		get_viewport().set_input_as_handled()
		
	if Input.is_action_just_pressed("ui_cancel"):
		skip_dialog()
		get_viewport().set_input_as_handled()

func _process(delta: float):
	pass

# --- Funções de Ação ---

func advance_dialog():
	# Se o texto ainda está aparecendo (sendo animado)...
	if dialog_label.visible_ratio < 1:
		# ...termina a animação instantaneamente.
		if _current_tween and _current_tween.is_running():
			_current_tween.kill()
		dialog_label.visible_ratio = 1
		# CORRIGIDO: Mostra o indicador "próximo" imediatamente ao acelerar.
		return
		
	# Se o texto já terminou, avança para o próximo.
	_id += 1
	if _id >= data.size():
		skip_dialog() # Se acabaram os diálogos, fecha a tela.
		return
	_initialize_dialog()

func skip_dialog():
	queue_free()

# --- Funções Internas ---

func _initialize_dialog():
	if not data.has(_id):
		print("Índice de diálogo inválido: ", _id)
		skip_dialog()
		return

	var current_page = data[_id]
	name_label.text = current_page.get("title", "???")
	dialog_label.bbcode_enabled = true
	dialog_label.text = current_page.get("dialog", "...")
	
	var faceset_path = current_page.get("faceset", "")
	if faceset_path:
		faceset_rect.texture = load(faceset_path)
	
	dialog_label.visible_ratio = 0
	
	if _current_tween and _current_tween.is_running():
		_current_tween.kill()
		
	_current_tween = create_tween()
	_current_tween.tween_property(dialog_label, "visible_ratio", 1, dialog_label.text.length() * _step)
	
	# Espera o tween terminar para mostrar o indicador de "próximo".
	await _current_tween.finished
