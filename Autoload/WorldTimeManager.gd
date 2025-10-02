# WorldTimeManager.gd
extends Node

# --- SINAIS ---
signal period_changed(period_name: String)
signal day_passed(new_day: int)
signal time_scale_changed

# --- CONFIGURAÇÕES DE TEMPO ---
@export var day_length_in_seconds: float = 300.0
@export var day_starts_at: float = 6.0    # 06:00
@export var evening_starts_at: float = 19.0 # 19:00
@export var night_starts_at: float = 22.0  # 22:00

# --- NOVO: CONDIÇÃO DE VITÓRIA ---
@export var victory_day: int = 30

# --- VARIÁVEIS DE ESTADO ---
var current_day: int = 1
var _current_hour: float = 6.0
var _current_period: String = "DAY"
var time_scale: float = 1.0

func _process(delta: float) -> void:
	var time_speed := 24.0 / day_length_in_seconds
	
	var previous_hour := _current_hour
	_current_hour = fmod(_current_hour + (delta * time_speed * time_scale), 24.0)

	# --- NOVA LÓGICA DE VIRADA DO DIA ---
	if _current_hour < previous_hour:
		current_day += 1
		#print("--- UM NOVO DIA COMEÇOU! DIA: ", current_day, " ---")
		day_passed.emit(current_day)
	
	var previous_period := _current_period
	_current_period = _determine_period(_current_hour)

	if _current_period != previous_period:
		#print("⏰ RELÓGIO MUNDIAL: Mudança para '", _current_period, "' às ", snapped(_current_hour, 0.01))
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
	if time_scale != 4.0:
		time_scale = 4.0
		emit_signal("time_scale_changed")
		print("WorldTimeManager: time_scale definido para RÁPIDO (4.0)")
