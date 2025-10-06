extends Node

signal status_updated

var recursos = {
	"dinheiro": 1000,
	"madeira": 0,
	"remedios": 0,
	"ferramentas": 0,
	"alimentos": 100,
	"libertos": 0,
}

var base_saude = 100
var base_fome = 100
var base_seguranca = 25
var base_relacoes = 50

var saude = 100
var fome = 100
var seguranca = 25
var relacoes = 50

var persistent_debuffs = {}

func _ready():
	WorldTimeManager.day_passed.connect(_on_day_passed)
	_recalculate_status()

func _on_day_passed(day_number):
	print("[StatusManager] Um dia passou. Diminuindo a fome.")
	mudar_status("fome", -5)

func mudar_status(nome_status, valor):
	if nome_status == "relacoes" and valor > 0 and GameManager.chosen_leader_type == GameManager.LeaderType.PACIFISTA:
		valor = int(valor * 1.25)
		print("Bônus do líder Pacifista: ganho de relações aumentado!")

	var base_variable_name = "base_" + nome_status
	var current_base_value = get(base_variable_name)
	
	if current_base_value is int or current_base_value is float:
		set(base_variable_name, clamp(current_base_value + valor, 0, 100))
		_recalculate_status()
		print("Status base alterado: ", nome_status, ", Novo valor base: ", get(base_variable_name))

func _check_defeat_conditions():
	if saude <= 0 and fome <= 0:
		GameManager.game_over.emit("O quilombo sucumbiu à fome e às doenças.")

func get_status_value(nome_status):
	return get(nome_status)

func mudar_recurso(nome_recurso: String, valor: int):
	if recursos.has(nome_recurso):
		recursos[nome_recurso] += valor
		emit_signal("status_updated")
	else:
		printerr("Tentativa de alterar recurso inexistente: %s" % nome_recurso)

func has_enough_resources(costs: Dictionary) -> bool:
	for resource in costs.keys():
		var required_amount = costs[resource]
		var current_amount = recursos.get(resource, 0)
		
		if current_amount < required_amount:
			print("Recurso insuficiente: %s. Necessário: %d, Possui: %d" % [resource, required_amount, current_amount])
			return false
	return true

func spend_resources(costs: Dictionary):
	if not has_enough_resources(costs):
		printerr("Tentativa de gastar recursos insuficientes!")
		return

	for resource in costs.keys():
		var amount_to_spend = costs[resource]
		recursos[resource] -= amount_to_spend
		print("Gasto: %d de %s." % [amount_to_spend, resource])
	
	emit_signal("status_updated")

func add_persistent_debuff(source_id, status_type: String, value: int):
	persistent_debuffs[source_id] = {"type": status_type, "value": value}
	_recalculate_status()

func remove_persistent_debuff(source_id):
	if persistent_debuffs.has(source_id):
		persistent_debuffs.erase(source_id)
		_recalculate_status()

func _recalculate_status():
	var total_debuffs = {
		"saude": 0,
		"fome": 0,
		"seguranca": 0,
		"relacoes": 0
	}

	for debuff in persistent_debuffs.values():
		if total_debuffs.has(debuff.type):
			total_debuffs[debuff.type] += debuff.value

	saude = clamp(base_saude + total_debuffs.saude, 0, 100)
	fome = clamp(base_fome + total_debuffs.fome, 0, 100)
	seguranca = clamp(base_seguranca + total_debuffs.seguranca, 0, 100)
	relacoes = clamp(base_relacoes + total_debuffs.relacoes, 0, 100)
	
	print("Debuffs totais recalculados: ", total_debuffs)
	print("Valores efetivos atualizados -> Saúde: %d, Relações: %d" % [saude, relacoes])

	emit_signal("status_updated")
	_check_defeat_conditions()

func get_resource(resource_name: String) -> int:
	return recursos.get(resource_name, 0)

func execute_trade(items_given: Dictionary, items_received: Dictionary):
	for resource in items_given:
		mudar_recurso(resource, -items_given[resource])

	for resource in items_received:
		mudar_recurso(resource, items_received[resource])
