# MusicManager.gd
extends Node

@export_category("Trilhas Sonoras")
@export var menu_music: AudioStream
@export var day_music: AudioStream
@export var night_music: AudioStream

# --- NOVA CATEGORIA PARA SONS AMBIENTES ---
@export_category("Sons Ambientes da Noite")
## Arraste aqui todos os sons que podem tocar aleatoriamente à noite (corujas, grilos, etc).
@export var night_sfx: Array[AudioStream]
## O tempo mínimo (em segundos) entre cada som ambiente.
@export var min_sfx_interval: float = 10.0
## O tempo máximo (em segundos) entre cada som ambiente.
@export var max_sfx_interval: float = 30.0

@export_category("Configurações")
@export var fade_duration: float = 2.0

# --- NOVAS REFERÊNCIAS DE NÓS ---
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var ambient_sfx_player: AudioStreamPlayer = $AmbientSFXPlayer
@onready var ambient_timer: Timer = $AmbientTimer

var _is_fading: bool = false
var _current_music: AudioStream = null


func _ready():
	# Conecta ao relógio mundial
	WorldTimeManager.period_changed.connect(_on_world_period_changed)
	
	# --- NOVA CONEXÃO DE SINAL ---
	# Conecta o sinal de timeout do nosso novo timer a uma função.
	ambient_timer.timeout.connect(_on_ambient_timer_timeout)


# --- Funções públicas (play_menu_music, etc.) não mudam ---


# A função principal que gerencia as transições
# Em MusicManager.gd

func _fade_to_music(new_stream: AudioStream):
	# Impede múltiplas transições ao mesmo tempo ou tocar a mesma música de novo
	if new_stream == _current_music or _is_fading:
		return

	_is_fading = true
	_current_music = new_stream
	
	# Se a nova música NÃO for a da noite, para os sons ambientes.
	if new_stream != night_music:
		ambient_timer.stop()

	# Cria um Tween para gerenciar toda a sequência
	var tween = create_tween()
	# Garante que o tween não morra se a cena mudar
	tween.set_parallel(true)
	
	# 1. FAZ O FADE-OUT (se houver música tocando)
	if music_player.playing:
		tween.tween_property(music_player, "volume_db", -80.0, fade_duration)

	# 2. TROCA A MÚSICA (será executado após o fade-out)
	tween.tween_callback(func():
		music_player.stream = new_stream
		if new_stream:
			music_player.play()
			# Se a nova música for a da noite, inicia o sistema de sons ambientes.
			if new_stream == night_music:
				_on_ambient_timer_timeout() # Toca o primeiro som imediatamente
		else:
			music_player.stop()
	)
	
	# 3. FAZ O FADE-IN (se houver uma nova música para tocar)
	if new_stream:
		tween.tween_property(music_player, "volume_db", 0.0, fade_duration)
		
	# 4. FINALIZAÇÃO (será executado no final de toda a sequência)
	tween.tween_callback(func():
		_is_fading = false
	)

# --- NOVA FUNÇÃO PARA TOCAR SONS AMBIENTES ---
# Chamada quando o AmbientTimer termina sua contagem.
func _on_ambient_timer_timeout():
	# Garante que temos sons para tocar e que ainda é noite.
	if not night_sfx.is_empty() and _current_music == night_music:
		# Escolhe um som aleatório da nossa lista
		ambient_sfx_player.stream = night_sfx.pick_random()
		ambient_sfx_player.play()
		
		# Define o PRÓXIMO intervalo de tempo aleatório para o timer
		ambient_timer.wait_time = randf_range(min_sfx_interval, max_sfx_interval)
		ambient_timer.start()


# --- O resto do seu código (play_music, _on_world_period_changed, etc.) ---
func play_menu_music():
	_fade_to_music(menu_music)
func play_game_music():
	if WorldTimeManager.is_day() or WorldTimeManager.is_evening():
		_fade_to_music(day_music)
	else:
		_fade_to_music(night_music)
		
func stop_music():
	_fade_to_music(null)
func _on_world_period_changed(period_name: String):
	if _current_music == day_music or _current_music == night_music:
		play_game_music()
