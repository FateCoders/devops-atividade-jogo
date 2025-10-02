extends Node2D

@export_category("Interação do Cursor")
@export var interaction_cursor: Texture2D
@export var move_cursor: Texture2D
@export var cursor_hotspot: Vector2 = Vector2.ZERO

@onready var hud = $HUD/Hud

var is_dragging_world: bool = false

@export var patrol_points_container: NodePath

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hud.placement_preview_started.connect(hud.show_preview)
	hud.placement_preview_ended.connect(hud.clear_preview)
	
	Input.set_custom_mouse_cursor(interaction_cursor, Input.CURSOR_ARROW, cursor_hotspot)
	MusicManager.play_game_music()
	GameManager.start_tutorial()

func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent):
	if hud.is_in_placement_mode:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			is_dragging_world = true
			Input.set_custom_mouse_cursor(move_cursor, Input.CURSOR_ARROW, cursor_hotspot)
		else:
			is_dragging_world = false
			Input.set_custom_mouse_cursor(interaction_cursor, Input.CURSOR_ARROW, cursor_hotspot)

	if event is InputEventMouseMotion and is_dragging_world:
		Input.set_custom_mouse_cursor(move_cursor, Input.CURSOR_ARROW, cursor_hotspot)

func get_random_patrol_point_position() -> Vector2:
	var patrol_points_node = get_node_or_null(patrol_points_container)
	if patrol_points_node and patrol_points_node.get_child_count() > 0:
		var random_point = patrol_points_node.get_children().pick_random()
		return random_point.global_position

	return Vector2.ZERO
