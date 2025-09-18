# QuilomboManager.gd
extends Node

signal npc_count_changed(new_count: int)
signal fugitives_awaiting_assignment(npcs: Array)

const NPC_SPAWN_SPACING: float = 40.0

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
		npc_count_changed.emit(all_npcs.size())

func register_building(building_node):
	var type = building_node.scene_file_path
	if not building_counts.has(type):
		building_counts[type] = 0
	building_counts[type] += 1
	print("Censo atualizado: %s agora tem %d instâncias." % [type.get_file(), building_counts[type]])
	
	if building_node.has_signal("vacancy_opened"):
		building_node.vacancy_opened.connect(_on_vacancy_opened)

# ADICIONADO: Função para remover uma construção do censo.
func unregister_building(building_node):
	var type = building_node.scene_file_path
	if building_counts.has(type) and building_counts[type] > 0:
		building_counts[type] -= 1
		print("Censo atualizado: %s agora tem %d instâncias." % [type.get_file(), building_counts[type]])

# ADICIONADO: Funções para a UI verificar o limite.
func get_build_count_for_type(scene_path: String) -> int:
	return building_counts.get(scene_path, 0)

func count_unemployed_by_profession(profession: NPC.Profession) -> int:
	var count = 0
	for npc in all_npcs:
		var is_available = npc.current_state in [NPC.State.DESEMPREGADO, NPC.State.OCIOSO, NPC.State.PASSEANDO, NPC.State.DESABRIGADO, NPC.State.EM_CASA]
		if is_instance_valid(npc) and is_available and npc.profession == profession:
			count += 1
	return count

# --- CONSTRUÇÃO ---
func build_structure(structure_scene: PackedScene, build_position: Vector2):
	if not structure_scene:
		printerr("Tentativa de construir uma estrutura sem cena válida!")
		return

	# A verificação de custo ainda é importante e pode ser feita aqui ou na UI.
	var temp_instance = structure_scene.instantiate()
	var build_cost = temp_instance.get("cost")
	if build_cost and not StatusManager.has_enough_resources(build_cost):
		print("Construção cancelada: Recursos insuficientes.")
		temp_instance.queue_free()
		return
	
	# Se passou, gasta os recursos e constrói de fato.
	if build_cost:
		StatusManager.spend_resources(build_cost)
	temp_instance.queue_free()

	var new_structure = structure_scene.instantiate()
	get_tree().current_scene.add_child(new_structure)
	new_structure.global_position = build_position
	print("--> Construído '%s' em %s" % [new_structure.name, build_position])
	
	register_building(new_structure)
	GameManager.check_tutorial_progress(structure_scene)

	var vacancies = new_structure.get("npc_count") if "npc_count" in new_structure else 0
	if vacancies > 0:
		var required_profession = new_structure.get("required_profession") if "required_profession" in new_structure else NPC.Profession.NENHUMA
		
		# --- LÓGICA DE PREENCHIMENTO INTELIGENTE ---
		
		# 1. Encontra e atribui todos os desempregados qualificados que puder.
		var unemployed_to_assign = _find_unemployed_npcs(required_profession, vacancies)
		for npc in unemployed_to_assign:
			print("Atribuindo NPC desempregado existente '%s' à nova construção." % npc.name)
			npc.assign_work(new_structure)
			
		# 2. Calcula quantos novos NPCs ainda precisam ser gerados.
		var amount_to_spawn = vacancies - unemployed_to_assign.size()
		
		# 3. Gera apenas os NPCs restantes, se houver necessidade.
		if amount_to_spawn > 0:
			print("Ainda restam %d vagas. Gerando novos NPCs para completar." % amount_to_spawn)
			# Usamos a função que você já tem, mas com a quantidade calculada.
			_spawn_npcs_for_workplace(new_structure, amount_to_spawn)

