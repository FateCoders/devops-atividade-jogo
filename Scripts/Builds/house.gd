# House.gd
extends StaticBody2D
class_name House

@export var capacity: int = 5
var residents: Array[NPC] = []

# --- FILA DE SAÍDA ---
var exit_queue: Array = []          # Fila de NPCs aguardando para sair
var is_exit_busy: bool = false      # Se TRUE, significa que alguém está saindo

func _ready():
	QuilomboManager.register_house(self)

func is_full() -> bool:
	return residents.size() >= capacity

func get_door_position() -> Vector2:
	return $DoorPosition.global_position

## Função chamada pelo QuilomboManager para designar um morador
func add_resident(npc: NPC):
	if not is_full() and not npc in residents:
		residents.append(npc)
		print("Casa '%s' agora tem '%s' como morador. Lotação: %d/%d" % [name, npc.name, residents.size(), capacity])
	else:
		printerr("Não foi possível designar '%s' para a casa '%s'." % [npc.name, name])

## Função para remover um morador
func remove_resident(npc: NPC):
	if npc in residents:
		residents.erase(npc)
		print("'%s' saiu da casa '%s'. Lotação atual: %d/%d" % [npc.name, name, residents.size(), capacity])

# NPC pede para sair → Adiciona ele na fila
func request_exit(npc: NPC):
	if npc not in exit_queue:
		exit_queue.append(npc)
		print("%s entrou na fila para sair da casa '%s'." % [npc.name, name])
		process_exit_queue()


# Processa a fila → Permite só UM NPC sair por vez
func process_exit_queue():
	if is_exit_busy:
		return  # Porta ocupada, espera o atual terminar

	if exit_queue.size() > 0:
		var next_npc = exit_queue.pop_front()
		is_exit_busy = true
		print("%s está autorizado a sair da casa '%s'." % [next_npc.name, name])
		next_npc.start_exit()


# Chamado pelo NPC quando ele terminar de sair
func notify_exit_done():
	is_exit_busy = false
	process_exit_queue()  # Libera o próximo da fila

func _on_entrance_area_body_entered(body: Node2D):
	print("!!! ÁREA DA PORTA DETECTOU ALGO: ", body.name)

	if body is NPC:
		print("--> O corpo é um NPC.")
		if body in residents:
			print("--> O NPC é um morador desta casa.")
			if body.current_state == NPC.State.INDO_PARA_CASA:
				print("--> O NPC quer entrar em casa. Comandando entrada...")
				body.enter_house()
			else:
				print("--> FALHA: O NPC é morador, mas seu estado não é INDO_PARA_CASA. Estado atual: %s" % NPC.State.keys()[body.current_state])
		else:
			print("--> FALHA: O NPC '%s' NÃO é um morador registrado desta casa." % body.name)
	else:
		print("--> O corpo detectado NÃO é um NPC.")

func _on_entrance_area_body_exited(body: Node2D):
	if body is NPC and body in residents:
		if body.current_state == NPC.State.SAINDO_DE_CASA:
			body.exit_house_complete()
