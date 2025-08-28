# WorldTimeManager.gd
extends Node

## Sinal emitido quando o período do dia muda (de "DAY" para "NIGHT" e vice-versa).
signal period_changed(period_name: String)

## A duração de um dia completo no jogo, em segundos reais.
@export var day_length_in_seconds: float = 120.0 # 2 minutos para um dia completo

## A hora em que a noite começa (formato 24h).
@export var night_starts_at: float = 20.0 # 8 PM
## A hora em que o dia começa (formato 24h).
@export var day_starts_at: float = 6.0  # 6 AM

# Variáveis internas
var _current_hour: float = 12.0 # Começa ao meio-dia
var _current_period: String = "DAY"


func _process(delta: float):
	# Calcula a velocidade que o tempo do jogo passa
	var time_speed = 24.0 / day_length_in_seconds
	
	# Avança a hora atual
	_current_hour += delta * time_speed
	
	# Se a hora passar de 24, volta para 0
	_current_hour = fmod(_current_hour, 24.0)
	
	# Verifica se o período do dia mudou
	var previous_period = _current_period
	if _current_hour >= night_starts_at or _current_hour < day_starts_at:
		_current_period = "NIGHT"
	else:
		_current_period = "DAY"
		
	# Se o período mudou, emite o sinal para avisar o resto do jogo
	if _current_period != previous_period:
		period_changed.emit(_current_period)


## Funções públicas para outros scripts poderem consultar o tempo
func get_current_hour() -> float:
	return _current_hour

func is_day() -> bool:
	return _current_period == "DAY"

func is_night() -> bool:
	return _current_period == "NIGHT"
