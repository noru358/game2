extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://game/world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.waterworks.reclaimed=true
	world.facility.entrance_open=true
	world.facility.refresh()
	await physics_frame
	await physics_frame
	for z in [-15,-18,-26,-33,-86,-90,-99,-108,-115,-123]:
		var x:=28 if z==-86 else 14
		var ray := PhysicsRayQueryParameters3D.create(Vector3(x,10,z),Vector3(x,-10,z),1)
		var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(ray)
		var valid: bool = not hit.is_empty() and hit.normal.y > 0.9 and absf(hit.position.y-world.Landscape.height_at(Vector3(x,0,z))) < 0.01
		print("PASS " if valid else "FAIL ","terrain collision agrees with elevation at ",z)
		if not valid: failures += 1
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
