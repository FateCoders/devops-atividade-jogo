# Hud.gd
extends Control
class_name Hud

signal placement_preview_started(bonuses: Dictionary)
signal placement_preview_ended()

const PlantationScene = preload("res://Scenes/UI/Assets/Sprites/Builds/plowed.tscn")
const HouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/tall_house.tscn")
const HidingPlaceScene = preload("res://Scenes/UI/Assets/Sprites/Builds/hiding_place.tscn")
const InfirmaryScene = preload("res://Scenes/UI/Assets/Sprites/Builds/infirmary.tscn")
const TrainingAreaScene = preload("res://Scenes/UI/Assets/Sprites/Builds/trainingArea.tscn")
const ChurchScene = preload("res://Scenes/UI/Assets/Sprites/Builds/church.tscn")
const LeadersHouseScene = preload("res://Scenes/UI/Assets/Sprites/Builds/leaders_house.tscn")
const QuilomboListScene = preload("res://Scenes/UI/QuilomboListUI.tscn")
const EscamboScene = preload("res://Scenes/UI/EscamboUI.tscn")

var is_in_placement_mode: bool = false
var scene_to_place: PackedScene = null
var placement_preview = null 
var notification_tween: Tween
var build_buttons: Dictionary = {}
var hover_candidates: Array[NPC] = []
var currently_highlighted_npc: NPC = null
var main_ui_panels: Dictionary = {}

@onready var health_bar = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/HealthContainer/Control/ProgressBar
@onready var hunger_bar = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/HungerContainer/Control/ProgressBar
@onready var security_bar = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/SecurityContainer/Control/ProgressBar
@onready var relations_bar = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/RelationsContainer/Control/ProgressBar

@onready var money_label = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/VBoxContainer/MoneyContainer/MoneyLabel
@onready var population_label = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/VBoxContainer/PopulationContainer/PopulationLabel
@onready var hunger_label = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/HungerContainer/HungerLabel

@onready var health_preview_bar = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/HealthContainer/Control/PreviewBar
@onready var hunger_preview_bar = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/HungerContainer/Control/PreviewBar
@onready var security_preview_bar = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/SecurityContainer/Control/PreviewBar
@onready var relations_preview_bar = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/RelationsContainer/Control/PreviewBar

@onready var health_icon = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/HealthContainer/HealthIcon
@onready var hunger_icon = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/HungerContainer/HungerIcon
@onready var relations_icon = $MainContainer/HBoxContainer/StatusPanel/VBoxContainer/RelationsContainer/RelationsIcon

@onready var status_panel = $MainContainer/HBoxContainer/StatusPanel
@onready var build_button = $MainContainer/ButtonsPanel/SectionsPanel/ButtonOptions/BuildButton
@onready var build_button_icon = $MainContainer/ButtonsPanel/SectionsPanel/ButtonOptions/BuildButton/TextureRect
@onready var button_builds = $MainContainer/ButtonsPanel/SectionsPanel/ButtonBuildsOptions

@onready var button_inventory = $MainContainer/ButtonsPanel/SectionsPanel/ButtonOptions/InventoryButton
@onready var inventory_button_icon = $MainContainer/ButtonsPanel/SectionsPanel/ButtonOptions/InventoryButton/TextureRect
@onready var button_inventorys = $MainContainer/ButtonsPanel/SectionsPanel/ButtonInventoryOptions
@onready var list_container = $MainContainer/ButtonsPanel/SectionsPanel/ButtonInventoryOptions/ScrollContainer/ItemList

@onready var notification_container: VBoxContainer = $NotificationContainer
@onready var notification_label: Label = $NotificationContainer/PanelContainer/NotificationLabel
@onready var timer_bar: ColorRect = $NotificationContainer/TimerBar
@onready var notification_timer: Timer = $NotificationTimer
@onready var construction_title = $BuildTitleLabel
@onready var day_label = $DayContainer/DayLabel

@onready var dialog_screen = $DialogScreen
@onready var profession_screen = $ProfessionAssignmentScreen

