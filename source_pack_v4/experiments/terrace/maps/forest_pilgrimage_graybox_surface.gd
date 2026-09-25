extends RefCounted
## One continuous ground surface for the three-act forest pilgrimage graybox.
const V=preload("res://game/visuals.gd")
const STEP:=0.75
const WATER_Y:=-1.55
var map_id:="forest_pilgrimage_graybox"
var bounds:=Rect2(-45,-56,85,116)
var art_enabled:=false
var art_materials: Array[Texture2D]=[]
var water_texture: Texture2D

func route() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-12,36),Vector2(-6,29),Vector2(1,21),Vector2(-6,13),
		Vector2(5,4),Vector2(-3,-6),Vector2(-1,-14),Vector2(-6,-22),
		Vector2(-2,-30),Vector2(-2,-37)
	])

func bank_x(z: float) -> float:
	return 10.0+sin((z+10.0)*0.13)*5.0+sin((z-4.0)*0.045)*2.0

func bank_distance(x: float,z: float) -> float:
	return bank_x(z)-x

func path_distance(p: Vector2) -> float:
	var points:=route()
	var result:=1000.0
	for i in range(points.size()-1):
		result=minf(result,p.distance_to(Geometry2D.get_closest_point_to_segment(p,points[i],points[i+1])))
	return result

func zone_at(at: Vector3) -> int:
	if at.z>=20.0:return 0
	if at.z>-25.0:return 1
	return 2

func land_height(z: float) -> float:
	if z>=22.0:return 0.70
	if z>=12.0:return lerpf(0.70,1.35,(22.0-z)/10.0)
	if z>=-6.0:return 1.35
	if z>=-16.0:return lerpf(1.35,2.75,(-6.0-z)/10.0)
	if z>=-23.0:return 2.75
	if z>=-29.0:
		var progress:=clampf((-23.0-z)/6.0,0.0,0.999)
		return lerpf(2.75,5.0,floorf(progress*9.0)/8.0)
	return 5.0

func raw(x: float,z: float) -> float:
	var shore:=smoothstep(-0.2,1.6,bank_distance(x,z))
	return lerpf(WATER_Y,land_height(z),shore)

func height_at(at: Vector3) -> float:
	var x:=floorf(at.x/STEP)*STEP
	var z:=floorf(at.z/STEP)*STEP
	var u:=(at.x-x)/STEP
	var v:=(at.z-z)/STEP
	var a:=raw(x,z)
	var b:=raw(x+STEP,z)
	var c:=raw(x+STEP,z+STEP)
	var d:=raw(x,z+STEP)
	return a+(b-a)*u+(c-b)*v if u>=v else a+(c-d)*u+(d-a)*v

func ground(at: Vector3,lift: float=0.0) -> Vector3:
	return Vector3(at.x,height_at(at)+lift,at.z)

func normal_at(at: Vector3) -> Vector3:
	var e:=0.08
	return Vector3(height_at(at-Vector3(e,0,0))-height_at(at+Vector3(e,0,0)),2.0*e,height_at(at-Vector3(0,0,e))-height_at(at+Vector3(0,0,e))).normalized()

func color_at(p: Vector2) -> Color:
	var shore:=bank_distance(p.x,p.y)
	if shore<0.55:return Color("3c8991")
	var base:=Color("647d62")
	if p.y>=20.0:base=Color("63745d")
	elif p.y<=-25.0:base=Color("788164")
	var path_weight:=1.0-smoothstep(3.2,6.5,path_distance(p))
	var path_color:=Color("a69a72") if p.y>-25.0 else Color("aaa17f")
	var result:=base.lerp(path_color,path_weight*0.78)
	var edge_weight:=1.0-smoothstep(0.55,2.5,shore)
	return result.lerp(Color("59745f"),edge_weight*0.65)

func hidden_wall(parent: Node3D,at: Vector3,size: Vector3) -> void:
	var wall:=V.box(parent,at,size,Color("203833"),true)
	wall.get_child(0).hide()

func build(parent: Node3D) -> void:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in range(roundi(bounds.size.y/STEP)):
		for ix in range(roundi(bounds.size.x/STEP)):
			var x:=bounds.position.x+ix*STEP
			var z:=bounds.position.y+iz*STEP
			for p in [Vector2(x,z),Vector2(x+STEP,z),Vector2(x+STEP,z+STEP),Vector2(x,z),Vector2(x+STEP,z+STEP),Vector2(x,z+STEP)]:
				st.set_color(color_at(p))
				st.add_vertex(Vector3(p.x,raw(p.x,p.y),p.y))
	st.generate_normals()
	var mesh:=MeshInstance3D.new()
	mesh.name="ForestPilgrimageSurface"
	mesh.mesh=st.commit()
	var material: Material
	if art_enabled:
		var shader_material:=ShaderMaterial.new()
		shader_material.shader=preload("res://maps/forest_pilgrimage_ground.gdshader")
		var points:=route()
		shader_material.set_shader_parameter("route_count",points.size())
		shader_material.set_shader_parameter("route_points",points)
		if art_materials.is_empty():
			var source:=Image.load_from_file(ProjectSettings.globalize_path("res://maps/assets/surface_materials_v1.png"))
			var half:=source.get_width()/2
			for i in range(4):
				var part:=source.get_region(Rect2i((i%2)*half,(i/2)*half,half,half))
				part.generate_mipmaps()
				art_materials.append(ImageTexture.create_from_image(part))
		shader_material.set_shader_parameter("grass_tex",art_materials[0])
		shader_material.set_shader_parameter("dirt_tex",art_materials[1])
		shader_material.set_shader_parameter("paving_tex",art_materials[2])
		shader_material.set_shader_parameter("masonry_tex",art_materials[3])
		if water_texture==null:
			var water_image:=Image.load_from_file(ProjectSettings.globalize_path("res://maps/assets/water_surface_v1.png"))
			water_image.generate_mipmaps()
			water_texture=ImageTexture.create_from_image(water_image)
		shader_material.set_shader_parameter("water_tex",water_texture)
		material=shader_material
	else:
		var flat_material:=StandardMaterial3D.new()
		flat_material.vertex_color_use_as_albedo=true
		flat_material.roughness=0.96
		material=flat_material
	mesh.material_override=material
	parent.add_child(mesh)
	mesh.create_trimesh_collision()
	# Water remains visible but the river edge is not traversable in this graybox.
	for z in range(-55,60):
		hidden_wall(parent,Vector3(bank_x(float(z))+0.25,land_height(float(z))+0.8,float(z)),Vector3(1.5,4.8,1.25))
	hidden_wall(parent,Vector3(bounds.position.x,3,-1),Vector3(0.8,9,bounds.size.y))
	hidden_wall(parent,Vector3(bounds.get_center().x,3,bounds.position.y),Vector3(bounds.size.x,9,0.8))
	hidden_wall(parent,Vector3(bounds.get_center().x,3,bounds.end.y),Vector3(bounds.size.x,9,0.8))
