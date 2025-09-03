# PlayerController.gd
extends CharacterBody2D

@export var move_speed: float = 150.0

@onready var animated_sprite: AnimatedSprite2D = $Texture

func _physics_process(delta: float):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	velocity = direction * move_speed
	move_and_slide()
	
	_update_animation()


func _update_animation():
	if velocity.length() > 0:
		animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")
	
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false
