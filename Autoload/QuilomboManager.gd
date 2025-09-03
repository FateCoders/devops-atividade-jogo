# QuilomboManager.gd
extends Node

var all_houses: Array[House] = []
var all_npcs: Array[Node] = []

# --- FUNÇÃO DE LIMPEZA ---
## Limpa todos os dados do quilombo atual. Deve ser chamada ao sair para o menu.
func reset_quilombo_state():
	print("[QUILOMBO MANAGER] Resetando o estado. Limpando listas de casas e NPCs.")
	all_houses.clear()
	all_npcs.clear()

## As casas se registram aqui quando são criadas
func register_house(house_node: House):
	if not house_node in all_houses:
		all_houses.append(house_node)
		print("Casa '%s' registrada. Total de casas: %d" % [house_node.name, all_houses.size()])

## Encontra uma casa com espaço vago
func find_available_house() -> House:
	for house in all_houses:
		# Adicionada verificação de segurança para ignorar casas "fantasmas"
		if is_instance_valid(house) and not house.is_full():
			return house
	return null

# --- FUNÇÃO ESPECÍFICA PARA CASAS ---
## Apenas instancia e posiciona a casa. A própria casa se registra no _ready().
func build_house(house_scene: PackedScene, build_position: Vector2):
	if not house_scene: return
	
	var new_house = house_scene.instantiate()
	get_tree().current_scene.add_child(new_house)
	new_house.global_position = build_position
	print("--> Construindo ", new_house.name, " (Casa) em ", build_position)


# --- FUNÇÃO ESPECÍFICA PARA LOCAIS DE TRABALHO ---
## Constrói um local de trabalho e o prepara para gerar NPCs.
func build_workplace(workplace_scene: PackedScene, build_position: Vector2):
	if not workplace_scene: return

	var new_workplace = workplace_scene.instantiate()
	get_tree().current_scene.add_child(new_workplace)
	new_workplace.global_position = build_position
	print("--> Construindo ", new_workplace.name, " (Local de Trabalho) em ", build_position)
	
	# Usamos call_deferred para garantir que a construção esteja 100% pronta
	# antes de tentarmos gerar os NPCs a partir dela.
	call_deferred("_spawn_npcs_for_workplace", new_workplace)


## Esta função é chamada de forma segura pelo call_deferred.
func _spawn_npcs_for_workplace(workplace_node):
	print("--> Construção '%s' está pronta. Verificando se ela gera NPCs." % workplace_node.name)

	var npc_count_to_spawn = workplace_node.npc_count
	var npc_scene_to_spawn = workplace_node.npc_scene_to_spawn
	
	if npc_count_to_spawn == 0 or not npc_scene_to_spawn:
		print("--> Esta construção não gera NPCs (verifique as propriedades no Inspetor da cena).")
		return

	print("--> Propriedades válidas! Gerando %d NPCs." % npc_count_to_spawn)
	
	var current_scene = get_tree().current_scene
	# Gera os NPCs
	for i in npc_count_to_spawn:
		var new_npc = npc_scene_to_spawn.instantiate()
		current_scene.add_child(new_npc)
		new_npc.global_position = workplace_node.global_position + Vector2(randf_range(-30, 30), randf_range(50, 80))

		new_npc.work_node = workplace_node
		
		var available_house = find_available_house()
		if available_house:
			print("--> Lar encontrado para o NPC #", i + 1, "! Casa: ", available_house.name)
			new_npc.house_node = available_house
			available_house.add_resident(new_npc)
		else:
			print("AVISO: Nenhum lar disponível para o novo NPC #", i + 1)
