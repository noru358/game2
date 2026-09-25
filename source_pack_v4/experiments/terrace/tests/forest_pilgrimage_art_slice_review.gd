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
func shot(name: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"capture "+name)

func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	output=OS.get_environment("MAP_QA_OUTPUT")
	root.size=Vector2i(1152,720)
	root.content_scale_size=Vector2i(1280,800)
	world=load("res://maps/forest_pilgrimage_art_slice.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	world.silent=true
	await frames(18)
	check(world.surface.art_enabled,"ACT 2 terrain art material is active")
	check(world.art_kit.cards.size()>=20,"bounded reusable prop set is instanced")
	check(world.surface.zone_at(world.player.position)==1,"slice starts in ACT 2")
	check(world.player.hero_visual.baked_motion(),"approved animated hero remains active")
	check(world.camera_pitch==60.0 and is_equal_approx(world.camera.size,22.0),"gameplay camera contract remains 60/20/22")
	await shot("01_act2_art_slice_gameplay")
	world.hud.hide()
	await shot("01b_act2_art_slice_clean")
	world.hud.show()
	world.player.position=world.surface.ground(Vector3(-5,0,-15),0.1)
	world.player.facing=world.movement_direction(Vector2.UP)
	world.update_camera(1)
	await frames(10)
	await shot("02_act2_art_slice_late")
	world.reset_encounter(true)
	world.focus_zone(1)
	world.player.invulnerability=20
	world.auto_enabled=true
	for i in range(180):await physics_frame
	check(world.auto_hits>0,"actual automatic combat runs inside the art slice")
	await shot("03_act2_art_slice_combat")
	world.free()
	await frames(2)
	check(preload("res://game/effect_surface.gd").override_surface==null,"surface override cleared on exit")
	print("RESULT ",checks-failures," PASS / ",failures," FAIL")
	quit(1 if failures else 0)
