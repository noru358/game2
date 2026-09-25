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
	for e in w.enemies():e.set_physics_process(false)
	w.guard_down=true
	w.discoveries=[0,1]
	w.player.position=w.Landscape.on_ground(Vector3(120,0,-24),0.1)
	w.interact_journey()
	check(w.chapter==0,"landmark no longer teleports")
	w.player.position=w.Landscape.on_ground(w.EXIT,0.1)
	w.interact_journey()
	check(w.chapter==1,"north trail connects next region")
	w.player.position=w.Landscape.on_ground(Vector3(130,0,10),0.1)
	w.interact_journey()
	check(w.chapter==1,"south scenery is not a broad return trigger")
	w.player.position=w.Landscape.on_ground(w.ENTRY,0.1)
	w.interact_journey()
	check(w.chapter==0 and w.guard_down and w.discoveries.size()==2,"south trail returns with discoveries")
	var data:Dictionary=w.snapshot()
	w.restore(data)
	w.player.position=w.Landscape.on_ground(Vector3(100.3,0,-12),0.1)
	await physics_frame
	await physics_frame
	await process_frame
	check(w.player.position.distance_to(w.checkpoint())<0.1,"old save overlapping new bank returns to checkpoint")
	check(w.discoveries.size()==2 and w.guard_down,"position repair keeps progress")
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
