extends Node

signal status_updated

var dinheiro = 500
var saude = 100
var fome = 100
var seguranca = 10
var relacoes = 10

var persistent_debuffs = {}

func _ready():
	emit_signal("status_updated")

func mudar_status(nome_status, valor):
	match nome_status:
		"dinheiro":
			dinheiro += valor
		"saude":
			saude = clamp(saude + valor, 0, 100)
		"fome":
			fome = clamp(fome + valor, 0, 100)
		"seguranca":
			seguranca = clamp(seguranca + valor, 0, 100)
		"relacoes":
			relacoes = clamp(relacoes + valor, 0, 100)

	emit_signal("status_updated")
	
	_check_defeat_conditions()

	print("Status alterado: ", nome_status, ", Novo valor: ", get(nome_status))
	
func _check_defeat_conditions():
	if saude <= 0 and fome <= 0:
		GameManager.game_over.emit("O quilombo sucumbiu à fome e às doenças.")

func get_status_value(nome_status):
	return get(nome_status)

func mudar_dinheiro(valor):
	dinheiro += valor
	emit_signal("status_updated")

# ADICIONADO: Nova função para verificar se temos recursos suficientes.
func has_enough_resources(costs: Dictionary) -> bool:
	for resource in costs.keys():
		var required_amount = costs[resource]
		
		var current_amount = get(resource)
		
		if current_amount == null or current_amount < required_amount:
			print("Recurso insuficiente: %s. Necessário: %d, Possui: %d" % [resource, required_amount, current_amount])
			return false
	return true

func spend_resources(costs: Dictionary):
	if not has_enough_resources(costs):
		printerr("Tentativa de gastar recursos insuficientes!")
		return

	for resource in costs.keys():
		var amount_to_spend = costs[resource]
		var current_value = get(resource)
		set(resource, current_value - amount_to_spend)
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
	var current_health_debuff = 0
	for debuff in persistent_debuffs.values():
		if debuff.type == "saude":
			current_health_debuff += debuff.value

	print("Debuff de saúde total atual: %d" % current_health_debuff)
