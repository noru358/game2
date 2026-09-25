extends SceneTree
var failures:=0
var w
func _initialize()->void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func check(ok:bool,label:String)->void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	var folder:=OS.get_environment("DEMO_QA_OUTPUT")
	if folder.is_empty():folder="res://docs/validation"
	root.get_texture().get_image().save_png(folder+"/moving-strike-"+label+".png")
func run()->void:
	w=load("res://game/world.tscn").instantiate()
	root.add_child(w)
	w.set_physics_process(false)
	var p=w.player
	p.set_physics_process(false)
	for e in w.enemies():e.free()
	p.position=Vector3(-8,0.1,0)
	var target=w.spawn_enemy("moving_probe",Vector3(-6,0.1,0),false,10000)
	target.set_physics_process(false)
	w.update_camera(1)
	for direction_index in range(8):
		var toward:=Vector3(cos(direction_index*PI/4),0,sin(direction_index*PI/4))
		for combo in range(1,4):
			w.hitstop=0
			w.combat.reset_transient()
			w.combat.combo_step=combo-1
			p.swing_left=0
			p.facing=toward
			p.velocity=toward*10
			p.walk_phase=0.7
			p.update_visual(0)
			target.position=p.position+toward*2
			await physics_frame
			var hp_before:int=target.hp
			w.combat.strike()
			var label:=" direction %d combo %d"%[direction_index,combo]
			check(target.hp<hp_before and w.hitstop>0,"moving attack hits"+label)
			check(p.portrait.texture in p.hero_visual.combos and p.weapon.visible and p.velocity.length()<0.01,"contact art and planted feet before freeze"+label)
			var texture=p.portrait.texture
			p._physics_process(0.016)
			check(p.portrait.texture==texture and p.occluded_portrait.texture==texture,"freeze keeps contact and locator"+label)
			if direction_index==0:await capture("contact-"+str(combo))
			p.swing_left=p.swing_duration*0.3
			p.update_visual(0)
			check(p.portrait.texture in p.hero_visual.recoveries and not p.weapon.visible,"stationary recovery withdraws hands and focus"+label)
			if direction_index==0:await capture("settle-"+str(combo))
			w.update_effects(2)
	w.hitstop=0
	Input.action_press("right")
	p.moving_seconds=2
	p.swing_left=0.06
	p._physics_process(0.016)
	check(p.velocity.x>3 and not p.weapon.visible and p.portrait.texture not in p.hero_visual.combos,"movement recovers as walking after contact")
	await capture("recovery")
	Input.action_release("right")
	Input.action_press("dash")
	p.dash_wait=0
	p.set_physics_process(true)
	await physics_frame
	await physics_frame
	p.set_physics_process(false)
	check(p.dash_left>0 and p.swing_left==0 and w.combat.recovery==0,"dodge cancels attack and recovery")
	Input.action_release("dash")
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
