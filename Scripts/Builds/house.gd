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
		if not npc in residents:
			residents.append(npc)
	else:
		printerr("A casa está cheia! Não foi possível adicionar '%s'." % npc.name)

func get_door_position() -> Vector2:
	return $DoorPosition.global_position

# --- NOVA LÓGICA DE ENTRADA ---
# Esta função é chamada automaticamente quando algo entra na Area2D da porta.
func _on_entrance_area_body_entered(body: Node2D):
	# 1. Verifica se o que entrou é um NPC
	if not body is NPC:
		return
		
	# 2. Verifica se este NPC é um dos moradores desta casa
	if not body in residents:
		return
		
	# 3. Verifica se o NPC está no estado de "INDO_PARA_CASA"
	if body.current_state == NPC.State.INDO_PARA_CASA:
		# 4. Se tudo estiver correto, comanda o NPC a entrar.
		print("Casa '%s' detectou a chegada do morador '%s'." % [self.name, body.name])
		body.enter_house()
