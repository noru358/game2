extends RefCounted
const Land=preload("res://game/landscape.gd")
const Surface=preload("res://game/effect_surface.gd")
const V=preload("res://game/visuals.gd")
static func make(parent:Node,center:Vector3,radius:float,color:Color)->MeshInstance3D:
	var node:=MeshInstance3D.new()
	node.mesh=ArrayMesh.new()
	node.material_override=V.material(Color.WHITE)
	node.material_override.vertex_color_use_as_albedo=true
	node.set_meta("warning_color",color)
	node.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	draw(node,center,radius)
	return node
static func draw(node:MeshInstance3D,center:Vector3,radius:float)->void:
	if unchanged(node,["ring",center,radius]):return
	var plane:=Surface.sample_plane(center)
	var inverse:=node.global_transform.affine_inverse()
	var points:=PackedVector3Array()
	var supported:=PackedByteArray()
	var units:=PackedVector3Array()
	# Each shared edge is sampled once, rather than once per triangle corner.
	for i in range(65):
		var unit:=Vector3(cos(i*TAU/64),0,sin(i*TAU/64))
		units.append(unit)
		for width in [-0.115,-0.065,0.065,0.115]:
			var offset:=unit*maxf(0,radius+width)
			points.append(inverse*Surface.plane_point(center,offset,plane))
			supported.append(int(Surface.plane_supported(center,offset,plane)))
	var vertices:=PackedVector3Array()
	var colors:=PackedColorArray()
	for i in range(64):
		if not Surface.plane_supported(center,(units[i]+units[i+1])*0.5*radius,plane):continue
		for band in range(3):
			var a:=i*4+band
			var b:=(i+1)*4+band
			if not (supported[a] and supported[a+1] and supported[b] and supported[b+1]):continue
			var color:Color=node.get_meta("warning_color") if band==1 else Color("241b20")
			for index in [a,a+1,b+1,a,b+1,b]:
				vertices.append(points[index])
				colors.append(color)
	commit(node,vertices,colors)

static func draw_lane(node:MeshInstance3D,center:Vector3,direction:Vector3,length:float=5.0,width:float=0.55)->void:
	if unchanged(node,["lane",center,direction,length,width]):return
	var plane:=Surface.sample_plane(center)
	var inverse:=node.global_transform.affine_inverse()
	var vertices:=PackedVector3Array()
	var colors:=PackedColorArray()
	var points:=PackedVector3Array()
	var supported:=PackedByteArray()
	var side:=direction.cross(Vector3.UP).normalized()*width*0.5
	for i in range(41):
		for offset in [direction*length*float(i)/40.0-side,direction*length*float(i)/40.0+side]:
			points.append(inverse*Surface.plane_point(center,offset,plane))
			supported.append(int(Surface.plane_supported(center,offset,plane)))
	for i in range(40):
		var a:=i*2
		if not (supported[a] and supported[a+1] and supported[a+2] and supported[a+3]):continue
		for index in [a,a+1,a+3,a,a+3,a+2]:
			vertices.append(points[index])
			colors.append(node.get_meta("warning_color"))
	commit(node,vertices,colors)

static func commit(node:MeshInstance3D,vertices:PackedVector3Array,colors:PackedColorArray)->void:
	node.set_meta("surface_vertices",vertices.size())
	if vertices.is_empty():
		vertices=PackedVector3Array([Vector3.ZERO,Vector3.ZERO,Vector3.ZERO])
		colors=PackedColorArray([Color.WHITE,Color.WHITE,Color.WHITE])
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_COLOR]=colors
	var mesh:ArrayMesh=node.mesh
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)

static func unchanged(node:MeshInstance3D,shape:Array)->bool:
	# Telegraphs are stationary during windup; only rebuild for changed geometry,
	# transform, terrain or tint. Animated caster radii still redraw normally.
	shape.append_array([node.global_transform,Land.lab_region,Land.lab_flat,Surface.signature(),node.get_meta("warning_color")])
	if node.get_meta("warning_signature",[])==shape:return true
	node.set_meta("warning_signature",shape)
	node.set_meta("warning_builds",int(node.get_meta("warning_builds",0))+1)
	return false
