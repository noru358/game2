extends Node
const Land=preload("res://game/landscape.gd")
const CLIPS=[preload("res://assets/audio/ambience_forest.wav"),preload("res://assets/audio/ambience_water.wav"),preload("res://assets/audio/ambience_reservoir.wav")]
const LEVEL_DB := -29.0
var voices: Array[AudioStreamPlayer]=[]
var weights:=Vector3.ZERO

func _ready()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	for clip in CLIPS:
		var voice:=AudioStreamPlayer.new()
		voice.stream=clip
		voice.volume_db=-80
		add_child(voice)
		voices.append(voice)

static func mix_at(at:Vector3)->Vector3:
	var nearest := Land.water_distance(at)
	var indoors:=smoothstep(84.0,94.0,-at.z)
	var water:float=(1.0-smoothstep(1.0,8.0,nearest))*0.75
	return Vector3((1-indoors)*(1-water),(1-indoors)*water,indoors)

func stop()->void:
	weights=Vector3.ZERO
	for voice in voices:voice.stop()

func update_mix(at:Vector3,delta:float,enabled:bool,paused:bool)->void:
	var gain:=clampf(float(get_tree().get_meta("ambience_gain",1.0)),0,1)
	if not enabled or gain==0:
		stop()
		return
	if not paused:weights=weights.move_toward(mix_at(at),maxf(0,delta)*0.45)
	for i in range(voices.size()):
		var voice:=voices[i]
		voice.volume_db=LEVEL_DB+linear_to_db(maxf(weights[i]*gain,0.00001))
		if not voice.playing and not paused:voice.play()
		voice.stream_paused=paused

func _process(delta:float)->void:
	var world=get_parent()
	update_mix(world.player.position,delta,not world.test_mode and not world.silent,get_tree().paused)
