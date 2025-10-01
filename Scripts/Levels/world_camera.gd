extends Camera2D

@export_category("Movimento (Pan)")
@export var pan_speed: float = 2000
@export var mouse_speed_multiplier: int = 8

@export_category("Zoom")
@export var zoom_speed: float = 0.15 
@export var min_zoom: float = 0.1
@export var max_zoom: float = 3
@export var initial_zoom: float = 0.3

@export_category("Limites do Mundo")
@export var world_limits: Rect2 = Rect2(-7840, -8479.5, 16000, 15999.5)

var dragging: bool = false
var last_mouse_position: Vector2

func _ready() -> void:
	zoom = Vector2(initial_zoom, initial_zoom)


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.is_camera_paused:
		return

	if event is InputEventMouseButton and event.is_pressed():
		# Roda para CIMA = Zoom Out (Afastar)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= (1.0 + zoom_speed) # Multiplica para aumentar o valor do zoom
			zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

		# Roda para BAIXO = Zoom In (Aproximar)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom /= (1.0 + zoom_speed) # Divide para diminuir o valor do zoom
			zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

		# Inicia o arrasto com o botão esquerdo
		elif event.button_index == MOUSE_BUTTON_LEFT:
			dragging = true
			last_mouse_position = get_viewport().get_mouse_position()

	# Pára de arrastar ao soltar o botão esquerdo
	if event is InputEventMouseButton and not event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = false
			
	# Movimento da câmera enquanto arrasta
	if event is InputEventMouseMotion and dragging:
		position -= event.relative * zoom * mouse_speed_multiplier
	

func _process(delta: float) -> void:
	if GameManager.is_camera_paused:
		return

	# Movimento com teclado
	var direction = Input.get_vector("ui_a", "ui_d", "ui_w", "ui_s")
	position += direction * pan_speed * delta

	# Lógica de limites do mundo
	if world_limits:
		var viewport_rect = get_viewport_rect()
		var viewport_half_size = viewport_rect.size * zoom / 2.0
		
		var min_pos_x = world_limits.position.x + viewport_half_size.x
		var max_pos_x = world_limits.end.x - viewport_half_size.x
		
		var min_pos_y = world_limits.position.y + viewport_half_size.y
		var max_pos_y = world_limits.end.y - viewport_half_size.y
		
		if min_pos_x > max_pos_x:
			position.x = world_limits.get_center().x
		else:
			position.x = clamp(position.x, min_pos_x, max_pos_x)

		if min_pos_y > max_pos_y:
			position.y = world_limits.get_center().y
		else:
			position.y = clamp(position.y, min_pos_y, max_pos_y)
