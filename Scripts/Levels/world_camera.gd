extends Camera2D

@export_category("Movimento (Pan)")
## A velocidade MÁXIMA que a câmera atinge quando o mouse está na borda da tela.
@export var max_pan_speed: float = 600.0
## Proporção da tela que será a "zona morta" central (0.3 = 30% do centro).
@export var dead_zone_ratio: float = 0.3

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
	# Lógica de zoom (permanece a mesma)
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom -= Vector2(zoom_speed, zoom_speed)
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom += Vector2(zoom_speed, zoom_speed)
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))


func _process(delta: float) -> void:
	# --- NOVA LÓGICA DE MOVIMENTO PROPORCIONAL ---
	
	var viewport_rect = get_viewport_rect()
	var viewport_center = viewport_rect.size / 2.0
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Calcula o vetor do centro da tela até o mouse
	var mouse_from_center = mouse_pos - viewport_center
	
	# Define o raio da "zona morta" com base na proporção definida
	var dead_zone_radius = viewport_rect.size.x * dead_zone_ratio / 2.0
	
	# Só move a câmera se o mouse estiver fora da zona morta
	if mouse_from_center.length() > dead_zone_radius:
		# Calcula a "influência" (de 0.0 a 1.0) do mouse sobre a velocidade
		# Usa a função remap para mapear a distância do mouse para a força do movimento
		var influence = remap(mouse_from_center.length(), dead_zone_radius, viewport_center.x, 0.0, 1.0)
		influence = clamp(influence, 0.0, 1.0)
		
		# A velocidade atual é a velocidade máxima multiplicada pela influência
		var current_speed = max_pan_speed * influence
		
		# A direção do movimento é a direção do centro para o mouse
		var direction = mouse_from_center.normalized()
		
		# Aplica o movimento
		position += direction * current_speed * delta
	
	# --- Lógica de Limites do Mundo (permanece a mesma) ---
	var viewport_half_size = viewport_rect.size * zoom / 2.0
	position.x = clamp(position.x, world_limits.position.x + viewport_half_size.x, world_limits.end.x - viewport_half_size.x)
	position.y = clamp(position.y, world_limits.position.y + viewport_half_size.y, world_limits.end.y - viewport_half_size.y)
