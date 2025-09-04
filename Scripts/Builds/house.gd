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
	if not is_full() and not npc in residents:
		residents.append(npc)
		print("'%s' entrou na casa. Lotação atual: %d/%d" % [npc.name, residents.size(), capacity])
	elif is_full():
		print("A casa '%s' está cheia! Não foi possível adicionar '%s'." % [self.name, npc.name])
	else:
		print("Aviso: O NPC '%s' já é um morador desta casa." % npc.name)


func get_door_position() -> Vector2:
	return $DoorPosition.global_position

func _on_entrance_area_body_entered(body: Node2D):
	if not body is NPC:
		return
		
	if not body in residents:
		return
		
	if body.current_state == NPC.State.INDO_PARA_CASA:
		print("Casa '%s' detectou a chegada do morador '%s'." % [self.name, body.name])
		body.enter_house()
