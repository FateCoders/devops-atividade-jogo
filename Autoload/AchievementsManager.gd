# AchievementsManager.gd
extends Node

var achievements = {
	"reach_day_20": {
		"title": "Sobrevivente Experiente",
		"unlocked": true,
		"tooltip_data": {
			# Descrição de sucesso
			"tooltip": "Sobrevivente Experiente: Você liderou
			 o quilombo por 20 dias desafiadores.",
			# ADICIONADO: Descrição de objetivo
			"locked_tooltip": "Sobreviva por 20 dias.",
			"icon": "res://Assets/Sprites/Exported/HUD/Icons/star-on-icon.png"
		}
	},
	"liberate_10_npcs": {
		"title": "Libertador",
		"unlocked": false,
		"tooltip_data": {
			"tooltip": "Libertador: sua comunidade cresceu para 10 
			moradores, um porto seguro para muitos.",
			"locked_tooltip": "Alcance uma população de 10 moradores.",
			"icon": "res://Assets/Sprites/Exported/HUD/Icons/population-icon.png"
		}
	},
	"achieve_unification": {
		"title": "Unificador dos Quilombos",
		"unlocked": false,
		"tooltip_data": {
			"tooltip": "Unificador dos Quilombo: Você uniu todos
			 os quilombos da região sob sua liderança.",
			"locked_tooltip": "Conquiste ou alie-se a todos
			 os quilombos da região.",
			"icon": "res://Assets/Sprites/Exported/HUD/Icons/health-icon.png"
		}
	}
}

# Sinal para anunciar quando uma conquista é desbloqueada.
signal achievement_unlocked(achievement_data)

# Outros scripts (como WorldTimeManager, QuilomboManager) chamarão esta função.
func check_and_unlock(achievement_id: String):
	if achievements.has(achievement_id) and not achievements[achievement_id]["unlocked"]:
		achievements[achievement_id]["unlocked"] = true
		var data = achievements[achievement_id]
		
		print("🏆 CONQUISTA DESBLOQUEADA: ", data["title"])
		# Anuncia para a UI (para mostrar uma notificação, por exemplo).
		emit_signal("achievement_unlocked", data)

# Função para a tela de vitória pegar a lista de todas as conquistas.
func get_all_achievements() -> Dictionary:
	return achievements
