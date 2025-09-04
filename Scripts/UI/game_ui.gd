# GameUI.gd
extends CanvasLayer

const PlantationScene = preload("res://Scenes/UI/Assets/Sprites/Builds/plowed.tscn")
const HouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/tall_house.tscn")

var is_in_build_mode: bool = false
var building_to_place_scene: PackedScene = null
var ghost_building = null
# NOVA VARIÁVEL: Guarda o tipo de construção ("house" ou "workplace")
var build_type: String = ""


func _process(delta: float):
	# ... (esta função não muda)
	if not is_in_build_mode or not ghost_building: return
	ghost_building.global_position = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	var is_valid_position = _check_valid_placement()
	if is_valid_position: ghost_building.modulate = Color(0.5, 1, 0.5, 0.7)
	else: ghost_building.modulate = Color(1, 0.5, 0.5, 0.7)


func _unhandled_input(event: InputEvent):
	if not is_in_build_mode: return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if _check_valid_placement():
			var build_pos = ghost_building.global_position
			
			# Verifica o tipo de construção e chama a função correta
			if build_type == "house":
				QuilomboManager.build_house(building_to_place_scene, build_pos)
				StatusManager.mudar_status("seguranca", 5) 
			elif build_type == "workplace":
				QuilomboManager.build_workplace(building_to_place_scene, build_pos)
			
			_exit_build_mode()
	
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed()) or event.is_action_pressed("ui_cancel"):
		_exit_build_mode()


# --- FUNÇÕES DOS BOTÕES E MODO DE CONSTRUÇÃO ATUALIZADOS ---

func _on_build_plantation_button_pressed():
	# Agora passamos o tipo de construção
	enter_build_mode(PlantationScene, "workplace")

func _on_build_house_button_pressed():
	# E aqui também
	enter_build_mode(HouseScene, "house")

func enter_build_mode(building_scene: PackedScene, type: String):
	if is_in_build_mode: return
	
	is_in_build_mode = true
	building_to_place_scene = building_scene
	build_type = type # Guarda o tipo para usar no clique
	
	ghost_building = building_to_place_scene.instantiate()
	get_tree().current_scene.add_child(ghost_building)
	
	var area = ghost_building.get_node_or_null("Area2D")
	if area:
		area.monitoring = false


# ... (as funções _check_valid_placement e _exit_build_mode não mudam)
func _check_valid_placement() -> bool:
	var area: Area2D = ghost_building.get_node_or_null("Area2D")
	if not area: return true
	return area.get_overlapping_bodies().is_empty() and area.get_overlapping_areas().is_empty()
func _exit_build_mode():
	if ghost_building: ghost_building.queue_free()
	is_in_build_mode = false
	building_to_place_scene = null
	ghost_building = null
	build_type = ""
