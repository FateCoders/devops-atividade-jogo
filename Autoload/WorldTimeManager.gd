extends Node

signal period_changed(period_name: String)

@export var day_length_in_seconds: float = 120.0 # 120 segundos para um dia completo

@export var night_starts_at: float = 20.0 # 8 PM
@export var day_starts_at: float = 6.0  # 6 AM

var _current_hour: float = 12.0 # Começa ao meio-dia
var _current_period: String = "DAY"


# Em WorldTimeManager.gd

func _process(delta: float):
	var time_speed = 24.0 / day_length_in_seconds
	
	_current_hour += delta * time_speed
	
	_current_hour = fmod(_current_hour, 24.0)
	
	var previous_period = _current_period
	if _current_hour >= night_starts_at or _current_hour < day_starts_at:
		_current_period = "NIGHT"
	else:
		_current_period = "DAY"
		
	if _current_period != previous_period:
		# --- ADICIONADO: O ESPIÃO DO RELÓGIO ---
		print("!!! RELÓGIO MUNDIAL: Enviando sinal de '", _current_period, "' na hora ", _current_hour)
		period_changed.emit(_current_period)


func get_current_hour() -> float:
	return _current_hour

func is_day() -> bool:
	return _current_period == "DAY"

func is_night() -> bool:
	return _current_period == "NIGHT"
