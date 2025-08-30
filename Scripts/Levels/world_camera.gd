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
@export var tilemap_layer_node: NodePath

var world_limits: Rect2


# Variáveis para controle do "arrastar com mouse"
var dragging: bool = false
var last_mouse_position: Vector2

func _ready() -> void:
	zoom = Vector2(initial_zoom, initial_zoom)
	await owner.ready

	var layer: TileMapLayer = get_node_or_null(tilemap_layer_node)
	if not layer:
		printerr("Câmera 2D: O nó TileMapLayer não foi atribuído no Inspetor!")
		return

	var tilemap: TileMap = layer.get_parent() as TileMap
	if not tilemap:
		printerr("Câmera 2D: A camada atribuída não é filha de um nó TileMap!")
		return

	var used_rect: Rect2i = layer.get_used_rect()
	var tile_size: Vector2i = tilemap.tile_set.tile_size

	world_limits = Rect2(
		used_rect.position * tile_size,
		used_rect.size * tile_size
	)


func _unhandled_input(event: InputEvent) -> void:
	# Zoom com scroll
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom += Vector2(zoom_speed, zoom_speed)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom -= Vector2(zoom_speed, zoom_speed)
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

		# Início do arraste com botão esquerdo
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.is_pressed()
			last_mouse_position = get_viewport().get_mouse_position()

	# Durante o arraste
	if event is InputEventMouseMotion and dragging:
		var mouse_delta = event.relative
		position -= mouse_delta * zoom * mouse_speed_multiplier  # multiplica pelo zoom para ter sensação de "mundo"
	
func _process(delta: float) -> void:
	# Movimento com teclado

	var direction = Input.get_vector("ui_a", "ui_d", "ui_w", "ui_s")
	position += direction * pan_speed * delta

	# Limites do mundo
	if world_limits:
		var viewport_rect = get_viewport_rect()
		var viewport_half_size = viewport_rect.size * zoom / 2.0
		
		position.x = clamp(position.x, world_limits.position.x + viewport_half_size.x, world_limits.end.x - viewport_half_size.x)
		position.y = clamp(position.y, world_limits.position.y + viewport_half_size.y, world_limits.end.y - viewport_half_size.y)
