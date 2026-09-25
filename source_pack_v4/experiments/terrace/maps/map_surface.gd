extends RefCounted
## Map-local height contract: rendering, collision and sampling share triangles.
const STEP := 0.25
const Altar=preload("res://maps/altar_layout.gd")
var map_id := "water_entry"
var art_enabled := true
var materials: Array[Texture2D]=[]
var water_texture: Texture2D
var bounds := Rect2(-27,-26,54,47)

func configure(id: String) -> void:
	map_id=id
	bounds=Rect2(-27,-26,54,47) if id=="water_entry" else Rect2(-18,-22,36,40)

func water_mask(x: float,z: float) -> float:
	if map_id!="water_entry":return 10.0
	return Vector2((x+1.0+sin(z*0.19)*2.0)/9.0,(z-3.0)/12.0).length()+0.035*sin(x*0.8+z*0.45)+0.022*cos(z*0.9)

func raw(x: float,z: float) -> float:
	if map_id=="roots_terrace":
		return Altar.height(x,z)
	var bank := smoothstep(0.94,1.18,water_mask(x,z))
	var rise := 2.7*smoothstep(0.0,17.0,-z)
	return lerpf(0.1,0.85+rise+0.12*sin(x*0.2)*sin(z*0.15),bank)

func height_at(at: Vector3) -> float:
	var x := floorf(at.x/STEP)*STEP
	var z := floorf(at.z/STEP)*STEP
	var u := (at.x-x)/STEP
	var v := (at.z-z)/STEP
	var a := raw(x,z)
	var b := raw(x+STEP,z)
	var c := raw(x+STEP,z+STEP)
	var d := raw(x,z+STEP)
	return a+(b-a)*u+(c-b)*v if u>=v else a+(c-d)*u+(d-a)*v

func ground(at: Vector3,lift: float=0.0) -> Vector3:
	return Vector3(at.x,height_at(at)+lift,at.z)

func normal_at(at: Vector3) -> Vector3:
	var e := 0.06
	return Vector3(height_at(at-Vector3(e,0,0))-height_at(at+Vector3(e,0,0)),2*e,height_at(at-Vector3(0,0,e))-height_at(at+Vector3(0,0,e))).normalized()

func path_distance(p: Vector2) -> float:
	var points := route()
	var result := 1000.0
	for i in range(points.size()-1):
		result=minf(result,p.distance_to(Geometry2D.get_closest_point_to_segment(p,points[i],points[i+1])))
	return result

func route() -> Array[Vector2]:
	if map_id=="roots_terrace":return Altar.route()
	return [Vector2(-19,15),Vector2(-16,6),Vector2(-15,-5),Vector2(-10,-12),Vector2(0,-15),Vector2(10,-13),Vector2(21,-11)]

func build(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in range(roundi(bounds.size.y/STEP)):
		for ix in range(roundi(bounds.size.x/STEP)):
			var x := bounds.position.x+ix*STEP
			var z := bounds.position.y+iz*STEP
			for p in [Vector2(x,z),Vector2(x+STEP,z),Vector2(x+STEP,z+STEP),Vector2(x,z),Vector2(x+STEP,z+STEP),Vector2(x,z+STEP)]:
				st.add_vertex(Vector3(p.x,raw(p.x,p.y),p.y))
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name="UnifiedTerrain"
	mesh.mesh=st.commit()
	var mat := ShaderMaterial.new()
	mat.shader=preload("res://maps/ground.gdshader")
	var points := route()
	mat.set_shader_parameter("route_count",points.size())
	while points.size()<7:points.append(points.back())
	mat.set_shader_parameter("route_points",PackedVector2Array(points))
	mat.set_shader_parameter("has_water",map_id=="water_entry")
	mat.set_shader_parameter("art_enabled",art_enabled)
	mat.set_shader_parameter("altar_field",map_id=="roots_terrace")
	if art_enabled:
		if materials.is_empty():
			var source := Image.load_from_file(ProjectSettings.globalize_path("res://maps/assets/surface_materials_v1.png"))
			var half := source.get_width()/2
			for i in range(4):
				var part := source.get_region(Rect2i((i%2)*half,(i/2)*half,half,half))
				part.generate_mipmaps()
				materials.append(ImageTexture.create_from_image(part))
		mat.set_shader_parameter("grass_tex",materials[0])
		mat.set_shader_parameter("dirt_tex",materials[1])
		mat.set_shader_parameter("paving_tex",materials[2])
		mat.set_shader_parameter("masonry_tex",materials[3])
		if water_texture==null:
			var water_image := Image.load_from_file(ProjectSettings.globalize_path("res://maps/assets/water_surface_v1.png"))
			water_image.generate_mipmaps()
			water_texture=ImageTexture.create_from_image(water_image)
		mat.set_shader_parameter("water_tex",water_texture)
	mesh.material_override=mat
	parent.add_child(mesh)
	mesh.create_trimesh_collision()
	# The visible water area is an impassable boundary, not a walkable floor.
	if map_id=="water_entry":
		for z in range(-8,15):
			for x in range(-12,11):
				if water_mask(x,z)<0.99:
					var body := StaticBody3D.new()
					var shape := CollisionShape3D.new()
					var cube := BoxShape3D.new()
					cube.size=Vector3(1,2.5,1)
					shape.shape=cube
					body.position=Vector3(x,0.7,z)
					body.add_child(shape)
					parent.add_child(body)
