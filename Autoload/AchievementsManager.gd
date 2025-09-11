# AchievementsManager.gd
extends Node

# Dicionário para guardar o estado de todas as conquistas.
var achievements = {
	"reach_day_20": {
		"title": "Sobrevivente Experiente",
		"description": "Chegue até o dia 20.",
		"unlocked": false
	},
	"liberate_10_npcs": {
		"title": "Libertador",
		"description": "Alcance uma população de 10 moradores.",
		"unlocked": false
	},
	"achieve_unification": {
		"title": "Unificador dos Quilombos",
		"description": "Conquiste ou alie-se a todos os quilombos.",
		"unlocked": false
	}
	# Adicione mais conquistas aqui no futuro
}

# Sinal para anunciar quando uma conquista é desbloqueada.
signal achievement_unlocked(achievement_data)

# Função para checar e desbloquear conquistas.
# Outros scripts (como WorldTimeManager, QuilomboManager) chamarão esta função.
func check_and_unlock(achievement_id: String):
	# Se a conquista existe e ainda não foi desbloqueada...
	if achievements.has(achievement_id) and not achievements[achievement_id]["unlocked"]:
		achievements[achievement_id]["unlocked"] = true
		var data = achievements[achievement_id]
		
		print("🏆 CONQUISTA DESBLOQUEADA: ", data["title"])
		# Anuncia para a UI (para mostrar uma notificação, por exemplo).
		emit_signal("achievement_unlocked", data)

# Função para a tela de vitória pegar a lista de todas as conquistas.
func get_all_achievements() -> Dictionary:
	return achievements
