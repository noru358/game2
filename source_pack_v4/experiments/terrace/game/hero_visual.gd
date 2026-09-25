extends RefCounted

func baked_motion() -> bool:
	return false

var poses: Array[AtlasTexture] = []
var combos: Array[AtlasTexture] = []
var recoveries: Array[AtlasTexture] = []
var recovery_meta: Array
var combo_meta: Array
var walks: Array[AtlasTexture] = []
var runs: Array[AtlasTexture] = []
var pose_meta: Array
var walk_meta: Array
var run_meta: Array
var walk_passes: Array[AtlasTexture] = []
var run_passes: Array[AtlasTexture] = []
var walk_pass_meta: Array
var run_pass_meta: Array

func _init() -> void:
	recovery_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero/grove_scholar_recovery_v1.json"))
	build_frames(preload("res://assets/hero/grove_scholar_recovery_v1.png"),recovery_meta,recoveries)
	combo_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero/grove_scholar_combo_v1.json"))
	build_frames(preload("res://assets/hero/grove_scholar_combo_v1.png"),combo_meta,combos)
	pose_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero/grove_scholar_eight_v1.json"))
	walk_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero/grove_scholar_walk_eight_v2.json"))
	build_frames(preload("res://assets/hero/grove_scholar_eight_v1.png"), pose_meta, poses)
	var idle_meta:Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero/grove_scholar_idle_v2.json"))
	var idle_frames:Array[AtlasTexture]=[]
	build_frames(preload("res://assets/hero/grove_scholar_idle_v2.png"),idle_meta,idle_frames)
	for i in range(8):
		poses[i]=idle_frames[i]
		pose_meta[i]=idle_meta[i]
	build_frames(preload("res://assets/hero/grove_scholar_walk_eight_v2.png"), walk_meta, walks)
	run_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero/grove_scholar_run_eight_v1.json"))
	build_frames(preload("res://assets/hero/grove_scholar_run_eight_v1.png"), run_meta, runs)
	walk_pass_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero/grove_scholar_walk_pass_v2.json"))
	run_pass_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero/grove_scholar_run_pass_v1.json"))
	build_frames(preload("res://assets/hero/grove_scholar_walk_pass_v2.png"),walk_pass_meta,walk_passes)
	build_frames(preload("res://assets/hero/grove_scholar_run_pass_v1.png"),run_pass_meta,run_passes)

func build_frames(texture: Texture2D, metadata: Array, frames: Array[AtlasTexture]) -> void:
	for data in metadata:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(data.region[0], data.region[1], data.region[2], data.region[3])
		frame.filter_clip = true
		frames.append(frame)

static func direction_index(direction: Vector3) -> int:
	return posmod(roundi(atan2(direction.z, direction.x) / (PI / 4.0)), 8)

func apply(sprite: Sprite3D, direction: Vector3, moving: bool, phase: float, casting: bool, running: bool = false, combo: int = 0, recovering: bool = false) -> void:
	# Sample every pose consistently: locomotion atlases have mipmaps, combat atlases do not.
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var index := direction_index(direction)
	var mirrored := moving and not casting and index in [3,4,5]
	if mirrored: index = {3:1,4:0,5:7}[index]
	var data: Dictionary
	if casting and combo > 0:
		var columns := {0:0,1:1,2:2,3:1,4:0,5:3,6:4,7:3}
		var frame_index: int = (clampi(combo,1,3)-1)*5+columns[index]
		data=recovery_meta[frame_index] if recovering else combo_meta[frame_index]
		mirrored = (index in [3,4,5]) != bool(data.source_mirrored)
		sprite.texture=recoveries[frame_index] if recovering else combos[frame_index]
	elif casting:
		index += 8
		sprite.texture = poses[index]
		data = pose_meta[index]
	elif moving:
		var step := int(fposmod(phase,TAU)/(PI/2.0))
		if index == 2 and step >= 2:
			mirrored = true
			step -= 2
		index += 8 * int(step/2)
		if step%2==1:
			sprite.texture = run_passes[index] if running else walk_passes[index]
			data = run_pass_meta[index] if running else walk_pass_meta[index]
		else:
			sprite.texture = runs[index] if running else walks[index]
			data = run_meta[index] if running else walk_meta[index]
	else:
		sprite.texture = poses[index]
		data = pose_meta[index]
	sprite.flip_h = mirrored
	sprite.pixel_size = (2.08 if running and moving and not casting else 2.25) / maxf(1, float(data.foot) - float(data.top))
	sprite.offset.x = (float(data.region[2]) * 0.5 - float(data.root_x)) * (-1.0 if mirrored else 1.0)
	var baseline := (float(data.foot) - float(data.region[3]) * 0.5) * sprite.pixel_size
	# Keep the same screen projection, but give the portrait upright world depth.
	# A camera-facing card extended 1.77 m into the uphill terrain at its head.
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.rotation.x = 0
	sprite.scale.y = 1.0 / cos(deg_to_rad(52))
	sprite.position = Vector3.UP * (baseline / cos(deg_to_rad(52)) + 0.04)

func focus_offset(direction: Vector3, combo: int) -> Vector3:
	var index:=direction_index(direction)
	var columns:={0:0,1:1,2:2,3:1,4:0,5:3,6:4,7:3}
	var data:Dictionary=combo_meta[(clampi(combo,1,3)-1)*5+columns[index]]
	var mirrored:bool=(index in [3,4,5]) != bool(data.source_mirrored)
	var pixel:float=2.25/(float(data.foot)-float(data.top))
	var screen_up:=Vector3(0,cos(deg_to_rad(52)),-sin(deg_to_rad(52)))
	return Vector3.RIGHT*(float(data.hand[0])-float(data.root_x))*pixel*(-1 if mirrored else 1)+screen_up*(float(data.foot)-float(data.hand[1]))*pixel+Vector3.UP*0.04

func focus_points(sprite:Sprite3D,direction:Vector3,combo:int) -> Array[Vector3]:
	var columns:={0:0,1:1,2:2,3:1,4:0,5:3,6:4,7:3}
	var data:Dictionary=combo_meta[(clampi(combo,1,3)-1)*5+columns[direction_index(direction)]]
	var result:Array[Vector3]=[]
	for hand in data.get("hands",[data.hand]):
		var local:=Vector3((float(hand[0])-float(data.region[2])*0.5)*(-1 if sprite.flip_h else 1)+sprite.offset.x,float(data.region[3])*0.5-float(hand[1])+sprite.offset.y,0)*sprite.pixel_size
		result.append(sprite.transform*local)
	return result
