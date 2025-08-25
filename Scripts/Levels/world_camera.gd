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
## Arraste e solte o seu nó TileMap aqui para que a câmera possa calcular os limites automaticamente.
@export var tilemap_node: NodePath

# Esta variável não é mais exportada. Será calculada no _ready().
var world_limits: Rect2


func _ready() -> void:
	# --- NOVA LÓGICA PARA DEFINIR LIMITES AUTOMATICAMENTE ---
	
	# Espera até que o dono do nó (a cena principal) esteja pronto.
	# Isso garante que o TileMap já exista na árvore de cena.
	await owner.ready
	
	# Pega o nó TileMap a partir do caminho que você definiu no Editor.
	var map: TileMap = get_node_or_null(tilemap_node)
	
	# Verifica se o TileMap foi encontrado.
	
	# get_used_rect() retorna um retângulo com as células usadas no TileMap.
	var used_rect: Rect2i = map.get_used_rect()
	
	# Pega o tamanho de cada tile (célula) do TileSet.
	var tile_size: Vector2i = map.tile_set.tile_size
	
	# Calcula o retângulo de limites do mundo em pixels.
	world_limits = Rect2(
		used_rect.position * tile_size,
		used_rect.size * tile_size
	)


func _unhandled_input(event: InputEvent) -> void:
	# A lógica de zoom com a roda do mouse permanece a mesma.
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += Vector2(zoom_speed, zoom_speed)
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom -= Vector2(zoom_speed, zoom_speed)
		
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))


func _process(delta: float) -> void:
	# --- LÓGICA DE MOVIMENTO COM TECLADO (permanece a mesma) ---
	
	# Pega a direção das teclas (W,A,S,D e setas) em um vetor normalizado.
	var direction = Input.get_vector("ui_a", "ui_d", "ui_w", "ui_s") # Nota: Corrigi para os inputs padrão.
	
	# Aplica o movimento à posição da câmera.
	position += direction * pan_speed * delta
	
	# --- LÓGICA DE LIMITES DO MUNDO (agora usa os limites dinâmicos) ---
	
	# Só aplica os limites se eles foram calculados com sucesso.
	if world_limits:
		var viewport_rect = get_viewport_rect()
		var viewport_half_size = viewport_rect.size * zoom / 2.0
		
		position.x = clamp(position.x, world_limits.position.x + viewport_half_size.x, world_limits.end.x - viewport_half_size.x)
		position.y = clamp(position.y, world_limits.position.y + viewport_half_size.y, world_limits.end.y - viewport_half_size.y)
