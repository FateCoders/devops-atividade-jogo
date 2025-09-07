# GameUI.gd
extends CanvasLayer

@export_category("Interação do Cursor")
@export var interaction_cursor: Texture2D
@export var cursor_hotspot: Vector2 = Vector2.ZERO

@export var default_cursor: Texture2D
@export var default_hotspot: Vector2 = Vector2.ZERO

@onready var day_label: Label = $DayLabel

const PlantationScene = preload("res://Scenes/UI/Assets/Sprites/Builds/plowed.tscn")
const HouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/tall_house.tscn")

const _DIALOG_SCREEN: PackedScene = preload("res://Scenes/UI/dialog.tscn")

var _dialog_data: Dictionary = {
	# ... seus diálogos aqui ...
}

var is_in_build_mode: bool = false
var building_to_place_scene: PackedScene = null
var ghost_building = null
var build_type: String = ""


func _ready():
	visible = false
	
	WorldTimeManager.day_passed.connect(_on_day_passed)
	_on_day_passed(WorldTimeManager.current_day)

func _process(delta: float):
	if visible: 
		Input.set_custom_mouse_cursor(interaction_cursor, Input.CURSOR_ARROW, cursor_hotspot)
	else:
		Input.set_custom_mouse_cursor(default_cursor, Input.CURSOR_ARROW, cursor_hotspot)

	if not is_in_build_mode or not ghost_building:
		return

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
				if build_type == "house": 
					QuilomboManager.build_house(building_to_place_scene, build_pos)
					StatusManager.mudar_status("seguranca", 5)
				elif build_type == "workplace":
					QuilomboManager.build_workplace(building_to_place_scene, build_pos)
				_exit_build_mode()
		
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			_exit_build_mode()
	
	if Input.is_action_just_pressed("ui_cancel"):
		if is_in_build_mode:
			_exit_build_mode()

func _on_day_passed(new_day: int):
	day_label.text = "Dia: %d" % new_day

func _on_build_plantation_button_pressed():
	enter_build_mode(PlantationScene, "workplace")

func _on_build_house_button_pressed():
	enter_build_mode(HouseScene, "house")

func enter_build_mode(building_scene: PackedScene, type: String):
	if is_in_build_mode: 
		return
	
	is_in_build_mode = true
	building_to_place_scene = building_scene
	build_type = type
	
	ghost_building = building_scene.instantiate()
	get_tree().current_scene.add_child(ghost_building)

	# --- DESABILITA TODAS AS COLISÕES E OBSTÁCULOS DO GHOST ---
	_disable_collisions(ghost_building)

func _disable_collisions(node: Node):
	for child in node.get_children():
		if child is CollisionShape2D:
			child.disabled = true
		elif child is NavigationObstacle2D:
			child.queue_free() # Remove do ghost
		_disable_collisions(child)

func _check_valid_placement() -> bool:
	var area: Area2D = ghost_building.get_node_or_null("Area2D")
	if not area: 
		return true
	return area.get_overlapping_bodies().is_empty() and area.get_overlapping_areas().is_empty()

func _exit_build_mode():
	if ghost_building:
		ghost_building.queue_free()
	
	is_in_build_mode = false
	building_to_place_scene = null
	ghost_building = null
	build_type = ""