func build_house(house_scene: PackedScene, build_position: Vector2):
	if not house_scene:
		printerr("Tentativa de construir casa sem cena válida!")
		return

	var new_house = house_scene.instantiate()
	get_tree().current_scene.add_child(new_house)
	new_house.global_position = build_position
	print("--> Construída casa '%s' em %s" % [new_house.name, build_position])

	# --- INÍCIO DA DEPURAÇÃO ---
	print("\n[DEBUG] Iniciando processo de alocação de desabrigados...")
	
	# 1. Vamos ver se estamos encontrando algum desabrigado.
	var homeless_npcs = _find_homeless_npcs()
	print("[DEBUG 1] Função _find_homeless_npcs foi chamada. NPCs desabrigados encontrados: %d" % homeless_npcs.size())
	
	# 2. Vamos checar a condição para entrar no loop.
	if not homeless_npcs.is_empty():
		print("[DEBUG 2] A lista de desabrigados não está vazia. Iniciando o processo de acolhimento...")
		
		for npc in homeless_npcs:
			# 3. Para cada NPC, vamos checar a lotação da casa.
			print("[DEBUG 3] Processando o NPC: %s. Verificando vagas na casa. Lotação atual: %d/%d" % [npc.name, new_house.residents.size(), new_house.capacity])
			
			if new_house.residents.size() < new_house.capacity:
				# 4. Se houver vaga, vamos confirmar a atribuição.
				print("[DEBUG 4] Vaga encontrada! Chamando npc.assign_house() para %s." % npc.name)
				npc.assign_house(new_house)
			else:
				print("[DEBUG X] A casa já está cheia. Não é possível abrigar %s." % npc.name)
				break
	else:
		print("[DEBUG 2] A lista de desabrigados está vazia. Processo de alocação encerrado.")

	print("[DEBUG] Fim do processo de alocação.\n")

# --- NPCs ---
func _spawn_npcs_for_workplace(workplace_node, amount_to_spawn: int):
	print("--> Gerando %d novos NPCs para '%s'" % [amount_to_spawn, workplace_node.name])

	var npc_scene = workplace_node.npc_scene_to_spawn
	if not npc_scene:
		printerr("--> ERRO: '%s' deveria gerar NPCs, mas a cena do NPC não foi definida!" % workplace_node.name)
		return

	var current_scene = get_tree().current_scene
	var nav_map = get_tree().root.get_world_2d().navigation_map
	
	var base_spawn_pos = workplace_node.global_position + Vector2(0, 65)
	
	# A lógica de formação agora usa 'amount_to_spawn'
	var total_formation_width = (amount_to_spawn - 1) * NPC_SPAWN_SPACING
	var start_offset_x = -total_formation_width / 2.0
	
	# O laço 'for' agora usa 'amount_to_spawn'
	for i in amount_to_spawn:
		var npc = npc_scene.instantiate()
		current_scene.add_child(npc)
		
		var current_offset_x = start_offset_x + (i * NPC_SPAWN_SPACING)
		var desired_pos = base_spawn_pos + Vector2(current_offset_x, 0)
		
		var safe_pos = NavigationServer2D.map_get_closest_point(nav_map, desired_pos)
		npc.global_position = safe_pos
		print("--> Novo NPC #%d gerado em %s" % [i + 1, safe_pos])

		npc.work_node = workplace_node

		var house = _find_house_with_space()
		if house:
			npc.assign_house(house)
		else:
			print("AVISO: Nenhuma casa disponível para o novo NPC #%d" % [i + 1])

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

func spawn_new_fugitives(amount: int):
	print("Acolhendo %d novos fugitivos no quilombo..." % amount)
	
	# 1. Crie uma lista com todas as cenas de NPC possíveis para este evento.
	#    !!! AJUSTE OS CAMINHOS ABAIXO PARA APONTAR PARA SUAS CENAS DE NPC !!!
	const FUGITIVE_NPC_SCENES = [
		preload("res://Scenes/Characters/citizen_09.tscn"),
		preload("res://Scenes/Characters/citizen_08.tscn"),
		preload("res://Scenes/Characters/citizen_07.tscn"),
		preload("res://Scenes/Characters/citizen_06.tscn"),
		preload("res://Scenes/Characters/citizen_05.tscn"),
		preload("res://Scenes/Characters/citizen_04.tscn"),
		preload("res://Scenes/Characters/citizen_03.tscn"),
		preload("res://Scenes/Characters/citizen_02.tscn"),
		preload("res://Scenes/Characters/citizen_01.tscn"),
		# Adicione quantas cenas de NPC você quiser aqui
	]
	
	# Verificação de segurança caso a lista esteja vazia.
	if FUGITIVE_NPC_SCENES.is_empty():
		printerr("Nenhuma cena de NPC foi definida na lista para gerar fugitivos.")
		return
		
	var new_fugitives: Array[NPC] = []

	var current_scene = get_tree().current_scene
	var arrival_point = Vector2(0, 200) 
	
	var total_formation_width = (amount - 1) * NPC_SPAWN_SPACING
	var start_offset_x = -total_formation_width / 2.0

	for i in amount:
		var random_npc_scene = FUGITIVE_NPC_SCENES.pick_random()
		var npc = random_npc_scene.instantiate()
		current_scene.add_child(npc)
		
		var current_offset_x = start_offset_x + (i * NPC_SPAWN_SPACING)
		var spawn_pos = arrival_point + Vector2(current_offset_x, 0)
		npc.global_position = spawn_pos
		
		npc.profession = NPC.Profession.NENHUMA
		var house = _find_house_with_space()

		if house:
			npc.assign_house(house) 
		
		register_npc(npc)
		new_fugitives.append(npc)

	var game_ui = get_tree().root.get_node_or_null("GameUI")
	if game_ui:
		game_ui.show_notification("%d novos moradores chegaram!" % amount)
	
	if not new_fugitives.is_empty():
		emit_signal("fugitives_awaiting_assignment", new_fugitives)

