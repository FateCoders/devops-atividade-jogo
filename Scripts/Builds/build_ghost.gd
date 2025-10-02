# devops-atividade-jogo/Scripts/Builds/building_ghost.gd

extends Area2D
class_name BuildingGhost

# Esta variável pode ser usada no futuro se você quiser que o fantasma
# desconsidere certos tipos de objetos. Por enquanto, a lógica principal
# está no hud.gd, que verifica qualquer corpo ou área sobreposta.

func _ready():
	# Garante que a monitorização esteja ativa para que a Area2D possa
	# detectar outras áreas e corpos. Isso geralmente é ativado por padrão.
	monitoring = true

# A função principal que faz a mágica acontecer está em hud.gd: _check_valid_placement()
# Ela pega a instância desta cena (o placement_preview) e chama get_overlapping_bodies()
# e get_overlapping_areas() para ver se a posição é válida.

# O hud.gd também é responsável por mudar a cor (modulate) do fantasma
# para verde ou vermelho, dependendo se a posição é válida ou não.
