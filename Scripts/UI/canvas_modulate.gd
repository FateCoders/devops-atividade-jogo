# DayNightVisuals.gd
extends CanvasModulate

@export var day_color := Color.WHITE
@export var night_color := Color(0.1, 0.1, 0.4, 1.0) # Um azul escuro

func _ready():
	# Conecta ao sinal do nosso gerenciador de tempo
	WorldTimeManager.period_changed.connect(_on_period_changed)
	
	# Define a cor inicial baseada na hora atual
	if WorldTimeManager.is_day():
		color = day_color
	else:
		color = night_color

func _on_period_changed(period_name: String):
	if period_name == "DAY":
		# Cria uma transição suave de cor
		create_tween().tween_property(self, "color", day_color, 2.0)
	else:
		create_tween().tween_property(self, "color", night_color, 2.0)
