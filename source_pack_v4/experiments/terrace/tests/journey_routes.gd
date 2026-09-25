extends SceneTree
var failures:=0
var world
var passable:Dictionary={}
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func map_routes():
	passable.clear()
	var query:=PhysicsShapeQueryParameters3D.new()
	var shape:=SphereShape3D.new()
	shape.radius=0.45
	query.shape=shape
	query.collision_mask=1
	for x in range(102,139):
		for z in range(-30,13):
			var at:Vector3=world.Landscape.on_ground(Vector3(x,0,z),0.65)
			query.transform=Transform3D(Basis.IDENTITY,at)
			if world.Landscape.normal_at(at).y>0.70 and world.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():passable[Vector2i(x,z)]=true
func walk(destination:Vector3) -> bool:
	var start:=Vector2i(roundi(world.player.position.x),roundi(world.player.position.z))
	var goal:=Vector2i(roundi(destination.x),roundi(destination.z))
	var queue:Array[Vector2i]=[start]
	var parent:Dictionary={start:start}
	var cursor:=0
	while cursor<queue.size() and not parent.has(goal):
		var at:=queue[cursor]
		cursor+=1
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next:Vector2i=at+offset
			if parent.has(next) or not passable.has(next):continue
			if absf(world.Landscape.height_at(Vector3(next.x,0,next.y))-world.Landscape.height_at(Vector3(at.x,0,at.y)))>0.72:continue
			parent[next]=at
			queue.append(next)
	if not parent.has(goal):print("NO PATH ",start," -> ",goal);return false
	var route:Array[Vector2i]=[]
	var node:=goal
	while node!=start:route.push_front(node);node=parent[node]
	for step in route:
		var reached:=false
		for frame in range(65):
			for action in ["left","right","up","down"]:Input.action_release(action)
			var d:=Vector2(step.x-world.player.position.x,step.y-world.player.position.z)
			if d.length()<0.30:reached=true;break
			if absf(d.x)>0.14:Input.action_press("right" if d.x>0 else "left")
			if absf(d.y)>0.14:Input.action_press("down" if d.y>0 else "up")
			await physics_frame
		if not reached:print("STUCK ",world.player.position," -> ",step);return false
	for action in ["left","right","up","down"]:Input.action_release(action)
	return true
func run():
	world=load("res://lab/journey.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	for chapter in range(3):
		for enemy in world.enemies():enemy.set_physics_process(false)
		await physics_frame
		await physics_frame
		map_routes()
		for i in range(2):
			var ok:bool=await walk(world.CLUES[i])
			check(ok,"real movement reaches region %d discovery %d"%[chapter,i])
			if not ok:quit(1);return
			world.interact_journey()
		check(world.exploration.respawn_point().distance_to(world.Landscape.on_ground(world.CLUES[1]+Vector3(2,0,0),0.1))<0.1,"discovery sets real respawn point")
		if chapter==1:
			check(world.shortcut,"root discovery opens persistent shortcut")
			check(await walk(world.LOOKOUT),"real movement reaches optional lookout")
			world.interact_journey()
			check(world.has_windstep(),"lookout grants permanent windstep")
		if chapter==2:check(world.has_windstep(),"windstep persists after region travel")
		if chapter==2:check(world.attack_profile().damage[0]==9,"temple discovery adds two manual power")
		check(await walk(world.EXIT),"real movement reaches region court "+str(chapter))
		for enemy in world.enemies():enemy.hit(9999)
		await process_frame
		if world.pending_choices()>0:world.choose_upgrade(world.available_upgrades()[0])
		world.interact_journey()
		check(world.chapter==mini(2,chapter+1),"interact travels after route")
	check(world.finished,"complete route ending")
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
