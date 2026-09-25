extends "res://maps/environment_kit.gd"
## Illustrated asset trial. Geometry and collision still belong to the map.
var atlas: Texture2D
var frames: Array=[]
var regions: Array[AtlasTexture]=[]
var cards: Array[Sprite3D]=[]
var stone_texture: Texture2D
var camera_pitch := 45.0

func prepare() -> void:
	if atlas!=null:return
	var im := Image.load_from_file(ProjectSettings.globalize_path("res://maps/assets/forest_props_v1.png"))
	im.fix_alpha_edges()
	im.generate_mipmaps()
	atlas=ImageTexture.create_from_image(im)
	frames=JSON.parse_string(FileAccess.get_file_as_string("res://maps/assets/props.json"))
	for d in frames:
		var t := AtlasTexture.new()
		t.atlas=atlas
		t.region=Rect2(d.region[0],d.region[1],d.region[2],d.region[3])
		t.filter_clip=true
		regions.append(t)
	var materials := Image.load_from_file(ProjectSettings.globalize_path("res://maps/assets/surface_materials_v1.png"))
	var half := materials.get_width()/2
	var stone := materials.get_region(Rect2i(half,half,half,half))
	stone.generate_mipmaps()
	stone_texture=ImageTexture.create_from_image(stone)

func card(at: Vector3,index: int,height: float,shade: float=1.0) -> Sprite3D:
	var sprite := Sprite3D.new()
	var d: Dictionary=frames[index]
	sprite.texture=regions[index]
	sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold=0.28
	sprite.shaded=false
	sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.pixel_size=height/float(d.region[3])
	sprite.rotation.x=deg_to_rad(-camera_pitch)
	sprite.modulate=Color(shade,shade,shade,1)
	var baseline: float=(float(d.foot)-float(d.region[3])*0.5)*sprite.pixel_size
	sprite.position=surface.ground(at)+Vector3(0,sin(deg_to_rad(camera_pitch)),cos(deg_to_rad(camera_pitch)))*0.025
	sprite.position+=Vector3(0,cos(deg_to_rad(camera_pitch)),-sin(deg_to_rad(camera_pitch)))*baseline
	sprite.set_meta("base_at",at)
	sprite.set_meta("baseline",baseline)
	parent.add_child(sprite)
	cards.append(sprite)
	return sprite

func tree(at: Vector3,height: float,_seed_value: int) -> void:
	prepare()
	card(at,5,height*0.95,0.93)
	# Retain a visible trunk collision; canopy is transparent illustrated art.
	var body := StaticBody3D.new()
	body.position=surface.ground(at)+Vector3.UP*height*0.25
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius=0.48
	shape.height=height*0.5
	collision.shape=shape
	body.add_child(collision)
	parent.add_child(body)
	shadow(at,Vector2(height*0.6,height*0.45),0.25)

func rock(at: Vector3,size: Vector3,color: Color=Color("80928a"),solid: bool=true) -> MeshInstance3D:
	prepare()
	var result := super.rock(at,size,color,solid)
	# Keep mesh volumes for edges/physics, add irregular illustrated surface.
	var material: StandardMaterial3D=result.material_override
	material.albedo_color=Color("afb39a")
	material.albedo_texture=stone_texture
	material.uv1_triplanar=true
	material.uv1_scale=Vector3.ONE*0.35
	if surface.map_id=="water_entry" and (at.x<-25.0 or at.z<-24.0):
		result.visible=false # Collision retained behind visible dense forest margin.
	if surface.map_id=="roots_terrace":result.visible=false
	return result

func block(at: Vector3,size: Vector3,color: Color,solid: bool=true) -> MeshInstance3D:
	prepare()
	var position := at+Vector3.UP*0.6 if size.y==1.4 else at
	var result := super.block(position,size,color,solid)
	var material: StandardMaterial3D=result.material_override
	material.albedo_color=Color("c5c3ab")
	material.albedo_texture=stone_texture
	material.uv1_triplanar=true
	material.uv1_scale=Vector3.ONE*0.45
	return result

func shadow(at: Vector3,size: Vector2,strength: float) -> void:
	var plane := PlaneMesh.new()
	plane.size=size
	var node := MeshInstance3D.new()
	node.mesh=plane
	var mat := ShaderMaterial.new()
	mat.shader=preload("res://game/contact.gdshader")
	mat.set_shader_parameter("tint",Color(0.05,0.12,0.09,strength))
	node.material_override=mat
	node.position=surface.ground(at,0.045)
	node.quaternion=Quaternion(Vector3.UP,surface.normal_at(at))
	parent.add_child(node)

