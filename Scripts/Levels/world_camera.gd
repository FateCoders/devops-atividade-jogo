extends Camera2D

@export_category("Movimento (Pan)")
## A velocidade com que a câmera se move ao usar as teclas W, A, S, D.
@export var pan_speed: float = 500.0

@export_category("Zoom")
## A "força" do zoom. Valores menores dão um zoom mais suave.
@export var zoom_speed: float = 0.1
## O nível máximo de zoom para dentro (números menores = mais perto).
@export var min_zoom: float = 0.5
## O nível máximo de zoom para fora (números maiores = mais longe).
@export var max_zoom: float = 3.0

@export_category("Limites do Mundo")
## O retângulo que define os limites do mundo. Precisa ser configurado no Editor.
@export var world_limits: Rect2 = Rect2(0, 0, 2000, 1200)


func _unhandled_input(event: InputEvent) -> void:
	# A lógica de zoom com a roda do mouse permanece a mesma.
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(zoom_speed, zoom_speed)
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= Vector2(zoom_speed, zoom_speed)
		
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))


func _process(delta: float) -> void:
	# --- NOVA LÓGICA DE MOVIMENTO COM TECLADO ---
	
	# Pega a direção das teclas (W,A,S,D e setas) em um vetor normalizado.
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Aplica o movimento à posição da câmera.
	position += direction * pan_speed * delta
	
	# --- LÓGICA DE LIMITES DO MUNDO (permanece a mesma) ---
	var viewport_rect = get_viewport_rect()
	var viewport_half_size = viewport_rect.size * zoom / 2.0
	position.x = clamp(position.x, world_limits.position.x + viewport_half_size.x, world_limits.end.x - viewport_half_size.x)
	position.y = clamp(position.y, world_limits.position.y + viewport_half_size.y, world_limits.end.y - viewport_half_size.y)
