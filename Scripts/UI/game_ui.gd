# GameUI.gd
extends CanvasLayer

const PlantationScene = preload("res://Scenes/UI/Assets/Sprites/Builds/plowed.tscn")
const HouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/tall_house.tscn")

const _DIALOG_SCREEN: PackedScene = preload("res://Scenes/UI/dialog.tscn")

var _dialog_data: Dictionary = {
	0: {
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"title": "Ancião do Quilombo",
		"dialog": "Seja bem-vindo, líder. Nosso povo precisa de sua orientação para prosperar."
	},
	1: {
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"title": "Ancião do Quilombo",
		"dialog": "Para começar, pressione [b]Enter[/b] a qualquer momento para abrir ou fechar o menu de construção. Experimente agora."
	},
	2: {
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"title": "Ancião do Quilombo",
		"dialog": "Muito bem. Este menu é sua principal ferramenta. Com ele, você dará forma ao nosso futuro."
	},
	3: {
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"title": "Ancião do Quilombo",
		"dialog": "Nossa primeira necessidade é um lar. Um povo sem casa é um povo sem raízes. Clique no botão [b]'Construir Casa'[/b]."
	},
	4: {
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"title": "Ancião do Quilombo",
		"dialog": "Agora, mova o mouse pelo mapa. A imagem 'fantasma' da casa o seguirá. Onde a sombra estiver [color=green]verde[/color], o terreno é bom. Se ficar [color=red]vermelha[/color], há um obstáculo."
	},
	5: {
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"title": "Ancião do Quilombo",
		"dialog": "Encontre um bom lugar e use o [b]clique esquerdo[/b] para fincar os alicerces. Se mudar de ideia, o [b]clique direito[/b] ou a tecla [b]Esc[/b] cancela a construção."
	},
	6: {
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"title": "Ancião do Quilombo",
		"dialog": "Excelente! Com um teto sobre suas cabeças, nosso povo pode pensar no futuro. Cada casa que você constrói abre espaço para mais gente se juntar a nós."
	},
	7: {
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"title": "Ancião do Quilombo",
		"dialog": "Agora, vamos garantir nosso sustento. Tente construir uma [b]Plantação[/b]. Ela nos trará recursos e fortalecerá nosso escambo com aliados."
	},
	8: {
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"title": "Ancião do Quilombo",
		"dialog": "Lembre-se desta regra de ouro: [b]só podemos criar um novo local de trabalho se houver uma casa vaga[/b] para os novos trabalhadores que chegarão."
	},
	9: {
		"faceset": "res://Scenes/UI/Assets/Sprites/paladin_faceset.png",
		"title": "Ancião do Quilombo",
		"dialog": "Com lares para morar e campos para cultivar, começamos nossa jornada. Esteja atento, pois os dias trarão desafios e oportunidades."
	}
}

var is_in_build_mode: bool = false
var building_to_place_scene: PackedScene = null
var ghost_building = null
var build_type: String = ""


func _ready():
	visible = false

func _process(delta: float):
	if not is_in_build_mode or not ghost_building: return
	ghost_building.global_position = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	var is_valid_position = _check_valid_placement()
	if is_valid_position:
		ghost_building.modulate = Color(0.5, 1, 0.5, 0.7)
	else:
		ghost_building.modulate = Color(1, 0.5, 0.5, 0.7) 

func _unhandled_input(event: InputEvent):
	
	if Input.is_action_just_pressed("ui_enter"):
		visible = not visible
		get_tree().paused = visible
		if not visible and is_in_build_mode:
			_exit_build_mode()
	
	if Input.is_action_just_pressed("ui_select"):
		if not find_child("DialogScreen", false, false) and visible:
			var new_dialog: DialogScreen = _DIALOG_SCREEN.instantiate()
			new_dialog.name = "DialogScreen"
			new_dialog.data = _dialog_data
			add_child(new_dialog)

	if not visible:
		return

	if is_in_build_mode:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if _check_valid_placement():
				var build_pos = ghost_building.global_position
				if build_type == "house": QuilomboManager.build_house(building_to_place_scene, build_pos)
				elif build_type == "workplace": QuilomboManager.build_workplace(building_to_place_scene, build_pos)
				_exit_build_mode()
		
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			_exit_build_mode()
	
	if Input.is_action_just_pressed("ui_cancel"):
		if is_in_build_mode:
			_exit_build_mode()

func _on_build_plantation_button_pressed():
	enter_build_mode(PlantationScene, "workplace")

func _on_build_house_button_pressed():
	enter_build_mode(HouseScene, "house")

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
