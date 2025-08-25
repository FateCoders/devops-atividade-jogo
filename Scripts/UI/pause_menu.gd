extends CanvasLayer

@onready var resume_button = $menu_holder/resume_button

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		visible = true
		get_tree().paused = true
		resume_button.grab_focus()

func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	visible = false

func _on_quit_button_2_pressed() -> void:
	SaveManager.save_game()
	
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/menu_inicial.tscn")
