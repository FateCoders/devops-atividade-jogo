# EventDialog.gd
extends CanvasLayer

@onready var title_label: Label = $ColorRect/CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var description_label: Label = $ColorRect/CenterContainer/Panel/VBoxContainer/ScrollContainer/DescriptionLabel
@onready var button_container: HBoxContainer = $ColorRect/CenterContainer/Panel/VBoxContainer/ChoicesContainer
@onready var custom_tooltip = $CustomTooltip
@onready var tooltip_timer: Timer = $TooltipTimer

var current_event_id: String
var _tooltip_data_to_show: Dictionary
var choice_buttons: Array[Button] = []

var camera = null
var cameras = []


func _ready():
	for child in button_container.get_children():
		if child is Button:
			choice_buttons.append(child)
			
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)

	self.process_mode = Node.PROCESS_MODE_ALWAYS


func start_event(event_id: String, data: Dictionary):
	get_tree().paused = true
	cameras = get_tree().get_nodes_in_group("player_camera")
	if not cameras.is_empty():
		camera = cameras[0]
		camera.process_mode = Node.PROCESS_MODE_DISABLED
	
	current_event_id = event_id
	
	title_label.text = data.get("title", "Evento")
	description_label.text = data.get("description", "...")
	
	for button in choice_buttons:
		button.visible = false
		if button.is_connected("pressed", _on_choice_button_pressed):
			button.pressed.disconnect(_on_choice_button_pressed)
		if button.is_connected("mouse_entered", _on_button_mouse_entered):
			button.mouse_entered.disconnect(_on_button_mouse_entered)
		if button.is_connected("mouse_exited", _on_button_mouse_exited):
			button.mouse_exited.disconnect(_on_button_mouse_exited)

	var choices = data.get("choices", {})
	var button_index = 0
	
	for choice_id in choices.keys():
		if button_index < choice_buttons.size():
			var button = choice_buttons[button_index]
			var choice_data = choices[choice_id]
			
			button.text = choice_data.get("label", "...")
			
			button.pressed.connect(_on_choice_button_pressed.bind(choice_id))
			button.mouse_entered.connect(_on_button_mouse_entered.bind(choice_data))
			button.mouse_exited.connect(_on_button_mouse_exited)
			
			button.visible = true
			button_index += 1


func _on_choice_button_pressed(choice_id: String):
	get_tree().paused = false
	cameras = get_tree().get_nodes_in_group("player_camera")
	if not cameras.is_empty():
		camera = cameras[0]
		camera.process_mode = Node.PROCESS_MODE_ALWAYS
		
	EventManager.emit_signal("event_choice_made", current_event_id, choice_id)
	queue_free() 


func _on_button_mouse_entered(data: Dictionary):
	_tooltip_data_to_show = data
	tooltip_timer.start()

func _on_button_mouse_exited():
	tooltip_timer.stop()
	custom_tooltip.hide_tooltip()

func _on_tooltip_timer_timeout():
	custom_tooltip.show_tooltip(_tooltip_data_to_show)
