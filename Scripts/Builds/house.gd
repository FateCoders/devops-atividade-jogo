# House.gd
extends StaticBody2D
class_name House

@export var capacity: int = 5

var residents: Array[Node] = []

func _ready():
	QuilomboManager.register_house(self)

func is_full() -> bool:
	return residents.size() >= capacity

func add_resident(npc: Node):
	if not is_full():
		residents.append(npc)
		print("'%s' entrou na casa. Lotação atual: %d/%d" % [npc.name, residents.size(), capacity])
	else:
		print("A casa está cheia! Não foi possível adicionar '%s'." % npc.name)

func get_door_position() -> Vector2:
	return $DoorPosition.global_position
