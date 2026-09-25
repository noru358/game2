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
	for i in range(540):
		var offset:=Vector3(target.x-world.player.position.x,0,target.y-world.player.position.z)
		release()
		if offset.length()<0.55:reached=true;break
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
	world=load("res://maps/forest_pilgrimage_graybox.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	world.silent=true
	await frames(16)
	check(world.camera_pitch==60.0 and is_equal_approx(world.camera.size,22.0),"gameplay camera starts at pitch 60 size 22")
	check(world.player.hero_visual.baked_motion(),"approved animated hero is active")
	check(world.surface.zone_at(Vector3(-8,0,36))==0,"entry is act one")
	check(world.surface.zone_at(Vector3(2,0,4))==1,"river ascent is act two")
	check(world.surface.zone_at(Vector3(-2,0,-33))==2,"root sanctuary is act three")
	check(world.surface.height_at(Vector3(-2,0,-33))>world.surface.height_at(Vector3(-8,0,36))+4.0,"sanctuary is materially higher than entry")
	await shot("01_act1_entry_gameplay")
	world.focus_zone(1)
	await frames(8)
	await shot("02_act2_river_gameplay")
	world.player.position=world.surface.ground(Vector3(-6,0,-23.5),0.1)
	world.player.facing=world.movement_direction(Vector2.UP)
	world.update_camera(1)
	await frames(8)
	await shot("02b_act2_late_reveal")
	world.focus_zone(2)
	await frames(8)
	await shot("03_act3_sanctuary_gameplay")
	world.overview=true
	world.update_camera(1)
	await frames(8)
	await shot("04_three_act_overview")
	world.reset_encounter(false)
	world.focus_zone(0)
	for point in world.surface.route().slice(1):await move_to(point)
	check(world.surface.zone_at(world.player.position)==2,"one continuous physical route reaches sanctuary")
	check(world.player.position.y>4.8,"physical player reaches upper sanctuary height")
	world.focus_zone(1)
	world.reset_encounter(true)
	world.focus_zone(1)
	world.set_frozen(false)
	world.auto_enabled=false
	world.player.invulnerability=20
	var warned:=false
	for i in range(280):
		await physics_frame
		for enemy in world.enemies():warned=warned or enemy.telegraph.visible or (is_instance_valid(enemy.charge_lane) and enemy.charge_lane.visible)
	check(warned,"actual enemy warnings run on graybox surface")
	Input.action_press("pulse")
	for i in range(220):await physics_frame
	Input.action_release("pulse")
	check(world.combat.swings>=3,"approved hero direct three-hit combat runs in act two")
	world.reset_encounter(true)
	world.focus_zone(1)
	world.player.invulnerability=20
	world.auto_enabled=true
	for i in range(180):await physics_frame
	check(world.auto_hits>0,"approved hero automatic combat runs in act two")
	await shot("05_act2_live_combat")
	world.free()
	await frames(2)
	check(preload("res://game/effect_surface.gd").override_surface==null,"surface override cleared on exit")
	print("RESULT ",checks-failures," PASS / ",failures," FAIL")
	quit(1 if failures else 0)
