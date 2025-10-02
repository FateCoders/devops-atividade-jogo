extends Node

signal status_updated

var recursos = {
	"dinheiro": 50000,
	"madeira": 20,
	"remedios": 90,
	"ferramentas": 30,
	"alimentos": 200,
	"libertos": 0,
}


var saude = 100
var fome = 100
var seguranca = 10
var relacoes = 10

var persistent_debuffs = {}

func _ready():
	emit_signal("status_updated")

func mudar_status(nome_status, valor):
	if nome_status == "relacoes" and valor > 0 and GameManager.chosen_leader_type == GameManager.LeaderType.PACIFISTA:
		valor = int(valor * 1.25) 
		print("Bônus do líder Pacifista: ganho de relações aumentado!")

	var current_value = get(nome_status)
	if current_value is int or current_value is float:
		set(nome_status, clamp(current_value + valor, 0, 100))
		emit_signal("status_updated")
		_check_defeat_conditions()
		print("Status alterado: ", nome_status, ", Novo valor: ", get(nome_status))

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

	# Aplica os debuffs aos status base (essa parte é conceitual,
	# você precisaria de uma lógica de 'status base' vs 'status atual',
	# por enquanto vamos apenas aplicar a mudança e emitir o sinal).
	# Exemplo simples de aplicação:
	for status_type in total_debuffs:
		# Esta linha é um exemplo, a lógica real pode precisar ser mais complexa
		# dependendo de como você quer que os debuffs interajam com os status.
		# Por enquanto, vamos assumir que o debuff é um modificador constante.
		pass # A lógica de aplicação real dependeria de como você gerencia os status base.

	print("Debuffs totais recalculados: ", total_debuffs)
	emit_signal("status_updated")

func get_resource(resource_name: String) -> int:
	return recursos.get(resource_name, 0)

func execute_trade(items_given: Dictionary, items_received: Dictionary):
	# Remove os itens que o jogador deu
	for resource in items_given:
		set(resource, get(resource) - items_given[resource])
	
	# Adiciona os itens que o jogador recebeu
	for resource in items_received:
		set(resource, get(resource) + items_received[resource])

	emit_signal("status_updated")
