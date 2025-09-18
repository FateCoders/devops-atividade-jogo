# QuilombosManager.gd
extends Node

# Este dicionário guardará os dados da PARTIDA ATUAL.
# É este que vamos modificar e salvar.
var current_quilombos_data: Dictionary = {}

# Estes são os "dados de fábrica", os valores iniciais.
# Eles nunca serão alterados durante o jogo.
const INITIAL_QUILOMBOS_DATA = {
	"palmares": {
		"name": "Quilombo dos Palmares",
		"relations": 50,
		"trade_offers": [
			{
				"id": "sell_food_palmares",
				"type": "sell", "item": "alimentos", "quantity": 20, "price": 30,
				"description": "Vender 20 Alimentos por 30", "available_on_day": 1
			},
			{
				"id": "buy_tools_palmares",
				"type": "buy", "item": "ferramentas", "quantity": 5, "price": 40,
				"description": "Comprar 5 Ferramentas por 40", "available_on_day": 1
			}
		]
	},
	# ... (seus outros quilombos)
}

# ADICIONADO: A função _ready() que estava faltando.
# Ela é chamada uma vez quando o jogo inicia.
func _ready():
	# Copiamos os dados iniciais para os dados da partida atual.
	# O 'true' faz uma "cópia profunda", garantindo que não seja apenas uma referência.
	current_quilombos_data = INITIAL_QUILOMBOS_DATA.duplicate(true)

# MODIFICADO: Esta função agora retorna os dados da partida atual.
func get_all_quilombos() -> Dictionary:
	return current_quilombos_data

# MODIFICADO: Esta função agora modifica os dados da partida atual.
func change_relation(quilombo_id: String, amount: int):
	if current_quilombos_data.has(quilombo_id):
		var current_relation = current_quilombos_data[quilombo_id]["relations"]
		current_quilombos_data[quilombo_id]["relations"] = clamp(current_relation + amount, 0, 100)
		print("Nova relação com '%s': %d" % [current_quilombos_data[quilombo_id]["name"], current_quilombos_data[quilombo_id]["relations"]])

# MODIFICADO: Esta função agora modifica os dados da partida atual.
# (E removi a referência a 'inventory' que não usamos mais).
func execute_trade(quilombo_id, items_given_by_them, items_received_by_them):
	# Esta função pode precisar de mais lógica dependendo do seu sistema de escambo.
	# O importante é que ela agora modifica 'current_quilombos_data'.
	change_relation(quilombo_id, 5)

func set_offer_on_cooldown(quilombo_id: String, offer_id: String, cooldown_days: int = 5):
	if not current_quilombos_data.has(quilombo_id):
		return

	for offer in current_quilombos_data[quilombo_id]["trade_offers"]:
		if offer["id"] == offer_id:
			offer["available_on_day"] = WorldTimeManager.current_day + cooldown_days
			print("Oferta '%s' de '%s' entrará em cooldown. Disponível no dia %d." % [offer_id, quilombo_id, offer["available_on_day"]])
			break

func get_save_data() -> Dictionary:
	return {
		"quilombos_data": current_quilombos_data
	}

func load_data(data: Dictionary):
	if data.has("quilombos_data"):
		current_quilombos_data = data["quilombos_data"]
		print("Dados dos quilombos carregados com sucesso.")
	else:
		printerr("Dados de quilombos não encontrados no arquivo de save.")