@onready var npc_inspector_panel = $MainContainer/HBoxContainer/NPCInspectorPanel
@onready var npc_sprite = $MainContainer/HBoxContainer/NPCInspectorPanel/VBoxContainer/HBoxContainer/NPCSprite
@onready var npc_name_label = $MainContainer/HBoxContainer/NPCInspectorPanel/VBoxContainer/HBoxContainer/VBoxContainer/NPCNameLabel
@onready var npc_profession_label = $MainContainer/HBoxContainer/NPCInspectorPanel/VBoxContainer/HBoxContainer/VBoxContainer/NPCProfessionLabel
@onready var npc_workplace_label = $MainContainer/HBoxContainer/NPCInspectorPanel/VBoxContainer/HBoxContainer/VBoxContainer/NPCWorkplaceLabel
@onready var npc_state_label = $MainContainer/HBoxContainer/NPCInspectorPanel/VBoxContainer/NPCStateLabel

const BUILD_TEXTURE = preload("res://Assets/Sprites/Exported/Buttons/button-base.png")
const INVENTORY_TEXTURE = preload("res://Assets/Sprites/Exported/Buttons/button-base.png")
const CLOSE_TEXTURE = preload("res://Assets/Sprites/Exported/Buttons/close-button.png")
const BUILD_CURSOR = preload("res://Assets/Sprites/Exported/HUD/Cursors/build_cursor-menor.png")
const INVENTORY_ICON = preload("res://Assets/Sprites/Exported/HUD/Icons/invetory-icon.png")
const CURSOR_HOTSPOT = Vector2(16, 16)
const DEFAULT_CURSOR = preload("res://Assets/Sprites/Exported/HUD/Cursors/default_cursor-menor.png")
const DEFAULT_CURSOR_HOTSPOT = Vector2(4, 4)
const LOW_RELATIONS_COLOR = Color("#ff163f")
const DEFAULT_RELATIONS_COLOR = Color("#309cff")
const HEALTH_ICON_NORMAL = preload("res://Assets/Sprites/Exported/HUD/Icons/health-icon.png")
const HEALTH_ICON_LOW = preload("res://Assets/Sprites/Exported/HUD/Icons/unhealth-icon.png")
const HUNGER_ICON_NORMAL = preload("res://Assets/Sprites/Exported/HUD/Icons/chicken-icon.png")
const HUNGER_ICON_LOW = preload("res://Assets/Sprites/Exported/HUD/Icons/bone-icon.png")
const RELATIONS_ICON_NORMAL = preload("res://Assets/Sprites/Exported/HUD/Icons/positive-relation-icon.png")
const RELATIONS_ICON_LOW = preload("res://Assets/Sprites/Exported/HUD/Icons/negative-relation-icon.png")
const MONEY_ICON = preload("res://Assets/Sprites/Exported/HUD/Icons/gold-coin-icon.png")

