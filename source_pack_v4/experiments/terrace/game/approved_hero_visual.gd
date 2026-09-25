extends "res://game/hero_visual.gd"
# Candidate frame renderer sharing Player/Combat's existing visual interface.
var animated := preload("res://lab/hero_pose_player.gd").new()
var locomotion := preload("res://lab/hero_reskin_locomotion.gd").new()
var exact_meta: Array=[]
var exact_frames: Array[AtlasTexture]=[]
var last_state := "idle"
func _init() -> void:
	var path := "res://art_review/hero_idle_exact_v1/"
	var image := Image.load_from_file(ProjectSettings.globalize_path(path+"candidate.png"))
	image.fix_alpha_edges()
	var texture := ImageTexture.create_from_image(image)
	exact_meta=JSON.parse_string(FileAccess.get_file_as_string(path+"frames.json"))
	build_frames(texture,exact_meta,exact_frames)
func baked_motion() -> bool:
	return true
func idle(sprite: Sprite3D, index: int) -> void:
	var d: Dictionary=exact_meta[index]
	sprite.texture=exact_frames[index]
	sprite.flip_h=false
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.pixel_size=2.25/(float(d.foot)-float(d.top))
	sprite.offset.x=d.region[2]*0.5-float(d.root_x)
	sprite.rotation=Vector3.ZERO
	sprite.scale=Vector3(1,1/cos(deg_to_rad(52)),1)
	sprite.position=Vector3.UP*((d.foot-d.region[3]*0.5)*sprite.pixel_size/cos(deg_to_rad(52))+0.04)
	last_state="idle"
func apply(sprite: Sprite3D, direction: Vector3, moving: bool, phase: float, casting: bool, running: bool=false, combo: int=0, recovering: bool=false) -> void:
	var index := direction_index(direction)
	idle(sprite,index)
	if combo>0:
		animated.apply(sprite,"attack",0,combo,recovering,index)
		last_state="recovery" if recovering else "strike"
	elif moving:
		# Preserve the proven grove_scholar gait and replace appearance only.
		locomotion.apply(sprite,direction,running,phase+PI*0.5 if running else phase)
		last_state="run" if running else "walk"
	else:
		animated.current={}
		return
	if combo>0:
		if not animated.current.is_empty():
			# Player adds its camera-depth bias once after the renderer returns.
			sprite.position-=Vector3(0,0.788,0.616)*0.65
		else:
			last_state="missing_pose"
func prepare(sprite: Sprite3D, direction: Vector3, combo: int) -> void:
	animated.apply(sprite,"attack",-1,combo,false,direction_index(direction))
	if not animated.current.is_empty():sprite.position-=Vector3(0,0.788,0.616)*0.65
	last_state="prepare"
func dash(sprite: Sprite3D, direction: Vector3, progress: float) -> void:
	# A held flight pose then a support pose reads as a short dodge. Walking
	# phase is frozen during dash and must not choose an arbitrary walking cell.
	locomotion.apply(sprite,direction,true,0 if progress<0.75 else PI*0.5)
	last_state="dash"
func focus_points(sprite: Sprite3D, _direction: Vector3, combo: int) -> Array[Vector3]:
	if not animated.current.is_empty() and animated.current.state=="attack":
		return animated.hands(sprite,combo)
	return [Vector3(0,1.2,0)]
func focus_offset(_direction: Vector3, _combo: int) -> Vector3:
	return Vector3(0,1.2,0)
