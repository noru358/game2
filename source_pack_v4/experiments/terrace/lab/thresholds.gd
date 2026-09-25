extends RefCounted
const V=preload("res://game/visuals.gd")
const Land=preload("res://game/landscape.gd")

static func rock(world:Node3D,at:Vector3,size:Vector3) -> void:
	# A lit, bevelled mass and its exact convex hull share one silhouette.
	var points:PackedVector3Array=[]
	for level in range(2):
		for i in range(8):
			var angle:=TAU*i/8.0
			var taper:=0.72 if level==1 else 1.0
			points.append(Vector3(cos(angle)*size.x*0.5*taper,0 if level==0 else size.y*(0.9+0.1*sin(i*2.0)),sin(angle)*size.z*0.5*taper))
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(8):
		var j:=(i+1)%8
		for vertex in [points[j],points[j+8],points[i],points[j+8],points[i+8],points[i],points[i+8],points[j+8],points[8]]:st.add_vertex(vertex)
	st.generate_normals()
	var mesh:=MeshInstance3D.new()
	mesh.mesh=st.commit()
	mesh.material_override=V.stone_material(Color("777b60"))
	var body:=StaticBody3D.new()
	body.position=Land.on_ground(at,-0.18)
	world.add_child(body)
	body.add_child(mesh)
	var collider:=CollisionShape3D.new()
	var hull:=ConvexPolygonShape3D.new()
	hull.points=points
	collider.shape=hull
	body.add_child(collider)

static func build(world:Node3D,chapter:int) -> void:
	var distant:=Sprite3D.new()
	distant.texture=preload("res://assets/environment/jungle_distance_v1.png")
	distant.pixel_size=70.0/distant.texture.get_width()
	distant.position=Vector3(158,8,-18)-Vector3(0,0.788,0.616)*30.0
	if chapter==2:distant.pixel_size=130.0/distant.texture.get_width()
	distant.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	if chapter==1:
		distant.position=Vector3(120,-3,-45)
		# Keep its framing but put the whole card behind the middle tree layer.
		distant.position-=Vector3(0,0.788,0.616)*30.0
		distant.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	distant.shaded=false
	# Opaque panorama lies behind the solid cliff, never alpha-blended over a road.
	distant.visible=chapter>0
	distant.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	world.add_child(distant)
	# Visible rock banks sit in front of the outer safety colliders.
	for side in [100.3,139.7]:
		for i in range(16):rock(world,Vector3(side,0,12.0-i*2.8),Vector3(2.1,1.8+0.3*sin(i),3.8))
	for z in [-31.7,13.7]:
		for x in range(102,139,3):
			if absf(x-110)<4:continue
			rock(world,Vector3(x,0,z),Vector3(4.1,2.0,2.3))
	# Both sides of a map connection use the same stone trail, trunks and sign.
	for z in [-29.0,10.0]:
		for offset in [-3.0,0.0,3.0]:Land.paving(world,Vector3(110,0,z+offset),Vector2(3.2,2.8),Land.PAVING_LIFT,Color("aaa080"))
		for side in [-1,1]:
			rock(world,Vector3(110+side*3.1,0,z),Vector3(2.2,2.1,3.0))
			V.tropical_prop(world,Land.on_ground(Vector3(110+side*4.0,0,z-1.8)),0,7.5)
		var sign_at:=Land.on_ground(Vector3(113,0,z+1))
		V.box(world,sign_at+Vector3.UP*0.75,Vector3(0.16,1.5,0.16),Color("59442f"))
		V.box(world,sign_at+Vector3.UP*1.25,Vector3(1.75,0.5,0.16),Color("7e6441"))
		var label:=Label3D.new()
		label.font=preload("res://assets/fonts/NanumGothic-Regular.ttf")
		label.font_size=30
		label.pixel_size=0.014
		label.position=sign_at+Vector3(0,1.8,0)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.text=("↑ "+world.TITLES[chapter+1] if chapter<2 else "↑ 여정의 끝") if z<0 else ("↓ "+world.TITLES[chapter-1] if chapter>0 else "여정의 시작")
		world.add_child(label)