const STATUS_DATA = {
	NPC.State.PASSEANDO: {"text": "Passeando...", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.INDO_PARA_CASA: {"text": "Indo para casa.", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.TRABALHANDO: {"text": "Trabalhando...", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.OCIOSO: {"text": "Descansando.", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.EM_CASA: {"text": "Dormindo...", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},

	NPC.State.SAINDO_DE_CASA: {"text": "Saindo de casa...", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.INDO_PARA_O_TRABALHO: {"text": "A caminho do trabalho.", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.REAGINDO_AO_JOGADOR: {"text": "Interagindo!", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.DESABRIGADO: {"text": "Desabrigado!", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
	NPC.State.DESEMPREGADO: {"text": "Sem local para trabalhar!", "icon": "res://Assets/Sprites/Exported/HUD/Cursors/dialogue_cursor-menor.png"},
}

const WORKPLACE_NAMES = {
	PlantationScene.resource_path: "Plantação",
	InfirmaryScene.resource_path: "Enfermaria",
	TrainingAreaScene.resource_path: "Área de Treinamento",
	ChurchScene.resource_path: "Centro Espiritual",
	LeadersHouseScene.resource_path: "Casa do Líder"
}

var InventoryItemScene = preload("res://Scenes/UI/InventoryItem.tscn")
var currently_inspected_npc: NPC = null

func _ready():
	StatusManager.status_updated.connect(_on_status_updated)
	QuilomboManager.npc_count_changed.connect(_on_npc_count_changed)
	WorldTimeManager.day_passed.connect(_on_day_passed)
	notification_timer.timeout.connect(_on_notification_timer_timeout)
	notification_container.modulate.a = 0.0
	construction_title.visible = false 
	_on_status_updated()

	var button_scene_map = {
		"BuildLeadersHouseButton": LeadersHouseScene,
		"BuildHouseButton": HouseScene,
		"BuildHidingPlaceButton": HidingPlaceScene,
		"BuildPlantetionButton": PlantationScene,
		"BuildInfirmaryButton": InfirmaryScene,
		"BuildTrainingAreaButton": TrainingAreaScene,
		"BuildChurchButton": ChurchScene
	}
	
	GameManager.tutorial_step_changed.connect(update_build_buttons_for_tutorial)

	var found_buttons_array = button_builds.find_children("*", "styledButton")
	for button in found_buttons_array:
		if button.name in button_scene_map:
			var scene = button_scene_map[button.name]
			button.pressed.connect(_on_any_build_button_pressed.bind(scene))
			
			build_buttons[scene.resource_path] = button
			
			var temp_instance = scene.instantiate()
			var structure_cost: Dictionary = {}
			if "cost" in temp_instance: structure_cost = temp_instance.cost
			temp_instance.queue_free()
			if structure_cost.has("dinheiro"):
				var cost_amount = structure_cost["dinheiro"]
				button.set_cost_value(cost_amount)
				button.cost_icon.texture = MONEY_ICON
				button.set_cost_visible(true)
	
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	QuilomboManager.fugitives_awaiting_assignment.connect(_on_fugitives_awaiting_assignment)

	main_ui_panels = {
		button_builds: {
			"button": build_button,
			"icon_node": build_button_icon,
			"base_texture": BUILD_TEXTURE
		},
		button_inventorys: {
			"button": button_inventory,
			"icon_node": inventory_button_icon,
			"base_texture": INVENTORY_TEXTURE 
		}
	}

	for panel in main_ui_panels:
		panel.visible = false

func _process(delta: float):
	_update_cursor_state()

	if not is_in_placement_mode or not is_instance_valid(placement_preview):
		return
	placement_preview.global_position = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	var is_valid_position = _check_valid_placement()
	if is_valid_position:
		placement_preview.modulate = Color(0.5, 1, 0.5, 0.7)
	else:
		placement_preview.modulate = Color(1, 0.5, 0.5, 0.7)
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_SPACE:
			self.visible = not self.visible
			get_viewport().set_input_as_handled()
			return

	if is_in_placement_mode:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			if _check_valid_placement():
				var build_pos = placement_preview.global_position
				
				if scene_to_place == HouseScene:
					QuilomboManager.build_house(scene_to_place, build_pos)
				else:
					QuilomboManager.build_structure(scene_to_place, build_pos)
				
				_exit_placement_mode()
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			_exit_placement_mode()

func update_build_buttons_for_tutorial(step_data: Dictionary):
	var enabled_builds = step_data.get("enabled_builds", [])
	if enabled_builds.is_empty():
		for button in build_buttons.values():
			if is_instance_valid(button):
				button.visible = true
		return
	
	for button in build_buttons.values():
		if is_instance_valid(button):
			button.visible = false
	
	for scene in enabled_builds:
		var scene_path = scene.resource_path
		if build_buttons.has(scene_path):
			var button_to_show = build_buttons[scene_path]
			if is_instance_valid(button_to_show):
				button_to_show.visible = true

func show_tutorial_dialog(data: Dictionary) -> DialogScreen:
	dialog_screen.setup_dialog(data)
	dialog_screen.show()
	return dialog_screen

func _on_status_updated():
	health_bar.value = StatusManager.saude
	hunger_bar.value = StatusManager.fome
	security_bar.value = StatusManager.seguranca
	relations_bar.value = StatusManager.relacoes

	money_label.text = str(StatusManager.dinheiro)
	population_label.text = str(QuilomboManager.all_npcs.size())

	if StatusManager.fome == 100:
		hunger_label.text = "Fome (Cheio)"
	elif StatusManager.fome < 50 and StatusManager.fome > 0:
		hunger_label.text = "Fome (Faminto)"
	elif StatusManager.fome == 0:
		hunger_label.text = "Fome (Fadiga)"
	else:
		hunger_label.text = "Fome (Normal)"

	health_icon.texture = HEALTH_ICON_LOW if StatusManager.saude < 50 else HEALTH_ICON_NORMAL
	hunger_icon.texture = HUNGER_ICON_LOW if StatusManager.fome < 50 else HUNGER_ICON_NORMAL
	relations_icon.texture = RELATIONS_ICON_LOW if StatusManager.relacoes < 50 else RELATIONS_ICON_NORMAL

	var base_color = LOW_RELATIONS_COLOR if StatusManager.relacoes < 50 else DEFAULT_RELATIONS_COLOR
	_set_bar_color(relations_bar, base_color)
	var preview_color = base_color
	preview_color.a = 127 / 255.0
	_set_bar_color(relations_preview_bar, preview_color)
	clear_preview()

func show_preview(bonuses: Dictionary):
	clear_preview()
	if bonuses.has("seguranca") and bonuses.seguranca: security_preview_bar.value = security_bar.value + bonuses.seguranca
	if bonuses.has("saude") and bonuses.saude: health_preview_bar.value = health_bar.value + bonuses.saude
	if bonuses.has("relacoes") and bonuses.relacoes: relations_preview_bar.value = relations_bar.value + bonuses.relacoes
	if bonuses.has("fome") and bonuses.fome: hunger_preview_bar.value = hunger_bar.value + bonuses.hunger

func clear_preview():
	health_preview_bar.value = health_bar.value
	hunger_preview_bar.value = hunger_bar.value
	security_preview_bar.value = security_bar.value
	relations_preview_bar.value = relations_bar.value

func _set_bar_color(bar: ProgressBar, new_color: Color):
	var stylebox = bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	stylebox.bg_color = new_color
	bar.add_theme_stylebox_override("fill", stylebox)

func _on_npc_count_changed(new_count: int):
	population_label.text = str(new_count)

func _on_button_pressed():
	_toggle_main_panel(button_builds)

func _on_any_build_button_pressed(scene: PackedScene):
	QuilomboManager._debug_print_all_npc_status("Clique no Botão de Construir")

	if is_in_placement_mode:
		_exit_placement_mode()
		return

	var temp_instance = scene.instantiate()
	
	# Checagem de limite de construção (já estava correta)
	var max_allowed = temp_instance.get("max_instances")
	if max_allowed != null and max_allowed > 0:
		var current_count = QuilomboManager.get_build_count_for_type(scene.resource_path)
		if current_count >= max_allowed:
			show_notification("Limite de construções deste tipo atingido!")
			temp_instance.queue_free()
			return

	# --- INÍCIO DA NOVA LÓGICA DE VERIFICAÇÃO ---
	var npcs_needed = temp_instance.npc_count if "npc_count" in temp_instance else 0
	var build_cost = temp_instance.get("cost")
	
	# 1. Primeiro, verificamos os recursos (dinheiro, etc.)
	if build_cost and not StatusManager.has_enough_resources(build_cost):
		show_notification("Recursos insuficientes para construir!")
		temp_instance.queue_free()
		return

	# 2. Agora, a verificação inteligente de trabalhadores e casas
	if npcs_needed > 0:
		var required_profession = temp_instance.required_profession if "required_profession" in temp_instance else NPC.Profession.NENHUMA
		
		# Quantos trabalhadores qualificados já temos desempregados?
		var available_workers = QuilomboManager.count_unemployed_by_profession(required_profession)
		
		# Quantos novos trabalhadores precisarão ser gerados?
		var new_workers_to_spawn = npcs_needed - available_workers
		if new_workers_to_spawn < 0:
			new_workers_to_spawn = 0 # Não podemos gerar um número negativo
		
		# Quantas vagas em casas precisamos para esses NOVOS trabalhadores?
		var available_housing = QuilomboManager.get_available_housing_space()
		
		if available_housing < new_workers_to_spawn:
			show_notification("Casas insuficientes para os novos moradores!")
			temp_instance.queue_free()
			return
	
	# --- FIM DA NOVA LÓGICA DE VERIFICAÇÃO ---
	
	temp_instance.queue_free() # Limpa a instância temporária

	# Se todas as verificações passaram, inicia o modo de posicionamento
	button_builds.visible = false
	construction_title.visible = false
	
	GameManager.pause_game()
	is_in_placement_mode = true
	scene_to_place = scene
	placement_preview = scene.instantiate()
	get_tree().current_scene.add_child(placement_preview)
	_disable_physics(placement_preview)
	var bonuses = {
		"seguranca": placement_preview.get("security_bonus"),
		"saude": placement_preview.get("health_bonus"),
		"fome": placement_preview.get("hunger_bonus"),
		"relacoes": placement_preview.get("relations_bonus")
	}
	emit_signal("placement_preview_started", bonuses)

func _exit_placement_mode():
	if is_instance_valid(placement_preview):
		placement_preview.queue_free()

	button_builds.visible = true
	construction_title.visible = true
	GameManager.pause_game()
	Input.set_custom_mouse_cursor(BUILD_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)

	is_in_placement_mode = false
	scene_to_place = null
	placement_preview = null
	emit_signal("placement_preview_ended")

func _check_valid_placement() -> bool:
	var area: Area2D = placement_preview.get_node_or_null("Area2D")
	if not area: return true
	return area.get_overlapping_bodies().is_empty() and area.get_overlapping_areas().is_empty()

func _disable_physics(node: Node):
	if node is CollisionObject2D:
		node.collision_layer = 0
		node.collision_mask = 0
	if node is NavigationObstacle2D:
		node.avoidance_enabled = false
	for child in node.get_children():
		_disable_physics(child)
		
func show_notification(message: String, duration: float = 3.0):
	if notification_tween and notification_tween.is_valid():
		notification_tween.kill()

	notification_label.text = message
	notification_container.modulate.a = 1.0
	notification_timer.wait_time = duration
	notification_timer.start()
	timer_bar.size.x = notification_container.size.x 

	notification_tween = create_tween()
	notification_tween.tween_property(timer_bar, "size:x", 0, duration)

func _on_notification_timer_timeout():
	if notification_tween and notification_tween.is_valid():
		notification_tween.kill()

	notification_tween = create_tween()
	notification_tween.tween_property(notification_container, "modulate:a", 0.0, 0.5)

func _update_cursor_state():
	if is_in_placement_mode:
		Input.set_custom_mouse_cursor(BUILD_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	elif button_builds.visible:
		Input.set_custom_mouse_cursor(BUILD_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	else:
		Input.set_custom_mouse_cursor(DEFAULT_CURSOR, Input.CURSOR_ARROW, DEFAULT_CURSOR_HOTSPOT)

func _on_day_passed(new_day: int):
	if day_label:
		day_label.text = "Dia %02d" % new_day

func _on_fugitives_awaiting_assignment(npcs: Array):
	profession_screen.show_panel(npcs)

func show_quilombo_list():
	# Medida de segurança para garantir que não abrimos duas janelas ao mesmo tempo.
	# Procura por uma janela antiga e a remove, se existir.
	var old_list = find_child("QuilomboListUI", true, false)
	if old_list:
		old_list.queue_free()

	# Cria a nova janela da lista de quilombos.
	var list_ui = QuilomboListScene.instantiate()
	# Damos um nome para que a verificação acima possa encontrá-la.
	list_ui.name = "QuilomboListUI" 
	# Adiciona a janela à cena, tornando-a visível.
	add_child(list_ui)
	
func show_escambo_ui(quilombo_id: String):
	var escambo_ui = EscamboScene.instantiate()
	add_child(escambo_ui)
	escambo_ui.start_trade(quilombo_id)

func _on_inventory_button_pressed() -> void:
	_toggle_main_panel(button_inventorys)

	if button_inventorys.visible:
		_populate_inventory_list()

	inventory_button_icon.visible = !button_inventorys.visible
	if button_inventorys.visible:
		button_inventory.texture_normal = CLOSE_TEXTURE
	else:
		button_inventory.texture_normal = INVENTORY_TEXTURE

func _populate_inventory_list():
	for child in list_container.get_children():
		child.queue_free()

	var player_inventory = StatusManager.get_all_resources()

	for resource_name in player_inventory:
		var amount = player_inventory[resource_name]

		if amount > 0 or resource_name == "dinheiro":
			var item = InventoryItemScene.instantiate()
			list_container.add_child(item)
			item.set_data(resource_name, amount)

func show_npc_inspector(npc_ref: NPC):
	if not is_instance_valid(npc_ref):
		hide_npc_inspector()
		return

	if is_instance_valid(currently_inspected_npc):
		if currently_inspected_npc.state_changed.is_connected(_on_inspected_npc_state_changed):
			currently_inspected_npc.state_changed.disconnect(_on_inspected_npc_state_changed)

	currently_inspected_npc = npc_ref
	currently_inspected_npc.state_changed.connect(_on_inspected_npc_state_changed)

	_update_npc_inspector_panel()
	npc_inspector_panel.show()

func report_npc_hover(npc: NPC):
	if not hover_candidates.has(npc):
		hover_candidates.append(npc)
	_update_highlight()
	
func report_npc_unhover(npc: NPC):
	if hover_candidates.has(npc):
		hover_candidates.erase(npc)
	_update_highlight()
	
func _update_highlight():
	var topmost_npc: NPC = null

	if not hover_candidates.is_empty():
		hover_candidates.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
		topmost_npc = hover_candidates.back()

	if topmost_npc != currently_highlighted_npc:
		if is_instance_valid(currently_highlighted_npc):
			currently_highlighted_npc.highlight_off()

		if is_instance_valid(topmost_npc):
			topmost_npc.highlight_on()

		currently_highlighted_npc = topmost_npc

func _on_close_button_pressed():
	hide_npc_inspector()

func hide_npc_inspector():
	if is_instance_valid(currently_inspected_npc):
		if currently_inspected_npc.state_changed.is_connected(_on_inspected_npc_state_changed):
			currently_inspected_npc.state_changed.disconnect(_on_inspected_npc_state_changed)
	
	currently_inspected_npc = null

	if is_instance_valid(npc_inspector_panel):
		npc_inspector_panel.hide()
	
	if is_instance_valid(currently_highlighted_npc):
		currently_highlighted_npc.highlight_off()
		currently_highlighted_npc = null
	
	hover_candidates.clear()
	
func _on_inspected_npc_state_changed(npc_ref: NPC):
	if npc_inspector_panel.visible and npc_ref == currently_inspected_npc:
		print("HUD: Recebido update de estado de %s. Atualizando painel." % npc_ref.npc_name)
		_update_npc_inspector_panel()

func _update_npc_inspector_panel():
	if not is_instance_valid(currently_inspected_npc):
		hide_npc_inspector()
		return

	var npc_ref = currently_inspected_npc

	npc_sprite.texture = npc_ref.get_idle_sprite_texture()
	npc_name_label.text = npc_ref.npc_name
	
	var profession_key = npc_ref.profession
	var profession_name = NPC.PROFESSION_NAMES.get(profession_key, "Desconhecida")
	npc_profession_label.text = "Profissão: %s" % profession_name
	
	if is_instance_valid(npc_ref.work_node):
		var workplace_path = npc_ref.work_node.scene_file_path
		var workplace_name = WORKPLACE_NAMES.get(workplace_path, "Local Desconhecido")
		npc_workplace_label.text = "Local de Trabalho: %s" % workplace_name
	else:
		npc_workplace_label.text = "Local de Trabalho: Desempregado"
	
	var state_key = npc_ref.current_state
	if STATUS_DATA.has(state_key):
		var state_text = STATUS_DATA[state_key].text
		npc_state_label.text = "Estado: %s" % state_text
	else:
		npc_state_label.text = "Estado: Desconhecido"


func _toggle_main_panel(panel_to_toggle: Control):
	var was_open = panel_to_toggle.visible

	for panel in main_ui_panels:
		var data = main_ui_panels[panel]
		panel.visible = false
		data.icon_node.visible = true
		data.button.texture_normal = data.base_texture

	if not was_open:
		var data = main_ui_panels[panel_to_toggle]
		panel_to_toggle.visible = true
		data.icon_node.visible = false
		data.button.texture_normal = CLOSE_TEXTURE

		if panel_to_toggle == button_inventorys:
			_populate_inventory_list()
		elif panel_to_toggle == button_builds:
			construction_title.visible = true

	var any_panel_open = was_open == false
	construction_title.visible = (button_builds.visible) 
	
	if any_panel_open:
		Input.set_custom_mouse_cursor(BUILD_CURSOR, Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	else:
		Input.set_custom_mouse_cursor(DEFAULT_CURSOR, Input.CURSOR_ARROW, DEFAULT_CURSOR_HOTSPOT)
