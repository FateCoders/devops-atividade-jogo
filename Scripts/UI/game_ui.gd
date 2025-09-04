# GameUI.gd
extends CanvasLayer

# --- CENAS DE CONSTRUÇÃO ---
# Pré-carrega todas as cenas que o jogador pode construir.
# ! IMPORTANTE: Verifique se os caminhos para suas cenas estão corretos!
const PlantationScene = preload("res://Scenes/UI/Assets/Sprites/Builds/plowed.tscn")
const HouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/tall_house.tscn")

# --- Variáveis para o Modo de Construção ---
var is_in_build_mode: bool = false
var building_to_place_scene: PackedScene = null
var ghost_building = null
var build_type: String = ""


func _ready():
	# Garante que a UI comece o jogo escondida.
	visible = false


func _process(delta: float):
	# Se não estamos no modo de construção, não faz nada.
	if not is_in_build_mode or not ghost_building:
		return

	# Faz o "fantasma" da construção seguir o mouse no mundo do jogo
	ghost_building.global_position = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	
	# Muda a cor do fantasma para dar feedback de posicionamento
	var is_valid_position = _check_valid_placement()
	if is_valid_position:
		ghost_building.modulate = Color(0.5, 1, 0.5, 0.7) # Verde
	else:
		ghost_building.modulate = Color(1, 0.5, 0.5, 0.7) # Vermelho


func _unhandled_input(event: InputEvent):
	# --- LÓGICA PARA EXIBIR E OCULTAR A UI ---
	# Verifica se a tecla "ui_enter" (geralmente a tecla Enter/Return) foi pressionada.
	if event.is_action_pressed("ui_enter"):
		# Inverte a visibilidade: se estiver visível, fica invisível, e vice-versa.
		visible = not visible
		
		# Pausa ou despausa o jogo junto com a UI.
		get_tree().paused = visible
		
		# Se acabamos de fechar a UI, cancela qualquer construção em andamento.
		if not visible and is_in_build_mode:
			_exit_build_mode()

	# Se a UI não estiver visível, ignora os outros inputs (como cliques do mouse)
	if not visible:
		return

	# --- Lógica de Construção (só executa se a UI estiver visível) ---
	if not is_in_build_mode: return
	
	# Confirma a construção com o botão esquerdo do mouse
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if _check_valid_placement():
			var build_pos = ghost_building.global_position
			
			if build_type == "house":
				QuilomboManager.build_house(building_to_place_scene, build_pos)
			elif build_type == "workplace":
				QuilomboManager.build_workplace(building_to_place_scene, build_pos)
			
			_exit_build_mode()
	
	# Cancela a construção com o botão direito do mouse ou a tecla Esc
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed()) or event.is_action_pressed("ui_cancel"):
		_exit_build_mode()


# --- FUNÇÕES DOS BOTÕES ---

func _on_build_plantation_button_pressed():
	enter_build_mode(PlantationScene, "workplace")

func _on_build_house_button_pressed():
	enter_build_mode(HouseScene, "house")


# --- LÓGICA DE CONSTRUÇÃO ---

# Função central que ativa o modo de construção
func enter_build_mode(building_scene: PackedScene, type: String):
	if is_in_build_mode: return
	
	is_in_build_mode = true
	building_to_place_scene = building_scene
	build_type = type
	
	ghost_building = building_to_place_scene.instantiate()
	get_tree().current_scene.add_child(ghost_building)
	
	var area = ghost_building.get_node_or_null("Area2D")
	if area:
		area.monitoring = false

# Verifica se a área do fantasma está colidindo com algo
func _check_valid_placement() -> bool:
	var area: Area2D = ghost_building.get_node_or_null("Area2D")
	if not area: return true
	return area.get_overlapping_bodies().is_empty() and area.get_overlapping_areas().is_empty()

# Limpa tudo e sai do modo de construção
func _exit_build_mode():
	if ghost_building:
		ghost_building.queue_free()
	
	is_in_build_mode = false
	building_to_place_scene = null
	ghost_building = null
	build_type = ""
