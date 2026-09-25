extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func run():
	var world=load("res://lab/world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	for enemy in world.enemies():enemy.set_physics_process(false)
	var player=world.player
	for site in [Vector3(104,0,-4),Vector3(126,0,-4),Vector3(104,0,-14),Vector3(126,0,-14),Vector3(110,0,1)]:
		player.position=world.Landscape.on_ground(site,0.1)
		player.velocity=Vector3.ZERO
		player.moving_seconds=0
		Input.action_press("up")
		for i in range(90):await physics_frame
		Input.action_release("up")
		await physics_frame
		var at:Vector3=player.position
		var grounded:float=world.Landscape.height_at(at)
		check(at.y>=grounded-0.08,"feet outside terrain at "+str(site))
		if site.x!=110:check(at.z>site.z-3.5,"steep riser blocks walking "+str(site))
		else:check(at.z< -8,"walkable ramp remains accessible")
		world.update_camera(1)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("DEMO_QA_OUTPUT")+"/footing-%d-%d.png"%[site.x,site.z])
		check(absf(player.portrait.rotation.x)<0.001,"upright portrait cannot extend into uphill face")
	for x in [104.0,126.0]:
		player.position=world.Landscape.on_ground(Vector3(x,0,-5),0.1)
		player.velocity=Vector3.ZERO
		player.dash_wait=0
		player.facing=Vector3.FORWARD
		Input.action_press("up")
		Input.action_press("dash")
		for i in range(35):await physics_frame
		Input.action_release("dash")
		Input.action_release("up")
		check(player.position.z> -7.5,"dash cannot tunnel through steep riser "+str(x))
		check(player.position.y>=world.Landscape.height_at(player.position)-0.08,"dash feet outside terrain")
	check(absf(float(player.hero_visual.walk_pass_meta[6].root_x)-97.0)<0.01,"north passing pose uses torso center")
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
