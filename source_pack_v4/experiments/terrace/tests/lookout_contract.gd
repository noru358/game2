extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func run():
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	var world=load("res://lab/journey.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.travel(1)
	for enemy in world.enemies():enemy.set_physics_process(false)
	world.player.position=world.Landscape.on_ground(world.LOOKOUT,0.1)
	world.interact_journey()
	check(world.has_windstep(),"lookout ability acquired")
	var data:Dictionary=world.snapshot()
	world.free()
	set_meta("journey_restore",data)
	world=load("res://lab/journey.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	check(world.vista and world.has_windstep(),"lookout persists in fresh restored scene")
	world.player.dash_wait=0
	await physics_frame
	world.player.set_physics_process(true)
	Input.action_press("dash")
	await physics_frame
	await physics_frame
	check(world.player.dash_wait>0.60 and world.player.dash_wait<=world.player.dash_cooldown*0.75,"reward changes actual dodge cooldown")
	Input.action_release("dash")
	world.player.set_physics_process(false)
	check(not world.player.occluded_portrait.visible,"no cyan xray portrait")
	world.travel(2)
	check(world.has_windstep(),"reward survives forward travel")
	world.travel(1)
	check(world.vista and world.has_windstep(),"reward survives return travel")
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
