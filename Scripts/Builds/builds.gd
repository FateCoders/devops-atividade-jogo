extends Area2D

class_name Bonfire

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var cost: Dictionary = {"madeira": 15, "dinheiro": 5}

@export var is_decoration: bool = true

var noise = FastNoiseLite.new()
var time_passed: float = 0.0


func _ready() -> void:
	animated_sprite.play("lit")

	noise.seed = randi()
	noise.frequency = 0.5
