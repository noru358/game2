extends RefCounted
const HeroVisual = preload("res://game/hero_visual.gd")
var frames: Array[AtlasTexture] = []
var metadata: Array
var height := 1.0
var first := 0

func _init(elite: bool, charger: bool) -> void:
	var texture: Texture2D
	if elite:
		texture = preload("res://assets/enemies/ruin_guardian_v1.png")
		metadata = JSON.parse_string(FileAccess.get_file_as_string("res://assets/enemies/ruin_guardian_v1.json"))
		height = 2.7
	else:
		texture = preload("res://assets/enemies/forest_creatures_v1.png")
		metadata = JSON.parse_string(FileAccess.get_file_as_string("res://assets/enemies/forest_creatures_v1.json"))
		first = 8 if charger else 0
		height = 1.15 if charger else 0.9
	for data in metadata:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(data.region[0], data.region[1], data.region[2], data.region[3])
		frame.filter_clip = true
		frames.append(frame)

func apply(sprite: Sprite3D, direction: Vector3, flash: bool) -> void:
	var index := first + HeroVisual.direction_index(direction)
	var data: Dictionary = metadata[index]
	sprite.texture = frames[index]
	sprite.pixel_size = height / maxf(1, float(data.foot) - float(data.top))
	sprite.offset.x = float(data.region[2]) * 0.5 - float(data.root_x)
	var baseline: float = (float(data.foot) - float(data.region[3]) * 0.5) * sprite.pixel_size
	sprite.position = Vector3(0, cos(deg_to_rad(52)), -sin(deg_to_rad(52))) * baseline + Vector3.UP * 0.03
	sprite.modulate = Color(1.6, 1.5, 1.2) if flash else Color.WHITE

func animate(sprite:Sprite3D,direction:Vector3,gait:float,moving:bool,preparing:bool,recoil:float,flash:bool) -> void:
	# Temporary body motion, not a replacement for drawn limb animation frames.
	var squash:=0.0
	var shift:=Vector3.ZERO
	if flash:
		squash=0.12
	elif preparing:
		squash=0.09
		shift=-direction*0.10
	elif recoil>0:
		var strike:=sin(recoil/0.22*PI)
		squash=-0.06*strike
		shift=direction*0.18*strike
	elif moving:
		shift.y=absf(sin(gait))*height*0.045
		squash=sin(gait*2)*0.018
	sprite.scale=Vector3(1+squash,1-squash,1)
	# Foot-root compensation keeps scaling from sinking/hovering the whole card.
	sprite.position*=1-squash
	sprite.position+=shift
