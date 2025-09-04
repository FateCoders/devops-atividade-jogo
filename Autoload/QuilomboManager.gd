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


# --- FUNÇÕES DE REGISTRO E BUSCA ---

## As casas se registram aqui quando são criadas em suas funções _ready().
func register_house(house_node: House):
	if not house_node in all_houses:
		all_houses.append(house_node)
		print("Casa '%s' registrada. Total de casas: %d" % [house_node.name, all_houses.size()])

## Encontra uma casa com espaço vago, ignorando casas que foram destruídas.
func find_available_house() -> House:
	for i in range(all_houses.size() - 1, -1, -1):
		var house = all_houses[i]
		if is_instance_valid(house):
			if not house.is_full():
				return house
		else:
			all_houses.remove_at(i)
			print("[QUILOMBO MANAGER] Removida referência de casa fantasma da lista.")
	return null


# --- FUNÇÕES DE CONSTRUÇÃO ---

## Apenas instancia e posiciona a casa.
func build_house(house_scene: PackedScene, build_position: Vector2):
	if not house_scene: 
		printerr("Tentativa de construir casa sem uma cena válida!")
		return

	var new_house = house_scene.instantiate()
	get_tree().current_scene.add_child(new_house)
	new_house.global_position = build_position
	print("--> Construindo ", new_house.name, " (Casa) em ", build_position)


## Constrói um local de trabalho e agenda a geração de NPCs.
func build_workplace(workplace_scene: PackedScene, build_position: Vector2):
	if not workplace_scene: 
		printerr("Tentativa de construir local de trabalho sem uma cena válida!")
		return

	var new_workplace = workplace_scene.instantiate()
	get_tree().current_scene.add_child(new_workplace)
	new_workplace.global_position = build_position
	print("--> Construindo ", new_workplace.name, " (Local de Trabalho) em ", build_position)

	# Agenda a função de geração de NPCs para ser executada de forma segura,
	# garantindo que a construção esteja 100% pronta.
	call_deferred("_spawn_npcs_for_workplace", new_workplace)


# --- LÓGICA DE GERAÇÃO DE NPCS ---

## Esta função é chamada de forma segura pelo call_deferred.
func _spawn_npcs_for_workplace(workplace_node):
	print("--> Construção '%s' está pronta. Verificando se ela gera NPCs." % workplace_node.name)

	var npc_count_to_spawn = workplace_node.npc_count
	var npc_scene_to_spawn = workplace_node.npc_scene_to_spawn
	
	if npc_count_to_spawn == 0 or not npc_scene_to_spawn:
		print("--> Esta construção não gera NPCs.")
		return

	print("--> Propriedades válidas! Gerando %d NPCs." % npc_count_to_spawn)
	
	var current_scene = get_tree().current_scene
	var nav_map = get_tree().get_root().get_world_2d().navigation_map
	
	# Gera os NPCs
	for i in npc_count_to_spawn:
		var new_npc = npc_scene_to_spawn.instantiate()
		current_scene.add_child(new_npc)
		
		# Lógica de Geração Segura para evitar que nasçam em locais inválidos
		var desired_spawn_pos = workplace_node.global_position + Vector2(randf_range(-30, 30), randf_range(50, 80))
		var safe_spawn_pos = NavigationServer2D.map_get_closest_point(nav_map, desired_spawn_pos)
		new_npc.global_position = safe_spawn_pos
		print("--> NPC #%d gerado em posição segura: %s" % [i + 1, safe_spawn_pos])

		# Atribui trabalho e casa
		new_npc.work_node = workplace_node
		
		var available_house = find_available_house()
		if available_house:
			print("--> Lar encontrado para o NPC #", i + 1, "! Casa: ", available_house.name)
			new_npc.house_node = available_house
			available_house.add_resident(new_npc)
		else:
			print("AVISO: Nenhum lar disponível para o novo NPC #", i + 1)
