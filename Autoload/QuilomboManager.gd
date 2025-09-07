# QuilomboManager.gd
extends Node

var all_houses: Array[House] = []
var all_npcs: Array[NPC] = []

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

# --- CONSTRUÇÃO ---
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

	var new_workplace = workplace_scene.instantiate()
	get_tree().current_scene.add_child(new_workplace)
	new_workplace.global_position = build_position
	print("--> Construído local '%s' em %s" % [new_workplace.name, build_position])

	# Spawna NPCs depois que o nó já está pronto
	call_deferred("_spawn_npcs_for_workplace", new_workplace)

# --- NPCs ---
func _spawn_npcs_for_workplace(workplace_node):
	print("--> Verificando NPCs para '%s'" % workplace_node.name)

	var npc_count = workplace_node.npc_count
	var npc_scene = workplace_node.npc_scene_to_spawn

	if npc_count == 0 or not npc_scene:
		print("--> Nenhum NPC será gerado.")
		return

	var current_scene = get_tree().current_scene
	var nav_map = get_tree().root.get_world_2d().navigation_map

	for i in npc_count:
		var npc = npc_scene.instantiate()
		current_scene.add_child(npc)

		# Posição segura
		var desired_pos = workplace_node.global_position + Vector2(randf_range(-30, 30), randf_range(50, 80))
		var safe_pos = NavigationServer2D.map_get_closest_point(nav_map, desired_pos)
		npc.global_position = safe_pos
		print("--> NPC #%d gerado em %s" % [i + 1, safe_pos])

		# Liga ao trabalho
		npc.work_node = workplace_node

		# Liga a uma casa se houver disponível
		var house = _find_house_with_space()
		if house:
			npc.house_node = house
			print("--> NPC #%d recebeu casa '%s'" % [i + 1, house.name])
			house.add_resident(npc)
		else:
			print("AVISO: Nenhuma casa disponível para NPC #%d" % [i + 1])

		register_npc(npc)

# --- Busca ---
func _find_house_with_space() -> House:
	for house in all_houses:
		if is_instance_valid(house) and house.residents.size() < house.capacity:
			return house
	return null
