extends CharacterBody2D

@export_category("Cursor")
@export var interrogation_cursor: Texture2D
@export var cursor_hotspot: Vector2 = Vector2(8, 24)


@export_category("Animação e Tremor")
@export var animation_speed: float = 0.7
@export var shake_intensity: float = 1.5

@export_category("Comportamento da Virada")
@export var min_turn_time: float = 1.5
@export var max_turn_time: float = 4.0

@onready var animated_sprite: AnimatedSprite2D = $Texture
@onready var timer: Timer = $Timer

var noise = FastNoiseLite.new()
var time_passed: float = 0.0


func _ready() -> void:
	timer.timeout.connect(_on_turn_timer_timeout)
	_on_turn_timer_timeout()

	animated_sprite.play("walk")
	animated_sprite.speed_scale = animation_speed
	noise.seed = randi()
	noise.frequency = 2.0
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _process(delta: float) -> void:
	time_passed += delta
	var offset_x = noise.get_noise_2d(time_passed * 5.0, 0) * shake_intensity
	var offset_y = noise.get_noise_2d(0, time_passed * 5.0) * shake_intensity
	animated_sprite.position = Vector2(offset_x, offset_y)


func _on_turn_timer_timeout() -> void:
	var random_direction = randi() % 2
	if random_direction == 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	timer.wait_time = randf_range(min_turn_time, max_turn_time)
	timer.start()

func _on_mouse_entered() -> void:
	if interrogation_cursor:
		Input.set_custom_mouse_cursor(interrogation_cursor, Input.CURSOR_ARROW, cursor_hotspot)


func _on_mouse_exited() -> void:
	Input.set_custom_mouse_cursor(null)
