extends RefCounted
const V=preload("res://game/visuals.gd")
const Land=preload("res://game/landscape.gd")
static func root_span(world:Node3D,at:Vector3,length:float,radius:float) -> Node3D:
	var body:=StaticBody3D.new()
	body.position=Land.on_ground(at,radius*0.65)
	world.add_child(body)
	var mesh:=MeshInstance3D.new()
	var cylinder:=CylinderMesh.new()
	cylinder.top_radius=radius*0.65
	cylinder.bottom_radius=radius
	cylinder.height=length
	cylinder.radial_segments=9
	mesh.mesh=cylinder
	mesh.rotation.x=PI/2
	var bark:=V.material(Color("65533c"))
	bark.albedo_texture=preload("res://assets/environment/reservoir_masonry_v1.png")
	bark.uv1_scale=Vector3(0.22,2.5,1)
	mesh.material_override=bark
	body.add_child(mesh)
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=Vector3(radius*1.5,radius*1.5,length)
	shape.shape=box
	body.add_child(shape)
	return body
static func build(world:Node3D) -> void:
	# The cliff is the actual terrain, not a facade laid over a walkable plane.
	# Roots connect planted trees to that mass while leaving both ascent lanes open.
	for at in [Vector3(104,0,-10),Vector3(118,0,-11),Vector3(124,0,-23),Vector3(137,0,-23)]:
		V.tropical_prop(world,Land.on_ground(at),0,7.0)
		root_span(world,at+Vector3(1,0,1.4),3.2,0.7)
	world.shortcut_body=root_span(world,Vector3(120,0,-12),5.4,1.0)
	for z in [1.0,-2.0,-5.0,-8.0,-11.0]:Land.paving(world,Vector3(132,0,z),Vector2(1.8,1.4),Land.PAVING_LIFT,Color("96977a"))
	for z in [-13.0,-16.0,-19.0,-22.0]:Land.paving(world,Vector3(110,0,z),Vector2(1.9,1.4),Land.PAVING_LIFT,Color("96977a"))
	# A broad inhabited lookout belongs to the upper shelf, with a low stone lip.
	Land.paving(world,Vector3(128,0,-28),Vector2(8,3.8),Land.PAVING_LIFT,Color("a69d81"))
	for x in [124.0,128.0,132.0]:V.stone_box(world,Land.on_ground(Vector3(x,0,-30.5),0.4),Vector3(3.8,0.8,0.65),Color("7e806b"),true)
	# Outside the playable boundary, a middle tree layer breaks the panorama seam.
	for x in [102.0,116.0,120.0,135.0,141.0]:
		V.tropical_prop(world,Vector3(x,3.4,-34.5),0,5.5+sin(x)*0.8)
