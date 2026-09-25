extends RefCounted
# Frame-based candidate review. No mesh deformation; no production promotion.
const DIR="res://art_review/hero_pose_v2/"
var frames: Array=[]
var textures: Dictionary={}
var current: Dictionary={}
var frame_changes := 0
var last_key := ""
func _init() -> void:
	# The generated walk/run frames in this manifest are retired and must never
	# be reused. This renderer now owns combat poses only.
	frames=JSON.parse_string(FileAccess.get_file_as_string(DIR+"frames.json")).frames.filter(func(frame): return frame.state=="attack")
	for f in frames:
		var name: String=f.sheet
		if textures.has(name):continue
		var im := Image.load_from_file(ProjectSettings.globalize_path(DIR+name))
		im.fix_alpha_edges()
		textures[name]=ImageTexture.create_from_image(im)
	for f in frames:
		var atlas := AtlasTexture.new()
		atlas.atlas=textures[f.sheet]
		atlas.region=Rect2(f.region[0],f.region[1],f.region[2],f.region[3])
		atlas.filter_clip=true
		f.texture=atlas

func select(state: String, phase: float, step: int=0, recovery: bool=false, direction: int=0) -> Dictionary:
	var frame := (2 if recovery else (0 if phase<0 else 1)) if state=="attack" else int(fposmod(phase,TAU)/(PI*0.5))
	for f in frames:
		if f.state==state and int(f.step)==step and int(f.frame)==frame and int(f.direction)==direction:return f
	return {}

func apply(sprite: Sprite3D, state: String, phase: float, step: int=0, recovery: bool=false, direction: int=0) -> void:
	current=select(state,phase,step,recovery,direction)
	if current.is_empty():return
	var key := state+str(direction)+str(step)+str(current.frame)
	if key!=last_key:frame_changes+=1;last_key=key
	sprite.texture=current.texture
	sprite.flip_h=current.get("mirror_h",false)
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR
	# Fixed scale per sheet, not frame-by-frame height normalization.
	sprite.pixel_size=2.25/float(current.height_reference)
	sprite.offset.x=current.region[2]*0.5-float(current.root_x)
	sprite.scale=Vector3(1,1/cos(deg_to_rad(52)),1)
	sprite.rotation=Vector3.ZERO
	var baseline: float=(current.foot-current.region[3]*0.5)*sprite.pixel_size
	sprite.position=Vector3.UP*(baseline/cos(deg_to_rad(52))+0.04)+Vector3(0,0.788,0.616)*0.65

func hands(sprite: Sprite3D, step: int) -> Array[Vector3]:
	# Provisional striking-glove anchors of the new sweep poses, never palm-thrust metadata.
	var coordinates: Array=current.get("hands",[])
	var result: Array[Vector3]=[]
	for coordinate in coordinates:
		var p := Vector2(coordinate[0],coordinate[1])
		var local := Vector3(p.x-current.region[2]*0.5+sprite.offset.x,current.region[3]*0.5-p.y,0)*sprite.pixel_size
		result.append(sprite.transform*local)
	return result
