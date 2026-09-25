# Historical D102 / 0.4 route only. For 0.5 use journey_routes; this script is not new-route timing evidence.
extends SceneTree
var world
var failures:=0
func _initialize():call_deferred("run")
func release():
	for action in ["up","down","left","right","pulse"]:Input.action_release(action)
func steer(to:Vector3):
	for action in ["up","down","left","right"]:Input.action_release(action)
	var d:Vector3=to-world.player.position
	if absf(d.x)>0.35:Input.action_press("right" if d.x>0 else "left")
	if absf(d.z)>0.35:Input.action_press("down" if d.z>0 else "up")
func walk(to:Vector3):
	for i in range(600):
		world.player.invulnerability=10
		if Vector2(to.x-world.player.position.x,to.z-world.player.position.z).length()<0.7:release();return true
		steer(to)
		await physics_frame
	print("FAIL route ",to," from ",world.player.position)
	failures+=1
	release()
	return false
func fight(center:Vector3):
	for i in range(2700):
		world.player.invulnerability=10
		if paused:
			world.choose_upgrade(world.available_upgrades()[0])
			world.resume_game()
		var targets:Array=world.enemies().filter(func(e):return Vector2(e.position.x-center.x,e.position.z-center.z).length()<11)
		if targets.is_empty():release();return
		targets.sort_custom(func(a,b):return a.position.distance_to(world.player.position)<b.position.distance_to(world.player.position))
		var enemy=targets[0]
		var d:Vector3=enemy.position-world.player.position
		d.y=0
		world.player.facing=d.normalized()
		if d.length()>2.2:steer(enemy.position)
		else:
			for action in ["up","down","left","right"]:Input.action_release(action)
		Input.action_press("pulse")
		await physics_frame
	print("FAIL combat timeout ",center)
	failures+=1
	release()
func run():
	world=load("res://lab/journey.tscn").instantiate()
	root.add_child(world)
	for chapter in range(3):
		print("START region ",chapter," elapsed ",world.journey_seconds)
		await fight(Vector3(110,0,0))
		await walk(Vector3(132,0,4))
		await walk(world.CLUES[0])
		world.interact_journey()
		await walk(Vector3(132,0,-11))
		await fight(Vector3(132,0,-12))
		await walk(Vector3(132,0,-22))
		await walk(Vector3(120,0,-22))
		await fight(Vector3(118,0,-23))
		await walk(Vector3(110,0,-12))
		await walk(world.CLUES[1])
		world.interact_journey()
		await walk(Vector3(110,0,-22))
		await walk(Vector3(120,0,-24))
		world.interact_journey()
		print("END region ",chapter," elapsed ",world.journey_seconds," remaining ",world.enemies().size())
		if world.chapter!=mini(chapter+1,2):failures+=1;break
	print("RESULT failures=",failures," finished=",world.finished," active_seconds=",world.journey_seconds," invulnerability used: timing is optimized lower-bound, not human playtime")
	quit(1 if failures or not world.finished else 0)