func build(world: Node3D,land) -> void:
	cards.clear()
	prepare()
	super.build(world,land)
	if land.map_id=="roots_terrace":
		decorate_altar()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed=42917
	# A representative bank section: keep the playable path clear, layer margins.
	for i in range(180):
		var at := Vector3(rng.randf_range(-25,15),0,rng.randf_range(-24,12))
		if surface.path_distance(Vector2(at.x,at.z))<3.25:continue
		if surface.water_mask(at.x,at.z)<1.19:continue
		if at.distance_to(Vector3(-20,0,-3))<2.5:continue
		if at.distance_to(Vector3(21,0,-11))<4.0:continue
		var index := 1 if i%5<3 else (0 if i%5==3 else 2)
		var h := rng.randf_range(1.7,3.1) if index!=2 else rng.randf_range(2.7,4.0)
		card(at,index,h,rng.randf_range(0.87,1.0))
		if i%3==0:shadow(at,Vector2(2.7,1.5),0.2)
	# Ancient stonework frames the open northern bank without blocking its route.
	for at in [Vector3(-16,0,-18),Vector3(-5,0,-21),Vector3(10,0,-19)]:
		card(at,3,5.4)
		shadow(at,Vector2(2.5,1.8),0.3)
	for at in [Vector3(-10,0,-4),Vector3(-6,0,-8),Vector3(2,0,-9),Vector3(9,0,-4)]:
		card(at,4,2.3)
	for at in [Vector3(-21,0,-12),Vector3(-19,0,-22),Vector3(1,0,-23),Vector3(15,0,-20)]:tree(at,7.7,0)
	# Forest continues beyond the playable boundary instead of a visible board edge.
	for x in [-33.0,-30.0,-27.0]:
		for z in range(-30,15,3):
			card(Vector3(x+rng.randf_range(-0.5,0.5),0,z),2,rng.randf_range(4.0,5.5),0.78 if x<-30 else 0.9)
	for z in [-29.0,-26.0]:
		for x in range(-24,18,3):card(Vector3(x,0,z),2,4.7,0.83)

func decorate_altar() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed=1924
	# Distinct upper pillars and lower garden make the floor split legible.
	for at in [Vector3(-7.5,0,-14.5),Vector3(7.5,0,-14.5)]:
		card(at,3,5.2)
		shadow(at,Vector2(2.3,1.7),0.25)
	for at in [Vector3(-6,0,5),Vector3(6,0,5),Vector3(-8,0,-6.5),Vector3(8,0,-6.5)]:card(at,4,1.8)
	for i in range(70):
		var at := Vector3(rng.randf_range(-18,18),0,rng.randf_range(-21,16))
		# Keep stairs, approach, upper circulation and discovery unobstructed.
		if absf(at.x)<11.7 and at.z>-18.0 and at.z<12.0:continue
		card(at,1 if i%3!=0 else 2,rng.randf_range(2,3.8),rng.randf_range(0.8,1))
	for x in range(-19,20,3):card(Vector3(x,0,-23),2,5.0,0.85)
	for z in range(-22,18,3):
		card(Vector3(-20,0,z),2,4.6,0.82)
		card(Vector3(20,0,z),2,4.6,0.82)
	for x in [-18.0,18.0]:
		for z in range(-24,22,3):card(Vector3(x,0,z),2,5.4,0.88)
	for z in [-25.0,-22.0,18.0,21.0]:
		for x in range(-24,25,3):card(Vector3(x,0,z),1 if z>0 else 2,5.7,0.82)

func update_occlusion(camera: Camera3D,hero: Vector3) -> void:
	var screen := camera.unproject_position(hero+Vector3.UP*1.2)
	for sprite in cards:
		var base: Vector3=surface.ground(sprite.get_meta("base_at"))
		var p := camera.unproject_position(base+Vector3.UP*1.1)
		var faded := p.distance_to(screen)<90 and base.z>hero.z-0.3
		sprite.modulate.a=0.24 if faded else 1.0
		# Scissor remains crisp when opaque; use normal alpha blend for near foliage.
		sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISABLED if faded else SpriteBase3D.ALPHA_CUT_DISCARD
