extends RefCounted
const V = preload("res://game/visuals.gd")
const TRAIL := [Vector3(14,0,-10), Vector3(14,0,-18), Vector3(10,0,-20), Vector3(8,0,-25), Vector3(8,0,-27.5), Vector3(15,0,-30), Vector3(16,0,-33)]
const STREAM := [Vector3(18,0,-37), Vector3(17,0,-31), Vector3(8,0,-26), Vector3(12,0,-21), Vector3(16,0,-15), Vector3(18,0,-9)]

# Sample the same unit-grid triangles used by collision, including compound slopes.
static var lab_flat := false
static var lab_region := -1
static var sampled_cells:Dictionary={}
static var sampled_mode:=Vector2i(-99,-99)

static func cell_heights(x:float,z:float)->Vector4:
	# All consumers sample the same immutable unit grid. A region/mode change
	# invalidates it, including repeated scene creation during QA and travel.
	var mode:=Vector2i(lab_region,int(lab_flat))
	if sampled_mode!=mode:
		sampled_cells.clear()
		sampled_mode=mode
	var key:=Vector2i(int(x),int(z))
	if not sampled_cells.has(key):
		sampled_cells[key]=Vector4(raw_height(Vector3(x,0,z)),raw_height(Vector3(x+1,0,z)),raw_height(Vector3(x+1,0,z+1)),raw_height(Vector3(x,0,z+1)))
	return sampled_cells[key]

static func raw_height(at: Vector3) -> float:
	if at.x >= 90:
		if lab_flat:return 0.0
		if lab_region==1:
			# Curved jungle shelves: east ascent first, west ascent second.
			var edge_a:float=-6.5+sin((at.x-102)*0.20)*1.7
			var edge_b:float=-19.0+sin((at.x-104)*0.17)*1.3
			var lower:=clampf((edge_a-at.z)/1.2,0,1)*3.2
			var upper:=clampf((edge_b-at.z)/1.2,0,1)*3.8
			var east:=1.0-smoothstep(2.7,4.8,absf(at.x-132))
			var west:=1.0-smoothstep(2.8,4.8,absf(at.x-110))
			lower=lerpf(lower,clampf((-at.z-1)/10.0,0,1)*3.2,east)
			upper=lerpf(upper,clampf((-at.z-13)/11.0,0,1)*3.8,west)
			return lower+upper
		# Terrace faces and ramps belong to the same rendered/collision mesh.
		var stairs:=clampf((-at.z-7.0),0,1)*2.5+clampf((-at.z-17.0),0,1)*2.5
		var ramp:=clampf((-at.z-3.0)/7.0,0,1)*2.5+clampf((-at.z-13.0)/8.0,0,1)*2.5
		var left:=1.0-smoothstep(3.0,5.0,absf(at.x-110.0))
		var right:=1.0-smoothstep(2.0,4.0,absf(at.x-132.0))
		var water:=1.0-smoothstep(1.5,2.5,absf(at.x-120.0))
		return lerpf(stairs,ramp,maxf(water,maxf(left,right)))
	if at.z <= -86 and at.x >= -8 and at.x <= 52:
		return 4.35+clampf((-at.z-92)*0.15,0,3.0)
	if at.z <= -38 and at.x >= -8 and at.x <= 52:
		at=Vector3(16+(at.x-16)/2,at.y,-38+(at.z+38)/2)
		var rise := clampf((-at.z-38)*0.075,0,1.8)
		var ridge := minf(clampf((22-at.x)*0.25,0,2.5),minf(clampf((-at.z-38)*0.35,0,2.5),clampf((at.z+60)*0.4,0,2.5)))
		return 2.55+rise+ridge*1.6
	if at.x < 4 or at.x > 22 or at.z > -14: return 0.0
	return clampf((-at.z-18)*0.15,0,2.55)

static func height_at(at: Vector3) -> float:
	var x := floorf(at.x)
	var z := floorf(at.z)
	var u := at.x-x
	var v := at.z-z
	var heights:=cell_heights(x,z)
	var a:=heights.x
	var b:=heights.y
	var c:=heights.z
	var d:=heights.w
	return a+(b-a)*u+(c-b)*v if u>=v else a+(c-d)*u+(d-a)*v

static func on_ground(at: Vector3, lift: float = 0.0) -> Vector3:
	return Vector3(at.x,height_at(at)+lift,at.z)

static func normal_at(at: Vector3) -> Vector3:
	var x := floorf(at.x)
	var z := floorf(at.z)
	var h:=cell_heights(x,z)
	return Vector3(h.x-h.y,1,h.y-h.z).normalized() if at.x-x>=at.z-z else Vector3(h.w-h.z,1,h.x-h.w).normalized()

