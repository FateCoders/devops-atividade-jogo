extends CharacterBody2D

@export var speed: float = 300.0

@onready var animated_sprite: AnimatedSprite2D = $Texture

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	velocity = direction * speed

	move_and_slide()

	update_animation()

func update_animation() -> void:
	if velocity.length() > 0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

	if velocity.x != 0:
		if velocity.x < 0:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
