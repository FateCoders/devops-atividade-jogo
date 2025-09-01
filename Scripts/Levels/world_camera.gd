extends Camera2D

@export_category("Movimento (Pan)")
@export var pan_speed: float = 2000
@export var mouse_speed_multiplier: int = 8

@export_category("Zoom")
@export var zoom_speed: float = 0.05
@export var min_zoom: float = 0.01
@export var max_zoom: float = 3
@export var initial_zoom: float = 0.3

@export_category("Limites do Mundo")
## Defina o retângulo dos limites do mundo manualmente.
## X e Y são a posição do canto superior esquerdo.
## W (Width) e H (Height) são a largura e altura do seu mapa.
@export var world_limits: Rect2 = Rect2(0, 0, 2000, 1200)

# Variáveis para controle do "arrastar com mouse"
var dragging: bool = false
var last_mouse_position: Vector2

func _ready() -> void:
	# Apenas define o zoom inicial.
	zoom = Vector2(initial_zoom, initial_zoom)


func _unhandled_input(event: InputEvent) -> void:
	# A lógica de zoom e arraste com o mouse permanece a mesma
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom += Vector2(zoom_speed, zoom_speed)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom -= Vector2(zoom_speed, zoom_speed)
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.is_pressed()
			last_mouse_position = get_viewport().get_mouse_position()

	if event is InputEventMouseMotion and dragging:
		var mouse_delta = event.relative
		position -= mouse_delta * zoom * mouse_speed_multiplier
	

# --- FUNÇÃO _PROCESS CORRIGIDA ---
func _process(delta: float) -> void:
	# Movimento com teclado
	var direction = Input.get_vector("ui_a", "ui_d", "ui_w", "ui_s")
	position += direction * pan_speed * delta

	# Lógica de limites do mundo
	if world_limits:
		var viewport_rect = get_viewport_rect()
		var viewport_half_size = viewport_rect.size * zoom / 2.0
		
		# Calcula os limites mínimo e máximo da posição da câmera
		var min_pos_x = world_limits.position.x + viewport_half_size.x
		var max_pos_x = world_limits.end.x - viewport_half_size.x
		
		var min_pos_y = world_limits.position.y + viewport_half_size.y
		var max_pos_y = world_limits.end.y - viewport_half_size.y
		
		# VERIFICAÇÃO: Se a visão é mais larga que o mundo, o min se torna > max.
		# Nesse caso, travamos a câmera no centro do mundo no eixo X.
		if min_pos_x > max_pos_x:
			position.x = world_limits.get_center().x
		else:
			# Se não, aplicamos o limite normalmente.
			position.x = clamp(position.x, min_pos_x, max_pos_x)

		# Repetimos a mesma lógica para o eixo Y.
		if min_pos_y > max_pos_y:
			position.y = world_limits.get_center().y
		else:
			position.y = clamp(position.y, min_pos_y, max_pos_y)
