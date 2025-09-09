# QuilomboManager.gd
extends Node

var all_houses: Array[House] = []
var all_npcs: Array[NPC] = []
var building_counts: Dictionary = {}

# --- RESET ---
func reset_quilombo_state():
	print("[QUILOMBO MANAGER] Resetando estado.")
	all_houses.clear()
	all_npcs.clear()

# --- REGISTRO ---
func register_house(house_node: House):
	if not all_houses.has(house_node):
		all_houses.append(house_node)
		print("Casa '%s' registrada. Total: %d" % [house_node.name, all_houses.size()])

func register_npc(npc: NPC):
	if not all_npcs.has(npc):
		all_npcs.append(npc)

func register_building(building_node):
	var type = building_node.get_class() # Pega o tipo do script (ex: "TrainingArea")
	if not building_counts.has(type):
		building_counts[type] = 0 # Inicializa o contador se for o primeiro do tipo
	building_counts[type] += 1
	print("Censo atualizado: %s agora tem %d instâncias." % [type, building_counts[type]])

# ADICIONADO: Função para remover uma construção do censo.
func unregister_building(building_node):
	var type = building_node.get_class()
	if building_counts.has(type) and building_counts[type] > 0:
		building_counts[type] -= 1
		print("Censo atualizado: %s agora tem %d instâncias." % [type, building_counts[type]])

# ADICIONADO: Funções para a UI verificar o limite.
func get_build_count_for_type(type: String) -> int:
	return building_counts.get(type, 0) # Retorna 0 se o tipo ainda não existir no censo.

# --- CONSTRUÇÃO ---
func build_structure(structure_scene: PackedScene, build_position: Vector2):
	if not structure_scene:
		printerr("Tentativa de construir uma estrutura sem cena válida!")
		return

	var temp_instance = structure_scene.instantiate()
	var build_cost = temp_instance.get("cost")
	temp_instance.queue_free()
	
	if build_cost and not StatusManager.has_enough_resources(build_cost):
		print("Construção cancelada no último segundo. Recursos se esgotaram.")
		# Na UI, o jogador não deve ver isso, mas é uma boa segurança.
		return

	# Se a verificação passou, gasta os recursos e constrói.
	if build_cost:
		StatusManager.spend_resources(build_cost)

	var new_structure = structure_scene.instantiate()
	get_tree().current_scene.add_child(new_structure)
	new_structure.global_position = build_position
	print("--> Construído '%s' em %s" % [new_structure.name, build_position])
	
	register_building(new_structure)

	new_structure.confirm_construction()

	if not new_structure is House:
		_spawn_npcs_for_workplace(new_structure)

func build_house(house_scene: PackedScene, build_position: Vector2):
	if not house_scene:
		printerr("Tentativa de construir casa sem cena válida!")
		return

	var new_house = house_scene.instantiate()
	get_tree().current_scene.add_child(new_house)
	new_house.global_position = build_position
	print("--> Construída casa '%s' em %s" % [new_house.name, build_position])

func build_workplace(workplace_scene: PackedScene, build_position: Vector2):
	if not workplace_scene:
		printerr("Tentativa de construir local de trabalho sem cena válida!")
		return
		
	print(building_counts)	

	var new_workplace = workplace_scene.instantiate()
	get_tree().current_scene.add_child(new_workplace)
	new_workplace.global_position = build_position
	print("--> Construído local '%s' em %s" % [new_workplace.name, build_position])

	_spawn_npcs_for_workplace(new_workplace)

# --- NPCs ---
func _spawn_npcs_for_workplace(workplace_node):
	print("--> Verificando NPCs para '%s'" % workplace_node.name)

	# MODIFICADO: A verificação de npc_count agora vem PRIMEIRO.
	# Todas as suas construções têm a variável npc_count, então esta linha é segura.
	var npc_count = workplace_node.npc_count
	
	# Se a construção não gera NPCs (npc_count == 0), nós paramos aqui.
	if npc_count == 0:
		print("--> Nenhum NPC será gerado para esta construção.")
		return

	# Se chegamos até aqui, significa que npc_count > 0.
	# Agora sim é seguro acessar a variável npc_scene_to_spawn.
	var npc_scene = workplace_node.npc_scene_to_spawn

	# Verificação de segurança extra caso a cena não tenha sido definida no inspetor.
	if not npc_scene:
		printerr("--> ERRO: '%s' deveria gerar %d NPCs, mas a cena do NPC não foi definida!" % [workplace_node.name, npc_count])
		return

	var current_scene = get_tree().current_scene
	var nav_map = get_tree().root.get_world_2d().navigation_map

	for i in npc_count:
		var npc = npc_scene.instantiate()
		current_scene.add_child(npc)

		var desired_pos = workplace_node.global_position + Vector2(randf_range(-30, 30), randf_range(50, 80))
		var safe_pos = NavigationServer2D.map_get_closest_point(nav_map, desired_pos)
		npc.global_position = safe_pos
		print("--> NPC #%d gerado em %s" % [i + 1, safe_pos])

		npc.work_node = workplace_node

		var house = _find_house_with_space()
		if house:
			npc.house_node = house
			print("--> NPC #%d recebeu casa '%s'" % [i + 1, house.name])
			house.add_resident(npc)
		else:
			print("AVISO: Nenhuma casa disponível para NPC #%d" % [i + 1])

		register_npc(npc)

func get_available_housing_space() -> int:
	var total_space = 0
	for house in all_houses:
		if is_instance_valid(house):
			# Vagas = Capacidade da casa - número de moradores atuais
			total_space += house.capacity - house.residents.size()
	
	print("[Quilombo Manager] Espaços de moradia disponíveis: %d" % total_space)
	return total_space

# --- Busca ---
func _find_house_with_space() -> House:
	for house in all_houses:
		if is_instance_valid(house) and house.residents.size() < house.capacity:
			return house
	return null