func find_work_for_npc(npc: NPC):
	if not is_instance_valid(npc) or npc.profession == NPC.Profession.NENHUMA:
		return

	print("'%s' está procurando trabalho como %s..." % [npc.name, NPC.Profession.keys()[npc.profession]])
	var workplace = _find_workplace_with_vacancies(npc.profession)
	
	if is_instance_valid(workplace):
		print("--> Vaga encontrada em '%s'!" % workplace.name)
		npc.assign_work(workplace)
		if workplace.has_method("add_worker"):
			workplace.add_worker(npc)
	else:
		print("--> Nenhuma vaga de trabalho encontrada no momento.")

func _find_workplace_with_vacancies(profession: NPC.Profession):
	for node in get_tree().get_nodes_in_group("buildings"):
		if not node is House and is_instance_valid(node):
			var required_prof = node.get("required_profession")
			var capacity = node.get("npc_count")
			var current_workers = node.get("workers").size() if "workers" in node else 0
			
			if required_prof == profession and current_workers < capacity:
				return node
	return null

func on_leader_lost():
	GameManager.game_over.emit("Seu líder foi capturado ou morto. O quilombo se desfez.")

func _find_unemployed_npcs(profession: NPC.Profession, limit: int) -> Array[NPC]:
	var found_npcs: Array[NPC] = []
	for npc in all_npcs:
		if found_npcs.size() >= limit:
			break 

		var is_available = npc.current_state in [NPC.State.DESEMPREGADO, NPC.State.OCIOSO, NPC.State.PASSEANDO, NPC.State.DESABRIGADO, NPC.State.EM_CASA]
		
		if is_instance_valid(npc) and is_available and npc.profession == profession:
			found_npcs.append(npc)
			
	print("Encontrados %d NPCs desempregados com a profissão %s" % [found_npcs.size(), NPC.Profession.keys()[profession]])
	return found_npcs


func _debug_print_all_npc_status(origem_da_chamada: String):
	print("==============================================================")
	print(">>> VERIFICAÇÃO DE ESTADO DOS NPCS (Origem: %s) <<<" % origem_da_chamada)
	print("Total de NPCs no quilombo: %d" % all_npcs.size())
	
	if all_npcs.is_empty():
		print("Nenhum NPC para verificar.")
		print("==============================================================")
		return

	for npc in all_npcs:
		if not is_instance_valid(npc):
			print(" - NPC inválido encontrado na lista.")
			continue
		
		# Converte os enums (números) para texto para ficar legível
		var estado_texto = NPC.State.keys()[npc.current_state]
		var profissao_texto = NPC.Profession.keys()[npc.profession]
		
		print(" - NPC: '%s' | Estado: %s | Profissão: %s" % [npc.name, estado_texto, profissao_texto])
	
	print("==============================================================")

func _find_homeless_npcs() -> Array[NPC]:
	var homeless: Array[NPC] = []
	for npc in all_npcs:
		# Um NPC é considerado desabrigado se for válido e seu estado for DESABRIGADO
		if is_instance_valid(npc) and npc.current_state == NPC.State.DESABRIGADO:
			homeless.append(npc)
	return homeless

func _on_vacancy_opened(profession: NPC.Profession):
	print("[Quilombo Manager] Vaga aberta para a profissão: %s" % NPC.Profession.keys()[profession])
	
	# Procura por um NPC desempregado com a profissão necessária
	for npc in all_npcs:
		if is_instance_valid(npc) and npc.current_state == NPC.State.DESEMPREGADO and npc.profession == profession:
			print("--> Desempregado qualificado encontrado: '%s'. Enviando para a vaga..." % npc.name)
			
			# Usa a função que já existe para fazer a mágica acontecer!
			find_work_for_npc(npc)
			
			# Importante: para o loop assim que encontra o primeiro candidato
			# para não enviar todos os desempregados para a mesma vaga.
			return
			
	print("--> Nenhum desempregado qualificado encontrado no momento.")
