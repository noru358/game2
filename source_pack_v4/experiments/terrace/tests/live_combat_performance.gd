extends SceneTree
## Real enemy AI, collision, warning drawing, player and world physics stay enabled.
var world
var results:Dictionary={}
var failures:=0
class PhysicsProbe extends Node:
	var begin:Node
	var tick:=0
	var samples:Array=[]
	func _physics_process(_delta:float):
		if begin==null:tick=Time.get_ticks_usec()
		else:samples.append((Time.get_ticks_usec()-begin.tick)/1000.0)
func _initialize():call_deferred("run")
func stats(values:Array)->Dictionary:
	if values.is_empty():return {"error":"No live samples; invalid benchmark"}
	values.sort()
	return {"p50_ms":values[int(values.size()*0.5)],"p95_ms":values[int(values.size()*0.95)],"max_ms":values[-1]}
func run():
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	var chapter:=int(OS.get_environment("LIVE_CHAPTER"))
	var hunt:=OS.get_environment("LIVE_HUNT")=="1"
	world=load("res://lab/journey.tscn").instantiate()
	root.add_child(world)
	var begin:=PhysicsProbe.new()
	begin.process_physics_priority=-10000
	root.add_child(begin)
	var end:=PhysicsProbe.new()
	end.begin=begin
	end.process_physics_priority=10000
	root.add_child(end)
	world.save_slot="user://live_combat_%d.json"%OS.get_process_id()
	for i in range(3):await physics_frame
	if chapter>0:world.travel(chapter)
	world.kills=24
	world.choices_claimed=2
	world.upgrades=["split","chain"]
	for i in range(30):await process_frame
	var counts:=[2,8,24] if OS.get_environment("LIVE_COUNTS").is_empty() else Array(OS.get_environment("LIVE_COUNTS").split(",")).map(func(value):return int(value))
	for count in counts:
		for enemy in world.enemies():enemy.free()
		world.player.position=world.Landscape.on_ground(Vector3(132,0,-5) if chapter==1 else Vector3(110,0,0),0.1)
		world.player.hp=5
		world.player.invulnerability=1000
		world.player.facing=Vector3.RIGHT
		for i in range(count):
			var at:Vector3=world.player.position+Vector3(cos(i*TAU/count),0,sin(i*TAU/count))*1.0
			var role:="wanderer"
			if OS.get_environment("LIVE_MIXED")=="1":role="caster" if i%8==7 else ("charger" if i%4==3 else "wanderer")
			world.spawn_enemy("live_%d"%i,at,false,[20,30,40][chapter] if hunt else 100000,role)
		if OS.get_environment("LIVE_GUARD")=="1":
			var guard=world.spawn_enemy("journey_guard",world.player.position+Vector3(4,0,0),true,100000)
			world.configure_guard(guard)
		world.test_mode=false # Only the PID-specific slot assigned before this point.
		var frames:Array=[]
		end.samples.clear()
		var warning_frames:=0
		var guardian_warning_frames:=0
		var resumed_focus_pauses:=0
		var initial_kills:int=world.kills
		var initial_swings:int=world.combat.swings
		var previous:=Time.get_ticks_usec()
		var started:=previous
		for frame in range(240):
			if frame%40==0:Input.action_press("pulse")
			if not hunt and frame%40==1:Input.action_release("pulse")
			if hunt:
				Input.action_release("left")
				Input.action_release("right")
				if frame%120 in range(50,80):Input.action_press("right")
				if frame%120 in range(80,110):Input.action_press("left")
			await process_frame
			var now:=Time.get_ticks_usec()
			if paused:
				world.resume_game()
				resumed_focus_pauses+=1
				previous=now
				continue
			frames.append((now-previous)/1000.0)
			previous=now
			if world.enemies().any(func(e):return e.windup>0):warning_frames+=1
			if world.enemies().any(func(e):return e.keeper!=null and e.keeper.phase=="warning"):guardian_warning_frames+=1
			if now-started>12000000:break
		results[str(count)]={"frame":stats(frames),"physics_callbacks":stats(end.samples),"warning_frames":warning_frames,"guardian_warning_frames":guardian_warning_frames,"frames":frames.size(),"chapter":chapter,"mixed":OS.get_environment("LIVE_MIXED")=="1","swings":world.combat.swings,"actual_kills":world.kills-initial_kills,"focus_pauses_excluded":resumed_focus_pauses}
		if end.samples.is_empty() or world.combat.swings<=initial_swings:
			failures+=1
			push_error("Invalid benchmark: live physics/attacks did not run")
		print("LIVE ",count," ",JSON.stringify(results[str(count)]))
		var partial=FileAccess.open(OS.get_environment("DEMO_QA_OUTPUT")+"/live_performance.json",FileAccess.WRITE)
		partial.store_string(JSON.stringify(results,"  "))
	Input.action_release("pulse")
	Input.action_release("left")
	Input.action_release("right")
	var file=FileAccess.open(OS.get_environment("DEMO_QA_OUTPUT")+"/live_performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  "))
	world.flush_save()
	for suffix in ["",".tmp",".bak"]:
		if FileAccess.file_exists(world.save_slot+suffix):DirAccess.remove_absolute(world.save_slot+suffix)
	quit(1 if failures else 0)
