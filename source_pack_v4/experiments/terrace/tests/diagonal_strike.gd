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
	for e in w.enemies():e.free()
	w.hud.hide()
	var p=w.player
	for side in ["left","right"]:
		p.position=w.Landscape.on_ground(Vector3(110,0,3),0.1)
		p.facing=Vector3(-1 if side=="left" else 1,0,1).normalized()
		p.velocity=p.facing*7.5
		p.moving_seconds=0
		p.swing_left=0
		w.combat.reset_transient()
		w.update_camera(1)
		w.combat.strike()
		Input.action_press(side)
		Input.action_press("down")
		var recovered:=false
		for frame in range(24):
			await physics_frame
			p._physics_process(1.0/60)
			w.update_effects(1.0/60)
			var moving:bool=Vector2(p.velocity.x,p.velocity.z).length()>0.1
			if moving and p.swing_left>0:
				check(is_zero_approx(p.portrait.rotation.z) and not p.weapon.visible,"recovery has no attack roll "+side+str(frame))
				if not recovered:
					check(p.portrait.texture in p.hero_visual.walk_passes,"first recovery step passes under body "+side)
					recovered=true
			if DisplayServer.get_name()!="headless":
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OS.get_environment("DEMO_QA_OUTPUT")+"/diagonal-%s-%02d.png"%[side,frame])
		check(recovered,"movement resumes during recovery "+side)
		Input.action_release(side)
		Input.action_release("down")
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
