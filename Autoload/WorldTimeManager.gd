# WorldTimeManager.gd
extends Node

# --- SINAIS ---
signal period_changed(period_name: String)
signal day_passed(new_day: int)
signal time_scale_changed

# --- CONFIGURAÇÕES DE TEMPO ---
@export var day_length_in_seconds: float = 60.0
@export var day_starts_at: float = 6.0    # 06:00
@export var evening_starts_at: float = 17.0 # 17:00
@export var night_starts_at: float = 20.0  # 20:00

# --- NOVO: CONDIÇÃO DE VITÓRIA ---
@export var victory_day: int = 3

# --- VARIÁVEIS DE ESTADO ---
# ADICIONADO: Contador de dias
var current_day: int = 1
var _current_hour: float = 6.0 # Começa às 6 da manhã
var _current_period: String = "DAY"
var time_scale: float = 1.0

func _process(delta: float) -> void:
	var time_speed := 24.0 / day_length_in_seconds
	
	# Guarda a hora antes de avançar para detectar a virada do dia
	var previous_hour := _current_hour
	_current_hour = fmod(_current_hour + (delta * time_speed * time_scale), 24.0)

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

func get_formatted_time() -> String:
	var hours = floori(_current_hour)
	var minutes_fraction = _current_hour - hours
	var total_minutes = floori(minutes_fraction * 60)
	var snapped_minutes = floori(total_minutes / 10.0) * 10
	return "%02d:%02d" % [hours, snapped_minutes]

func toggle_fast_forward():
	if time_scale > 1.0:
		time_scale = 1.0
	else:
		time_scale = 3.0
	emit_signal("time_scale_changed")
	print("WorldTimeManager: time_scale definido para ", time_scale)

func set_normal_speed():
	if time_scale != 1.0:
		time_scale = 1.0
		emit_signal("time_scale_changed")
		print("WorldTimeManager: time_scale resetado para 1.0")

func set_fast_speed():
	if time_scale != 3.0:
		time_scale = 3.0
		emit_signal("time_scale_changed")
		print("WorldTimeManager: time_scale definido para RÁPIDO (3.0)")
