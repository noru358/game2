extends SceneTree
var world
var checks:=0
var failures:=0
var output:=""

func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func release() -> void:
	for action in ["up","down","left","right","dash","pulse"]:Input.action_release(action)
func shot(name: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"capture "+name)
func move_to(target: Vector2) -> void:
	var reached:=false
	for i in range(720):
		var offset:=Vector3(target.x-world.player.position.x,0,target.y-world.player.position.z)
		release()
		if offset.length()<0.48:reached=true;break
		var local:=offset.normalized().rotated(Vector3.UP,-world.view_yaw)
		if absf(local.x)>0.04:Input.action_press("right" if local.x>0 else "left",absf(local.x))
		if absf(local.z)>0.04:Input.action_press("down" if local.z>0 else "up",absf(local.z))
		await physics_frame
	release()
	check(reached,"physical route %s at %s"%[target,world.player.position])

func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	output=OS.get_environment("MAP_QA_OUTPUT")
	root.size=Vector2i(1152,720)
	root.content_scale_size=Vector2i(1280,800)
	world=load("res://maps/composition_proof.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	world.silent=true
	await frames(12)
	check(world.overview and world.frozen,"starts as frozen framed composition")
	check(world.enemies().size()==8,"eight actual enemies stage the combat pocket")
	check(is_equal_approx(world.surface.height_at(Vector3(122,0,8)),world.surface.MAIN_Y),"central combat landform")
	check(is_equal_approx(world.surface.height_at(Vector3(132,0,-21)),world.surface.UPPER_Y),"rear shrine landform")
	check(is_equal_approx(world.surface.height_at(Vector3(90,0,-2)),world.surface.WATER_Y),"water separates authored masses")
	check(world.surface.height_at(Vector3(128,0,-9))>world.surface.MAIN_Y and world.surface.height_at(Vector3(128,0,-9))<world.surface.UPPER_Y,"shared stairs interpolate height")
	await shot("01_framed_20")
	world.overview=false
	world.update_camera(1)
	await shot("02_gameplay_20")
	for angle in [15,25]:
		world.set_view(angle)
		await shot("03_yaw_%02d"%angle)
	world.set_view(20)
	world.reset_encounter(false)
	world.overview=false
	for point in [Vector2(110,14),Vector2(106.5,16.5),Vector2(102.5,18.5),Vector2(97,22)]:await move_to(point)
	check(world.surface.inside(Vector2(world.player.position.x,world.player.position.z),world.surface.entry_polygon()),"actual bridge reaches entry landform")
	for point in [Vector2(102.5,18.5),Vector2(107,16.5),Vector2(118,10)]:await move_to(point)
	for point in [Vector2(125,-3.5),Vector2(128,-6.2),Vector2(128,-9.4),Vector2(128,-13.2),Vector2(128,-15.0),Vector2(132,-17.0)]:await move_to(point)
	check(world.player.position.y>4.3,"actual ascent reaches shrine terrace")
	world.overview=true
	world.update_camera(1)
	await shot("04_upper_arrival")
	world.overview=false
	world.reset_encounter(true)
	world.set_frozen(false)
	world.auto_enabled=false
	world.player.invulnerability=20
	var warned:=false
	for i in range(300):
		await physics_frame
		for enemy in world.enemies():warned=warned or enemy.telegraph.visible or (is_instance_valid(enemy.charge_lane) and enemy.charge_lane.visible)
	check(warned,"enemy warnings use the proof surface")
	world.auto_enabled=true
	for i in range(150):await physics_frame
	check(world.auto_hits>0,"existing automatic combat works in composition proof")
	check(world.player.position.y>world.surface.WATER_Y+1.0,"combat safety rim prevents water fall")
	await shot("05_live_combat")
	world.free()
	await frames(2)
	check(preload("res://game/effect_surface.gd").override_surface==null,"surface override cleared on exit")
	print("RESULT ",checks-failures," PASS / ",failures," FAIL")
	quit(1 if failures else 0)
