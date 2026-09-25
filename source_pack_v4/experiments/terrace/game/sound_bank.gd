extends Node
const CLIPS := {
	"fireball":preload("res://assets/audio/fox_fire_launch.wav"),
	"auto":preload("res://assets/audio/auto.wav"),
	"cast":preload("res://assets/audio/cast.wav"),
	"hit":preload("res://assets/audio/hit.wav"),
	"heavy":preload("res://assets/audio/heavy.wav"),
	"dash":preload("res://assets/audio/dash.wav"),
	"hurt":preload("res://assets/audio/hurt.wav"),
	"reward":preload("res://assets/audio/reward.wav"),
	"warning":preload("res://assets/audio/warning.wav")
}
const GAIN := {"fireball":-12.5,"auto":-17.5,"cast":-22.0,"hit":-19.0,"heavy":-17.0,"dash":-25.0,"hurt":-17.0,"reward":-21.0,"warning":-20.0}
var channels := {}
var turns := {}
var muted := false

func _ready() -> void:
	for event in CLIPS:
		var group: Array[AudioStreamPlayer] = []
		for i in range(2 if event in ["auto","hit"] else 1):
			var voice := AudioStreamPlayer.new()
			voice.stream=CLIPS[event]
			voice.volume_db=GAIN[event]
			add_child(voice)
			group.append(voice)
		channels[event]=group
		turns[event]=0

func play(event: String, combo: int = 0) -> void:
	if muted or not channels.has(event):return
	var group: Array = channels[event]
	var turn: int=turns[event]
	var voice: AudioStreamPlayer=group[turn%group.size()]
	# Small deterministic variation avoids exact repetition without consuming gameplay RNG.
	voice.pitch_scale=1.0+[-0.025,0.0,0.025][turn%3] if event in ["auto","cast","hit","heavy"] else 1.0
	if event == "cast" and combo > 0:
		voice.pitch_scale = [1.12,0.96,0.73][clampi(combo-1,0,2)]
		voice.volume_db = -19.0 if combo < 3 else -16.0
	voice.play()
	turns[event]=turn+1

func set_muted(value: bool) -> void:
	muted=value
	if muted:
		for group in channels.values():
			for voice in group:voice.stop()
