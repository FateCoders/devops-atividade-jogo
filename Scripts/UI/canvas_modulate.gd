# DayNightVisuals.gd
extends CanvasModulate

@export var day_color := Color.WHITE
@export var evening_color := Color(1.0, 0.8, 0.6, 1.0) # Um tom alaranjado para a tarde
@export var night_color := Color(0.1, 0.1, 0.4, 1.0)   # Azul escuro

func _ready():
	# Conecta ao sinal do nosso gerenciador de tempo
	WorldTimeManager.period_changed.connect(_on_period_changed)
	
	# Define a cor inicial baseada na hora atual
	match WorldTimeManager._current_period:
		"DAY":
			color = day_color
		"EVENING":
			color = evening_color
		"NIGHT":
			color = night_color

func _on_period_changed(period_name: String):
	var target_color: Color
	match period_name:
		"DAY":
			target_color = day_color
		"EVENING":
			target_color = evening_color
		"NIGHT":
			target_color = night_color
	# Cria uma transição suave de cor
	create_tween().tween_property(self, "color", target_color, 2.0)
