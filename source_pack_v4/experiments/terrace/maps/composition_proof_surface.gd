extends RefCounted
## Authored land masses for the map philosophy proof. No sine-wave shelf or corridor template.
const V=preload("res://game/visuals.gd")
const WATER_Y := -1.45
const MAIN_Y := 0.75
const UPPER_Y := 4.75
const STAIR_START := -5.5
const STAIR_END := -14.5
const STAIR_CENTER_X := 128.0
const STAIR_HALF_WIDTH := 2.8
const STEPS := 18
const STEP := 0.25
var map_id := "composition_proof"
var bounds := Rect2(88,-31,64,60)
var materials: Array[Texture2D]=[]
var water_texture: Texture2D

func main_polygon() -> PackedVector2Array:
	return PackedVector2Array([Vector2(103,16),Vector2(102,5),Vector2(108,-5),Vector2(120,-8),Vector2(124,-6),Vector2(132,-5),Vector2(143,1),Vector2(145,12),Vector2(137,19),Vector2(119,21),Vector2(109,20)])

func upper_polygon() -> PackedVector2Array:
	return PackedVector2Array([Vector2(112,-13),Vector2(118,-27),Vector2(143,-29),Vector2(151,-20),Vector2(148,-8),Vector2(137,-10),Vector2(134,-13),Vector2(130.8,-13),Vector2(130.8,-14.5),Vector2(125.2,-14.5),Vector2(125.2,-13)])

func entry_polygon() -> PackedVector2Array:
	return PackedVector2Array([Vector2(89,16),Vector2(97,12),Vector2(104,16),Vector2(104,24),Vector2(98,29),Vector2(88,25)])

func inside(p: Vector2,polygon: PackedVector2Array) -> bool:
	return Geometry2D.is_point_in_polygon(p,polygon)

func bridge_distance(p: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p,Vector2(100.5,19.5),Vector2(108.0,16.0)))

func on_bridge(p: Vector2) -> bool:
	return bridge_distance(p)<=1.55

func on_stairs(x: float,z: float) -> bool:
	return absf(x-STAIR_CENTER_X)<=STAIR_HALF_WIDTH and z<=STAIR_START and z>=STAIR_END

func stair_height(x: float,z: float) -> float:
	var side_fade:=1.0-smoothstep(STAIR_HALF_WIDTH-0.3,STAIR_HALF_WIDTH,absf(x-STAIR_CENTER_X))
	var progress:=clampf((STAIR_START-z)/(STAIR_START-STAIR_END),0.0,0.9999)*STEPS
	var index:=floorf(progress)
	var phase:=progress-index
	var bevel:=minf(phase*2.0,1.0)*0.9+maxf(phase*2.0-1.0,0.0)*0.1
	return MAIN_Y+(UPPER_Y-MAIN_Y)*((index+bevel)/STEPS)*side_fade

func height_at(at: Vector3) -> float:
	var p:=Vector2(at.x,at.z)
	if on_stairs(at.x,at.z):return stair_height(at.x,at.z)
	if inside(p,upper_polygon()):return UPPER_Y
	if inside(p,main_polygon()) or inside(p,entry_polygon()) or on_bridge(p):return MAIN_Y
	return WATER_Y

func ground(at: Vector3,lift: float=0.0) -> Vector3:
	return Vector3(at.x,height_at(at)+lift,at.z)

func normal_at(at: Vector3) -> Vector3:
	var e:=0.06
	return Vector3(height_at(at-Vector3(e,0,0))-height_at(at+Vector3(e,0,0)),2.0*e,height_at(at-Vector3(0,0,e))-height_at(at+Vector3(0,0,e))).normalized()

func prepare_materials() -> void:
	if not materials.is_empty():return
	var source:=Image.load_from_file(ProjectSettings.globalize_path("res://maps/assets/surface_materials_v1.png"))
	var half:=source.get_width()/2
	for i in range(4):
		var part:=source.get_region(Rect2i((i%2)*half,(i/2)*half,half,half))
		part.generate_mipmaps()
		materials.append(ImageTexture.create_from_image(part))
	var water_image:=Image.load_from_file(ProjectSettings.globalize_path("res://maps/assets/water_surface_v1.png"))
	water_image.generate_mipmaps()
	water_texture=ImageTexture.create_from_image(water_image)

