extends "res://game/player.gd"
## Reuses original movement/dash. Only presentation and terrain footsteps differ.
var frames: Array=[]
var regions: Array[AtlasTexture]=[]

func _ready() -> void:
	var path := "res://art_review/hero_idle_exact_v1/"
	var image := Image.load_from_file(ProjectSettings.globalize_path(path+"candidate.png"))
	image.fix_alpha_edges()
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	frames=JSON.parse_string(FileAccess.get_file_as_string(path+"frames.json"))
	for d in frames:
		var region := AtlasTexture.new()
		region.atlas=texture
		region.region=Rect2(d.region[0],d.region[1],d.region[2],d.region[3])
		region.filter_clip=true
		regions.append(region)
	super._ready()
	for familiar in familiars:familiar.hide()

func update_visual(_delta: float) -> void:
	if frames.is_empty():return
	var index := posmod(roundi(atan2(facing.z,facing.x)/(PI/4)),8)
	var d: Dictionary=frames[index]
	var pitch: float=get_parent().camera_pitch
	portrait.texture=regions[index]
	portrait.pixel_size=2.25/(float(d.foot)-float(d.top))
	portrait.offset.x=float(d.region[2])*0.5-float(d.root_x)
	# Match HeroVisual: vertical card + cosine correction. Rotating the card
	# toward the camera as well would double-correct size and lift the feet.
	portrait.rotation.x=0
	portrait.scale=Vector3(1,1.0/cos(deg_to_rad(pitch)),1)
	var baseline: float=(float(d.foot)-float(d.region[3])*0.5)*portrait.pixel_size
	portrait.position=Vector3.UP*(baseline/cos(deg_to_rad(pitch))+0.04)+Vector3(0,sin(deg_to_rad(pitch)),cos(deg_to_rad(pitch)))*0.65
	weapon.hide()
	second_focus.hide()
	var terrain=get_parent().surface
	contact_shadow.position.y=terrain.height_at(position)-position.y+0.035
	contact_shadow.quaternion=Quaternion(Vector3.UP,terrain.normal_at(position))

func advance_stride(_distance: float) -> void:
	pass # No false claim of finished animation; no legacy terrain footsteps.
