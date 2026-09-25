extends SceneTree
var world
var timings:Dictionary={"effects":[],"portrait":[],"strike":[],"defeat_batch":[],"frame":[]}
func _initialize():call_deferred("run")
func run():
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	world=load("res://lab/journey.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.kills=24
	world.upgrades=["split","chain"]
	world.choices_claimed=2
	world.player.position=world.Landscape.on_ground(Vector3(110,0,0),0.1)
	world.player.facing=Vector3.RIGHT
	world.update_camera(1)
	world.save_slot="user://combat_perf_%d.json"%OS.get_process_id()
	for enemy in world.enemies():enemy.free()
	for i in range(8):
		var enemy=world.spawn_enemy("perf_target_%d"%i,world.player.position+Vector3(1.5+(i%2)*0.3,0,(i/2-1.5)*0.35),false,100000,"wanderer")
		enemy.set_physics_process(false)
	var victim_groups=[]
	for group in range(3):
		var victims=[]
		for i in range(8):
			var enemy=world.spawn_enemy("perf_victim_%d_%d"%[group,i],world.Landscape.on_ground(Vector3(134,0,8),0.1),false,1,"wanderer")
			enemy.set_physics_process(false)
			victims.append(enemy)
		victim_groups.append(victims)
	for i in range(60):await process_frame
	var previous:=Time.get_ticks_usec()
	for frame in range(360):
		var started:=Time.get_ticks_usec()
		if frame%24==0:
			world.combat.reset_transient()
			world.combat.combo_step=(frame/24)%3
			world.combat.strike()
			world.auto_attack()
			timings.strike.append((Time.get_ticks_usec()-started)/1000.0)
		if frame%120==60:
			var victims:Array=victim_groups[int(frame/120)]
			for i in range(8):victims[i].position=world.player.position+Vector3(2,0,i*.2)
			world.test_mode=false # Only the unique PID slot above is writable.
			started=Time.get_ticks_usec()
			for enemy in victims:enemy.hit(999)
			timings.defeat_batch.append((Time.get_ticks_usec()-started)/1000.0)
			world.test_mode=true
		started=Time.get_ticks_usec()
		world.update_effects(1.0/60)
		timings.effects.append((Time.get_ticks_usec()-started)/1000.0)
		started=Time.get_ticks_usec()
		world.player.swing_left=maxf(0,world.player.swing_left-1.0/60)
		world.player.orbit_clock+=1.0/60
		world.player.update_visual(1.0/60)
		timings.portrait.append((Time.get_ticks_usec()-started)/1000.0)
		await process_frame
		var now:=Time.get_ticks_usec()
		timings.frame.append((now-previous)/1000.0)
		previous=now
	var summary={}
	for key in timings:
		var values:Array=timings[key]
		values.sort()
		summary[key]={"p50_ms":values[int(values.size()*.5)],"p95_ms":values[mini(values.size()-1,int(values.size()*.95))],"max_ms":values[-1]}
	print(JSON.stringify(summary))
	var file=FileAccess.open(OS.get_environment("DEMO_QA_OUTPUT")+"/performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(summary,"  "))
	if world.has_method("flush_save"):world.flush_save()
	for suffix in ["",".tmp",".bak"]:
		if FileAccess.file_exists(world.save_slot+suffix):DirAccess.remove_absolute(world.save_slot+suffix)
	quit()
