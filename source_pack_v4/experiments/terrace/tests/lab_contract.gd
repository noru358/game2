extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func run() -> void:
	for flat in [false,true]:
		set_meta("lab_flat",flat)
		var world=load("res://lab/world.tscn").instantiate()
		root.add_child(world)
		world.set_physics_process(false)
		world.player.set_physics_process(false)
		for e in world.enemies(): e.set_physics_process(false)
		await physics_frame
		await physics_frame
		var ground_count:=0
		var paving_samples:=0
		var valid:=true
		for node in world.get_children():
			if node is MeshInstance3D and node.material_override is ShaderMaterial and node.material_override.shader.resource_path.ends_with("lab/ground.gdshader"):ground_count+=1
			if not node.has_meta("ground_clearance"):continue
			var vertices: PackedVector3Array=node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for i in range(0,vertices.size(),3):
				var p: Vector3=(vertices[i]+vertices[i+1]+vertices[i+2])/3.0
				valid=valid and absf(p.y-world.Landscape.height_at(p)-float(node.get_meta("ground_clearance")))<0.001
				paving_samples+=1
		check(ground_count==1,"A" if flat else "B"+" owns one opaque terrain")
		check(valid and (flat or paving_samples>100),"paving follows shared triangle height contract")
		var probes:=0
		for x in [108.2,110.4,130.3,132.7]:
			for z in [7.2,-3.6,-12.3,-19.4]:
				var p:=Vector3(x,0,z)
				var query:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*20,p-Vector3.UP*3,1)
				var hit: Dictionary=world.get_world_3d().direct_space_state.intersect_ray(query)
				if not hit.is_empty() and absf(hit.position.y-world.Landscape.height_at(p))<0.02:probes+=1
		check(probes==16,"16 route probes match rendered and saved height")
		var target=world.enemies()[0]
		target.position=world.Landscape.on_ground(Vector3(120,0,-12),0.1)
		var origin: Vector3=world.Landscape.on_ground(Vector3(120,0,-4),0.1)
		check(world.visible_target(target,origin)==flat,"central wall changes magic line of sight between A and B")
		check(world.enemies().size()==12 and world.enemies().filter(func(e):return e.role=="charger").size()==3,"identical enemy count and roles")
		world.free()
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
