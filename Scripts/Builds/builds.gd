extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var noise = FastNoiseLite.new()
var time_passed: float = 0.0


func _ready() -> void:
	animated_sprite.play("lit")

	noise.seed = randi()
	noise.frequency = 0.5
