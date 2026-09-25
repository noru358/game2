extends SceneTree
func _initialize():call_deferred("run")
func run():
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	var w=load("res://lab/journey.tscn").instantiate()
	root.add_child(w)
	w.set_physics_process(false)
	w.player.set_physics_process(false)
	w.hud.hide()
	w.travel(1)
	w.hud.hide()
	w.player.position=w.Landscape.on_ground(Vector3(132,0,-12),0.1)
	w.update_camera(1)
	for e in w.enemies():e.set_physics_process(false)
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("DEMO_QA_OUTPUT")+"/ui-backdrop.png")
	for e in w.enemies():e.free()
	var enemy=w.spawn_enemy("motion_review",w.Landscape.on_ground(Vector3(132,0,-10),0.1),false,100,"charger")
	enemy.set_physics_process(false)
	for i in range(24):
		enemy.visual.apply(enemy.portrait,Vector3(1,0,1).normalized(),false)
		enemy.visual.animate(enemy.portrait,Vector3(1,0,1).normalized(),i*0.3,i<8,i>=8 and i<16,(24-i)/8.0*0.22 if i>=16 else 0,false)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("DEMO_QA_OUTPUT")+"/enemy-motion-%02d.png"%i)
	print("RESULT presentation captures complete; visual judgment required")
	quit()
