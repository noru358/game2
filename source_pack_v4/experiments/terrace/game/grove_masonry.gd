extends RefCounted
const V=preload("res://game/visuals.gd")

static func wall(parent:Node3D,at:Vector3,size:Vector3)->Node3D:
	var solid:=V.box(parent,at,size,Color.WHITE,true)
	solid.get_child(0).hide()
	var along_x:=size.x>size.z
	var length:float=size.x if along_x else size.z
	var width:float=size.z if along_x else size.x
	var height:=at.y+size.y*0.5
	var count:=maxi(1,ceili(length/2.2))
	var pitch:=length/count
	var batches:Dictionary={}
	for i in range(count):
		var center:=at
		center.y=0
		if along_x:center.x+=-length*0.5+pitch*(i+0.5)
		else:center.z+=-length*0.5+pitch*(i+0.5)
		var support:=i%4==0
		var top:=height+(0.12 if support else -0.08*float(i%3))
		# Three stacked courses meet at their edges; no coplanar overlay faces.
		for band in [[0.0,0.24,width,Color("78664b")],[0.24,top-0.22,width if support else width*0.76,Color("a08a64")],[top-0.22,top,width,Color("b19c75")]]:
			var at_band:Vector3=center+Vector3.UP*(band[0]+band[1])*0.5
			var dimensions:=Vector3(pitch-0.02,band[1]-band[0],band[2]) if along_x else Vector3(band[2],band[1]-band[0],pitch-0.02)
			var color:Color=band[3]
			if not batches.has(color):
				var surface:=SurfaceTool.new()
				surface.begin(Mesh.PRIMITIVE_TRIANGLES)
				batches[color]=surface
			var block:=BoxMesh.new()
			block.size=dimensions
			batches[color].append_from(block,0,Transform3D(Basis.IDENTITY,at_band-at))
	# Keep one render mesh per course and wall, preserving the original collider.
	for color in batches:
		var mesh:=MeshInstance3D.new()
		mesh.mesh=batches[color].commit()
		mesh.material_override=V.stone_material(color)
		solid.add_child(mesh)
	return solid
