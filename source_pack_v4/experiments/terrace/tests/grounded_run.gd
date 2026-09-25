extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
	print("PASS " if value else "FAIL ",label)
	if not value: failures += 1
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://game/world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	for enemy in world.enemies(): enemy.set_physics_process(false)
	var p = world.player
	await frames(3)
	Input.action_press("right")
	await frames(10)
	check(not p.running_visual and p.portrait.texture in p.hero_visual.walks+p.hero_visual.walk_passes,"early movement uses walk poses")
	await frames(65)
	check(p.running_visual and p.portrait.texture in p.hero_visual.runs+p.hero_visual.run_passes,"acceleration changes to dedicated run poses")
	check(p.footfalls > 2,"actual distance produces foot contacts")
	Input.action_release("right")
	await frames(3)
	check(not p.running_visual and p.walk_phase == 0,"release settles immediately without visual sliding")
	p.position = Vector3(4.25,0.1,0)
	Input.action_press("right")
	await frames(15)
	var count: int = p.footfalls
	var phase: float = p.walk_phase
	await frames(30)
	check(p.footfalls == count and is_equal_approx(p.walk_phase,phase),"blocked movement cannot run in place or leave footprints")
	Input.action_release("right")
	p.position = world.Landscape.on_ground(Vector3(10,0,-20),0.2)
	Input.action_press("up")
	await frames(40)
	Input.action_release("up")
	await frames(10)
	check(p.position.y > 0.7 and p.is_on_floor(),"ascending ramp changes physical height and stays grounded")
	var resting: Vector3 = p.position
	await frames(20)
	check(p.position.distance_to(resting) < 0.02,"standing on incline does not drift downhill")
	Input.action_press("down")
	await frames(30)
	Input.action_release("down")
	await frames(5)
	check(p.position.y < resting.y and p.is_on_floor(),"descending ramp stays snapped to ground")
	var data: Dictionary = world.snapshot()
	data.player = [16,0.2,-33]
	for enemy in world.enemies(): enemy.free()
	world.restore(data)
	check(p.position.y > 2.25,"old flat save resumes above raised terrain")
	await frames(10)
	check(p.is_on_floor(),"restored player settles safely on new terrain")
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
