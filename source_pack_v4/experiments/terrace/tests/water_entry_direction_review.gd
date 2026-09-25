extends "res://tests/forest_pilgrimage_graybox_review.gd"

func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	output=OS.get_environment("MAP_QA_OUTPUT")
	if not output.is_empty():DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1152,720);root.content_scale_size=Vector2i(1280,800)
	world=load("res://maps/water_entry_direction.tscn").instantiate()
	root.add_child(world);current_scene=world;world.silent=true
	await frames(12)
	for v in [[55,30,"01_previous"],[45,45,"02_proposed"],[40,45,"03_lower"]]:
		world.set_view(v[0],v[1]);world.update_hud();await frames(5);await shot(v[2])
	world.set_view(45,45);world.set_plain(true);await frames(3);await shot("04_structure")
	world.set_plain(false)
	world.ui.hide();world.prompt.hide();world.player.hide()
	await frames(2);await shot("06_layout_reference")
	world.ui.show();world.prompt.show();world.player.show()
	var origin: Vector2=world.camera.unproject_position(Vector3(5,2,8))
	var axis_x: Vector2=world.camera.unproject_position(Vector3(9,2,8))-origin
	var axis_z: Vector2=world.camera.unproject_position(Vector3(5,2,12))-origin
	check(absf(absf(axis_x.x)-absf(axis_z.x))<0.5,"balanced diamond ground axes")
	check(world.architecture.get_child_count()>8,"volumetric gate assembly")
	check(world.camera.size==22,"gameplay scale unchanged")
	if not "--shots-only" in OS.get_cmdline_user_args():
		world.reset_encounter(false)
		for point in world.surface.route():await move_to(point)
		check(world.player.position.y>4.6,"reaches upstream connector through gate")
		check(not world.roof_parts[0].visible,"gate roof cuts away behind player")
		await shot("05_inside_gate")
		var back: Array=world.surface.route().duplicate();back.reverse()
		for point in back:await move_to(point)
		check(absf(world.player.position.y-2)<0.15,"returns to water entrance")
		check(world.roof_parts[0].visible,"gate roof returns after crossing back")
		world.player.position=world.surface.ground(Vector3(-5,0,13),0.1)
		await frames(4)
		var local:=Vector3.FORWARD.rotated(Vector3.UP,-world.view_yaw)
		Input.action_press("left",absf(local.x));Input.action_press("up",absf(local.z))
		await frames(100);release()
		check(world.player.position.z>9.8 and world.player.position.y>1.8,"bridge edge prevents entering canal")
		world.reset_encounter(true);world.player.position=world.surface.ground(world.data.hero_view,0.1)
		world.player.invulnerability=20;world.auto_enabled=false
		var warned:=false
		for i in range(280):
			await physics_frame
			for enemy in world.enemies():warned=warned or enemy.telegraph.visible or (is_instance_valid(enemy.charge_lane) and enemy.charge_lane.visible)
		check(warned,"live enemy warnings on entry terrain")
		Input.action_press("pulse");await frames(220);Input.action_release("pulse")
		check(world.combat.swings>=3,"live direct combo on entry terrain")
		world.reset_encounter(true);world.player.position=world.surface.ground(world.data.hero_view,0.1)
		world.player.invulnerability=20;world.auto_enabled=true
		await frames(180)
		check(world.auto_hits>0,"live automatic attacks on entry terrain")
		await shot("08_live_combat")
	world.free();await frames(2)
	check(preload("res://game/effect_surface.gd").override_surface==null,"surface cleanup")
	print("RESULT ",checks-failures," PASS / ",failures," FAIL")
	quit(1 if failures else 0)
