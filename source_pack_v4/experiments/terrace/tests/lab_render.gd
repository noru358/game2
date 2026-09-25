extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var folder:=OS.get_environment("DEMO_QA_OUTPUT")
	if folder.is_empty():folder="res://docs/validation/d100"
	for flat in [false,true]:
		set_meta("lab_flat",flat)
		var world=load("res://lab/world.tscn").instantiate()
		root.add_child(world)
		world.set_physics_process(false)
		world.player.set_physics_process(false)
		for e in world.enemies():e.set_physics_process(false)
		var sites: Array=[Vector3(110,0,8),Vector3(110,0,-7),Vector3(120,0,-22),Vector3(132,0,-10)]
		for i in range(sites.size()):
			world.player.position=world.Landscape.on_ground(sites[i],0.1)
			world.update_camera(1)
			world.update_hud()
			var initial: Vector3=world.camera.position
			for frame in range(24):
				world.camera.position=initial+Vector3(frame*0.012,0,frame*0.007)
				await process_frame
				await RenderingServer.frame_post_draw
				if frame in [0,7,15,23]:
					var error: Error=root.get_texture().get_image().save_png(folder+"/lab-%s-%d-%02d.png"%["A" if flat else "B",i,frame])
					if error!=OK:failures+=1
		world.free()
	print("RESULT capture failures=",failures,"; 8 viewpoints / 192 frames; visual review required")
	quit(1 if failures else 0)
