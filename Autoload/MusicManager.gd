# MusicManager.gd
extends Node

# --- EXPORTE AS MÚSICAS AQUI ---
# Arraste seus arquivos de áudio (MP3 ou OGG) para estes campos no Inspetor.
@export_category("Trilhas Sonoras")
@export var menu_music: AudioStream
@export var day_music: AudioStream
@export var night_music: AudioStream

@export_category("Configurações")
@export var fade_duration: float = 2.0 # Duração da transição em segundos

# --- NÓS INTERNOS ---
# Garante que o nó filho se chame "MusicPlayer" na sua cena MusicManager.tscn
@onready var music_player: AudioStreamPlayer = $MusicPlayer

# --- CONTROLE INTERNO ---
var _is_fading: bool = false
var _current_music: AudioStream = null


func _ready():
	WorldTimeManager.period_changed.connect(_on_world_period_changed)


# --- FUNÇÕES PÚBLICAS (para chamar de outros scripts) ---

## Toca a música do menu principal
func play_menu_music():
	_fade_to_music(menu_music)

## Toca a música de jogo correta (dia ou noite)
func play_game_music():
	# Verifica a hora atual para decidir qual música tocar
	if WorldTimeManager.is_day():
		_fade_to_music(day_music)
	else:
		# Se não houver WorldTimeManager, assume que é noite como padrão
		_fade_to_music(night_music)

## Para a música completamente
func stop_music():
	_fade_to_music(null)


# --- FUNÇÕES INTERNAS (reações e lógica) ---

# Chamada AUTOMATICAMENTE quando o dia vira noite ou vice-versa
func _on_world_period_changed(_period_name: String):
	# Só troca a música se já estivermos no "modo jogo"
	if _current_music == day_music or _current_music == night_music:
		play_game_music()


# A função principal que gerencia as transições
# Em MusicManager.gd

# Em MusicManager.gd, substitua a função inteira

func _fade_to_music(new_stream: AudioStream):
	# Impede múltiplas transições ao mesmo tempo ou tocar a mesma música de novo
	if new_stream == _current_music or _is_fading:
		return

	_is_fading = true
	_current_music = new_stream
	
	# O Tween é a ferramenta do Godot para animar propriedades ao longo do tempo
	var tween = create_tween()
	# Adicionamos uma propriedade para que o tween não seja morto se a cena mudar
	tween.set_parallel(true)
	
	# 1. FAZ O FADE-OUT da música atual (se estiver tocando)
	# Esta é a primeira parte da nossa sequência.
	if music_player.playing:
		tween.tween_property(music_player, "volume_db", -80.0, fade_duration)

	# 2. TROCA A MÚSICA
	# Esta função será chamada APÓS o fade-out terminar.
	tween.tween_callback(func():
		music_player.stream = new_stream
		if new_stream:
			music_player.play()
		else:
			music_player.stop()
	)
	
	# 3. FAZ O FADE-IN da nova música (se houver uma)
	# Esta etapa será executada em paralelo com o passo 2 se não houver fade-out,
	# ou em sequência se houver. O tween gerencia isso.
	if new_stream:
		tween.tween_property(music_player, "volume_db", 0.0, fade_duration)
		
	# 4. FINALIZAÇÃO
	# Esta função será chamada no final de TODA a sequência.
	tween.tween_callback(func():
		_is_fading = false
	)
