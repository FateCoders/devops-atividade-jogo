extends Node

const SAVE_PATH = "user://savegame.json"

var game_data = {}


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		game_data["player_data"] = player.get_save_data()

		game_data["quilombos_manager_data"] = QuilombosManager.get_save_data()

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		printerr("Erro ao tentar abrir o arquivo de save para escrita!")
		return

	var json_string = JSON.stringify(game_data, "\t")
	
	file.store_string(json_string)
	
	file.close()
	print("Jogo salvo com sucesso em: ", SAVE_PATH)

## Carrega os dados do arquivo JSON para o jogo.
func load_game():
	# Verifica se o arquivo de save existe.
	if not FileAccess.file_exists(SAVE_PATH):
		print("Nenhum arquivo de save encontrado.")
		return false # Retorna false para indicar que não havia jogo salvo.

	# Abre o arquivo no modo de leitura.
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		printerr("Erro ao tentar abrir o arquivo de save para leitura!")
		return false

	var content = file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)

	if data == null:
		printerr("Erro ao analisar o arquivo JSON. O arquivo pode estar corrompido.")
		return false
	
	game_data = data
	
	var player = get_tree().get_first_node_in_group("player")
	if player and game_data.has("player_data"):
		player.load_data(game_data["player_data"])
		
	if game_data.has("quilombos_manager_data"):
		QuilombosManager.load_data(game_data["quilombos_manager_data"])

	print("Jogo carregado com sucesso!")
	return true
