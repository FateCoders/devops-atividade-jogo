# VictoryScreen.gd
extends CanvasLayer

# --- Referências para os botões ---
@onready var restart_button: Button = $VBoxContainer/HBoxContainer/continuar_btn
@onready var main_menu_button: Button = $VBoxContainer/HBoxContainer/sair_btn

@onready var achievements_container: HBoxContainer = $VBoxContainer/AchievementsContainer
const AchievementItemScene = preload("res://Scenes/UI/AchievementItem.tscn")

func _ready():
	visible = false
	
	restart_button.pressed.connect(_on_restart_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	GameManager.victory_achieved.connect(_on_victory_achieved)
	
func _on_victory_achieved():
	visible = true
	get_tree().paused = true
	_populate_achievements()

func _populate_achievements():
	for child in achievements_container.get_children():
		child.queue_free()

	var all_achievements = AchievementsManager.get_all_achievements()
	
	for achievement_id in all_achievements.keys():
		var data = all_achievements[achievement_id]
		var item = AchievementItemScene.instantiate()
		achievements_container.add_child(item)
		item.set_data(data)

# --- FUNÇÕES DOS BOTÕES ---

func _on_restart_button_pressed():
	get_tree().paused = false
	visible = false

func _on_main_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/menu_inicial.tscn")
