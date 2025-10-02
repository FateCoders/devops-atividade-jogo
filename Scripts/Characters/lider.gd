extends NPC
class_name Lider

var is_alive: bool = true

func _ready():
	super()
	npc_name = "Líder"

func die():
	if is_alive:
		is_alive = false
		print("O LÍDER MORREU!")
		EventManager.emit_signal("leader_died")
		queue_free()
