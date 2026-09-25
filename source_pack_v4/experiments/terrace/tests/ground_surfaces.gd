extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func run() -> void:
	var world = load("res://game/world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	var ground_faces := 0
	var paving_count := 0
	var valid := true
	for node in world.get_children():
		if not node is MeshInstance3D: continue
		if node.material_override is ShaderMaterial:
			var shader: Shader = node.material_override.shader
			if shader.resource_path.ends_with("ground.gdshader"): ground_faces += 1
			check(not shader.resource_path.ends_with("path.gdshader") and not shader.resource_path.ends_with("water.gdshader"),"no stacked path/water mesh")
		if not node.has_meta("ground_clearance"): continue
		paving_count += 1
		var vertices: PackedVector3Array = node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for i in range(0,vertices.size(),3):
			var a: Vector3 = node.to_global(vertices[i])
			var b: Vector3 = node.to_global(vertices[i+1])
			var c: Vector3 = node.to_global(vertices[i+2])
			for point in [a,b,c,(a+b+c)/3.0]:
				var clearance: float = point.y-world.Landscape.height_at(point)
				valid = valid and absf(clearance-float(node.get_meta("ground_clearance"))) < 0.001
	check(ground_faces == 4,"main, uphill, waterworks and facility terrain own ground appearance without ribbon overlays")
	check(paving_count > 20 and valid,"all paving vertices and triangle interiors clear terrain consistently")
	var box_tops: Array = []
	for node in world.get_children():
		if not node is Node3D or node.rotation.length() > 0.001: continue
		for child in node.get_children():
			if not child is MeshInstance3D or not child.visible or not child.mesh is BoxMesh: continue
			var size: Vector3 = child.mesh.size
			var center: Vector3 = child.global_position
			box_tops.append({"y":center.y+size.y/2,"rect":Rect2(center.x-size.x/2,center.z-size.z/2,size.x,size.z)})
	var overlapping_tops := 0
	for i in range(box_tops.size()):
		for j in range(i+1,box_tops.size()):
			if absf(box_tops[i].y-box_tops[j].y) > 0.0001: continue
			var overlap: Rect2 = box_tops[i].rect.intersection(box_tops[j].rect)
			if overlap.size.x > 0.0001 and overlap.size.y > 0.0001: overlapping_tops += 1
	check(overlapping_tops == 0,"static box tops never overlap coplanarly, including wall corners")
	# Probe tiles across BOTH slope transitions, including the formerly rotated flat upper area.
	for z in [-18.0,-35.0,-36.0]:
		var tile = world.Landscape.paving(world,Vector3(14,0,z),Vector2(1.2,1.2),0.09,Color.WHITE)
		var vertices: PackedVector3Array = tile.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var conforms := true
		for i in range(0,vertices.size(),3):
			var p := (vertices[i]+vertices[i+1]+vertices[i+2])/3.0
			conforms = conforms and absf(p.y-world.Landscape.height_at(p)-0.09)<0.001
		check(conforms,"paving conforms through slope boundary "+str(z))
	print("RESULT failures=",failures)
	quit(1 if failures else 0)