static func expand_old_waterworks(at: Vector3) -> Vector3:
	return Vector3(16+(at.x-16)*2,at.y,-38+(at.z+38)*2) if at.z < -38 else at

const FLOOD_CENTER := Vector2(43,-64)
const FLOOD_RADII := Vector2(7,11)

static func in_flood(at:Vector3,margin:float=0.0)->bool:
	return ((Vector2(at.x,at.z)-FLOOD_CENTER)/(FLOOD_RADII+Vector2.ONE*margin)).length()<1.0

const LOW_ROUTE := [Vector3(16,0,-33),Vector3(19,0,-36),Vector3(16,0,-42),Vector3(34,0,-50),Vector3(33,0,-62),Vector3(28,0,-76)]
const HIGH_ROUTE := [Vector3(16,0,-42),Vector3(4,0,-48),Vector3(4,0,-62),Vector3(20,0,-76),Vector3(28,0,-76)]
const UPPER_STREAM := [Vector3(28,0,-86),Vector3(30,0,-76),Vector3(32,0,-62),Vector3(26,0,-48),Vector3(18,0,-37)]

# One sampled centerline serves the shader, footsteps and spatial ambience.
# Joining upstream + downstream before interpolation removes the seam at z=-37.
static var WATER_COURSE: PackedVector3Array = build_water_course()

static func build_water_course() -> PackedVector3Array:
	var anchors: Array = UPPER_STREAM.duplicate()
	anchors.append_array(STREAM.slice(1))
	var result := PackedVector3Array()
	for i in range(anchors.size() - 1):
		var a: Vector3 = anchors[maxi(0,i-1)]
		var b: Vector3 = anchors[i]
		var c: Vector3 = anchors[i+1]
		var d: Vector3 = anchors[mini(anchors.size()-1,i+2)]
		for step in range(5):
			var t := float(step) / 5.0
			result.append(0.5 * ((2.0*b) + (c-a)*t + (2.0*a-5.0*b+4.0*c-d)*t*t + (-a+3.0*b-3.0*c+d)*t*t*t))
	result.append(anchors[-1])
	return result

static func water_distance(at: Vector3) -> float:
	var point := Vector2(at.x, at.z)
	var nearest := INF
	for i in range(WATER_COURSE.size()-1):
		var a := Vector2(WATER_COURSE[i].x, WATER_COURSE[i].z)
		var b := Vector2(WATER_COURSE[i+1].x, WATER_COURSE[i+1].z)
		nearest = minf(nearest, point.distance_squared_to(Geometry2D.get_closest_point_to_segment(point,a,b)))
	return sqrt(nearest)

# Ground ownership: soil/path/water share one opaque surface. Never stack road ribbons.
const PAVING_LIFT := 0.09
const CROSSING_LIFT := 0.13
const MARKER_LIFT := 0.22
const MAIN_TRAIL := [Vector3(-20,0,0),Vector3(5,0,0),Vector3(14,0,0),Vector3(14,0,-10)]

static func floor_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://game/ground.gdshader")
	mat.set_shader_parameter("flood_center",FLOOD_CENTER)
	mat.set_shader_parameter("flood_radii",FLOOD_RADII)
	mat.set_shader_parameter("ground_texture",preload("res://assets/environment/forest_floor_v1.png"))
	mat.set_shader_parameter("stone_texture",preload("res://assets/environment/reservoir_floor_v1.png"))
	for entry in [["main_points",MAIN_TRAIL],["trail_points",TRAIL],["water_points",WATER_COURSE],["low_points",LOW_ROUTE],["high_points",HIGH_ROUTE]]:
		var points := PackedVector2Array()
		for p in entry[1]: points.append(Vector2(p.x,p.z))
		mat.set_shader_parameter(entry[0],points)
	return mat

static func make_terrain(parent: Node3D, rect: Rect2, solid: bool = true) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(rect.position.y), int(rect.end.y)):
		for x in range(int(rect.position.x), int(rect.end.x)):
			var a := on_ground(Vector3(x,0,z))
			var b := on_ground(Vector3(x+1,0,z))
			var c := on_ground(Vector3(x+1,0,z+1))
			var d := on_ground(Vector3(x,0,z+1))
			# Godot uses clockwise front faces; upward winding also defines one-sided terrain collision.
			for p in [a,b,c,a,c,d]:
				surface.set_uv(Vector2(p.x,p.z) / 10.0)
				surface.add_vertex(p)
	if rect.position.x>=90 and lab_region==2:
		# Close the eastern shelf with a real side face, sharing the exact top edge.
		for z in range(int(rect.position.y),int(rect.end.y)):
			var a:=on_ground(Vector3(rect.end.x,0,z))
			var b:=on_ground(Vector3(rect.end.x,0,z+1))
			var c:=Vector3(b.x+3.5,-10,b.z)
			var d:=Vector3(a.x+3.5,-10,a.z)
			for p in [a,c,b,a,d,c]:
				surface.set_uv(Vector2(p.z,p.y)/10.0)
				surface.add_vertex(p)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.material_override = floor_material()
	if rect.position.x >= 90:
		var lab_material := ShaderMaterial.new()
		lab_material.shader=preload("res://lab/ground.gdshader")
		lab_material.set_shader_parameter("soil_texture",preload("res://assets/environment/forest_floor_v1.png"))
		lab_material.set_shader_parameter("stone_texture",preload("res://assets/environment/reservoir_floor_v1.png"))
		mesh.material_override=lab_material
	parent.add_child(mesh)
	if solid:
		mesh.create_trimesh_collision()
	return mesh

