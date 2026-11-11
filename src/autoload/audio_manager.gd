extends Node

## Centralized audio manager for sound effects and office ambience.

var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer

func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)
	
	# Create pool of 8 SFX players for overlapping clicks, ringtones, etc.
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = pitch
			player.play()
			return
	# Fallback if all busy
	_sfx_players[0].stream = stream
	_sfx_players[0].volume_db = volume_db
	_sfx_players[0].pitch_scale = pitch
	_sfx_players[0].play()

func play_bgm(stream: AudioStream, volume_db: float = -6.0) -> void:
	if stream == null:
		return
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	_bgm_player.stream = stream
	_bgm_player.volume_db = volume_db
	_bgm_player.play()

func stop_bgm() -> void:
	_bgm_player.stop()

