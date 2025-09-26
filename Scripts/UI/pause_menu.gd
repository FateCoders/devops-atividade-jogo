extends CanvasLayer

@export_category("Interação do Cursor")
@export var interaction_cursor: Texture2D
@export var cursor_hotspot: Vector2 = Vector2.ZERO

@export var default_cursor: Texture2D
@export var default_hotspot: Vector2 = Vector2.ZERO
@onready var resume_button = $menu_holder/resume_button

var camera = null
var cameras = []

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		visible = true
		get_tree().paused = true
		resume_button.grab_focus()
		
		cameras = get_tree().get_nodes_in_group("player_camera")
		camera = cameras[0]
		camera.process_mode = Node.PROCESS_MODE_DISABLED

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	visible = false
	
	cameras = get_tree().get_nodes_in_group("player_camera")
	camera = cameras[0]
	camera.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_quit_button_2_pressed() -> void:
	SaveManager.save_game()
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/menu_inicial.tscn")

func open_menu():
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()
	
	cameras = get_tree().get_nodes_in_group("player_camera")
	if not cameras.is_empty():
		camera = cameras[0]
		camera.process_mode = Node.PROCESS_MODE_DISABLED
