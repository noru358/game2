extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func run():
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	var w=load("res://lab/journey.tscn").instantiate()
	root.add_child(w)
	w.set_physics_process(false)
	w.player.set_physics_process(false)
	w.kills=24
	w.player.position=w.Landscape.on_ground(Vector3(110,0,3),0.1)
	for e in w.enemies():e.free()
	w.hud.hide()
	w.update_camera(1)
	for direction in range(8):
		for combo in range(1,4):
			w.player.facing=Vector3(cos(direction*PI/4),0,sin(direction*PI/4))
			w.combat.reset_transient()
			w.combat.combo_step=combo-1
			w.combat.strike()
			var points=w.player.hero_visual.focus_points(w.player.portrait,w.player.casting_direction,combo)
			check(w.player.weapon.position.distance_to(points[0])<0.001,"live sprite hand origin direction %d combo %d"%[direction,combo])
			check(w.player.second_focus.visible==(points.size()>1),"separate palms where painted")
			for phase in range(3):
				w.player.swing_left=w.player.swing_duration*[0.96,0.64,0.30][phase]
				w.player.update_visual(0)
				check(is_zero_approx(w.player.portrait.rotation.z),"no whole-body attack roll")
				for i in range(2):await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OS.get_environment("DEMO_QA_OUTPUT")+"/hands-%d-%d-%d.png"%[direction,combo,phase])
			for e in w.effects:e.node.free()
			w.effects.clear()
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
