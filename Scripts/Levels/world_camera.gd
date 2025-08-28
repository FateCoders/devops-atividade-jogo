extends Camera2D

@export_category("Movimento (Pan)")
@export var pan_speed: float = 500.0

@export_category("Zoom")
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.5

@export_category("Limites do Mundo")
## Arraste e solte o seu nó TileMapLayer aqui.
@export var tilemap_layer_node: NodePath

var world_limits: Rect2


func _ready() -> void:
	zoom = Vector2(min_zoom, min_zoom)
	await owner.ready
	
	# --- LÓGICA ATUALIZADA ---
	
	# 1. Pega o nó TileMapLayer a partir do caminho que você definiu no Editor.
	var layer: TileMapLayer = get_node_or_null(tilemap_layer_node)
	
	# Verificação de segurança: garante que a camada foi atribuída.
	if not layer:
		printerr("Câmera 2D: O nó TileMapLayer não foi atribuído no Inspetor!")
		return

	# 2. Pega o nó TileMap pai para acessar o TileSet.
	var tilemap: TileMap = layer.get_parent() as TileMap

	# Verificação de segurança: garante que a camada é filha de um TileMap.
	if not tilemap:
		printerr("Câmera 2D: A camada atribuída não é filha de um nó TileMap!")
		return

	# 3. get_used_rect() é chamado diretamente na CAMADA (layer).
	var used_rect: Rect2i = layer.get_used_rect()
	
	# 4. O tile_size é pego a partir do TileSet do PAI (tilemap).
	var tile_size: Vector2i = tilemap.tile_set.tile_size
	
	# O cálculo final permanece o mesmo.
	world_limits = Rect2(
		used_rect.position * tile_size,
		used_rect.size * tile_size
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(zoom_speed, zoom_speed)
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= Vector2(zoom_speed, zoom_speed)
		
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))


func _process(delta: float) -> void:
	var direction = Input.get_vector("ui_a", "ui_d", "ui_w", "ui_s")
	
	position += direction * pan_speed * delta
	
	if world_limits:
		var viewport_rect = get_viewport_rect()
		var viewport_half_size = viewport_rect.size * zoom / 2.0
		
		position.x = clamp(position.x, world_limits.position.x + viewport_half_size.x, world_limits.end.x - viewport_half_size.x)
		position.y = clamp(position.y, world_limits.position.y + viewport_half_size.y, world_limits.end.y - viewport_half_size.y)