static func add_ground_polygon(surface: SurfaceTool, polygon: Array, lift: float) -> void:
	# Clip paving against actual collision triangles, not a separate approximation of slopes.
	var outline := PackedVector2Array()
	var bounds := Rect2(Vector2(polygon[0].p.x,polygon[0].p.z),Vector2.ZERO)
	for data in polygon:
		var point := Vector2(data.p.x,data.p.z)
		outline.append(point)
		bounds = bounds.expand(point)
	for z in range(int(floorf(bounds.position.y)),int(ceilf(bounds.end.y))):
		for x in range(int(floorf(bounds.position.x)),int(ceilf(bounds.end.x))):
			var a := Vector2(x,z)
			var b := Vector2(x+1,z)
			var c := Vector2(x+1,z+1)
			var d := Vector2(x,z+1)
			for tri in [PackedVector2Array([a,b,c]),PackedVector2Array([a,c,d])]:
				for piece in Geometry2D.intersect_polygons(outline,tri):
					var indices := Geometry2D.triangulate_polygon(piece)
					for index in indices:
						var point: Vector2 = piece[index]
						surface.set_uv(point)
						surface.add_vertex(on_ground(Vector3(point.x,0,point.y),lift))

static func paving(parent: Node3D, at: Vector3, size: Vector2, lift: float, color: Color) -> MeshInstance3D:
	# A single top follows every terrain slope transition; no buried coplanar bottom face.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var polygon: Array = []
	for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
		polygon.append({"p":at+Vector3(corner.x*size.x/2,0,corner.y*size.y/2),"uv":corner})
	add_ground_polygon(surface,polygon,lift)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = V.material(color.lightened(0.22))
	mesh.material_override.albedo_texture=preload("res://assets/environment/reservoir_floor_v1.png")
	mesh.material_override.uv1_scale=Vector3(0.125,0.125,1)
	mesh.material_override.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mesh.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.set_meta("ground_clearance",lift)
	parent.add_child(mesh)
	return mesh

static func masonry(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid: bool = false) -> Node3D:
	return V.stone_box(parent,at,size,color,solid)

static func build_connections(parent: Node3D) -> void:
	# The old arch stands at the crossing; its stone apron carries the same paving as the trail.
	for i in range(8):
		var p := Vector3(8,0,-24.8-i*0.35)
		paving(parent,p,Vector2(2.7,0.32),CROSSING_LIFT,Color("8a8b74"))
	for segment in range(TRAIL.size()-1):
		var a: Vector3 = TRAIL[segment]
		var b: Vector3 = TRAIL[segment+1]
		for i in range(int(a.distance_to(b)/1.5)):
			var p := a.lerp(b, float(i)/maxf(1,int(a.distance_to(b)/1.5)))
			if absf(p.z+26) < 1.6:
				continue
			paving(parent,p,Vector2(1.25,0.65),PAVING_LIFT,Color("777d67"))
	# Damaged retaining walls follow the raised banks, with deliberate openings at the bends.
	for data in [[17.5,-22.0,8.0],[8.0,-29.0,8.0]]:
		for i in range(int(data[2]/0.9)):
			var p := Vector3(data[0]-data[2]*0.5+i*0.9,0,data[1])
			masonry(parent,on_ground(p,0.6),Vector3(0.85,1.2,0.9),Color("5c6b59"),true)
	# Trail-side waystones carry the same lozenge motif as the guardian and old gateway.
	for p in [Vector3(15.8,0,-13),Vector3(11.5,0,-24),Vector3(17.7,0,-32)]:
		masonry(parent,on_ground(p,0.45),Vector3(0.45,0.9,0.4),Color("8e9580"),true)
		var mark := V.box(parent,on_ground(p,0.92),Vector3(0.16,0.16,0.08),Color("9ce4c6"))
		mark.rotation.z = PI/4

static func wet_at(at: Vector3) -> bool:
	if absf(at.z + 26) < 1.6 and absf(at.x-8) < 1.4:
		return false
	return water_distance(at) < 0.65
