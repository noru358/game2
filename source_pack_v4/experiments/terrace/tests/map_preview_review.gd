extends SceneTree
var world
var failures := 0
var checks := 0
var max_foot_error := 0.0
var output := ""
var screenshots := false

func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func release() -> void:
	for action in ["left","right","up","down","dash","interact"]:Input.action_release(action)
func wait_frames(count: int) -> void:
	for i in range(count):await physics_frame
func move_to(target: Vector2) -> void:
	var reached := false
	for i in range(720):
		var at := Vector2(world.player.position.x,world.player.position.z)
		var delta := target-at
		release()
		if delta.length()<0.45:
			reached=true
			break
		if absf(delta.x)>0.18:Input.action_press("right" if delta.x>0 else "left",minf(1,absf(delta.x)/maxf(delta.length(),0.01)))
		if absf(delta.y)>0.18:Input.action_press("down" if delta.y>0 else "up",minf(1,absf(delta.y)/maxf(delta.length(),0.01)))
		await physics_frame
		if world.player.is_on_floor():max_foot_error=maxf(max_foot_error,absf(world.player.position.y+0.025-world.surface.height_at(world.player.position)))
	release()
	await wait_frames(3)
	check(reached,"physical route %s at %s"%[target,world.player.position])
func interact() -> void:
	Input.action_press("interact")
	await wait_frames(2)
	Input.action_release("interact")
	await wait_frames(2)
func shot(name: String) -> void:
	if not screenshots:return
	world.update_camera(1)
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"capture "+name)
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	output=OS.get_environment("MAP_QA_OUTPUT")
	screenshots=not output.is_empty() and DisplayServer.get_name()!="headless"
	root.size=Vector2i(1152,720)
	root.content_scale_size=Vector2i(1280,800)
	world=load("res://maps/map_preview.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	await wait_frames(60)
	check(world.player.is_on_floor(),"entry grounded")
	check(world.player.run_ramp_seconds==0.75 and world.player.run_speed==10,"existing Player speed contract")
	await shot("01_entry")
	world.overview=true
	await shot("02_overview")
	world.overview=false
	await move_to(Vector2(-16,6))
	await shot("03_water_bank")
	await move_to(Vector2(-20,-3))
	await interact()
	check(world.states.water_entry.get("found",false),"optional discovery retained")
	await move_to(Vector2(-15,-5))
	await move_to(Vector2(-10,-12))
	await shot("04_upper_bank")
	await move_to(Vector2(0,-15))
	await move_to(Vector2(10,-13))
	await move_to(Vector2(21,-11))
	await shot("05_forest_gate")
	await interact()
	check(world.map_id=="roots_terrace","exit reaches destination map")
	check(world.transitions==1,"no automatic bounce")
	await wait_frames(60)
	check(world.player.is_on_floor(),"destination arrival grounded")
	await shot("06_roots_arrival")
	await move_to(Vector2(-6,9))
	await move_to(Vector2(0,8))
	await shot("06b_altar_lower")
	world.overview=true
	await shot("06c_altar_overview")
	world.overview=false
	for p in [Vector2(-6,9),Vector2(0,6),Vector2(0,1),Vector2(0,-4),Vector2(0,-8.5)]:await move_to(p)
	check(world.player.position.y>5.0,"walked onto second-floor altar")
	await interact()
	check(world.states.roots_terrace.get("found",false),"second map discovery")
	await shot("07_roots_shelf")
	for p in [Vector2(0,-4),Vector2(0,1),Vector2(0,6),Vector2(-6,9),Vector2(-12,9)]:await move_to(p)
	check(world.player.position.y<1.2,"walked back to first-floor courtyard")
	# A retaining wall must not act as a second staircase.
	world.player.position=world.surface.ground(Vector3(-7,0,1),0.1)
	await wait_frames(15)
	Input.action_press("up")
	await wait_frames(100)
	release()
	check(world.player.position.y<1.3 and world.player.position.z>-3,"retaining wall blocks direct ascent")
	world.player.position=world.surface.ground(Vector3(-12,0,9),0.1)
	await wait_frames(15)
	await interact()
	check(world.map_id=="water_entry" and world.transitions==2,"physical round trip")
	check(world.states.water_entry.get("found",false),"discovery survives map return")
	world.save_now()
	world.states={"water_entry":{},"roots_terrace":{}}
	check(world.restore_preview(world.save_path),"isolated snapshot restores")
	check(world.states.water_entry.get("found",false) and world.states.roots_terrace.get("found",false),"both map states restored")
	await wait_frames(15)
	# Regression: original dash reaches cooldown and input release stops movement.
	world.player.position=world.surface.ground(Vector3(4,0,-15),0.1)
	await wait_frames(12)
	Input.action_press("right")
	await wait_frames(8)
	Input.action_press("dash")
	await wait_frames(2)
	check(world.player.dash_wait>0,"existing dash active")
	release()
	await wait_frames(40)
	check(Vector2(world.player.velocity.x,world.player.velocity.z).length()<0.01,"release stops after dash")
	check(max_foot_error<0.18,"triangle grounding error %.4f"%max_foot_error)
	# Water collision must stop walking into the visible pond.
	world.player.position=world.surface.ground(Vector3(-15,0,3),0.12)
	await wait_frames(20)
	Input.action_press("right")
	await wait_frames(100)
	release()
	check(world.surface.water_mask(world.player.position.x,world.player.position.z)>0.93,"water boundary blocks entry")
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("results.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"max_foot_error":max_foot_error,"transitions":world.transitions,"scope":"terrain/input/round-trip/in-process temp snapshot; no combat or cross-launch saves"},"  "))
	var temp_path: String=world.save_path
	world.free()
	check(not FileAccess.file_exists(temp_path),"own temporary profile removed")
	print("RESULT ",checks-failures," PASS / ",failures," FAIL")
	quit(1 if failures else 0)
