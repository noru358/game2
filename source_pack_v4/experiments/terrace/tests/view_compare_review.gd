extends SceneTree
var world
var checks := 0
var failures := 0
var output := ""
var snapshots: Array=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func release() -> void:
	for a in ["up","down","left","right","dash","pulse"]:Input.action_release(a)
func key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode=code;event.pressed=true
	world._unhandled_input(event)
func shot(name: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"capture "+name)
func move_to(target: Vector2) -> void:
	var reached := false
	for i in range(600):
		var offset := Vector3(target.x-world.player.position.x,0,target.y-world.player.position.z)
		release()
		if offset.length()<0.5:reached=true;break
		var local := offset.normalized().rotated(Vector3.UP,-world.view_yaw)
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
	world=load("res://maps/view_compare.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	world.silent=true
	await frames(10)
	check(world.frozen and world.enemies().size()==8,"starts frozen with eight actual enemies")
	key(KEY_1)
	check(is_zero_approx(world.view_yaw),"key 1 selects zero degrees")
	key(KEY_3)
	check(is_equal_approx(world.view_yaw,PI/4),"key 3 selects 45 degrees")
	key(KEY_2)
	check(is_equal_approx(world.view_yaw,deg_to_rad(20)),"key 2 selects 20 degrees")
	key(KEY_F)
	check(not world.frozen and world.player.is_physics_processing(),"key F resumes actors")
	key(KEY_T)
	check(not world.encounter_on and world.enemies().is_empty(),"key T enters exploration")
	key(KEY_N)
	check(world.encounter_count==24 and world.enemies().size()==24,"key N rebuilds 24 enemy encounter")
	key(KEY_N)
	key(KEY_R)
	check(world.enemies().size()==8 and world.kills==0,"N and R return to identical eight enemy reset")
	for angle in [0,20,45]:
		world.reset_encounter(false)
		world.set_view(angle)
		world.encounter_on=true
		world.auto_enabled=false
		await frames(12)
		check(world.player.is_on_floor(),"grounded %d"%angle)
		var start: Vector3=world.player.position
		var screen_start: Vector2=world.camera.unproject_position(start)
		Input.action_press("right")
		await frames(15)
		release()
		var screen_end: Vector2=world.camera.unproject_position(world.player.position)
		check(screen_end.x>screen_start.x+15 and absf(screen_end.y-screen_start.y)<2,"screen-right input %d"%angle)
		check(world.player.facing.dot(world.movement_direction(Vector2.RIGHT))>0.99,"world facing %d"%angle)
		Input.action_press("dash")
		await frames(2)
		release()
		check(world.player.dash_wait>0,"actual dash %d"%angle)
		await frames(35)
		check(Vector2(world.player.velocity.x,world.player.velocity.z).length()<0.01,"release %d"%angle)
		# Identical initialized positions for visual comparison, no AI disabled in live play.
		world.reset_encounter(true)
		world.set_physics_process(false)
		world.player.set_physics_process(false)
		var positions: Array=[]
		for e in world.enemies():
			e.set_physics_process(false)
			e.refresh_view()
			positions.append(e.position)
		if snapshots.is_empty():snapshots=positions.duplicate()
		check(positions==snapshots,"identical enemy starting positions %d"%angle)
		await shot("view_%02d_same_encounter"%angle)
		world.set_physics_process(true)
		world.player.set_physics_process(true)
		for e in world.enemies():e.set_physics_process(true)
		world.auto_enabled=true
		world.player.invulnerability=20
		Input.action_press("pulse")
		var warned := false
		var damaged := false
		for i in range(180):
			await physics_frame
			for e in world.enemies():
				warned=warned or e.telegraph.visible or (is_instance_valid(e.charge_lane) and e.charge_lane.visible)
				damaged=damaged or e.hp<12
		release()
		check(world.combat.swings>=3,"real manual combo %d"%angle)
		check(world.auto_hits>0 and (damaged or world.kills>0),"actual auto damage %d"%angle)
		check(warned,"live AI warning %d"%angle)
		await shot("view_%02d_live"%angle)
		world.reset_encounter(false)
		world.auto_enabled=false
		var target=world.CompareEnemy.new()
		target.stable_id="manual_probe"
		target.hp=12
		target.position=world.player.position+world.movement_direction(Vector2.RIGHT)*1.8
		world.add_child(target)
		target.set_physics_process(false)
		world.player.facing=world.movement_direction(Vector2.RIGHT)
		Input.action_press("pulse")
		await frames(3)
		release()
		check(target.hp<12,"manual damage follows camera-relative facing %d"%angle)
		world.set_frozen(true)
		var frozen_position: Vector3=world.player.position
		var frozen_hp: int=target.hp
		world.set_view(45 if angle!=45 else 0)
		await frames(5)
		check(world.player.position==frozen_position and target.hp==frozen_hp,"frozen view switch preserves combat %d"%angle)
		world.set_frozen(false)
	world.reset_encounter(false)
	world.set_view(20)
	for point in [Vector2(132,0),Vector2(132,-11),Vector2(123,-13)]:await move_to(point)
	check(world.player.position.y>3,"actual upper shelf ascent")
	await shot("upper_shelf_20")
	for point in [Vector2(132,-11),Vector2(132,0),Vector2(122,0)]:await move_to(point)
	check(world.player.position.y<0.2,"actual return to clearing")
	world.encounter_count=24
	world.auto_enabled=true
	world.reset_encounter(true)
	check(world.enemies().size()==24,"24 enemy mode")
	world.player.invulnerability=20
	await frames(90)
	await shot("view_20_crowd24")
	check(world.auto_hits>0,"24 enemy live combat")
	world.set_frozen(true)
	for angle in [0,45]:
		world.set_view(angle)
		await shot("view_%02d_crowd24_frozen"%angle)
	world.free()
	check(preload("res://game/landscape.gd").lab_region==-1,"Landscape mode restored on exit")
	print("RESULT ",checks-failures," PASS / ",failures," FAIL")
	quit(1 if failures else 0)
