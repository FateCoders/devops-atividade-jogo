# QuilombosManager.gd
extends Node

# Este dicionário guardará os dados da PARTIDA ATUAL.
var current_quilombos_data: Dictionary = {}

# Estes são os "dados de fábrica", os valores iniciais.
const INITIAL_QUILOMBOS_DATA = {
	"palmares": {
		"name": "Quilombo dos Palmares",
		"relations": 90,
		"trade_offers": [
			{
				"id": "sell_food_palmares", "type": "sell", "item": "alimentos",
				"quantity": 20, "price": 30, "description": "Vender 20 Alimentos por 30 Dinheiro",
				"available_on_day": 1
			},
			{
				"id": "buy_tools_palmares", "type": "buy", "item": "ferramentas",
				"quantity": 5, "price": 40, "description": "Comprar 5 Ferramentas por 40 Dinheiro",
				"available_on_day": 1
			}
		]
	},
	
	# --- NOVOS QUILOMBOS ADICIONADOS ---
	
	"camapua": {
		"name": "Quilombo de Camapuã",
		"relations": 90,
		"trade_offers": [
			{
				"id": "sell_wood_camapua", "type": "sell", "item": "madeira",
				"quantity": 50, "price": 40, "description": "Vender 50 Madeira por 40 Dinheiro",
				"available_on_day": 1
			},
			{
				"id": "buy_remedies_camapua", "type": "buy", "item": "remedios",
				"quantity": 10, "price": 25, "description": "Comprar 10 Remédios por 25 Dinheiro",
				"available_on_day": 1
			}
		]
	},

	"catucá": {
		"name": "Quilombo do Catucá",
		"relations": 90,
		"trade_offers": [
			{
				"id": "sell_remedies_catuca", "type": "sell", "item": "remedios",
				"quantity": 15, "price": 35, "description": "Vender 15 Remédios por 35 Dinheiro",
				"available_on_day": 1
			},
			{
				"id": "buy_food_catuca", "type": "buy", "item": "alimentos",
				"quantity": 40, "price": 50, "description": "Comprar 40 Alimentos por 50 Dinheiro",
				"available_on_day": 1
			}
		]
	},
	
	"curiaú": {
		"name": "Quilombo do Curiaú",
		"relations": 65,
		"trade_offers": [
			{
				"id": "sell_tools_curiau", "type": "sell", "item": "ferramentas",
				"quantity": 3, "price": 30, "description": "Vender 3 Ferramentas por 30 Dinheiro",
				"available_on_day": 1
			},
			{
				"id": "buy_wood_curiau", "type": "buy", "item": "madeira",
				"quantity": 80, "price": 60, "description": "Comprar 80 Madeira por 60 Dinheiro",
				"available_on_day": 1
			}
		]
	},

	"ivaporunduva": {
		"name": "Quilombo de Ivaporunduva",
		"relations": 25,
		"trade_offers": [
			{
				"id": "sell_food_iva", "type": "sell", "item": "alimentos",
				"quantity": 30, "price": 45, "description": "Vender 30 Alimentos por 45 Dinheiro",
				"available_on_day": 1
			},
			{
				"id": "sell_wood_iva", "type": "sell", "item": "madeira",
				"quantity": 30, "price": 25, "description": "Vender 30 Madeira por 25 Dinheiro",
				"available_on_day": 1
			}
		]
	},

	"mimbó": {
		"name": "Quilombo Mimbó",
		"relations": 55,
		"trade_offers": [
			{
				"id": "buy_remedies_mimbo", "type": "buy", "item": "remedios",
				"quantity": 25, "price": 50, "description": "Comprar 25 Remédios por 50 Dinheiro",
				"available_on_day": 1
			},
			{
				"id": "buy_tools_mimbo", "type": "buy", "item": "ferramentas",
				"quantity": 2, "price": 20, "description": "Comprar 2 Ferramentas por 20 Dinheiro",
				"available_on_day": 1
			}
		]
	}
}

func _ready():
	current_quilombos_data = INITIAL_QUILOMBOS_DATA.duplicate(true)
	pass

func start_new_game_data():
	current_quilombos_data = INITIAL_QUILOMBOS_DATA.duplicate(true)
	print("Dados para um novo jogo foram inicializados.")

func get_all_quilombos() -> Dictionary:
	return current_quilombos_data

func change_relation(quilombo_id: String, amount: int):
	if current_quilombos_data.has(quilombo_id):
		var current_relation = current_quilombos_data[quilombo_id]["relations"]
		current_quilombos_data[quilombo_id]["relations"] = clamp(current_relation + amount, 0, 100)
		print("Nova relação com '%s': %d" % [current_quilombos_data[quilombo_id]["name"], current_quilombos_data[quilombo_id]["relations"]])
		check_alliance_victory()

func execute_trade(quilombo_id, items_given_by_them, items_received_by_them):
	change_relation(quilombo_id, 5)

func set_offer_on_cooldown(quilombo_id: String, offer_id: String, cooldown_days: int = 5):
	if not current_quilombos_data.has(quilombo_id):
		return

	for offer in current_quilombos_data[quilombo_id]["trade_offers"]:
		if offer["id"] == offer_id:
			offer["available_on_day"] = WorldTimeManager.current_day + cooldown_days
			print("Oferta '%s' de '%s' entrará em cooldown. Disponível no dia %d." % [offer_id, quilombo_id, offer["available_on_day"]])
			break

func check_alliance_victory():
	var allied_quilombos_count = 0
	# Passa por todos os quilombos nos dados da partida atual.
	for quilombo_id in current_quilombos_data:
		var data = current_quilombos_data[quilombo_id]
		# Se a relação for 100 ou mais, conta como um aliado.
		if data.get("relations", 0) >= 100:
			allied_quilombos_count += 1
	
	print("[QuilombosManager] Verificando vitória por aliança. Aliados: %d/3" % allied_quilombos_count)
	
	# Se o número de aliados for 3 ou mais, avisa o GameManager.
	if allied_quilombos_count >= 3:
		# Passamos uma string para identificar o tipo de vitória.
		GameManager._trigger_victory("unification")

func get_save_data() -> Dictionary:
	return { "quilombos_data": current_quilombos_data }

func load_data(data: Dictionary):
	if data.has("quilombos_data"):
		current_quilombos_data = data["quilombos_data"]
		print("Dados dos quilombos carregados com sucesso.")
	else:
		start_new_game_data()
