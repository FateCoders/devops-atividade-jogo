# WorldTimeManager.gd
extends Node

# --- SINAIS ---
signal period_changed(period_name: String)
signal day_passed(new_day: int)

# --- CONFIGURAÇÕES DE TEMPO ---
@export var day_length_in_seconds: float = 20.0
@export var day_starts_at: float = 6.0    # 06:00
@export var evening_starts_at: float = 17.0 # 17:00
@export var night_starts_at: float = 20.0  # 20:00

# --- NOVO: CONDIÇÃO DE VITÓRIA ---
@export var victory_day: int = 2

# --- VARIÁVEIS DE ESTADO ---
# ADICIONADO: Contador de dias
var current_day: int = 1
var _current_hour: float = 6.0 # Começa às 6 da manhã
var _current_period: String = "DAY"


func _process(delta: float) -> void:
	var time_speed := 24.0 / day_length_in_seconds
	
	# Guarda a hora antes de avançar para detectar a virada do dia
	var previous_hour := _current_hour
	_current_hour = fmod(_current_hour + delta * time_speed, 24.0)

	# --- NOVA LÓGICA DE VIRADA DO DIA ---
	# Se a hora anterior era alta (ex: 23.9) e a nova é baixa (ex: 0.1), um dia passou.
	if _current_hour < previous_hour:
		current_day += 1
		print("--- UM NOVO DIA COMEÇOU! DIA: ", current_day, " ---")
		day_passed.emit(current_day)

	# --- Lógica de período (permanece a mesma) ---
	var previous_period := _current_period
	_current_period = _determine_period(_current_hour)

	if _current_period != previous_period:
		print("⏰ RELÓGIO MUNDIAL: Mudança para '", _current_period, "' às ", snapped(_current_hour, 0.01))
		period_changed.emit(_current_period)

# --- O resto das suas funções permanece o mesmo ---
func _determine_period(hour: float) -> String:
	if hour >= night_starts_at or hour < day_starts_at:
		return "NIGHT"
	elif hour >= evening_starts_at:
		return "EVENING"
	else:
		return "DAY"

func get_current_hour() -> float:
	return _current_hour

func is_day() -> bool:
	return _current_period == "DAY"

func is_evening() -> bool:
	return _current_period == "EVENING"

func is_night() -> bool:
	return _current_period == "NIGHT"
