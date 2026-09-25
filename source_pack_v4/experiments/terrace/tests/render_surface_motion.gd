extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func close_color(a: Color,b: Color) -> bool:
	return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))) < 0.035
func run() -> void:
	var folder:=OS.get_environment("DEMO_QA_OUTPUT")
	if folder.is_empty():folder="res://docs/validation/d100"
	var world = load("res://game/world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.hud.hide()
	for e in world.enemies(): e.free()
	var materials:=[]
	for node in world.get_children():
		if node.has_meta("ground_clearance"):
			materials.append({"mat":node.material_override,"texture":node.material_override.albedo_texture})
	var regions := [Vector3(13,0,0),Vector3(12,0,-18),Vector3(8,0,-26),Vector3(16,0,-33),Vector3(4,0,-62),Vector3(33,0,-60),Vector3(28,0,-76),Vector3(44,0,-66),Vector3(44,0,-66),Vector3(28,0,-90),Vector3(14,0,-104),Vector3(28,0,-122),Vector3(38,0,-54),Vector3(38,0,-54)]
	for region in range(regions.size()):
		if region in [12,13]:
			world.waterworks.sluice_open=region==13
			world.waterworks.apply_sluice_state(true)
		if region==8:
			world.waterworks.sluice_open=true
			world.waterworks.apply_sluice_state(true)
		world.player.position = world.Landscape.on_ground(regions[region],0.1)
		world.update_camera(1)
		var camera_start: Vector3 = world.camera.position
		var candidates: Array = []
		var samples := 0
		var mismatches := 0
		for frame in range(24):
			world.camera.position = camera_start+Vector3(frame*0.012,0,frame*0.007)
			# Constant-color diagnostic pass checks surface visibility at fixed world
			# samples without treating texture filtering as a depth conflict.
			for entry in materials:entry.mat.albedo_texture=null
			await process_frame
			await RenderingServer.frame_post_draw
			var shot := root.get_texture().get_image()
			if frame == 0:
				for node in world.get_children():
					if not node.has_meta("ground_clearance") or not node.visible: continue
					var point: Vector3 = node.get_aabb().get_center()
					point.y = world.Landscape.height_at(point)+float(node.get_meta("ground_clearance"))
					var uv: Vector2 = world.camera.unproject_position(point) * Vector2(shot.get_size()) / root.get_visible_rect().size
					if uv.x<4 or uv.y<4 or uv.x>=shot.get_width()-4 or uv.y>=shot.get_height()-4: continue
					var color: Color = node.material_override.albedo_color
					var clear := true
					for dx in range(-2,3):
						for dy in range(-2,3):
							clear = clear and close_color(shot.get_pixel(int(uv.x)+dx,int(uv.y)+dy),color)
					if clear: candidates.append({"point":point,"color":color})
			for sample in candidates:
				var uv: Vector2 = world.camera.unproject_position(sample.point) * Vector2(shot.get_size()) / root.get_visible_rect().size
				samples += 1
				if not close_color(shot.get_pixel(int(uv.x),int(uv.y)),sample.color): mismatches += 1
			for entry in materials:entry.mat.albedo_texture=entry.texture
			await process_frame
			await RenderingServer.frame_post_draw
			shot=root.get_texture().get_image()
			if frame in [0,7,15,23]:
				shot.save_png(folder+"/surface-motion-%d-%02d.png"%[region,frame])
		var ok := candidates.size() >= 2 and mismatches == 0
		print("PASS " if ok else "FAIL ","moving camera region ",region," visible tiles=",candidates.size()," diagnostic samples=",samples," depth visibility mismatches=",mismatches,"; textured captures require visual review")
		if not ok: failures += 1
	print("RESULT failures=",failures)
	quit(1 if failures else 0)

