extends "res://tests/forest_pilgrimage_graybox_review.gd"

func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	output=OS.get_environment("MAP_QA_OUTPUT")
	if not output.is_empty():DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1152,720)
	root.content_scale_size=Vector2i(1280,800)
	for id in ["A","B"]:
		set_meta("ruin_layout",id)
		world=load("res://maps/ruin_production.tscn").instantiate()
		root.add_child(world);current_scene=world;world.silent=true
		world.reset_encounter(false);world.overview=true;world.update_camera(1)
		await frames(12)
		await shot(id+"_overview")
		world.set_plain(true)
		await frames(3);await shot(id+"_structure")
		world.set_plain(false)
		world.player.position=world.surface.ground(world.data.hero_view,0.1)
		world.overview=false;world.update_camera(1)
		await frames(8);await shot(id+"_gameplay")
		check(world.surface.height_at(world.data.landmark)>world.surface.height_at(world.data.spawn),id+" upper terrace")
		if not "--shots-only" in OS.get_cmdline_user_args():
			world.reset_encounter(false)
			for point in world.surface.route():await move_to(point)
			check(world.player.position.y>5,id+" physical ascent")
			var back: Array=world.surface.route().duplicate();back.reverse()
			for point in back:await move_to(point)
			check(absf(world.player.position.y-2)<0.15,id+" physical descent")
		world.free();await frames(2)
		check(preload("res://game/effect_surface.gd").override_surface==null,id+" surface cleanup")
	print("RESULT ",checks-failures," PASS / ",failures," FAIL")
	quit(1 if failures else 0)
