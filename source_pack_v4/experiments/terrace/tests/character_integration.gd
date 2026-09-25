extends SceneTree
var failures := 0
var checks := 0
var world
func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func create_world() -> void:
	world=load("res://lab/character_integration.tscn").instantiate()
	root.add_child(world);current_scene=world
func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://art_review/hero_reskin_v1/"+name+".png")==OK,name)
func run() -> void:
	root.size=Vector2i(1152,720);root.content_scale_size=root.size
	create_world()
	world.set_physics_process(false);world.player.set_physics_process(false)
	for enemy in world.enemies():enemy.set_physics_process(false)
	check(world.test_mode and world.save_queue==null,"test-only integration no save queue")
	var visual=world.player.hero_visual
	for direction in range(8):
		var v := Vector3(cos(direction*PI/4),0,sin(direction*PI/4))
		for step in range(1,4):
			world.player.casting_direction=v;world.player.swing_step=step
			world.player.swing_duration=0.4;world.player.swing_left=0.4
			world.player.update_visual(0)
			check(visual.last_state=="strike" and int(visual.animated.current.get("direction",-1))==direction,"attack direction %d step %d"%[direction,step])
			var fx=preload("res://game/combat_effect.gd").spawn(world,"sweep",world.player.position,v,step,Color.CYAN)
			check(fx.emission_offsets.size()==1 and fx.to_global(fx.emission_offsets[0]).distance_to(world.player.weapon.global_position)<0.0001,"spell stroke starts at visible glove direction %d step %d"%[direction,step])
			world.effects.pop_back();fx.free()
		visual.apply(world.player.portrait,v,true,PI/2,false,false)
		check(visual.last_state=="walk" and visual.locomotion.current.state=="walk" and int(visual.locomotion.current.direction)==direction,"walk direction %d"%direction)
		visual.apply(world.player.portrait,v,true,PI/2,false,true)
		check(visual.last_state=="run" and visual.locomotion.current.state=="run" and int(visual.locomotion.current.direction)==direction,"run direction %d"%direction)
	var player=world.player
	player.swing_left=0
	player.position=world.Landscape.on_ground(Vector3(110,0,3),0.1)
	player.facing=Vector3.RIGHT
	player.set_physics_process(true)
	for tick in range(12):await physics_frame
	player.set_physics_process(false)
	check(player.is_on_floor(),"gait contract starts on actual collision floor")
	player.swing_left=0;player.velocity=Vector3.ZERO
	player.advance_stride(0)
	player.velocity=Vector3.RIGHT*7.5;player.current_speed=7.5
	player.advance_stride(0.01);player.update_visual(0)
	check(visual.locomotion.current.frame==1,"start walk with passing foot under hips")
	var prints: int=player.footfalls
	player.advance_stride(0.85);player.update_visual(0)
	check(player.footfalls==prints+1 and visual.locomotion.current.frame==2,"first footprint shares opposite contact pose")
	player.advance_stride(1.7);player.update_visual(0)
	check(player.footfalls==prints+2 and visual.locomotion.current.frame==0,"second footprint shares alternating contact pose")
	player.current_speed=10;player.velocity=Vector3.RIGHT*10
	player.advance_stride(1.9);player.update_visual(0)
	check(visual.last_state=="run" and visual.locomotion.current.frame==3 and visual.locomotion.current.gait_role=="support" and player.footfalls==prints+3,"run footprint uses support pose while changing stride length")
	player.velocity=Vector3.ZERO;player.advance_stride(0);player.update_visual(0)
	check(visual.last_state=="idle" and not player.stride_active,"stop resets stride without an extra footprint")
	player.velocity=Vector3.RIGHT*7.5;player.current_speed=7.5
	player.advance_stride(0.01);player.update_visual(0)
	check(visual.locomotion.current.frame==1,"restart returns to passing pose")
	player.velocity=Vector3.ZERO;player.advance_stride(0)
	var target=world.enemies()[0]
	target.position=world.Landscape.on_ground(Vector3(112,0,3),0.1)
	target.hp=999;target.dead=false
	world.update_camera(1)
	for step in range(1,4):
		world.combat.recovery=0;world.hitstop=0
		var hp: int=target.hp
		world.combat.strike()
		check(target.hp==hp and player.attack_windup and visual.last_state=="prepare","step %d preparation does not deal damage"%step)
		world.combat.update(0.1)
		check(target.hp<hp and not player.attack_windup and visual.last_state=="strike","step %d release pose and damage share tick"%step)
		await shot("integrated_strike_"+str(step))
		player.swing_left=0;world.combat.recovery=0.04;player.update_visual(0)
		check(visual.last_state=="recovery" and visual.animated.current.step==step,"combo tail keeps follow-through instead of idle flash")
	world.combat.recovery=0;player.update_visual(0)
	check(visual.last_state=="idle","completed recovery returns to approved idle")
	world.combat.reset_transient();world.hitstop=0
	var hp: int=target.hp
	world.combat.strike()
	player.dash_left=0.1
	world.combat.update(0.1)
	check(world.combat.pending_step==0 and target.hp==hp and not player.attack_windup,"dodge cancels queued damage")
	player.update_visual(0)
	check(visual.last_state=="dash" and visual.locomotion.current.state=="run","dodge uses flight pose instead of frozen walking pose")
	# Hold real movement input through each complete planted attack, including
	# preparation and the cooldown tail that used to slide at full speed.
	player.dash_left=0;player.swing_left=0
	world.combat.reset_transient();world.hitstop=0
	player.set_physics_process(true)
	Input.action_press("down")
	for step in range(1,4):
		player.velocity=Vector3.ZERO
		world.combat.combo_step=step-1
		world.combat.strike()
		var origin: Vector3=player.position
		var footprints: int=player.footfalls
		var drift := 0.0
		for tick in range(60):
			world.hitstop=0
			await physics_frame
			var offset: Vector3=player.position-origin
			drift=maxf(drift,Vector2(offset.x,offset.z).length())
			world.combat.update(1.0/60.0)
			if not player.planted_attack():break
		check(drift<0.001 and player.footfalls==footprints,"held movement does not slide or emit footsteps during strike %d"%step)
		for tick in range(4):await physics_frame
		check(player.position.distance_to(origin)>0.05 and visual.last_state=="walk" and not player.running_visual,"strike %d resumes walking without charged sprint"%step)
	Input.action_release("down")
	world.free()
	create_world()
	world.player.position=world.Landscape.on_ground(Vector3(110,0,2),0.1)
	world.player.facing=Vector3.FORWARD
	world.player.invulnerability=999
	Input.action_press("pulse")
	for tick in range(480):
		await physics_frame
		if paused:
			world.choose_upgrade("split")
			world.resume_game()
	Input.action_release("pulse")
	check(world.kills>0 and world.auto_hits>0 and world.combat.swings>0,"actual enemy AI / auto magic / manual sweeps run together")
	check(world.save_queue==null,"live integration still has no save queue")
	await shot("integrated_live_combat")
	var f := FileAccess.open("res://art_review/hero_reskin_v1/integration_qa.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"kills":world.kills,"auto_hits":world.auto_hits,"swings":world.combat.swings,"art_acceptance":false},"  "))
	quit(1 if failures else 0)
