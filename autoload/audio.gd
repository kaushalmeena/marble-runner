extends Node
## Fire-and-forget sound effects.
##
## Every clip is generated offline into [code]assets/audio[/code], so the game
## ships with no third-party audio and no licensing to track. Callers just say
## what happened - [code]Audio.play(&"pickup")[/code] - and never touch a player
## node themselves.

const SOUND_DIR := "res://assets/audio/"
const SOUND_NAMES: Array[StringName] = [
	&"pickup",
	&"jump",
	&"land",
	&"crash",
	&"power_up",
	&"power_down",
	&"shield_break",
]
## Simultaneous sounds. Anything past this steals the oldest voice.
const VOICES := 10

var _streams: Dictionary[StringName, AudioStream] = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0


func _ready() -> void:
	# Autoloads sit under the root, which always processes. Marking the bank
	# pausable means effects stop with the game instead of playing on over a
	# paused scene.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for sound_name in SOUND_NAMES:
		var stream := load(SOUND_DIR + String(sound_name) + ".wav") as AudioStream
		if stream == null:
			push_warning("Audio: missing clip '%s'." % sound_name)
			continue
		_streams[sound_name] = stream
	for _i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


## Plays a clip. [param pitch_jitter] randomises the pitch by up to that
## fraction either way, which stops repeated pickups sounding mechanical.
func play(sound_name: StringName, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(sound_name)
	if stream == null:
		return
	var player := _take_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()


## Prefers a free voice, and only steals one when every voice is busy.
func _take_player() -> AudioStreamPlayer:
	for offset in _players.size():
		var index := (_next + offset) % _players.size()
		if not _players[index].playing:
			_next = (index + 1) % _players.size()
			return _players[index]
	var stolen := _players[_next]
	_next = (_next + 1) % _players.size()
	return stolen