func ground_material(kind: int) -> ShaderMaterial:
	prepare_materials()
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://maps/composition_proof_ground.gdshader")
	mat.set_shader_parameter("grass_tex",materials[0])
	mat.set_shader_parameter("dirt_tex",materials[1])
	mat.set_shader_parameter("paving_tex",materials[2])
	mat.set_shader_parameter("masonry_tex",materials[3])
	mat.set_shader_parameter("surface_kind",kind)
	return mat

func add_prism(parent: Node3D,polygon: PackedVector2Array,top_y: float,bottom_y: float,kind: int,name_value: String) -> MeshInstance3D:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices:=Geometry2D.triangulate_polygon(polygon)
	for index in indices:
		var p:=polygon[index]
		st.set_uv(p/8.0)
		st.add_vertex(Vector3(p.x,top_y,p.y))
	for i in range(polygon.size()):
		var a:=polygon[i]
		var b:=polygon[(i+1)%polygon.size()]
		var pairs: Array=[[a,b]]
		# The concave shrine front has one authored stair opening. Do not add a
		# vertical facade across the back of that notch.
		if name_value=="ShrineLandform" and absf(a.y-STAIR_END)<0.01 and absf(b.y-STAIR_END)<0.01:
			pairs=[]
		for pair in pairs:
			var side_a: Vector2=pair[0]
			var side_b: Vector2=pair[1]
			for v in [Vector3(side_a.x,top_y,side_a.y),Vector3(side_a.x,bottom_y,side_a.y),Vector3(side_b.x,bottom_y,side_b.y),Vector3(side_a.x,top_y,side_a.y),Vector3(side_b.x,bottom_y,side_b.y),Vector3(side_b.x,top_y,side_b.y)]:
				st.set_uv(Vector2(v.x,v.y)/8.0)
				st.add_vertex(v)
	st.generate_normals()
	var mesh:=MeshInstance3D.new()
	mesh.name=name_value
	mesh.mesh=st.commit()
	mesh.material_override=ground_material(kind)
	parent.add_child(mesh)
	mesh.create_trimesh_collision()
	return mesh

func add_stairs(parent: Node3D) -> MeshInstance3D:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0:=STAIR_CENTER_X-STAIR_HALF_WIDTH
	var width:=STAIR_HALF_WIDTH*2.0
	var depth:=STAIR_START-STAIR_END
	for iz in range(roundi(depth/STEP)):
		for ix in range(roundi(width/STEP)):
			var x:=x0+ix*STEP
			var z:=STAIR_END+iz*STEP
			for p in [Vector2(x,z),Vector2(x+STEP,z),Vector2(x+STEP,z+STEP),Vector2(x,z),Vector2(x+STEP,z+STEP),Vector2(x,z+STEP)]:
				st.set_uv(p/6.0)
				st.add_vertex(Vector3(p.x,stair_height(p.x,p.y),p.y))
	st.generate_normals()
	var mesh:=MeshInstance3D.new()
	mesh.name="SharedStairSurface"
	mesh.mesh=st.commit()
	mesh.material_override=ground_material(3)
	parent.add_child(mesh)
	mesh.create_trimesh_collision()
	return mesh

func add_water(parent: Node3D) -> void:
	prepare_materials()
	var plane:=PlaneMesh.new()
	plane.size=bounds.size
	var node:=MeshInstance3D.new()
	node.name="WaterBackdrop"
	node.mesh=plane
	node.position=Vector3(bounds.get_center().x,WATER_Y,bounds.get_center().y)
	var mat:=StandardMaterial3D.new()
	mat.albedo_texture=water_texture
	mat.albedo_color=Color("5a9a96")
	mat.uv1_scale=Vector3(5.2,3.8,1)
	mat.roughness=0.55
	mat.metallic_specular=0.2
	node.material_override=mat
	parent.add_child(node)

func build(parent: Node3D) -> void:
	add_water(parent)
	add_prism(parent,entry_polygon(),MAIN_Y,WATER_Y-0.35,2,"EntryLandform")
	add_prism(parent,main_polygon(),MAIN_Y,WATER_Y-0.35,0,"CombatLandform")
	add_prism(parent,upper_polygon(),UPPER_Y,WATER_Y-0.35,1,"ShrineLandform")
	add_stairs(parent)
