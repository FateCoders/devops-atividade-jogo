# GameUI.gd
extends CanvasLayer

# --- CENAS DE CONSTRUÇÃO ---
# ! IMPORTANTE: Verifique se os caminhos para suas cenas estão corretos!
const PlantationScene = preload("res://Scenes/Buildings/Plantation.tscn")
const HouseScene = preload("res://Scenes/Buildings/House.tscn")

# --- CENA DE DIÁLOGO ---
const _DIALOG_SCREEN: PackedScene = preload("res://Scenes/UI/dialog.tscn")

# --- Variáveis para o Modo de Construção ---
var is_in_build_mode: bool = false
var building_to_place_scene: PackedScene = null
var ghost_building = null
var build_type: String = ""

# --- Dados do Diálogo (Exemplo) ---
# (Mantido aqui, mas pode ser movido para um gerenciador de diálogos no futuro)
var _dialog_data: Dictionary = {
	0: {"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png", "dialog": "Ufa... a Luz nos deu forças mais uma vez.", "title": "Paladino"},
	1: {"faceset": "res://Scenes/UI/Assets/Sprites/warrior_faceset.png", "dialog": "Paz... por enquanto.", "title": "Guerreiro"},
}


func _ready():
	# Garante que a UI comece o jogo escondida.
	visible = false


func _input(event: InputEvent):
	# Usamos _input para ter controle total e consumir eventos quando necessário.
	
	# --- LÓGICA PARA EXIBIR/OCULTAR A UI ---
	if event.is_action_just_pressed("ui_enter"):
		visible = not visible
		get_tree().paused = visible
		# Consome o evento para evitar que outros nós (como o diálogo) o recebam
		get_viewport().set_input_as_handled()
		
		# Se acabamos de fechar a UI, cancela qualquer construção em andamento.
		if not visible and is_in_build_mode:
			_exit_build_mode()

	# --- LÓGICA PARA DIÁLOGO E CONSTRUÇÃO (SÓ EXECUTA SE A UI ESTIVER ATIVA) ---
	if not visible:
		return

	# Lógica para iniciar o diálogo
	if event.is_action_just_pressed("ui_select"):
		if not find_child("DialogScreen", false, false):
			var new_dialog: DialogScreen = _DIALOG_SCREEN.instantiate()
			new_dialog.name = "DialogScreen"
			new_dialog.data = _dialog_data
			add_child(new_dialog)
			get_viewport().set_input_as_handled()

	# Lógica de Construção
	if is_in_build_mode:
		# Confirma a construção com o botão esquerdo do mouse
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if _check_valid_placement():
				var build_pos = ghost_building.global_position
				if build_type == "house": QuilomboManager.build_house(building_to_place_scene, build_pos)
				elif build_type == "workplace": QuilomboManager.build_workplace(building_to_place_scene, build_pos)
				_exit_build_mode()
				get_viewport().set_input_as_handled()
		
		# Cancela a construção com o botão direito do mouse
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			_exit_build_mode()
			get_viewport().set_input_as_handled()
	
	# Cancela a construção com a tecla Esc
	if event.is_action_just_pressed("ui_cancel"):
		if is_in_build_mode:
			_exit_build_mode()
			get_viewport().set_input_as_handled()


func _process(delta: float):
	# A função _process agora tem UMA ÚNICA responsabilidade: mover o fantasma.
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


# --- FUNÇÕES DOS BOTÕES (NÃO MUDAM) ---
func _on_build_plantation_button_pressed():
	enter_build_mode(PlantationScene, "workplace")

func _on_build_house_button_pressed():
	enter_build_mode(HouseScene, "house")


# --- LÓGICA DE CONSTRUÇÃO (NÃO MUDAM) ---
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

func _check_valid_placement() -> bool:
	var area: Area2D = ghost_building.get_node_or_null("Area2D")
	if not area: return true
	return area.get_overlapping_bodies().is_empty() and area.get_overlapping_areas().is_empty()

func _exit_build_mode():
	if ghost_building:
		ghost_building.queue_free()
	
	is_in_build_mode = false
	building_to_place_scene = null
	ghost_building = null
	build_type = ""
