extends SceneTree
var world
var failures := 0
var count := 0
var output := ""
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	count+=1
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func shot(name: String) -> void:
	world.update_camera(1)
	for i in range(8):await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,name)
func key(code: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode=code
	ev.pressed=true
	world._unhandled_input(ev)
	for i in range(5):await physics_frame
func check_projection() -> void:
	world.player.update_visual(0)
	world.update_camera(1)
	var sprite: Sprite3D=world.player.portrait
	var index := posmod(roundi(atan2(world.player.facing.z,world.player.facing.x)/(PI/4)),8)
	var d: Dictionary=world.player.frames[index]
	var foot_local := Vector3(0,(float(d.region[3])*0.5-float(d.foot))*sprite.pixel_size,0)
	var top_local := Vector3(0,(float(d.region[3])*0.5-float(d.top))*sprite.pixel_size,0)
	var foot: Vector2=world.camera.unproject_position(sprite.global_transform*foot_local)
	var top: Vector2=world.camera.unproject_position(sprite.global_transform*top_local)
	var root_at: Vector2=world.camera.unproject_position(world.player.global_position)
	var expected: float=root.get_visible_rect().size.y*2.25/22.0
	check(absf(foot.distance_to(top)-expected)<0.5,"projected hero height %.2f expected %.2f at %.0f"%[foot.distance_to(top),expected,world.camera_pitch])
	check(foot.distance_to(root_at)<2.0,"projected foot anchor %.3fpx"%foot.distance_to(root_at))
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	output=OS.get_environment("MAP_QA_OUTPUT")
	if output.is_empty():quit(2);return
	root.size=Vector2i(1152,720)
	root.content_scale_size=Vector2i(1280,800)
	world=load("res://maps/map_preview.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	await key(KEY_P)
	for i in range(20):await physics_frame
	check(world.player.is_on_floor(),"representative scene grounded")
	check(world.kit.frames.size()==6 and world.surface.materials.size()==4,"assets loaded")
	var at: Vector3=world.player.position
	world.states.water_entry.found=true
	check_projection()
	await shot("01_art_45")
	await key(KEY_C)
	check(world.camera_pitch==52 and world.player.position.distance_to(at)<0.15,"pitch comparison preserves player position")
	check_projection()
	await shot("02_art_52")
	await key(KEY_V)
	check(not world.art_enabled and world.states.water_entry.found,"baseline comparison preserves discovery")
	await shot("03_blockout_52")
	await key(KEY_V)
	await key(KEY_C)
	check(world.art_enabled and world.camera_pitch==45,"return to art trial")
	check(world.player.position.distance_to(at)<0.15,"no position drift after comparisons")
	world.player.position=world.surface.ground(Vector3(-15,0,1),0.1)
	for i in range(20):await physics_frame
	await shot("04_water_edge")
	world.player.position=world.surface.ground(Vector3(-4,0,-15),0.1)
	for i in range(20):await physics_frame
	await shot("05_pillars")
	var file := FileAccess.open(output.path_join("environment_results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":count,"failures":failures,"scope":"asset loading, camera/hero pitch, view switching and GPU captures; visual quality reviewed separately"},"  "))
	world.free()
	print("RESULT ",count-failures," PASS / ",failures," FAIL")
	quit(1 if failures else 0)
