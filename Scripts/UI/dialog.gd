# DialogScreen.gd
extends Control
class_name DialogScreen

@export_category("Objects")
@export var _name: Label = null
@export var _dialog: RichTextLabel = null
@export var _faceset: TextureRect = null

var _step: float = 0.05
var _id: int = 0
var _current_tween: Tween # Para controlar a animação do texto

# A variável de dados agora tem uma função "setter" para inicialização segura
var data: Dictionary = {}:
	set(value):
		data = value
		# A inicialização acontece aqui, depois que 'data' recebe um valor.
		_initialize_dialog()

# A função _ready() agora fica vazia
func _ready() -> void:
	pass
	
func _process(_delta: float) -> void:
	# Se o jogador apertar o botão de ação e o texto ainda está aparecendo...
	if Input.is_action_just_pressed("ui_accept") and _dialog.visible_ratio < 1:
		# ...termina a animação de texto instantaneamente.
		if _current_tween and _current_tween.is_running():
			_current_tween.kill() # Para o tween
		_dialog.visible_ratio = 1 # Mostra todo o texto
		return
		
	# Se o texto já terminou de aparecer, avança para o próximo diálogo
	if Input.is_action_just_pressed("ui_accept"):
		_id += 1
		# Se o diálogo terminou, a tela se fecha
		if _id >= data.size():
			queue_free()
			return
			
		# Se ainda há diálogos, inicializa o próximo
		_initialize_dialog()
		
func _initialize_dialog() -> void:
	# Verificação de segurança para garantir que os dados existem antes de usar
	if not data.has(_id):
		print("Índice de diálogo inválido: ", _id)
		queue_free()
		return

	_name.text = data[_id].get("title", "???")
	_dialog.text = data[_id].get("dialog", "...")
	
	# Carrega a textura de forma segura
	var faceset_path = data[_id].get("faceset", "")
	if faceset_path:
		_faceset.texture = load(faceset_path)
	
	# Animação do texto letra por letra usando Tween
	_dialog.visible_characters = 0
	# Certifica-se de que qualquer tween anterior seja parado
	if _current_tween and _current_tween.is_running():
		_current_tween.kill()
		
	_current_tween = create_tween().set_parallel(false)
	# Anima a propriedade 'visible_characters' do início ao fim do texto
	_current_tween.tween_property(_dialog, "visible_characters", _dialog.text.length(), _dialog.text.length() * _step)
