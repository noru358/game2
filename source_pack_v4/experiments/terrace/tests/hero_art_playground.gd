extends SceneTree
var failures := 0
var samples: Array=[]
var world
func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func release() -> void:
	for action in ["left","right","up","down","dash"]:Input.action_release(action)
func shot(name: String) -> void:
	world.update_art()
	world.update_camera(1)
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OS.get_environment("HERO_QA_OUTPUT")+"/"+name+".png")
	check(error==OK,"capture "+name)
func run() -> void:
	root.size=Vector2i(1152,720)
	root.content_scale_size=Vector2i(1152,720)
	world=load("res://lab/hero_art_playground.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	check(world.test_mode and world.save_queue==null,"isolated test mode; no save queue")
	check(world.enemies().is_empty(),"asset preview does not spawn combat")
	var actions := [["right"],["right","down"],["down"],["left","down"],["left"],["left","up"],["up"],["right","up"]]
	for region in range(3):
		world.preview_region(region)
		for i in range(8):
			release()
			world.reset_preview_position()
			for frame in range(8):await physics_frame
			for action in actions[i]:Input.action_press(action)
			for frame in range(20):await physics_frame
			world.update_art()
			check(world.art_index==i and not world.art_sprite.flip_h,"region %d direct view %d"%[region,i])
			check(not world.player.portrait.visible and world.locomotion.visible,"no mixed old/new sprite")
			samples.append({"region":region,"direction":i,"speed":Vector2(world.player.velocity.x,world.player.velocity.z).length(),"grounded":world.player.is_on_floor(),"phase":world.player.walk_phase})
			release()
			for frame in range(2):await physics_frame
			check(Vector2(world.player.velocity.x,world.player.velocity.z).length()<0.01,"input release stops")
			if region==0 and i in [0,2,4,6]:await shot("playground_direction_"+str(i))
		await shot("playground_region_"+str(region))
	world.preview_region(0)
	Input.action_press("right")
	for frame in range(50):await physics_frame
	check(world.player.current_speed>=9.99,"original 0.75s run ramp retained")
	release()
	for frame in range(2):await physics_frame
	world.approved_visible=false
	await shot("playground_old_comparison")
	check(world.player.portrait.visible and not world.locomotion.visible,"comparison switch exclusive")
	world.approved_visible=true
	world.update_art()
	world.player.position=world.Landscape.on_ground(Vector3(113,0,8),0.1)
	world.player.facing=Vector3.RIGHT
	world.foliage.enabled=false
	for frame in range(40):await process_frame
	await shot("playground_foliage_before")
	world.foliage.enabled=true
	for frame in range(40):await process_frame
	check(world.foliage.active_count>0,"opaque foreground foliage is detected")
	await shot("playground_foliage_after")
	world.foliage.enabled=false
	for frame in range(60):await process_frame
	var restored := true
	for e in world.foliage.entries:
		if is_instance_valid(e.sprite):restored=restored and absf(e.sprite.modulate.a-e.color.a)<0.001
	check(restored,"foliage colors restore after disabling fade")
	world.foliage.enabled=true
	world.reset_preview_position()
	for frame in range(90):await process_frame
	check(world.foliage.active_count==0,"clear center path does not fade surrounding trees")
	var left_restored := true
	for e in world.foliage.entries:
		if is_instance_valid(e.sprite):left_restored=left_restored and absf(e.sprite.modulate.a-e.color.a)<0.001
	check(left_restored,"leaving occlusion restores foliage")
	await shot("playground_start")
	check(world.preview_ticks>0 and world.player.footfalls>0,"real physics and distance-driven gait ran")
	check(world.save_queue==null,"no save queue after regions and movement")
	var file := FileAccess.open(OS.get_environment("HERO_QA_OUTPUT")+"/playground.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"samples":samples,"actual_physics":true,"combat":false,"new_art_is_static":false,"procedural_motion":true},"  "))
	quit(1 if failures else 0)


