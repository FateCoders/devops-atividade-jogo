# House.gd
extends StaticBody2D
class_name House

@export var capacity: int = 5
var residents: Array[NPC] = []

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
		# ESTE PRINT É A PROVA!
		print("Casa '%s' agora tem '%s' como morador. Lotação: %d/%d" % [name, npc.name, residents.size(), capacity])
	else:
		printerr("Não foi possível designar '%s' para a casa '%s'." % [npc.name, name])

## Função para remover um morador (chamada pelo próprio NPC ao sair)
func remove_resident(npc: NPC):
	if npc in residents:
		residents.erase(npc)
		# MODIFICADO: Ajustei a mensagem de print para ser mais correta
		print("'%s' saiu da casa '%s'. Lotação atual: %d/%d" % [npc.name, name, residents.size(), capacity])

# --- LÓGICA DE ENTRADA ---
# Chamada quando um corpo FÍSICO entra na Area2D da porta.
func _on_entrance_area_body_entered(body: Node2D):
	# PRINT 1: Este é o print mais importante. Ele nos diz se o sinal está funcionando.
	print("!!! ÁREA DA PORTA DETECTOU ALGO: ", body.name)

	# 1. Verifica se o que entrou é um NPC.
	if body is NPC:
		print("--> O corpo é um NPC.")
		
		# 2. Verifica se ele é um morador desta casa.
		if body in residents:
			print("--> O NPC é um morador desta casa.")
			
			# 3. Verifica se a INTENÇÃO do NPC é entrar.
			if body.current_state == NPC.State.INDO_PARA_CASA:
				print("--> O NPC quer entrar em casa. Comandando entrada...")
				body.enter_house()
			else:
				print("--> FALHA: O NPC é morador, mas seu estado não é INDO_PARA_CASA. Estado atual: %s" % NPC.State.keys()[body.current_state])
		else:
			print("--> FALHA: O NPC '%s' NÃO é um morador registrado desta casa." % body.name)
	else:
		print("--> O corpo detectado NÃO é um NPC.")
			
# --- LÓGICA DE SAÍDA ---
# Chamada quando um corpo FÍSICO sai da Area2D da porta.
func _on_entrance_area_body_exited(body: Node2D):
	# 1. Verifica se o que saiu é um NPC e se ele é um morador.
	if body is NPC and body in residents:
		# 2. Verifica se a INTENÇÃO do NPC era sair.
		if body.current_state == NPC.State.SAINDO_DE_CASA:
			# 3. Comanda o NPC a completar a ação de sair.
			body.exit_house_complete()
