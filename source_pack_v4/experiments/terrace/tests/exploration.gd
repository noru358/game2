extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
	print("PASS " if value else "FAIL ", label)
	if not value:
		failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://game/world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	for e in world.enemies():
		e.free()
	var trail = world.exploration
	check(not trail.attune("reach"), "cannot choose an unearned level upgrade")
	world.player.position = Vector3(14, 0.2, -18)
	trail.update()
	check(trail.discovered.is_empty(), "new exploration requires open route")
	world.open_gate()
	for id in trail.SITES:
		world.player.position = world.Landscape.on_ground(trail.SITES[id].at,0.2)
		trail.update()
		trail.update()
	check(trail.interact(), "shelter rest begins after discovering route")
	trail.update_rest(trail.REST_SECONDS)
	check(trail.discovered.size() == 3 and trail.crystals() == 3, "three distinct discoveries reward exactly once")
	check(trail.journal_text().contains("인장"), "relic story stays available in journal")
	world.kills=28
	for id in ["split","chain","echo"]: world.choose_upgrade(id)
	check(trail.attune("reach") and trail.crystals() == 0 and not trail.attune("force"), "level-up grants one persistent attunement without a second purchase")
	world.player.position = Vector3(-10, 0.2, 0)
	var enemy = world.spawn_enemy("range", Vector3(-2.5, 0.2, 0), false, 12)
	enemy.set_physics_process(false)
	await physics_frame
	world.auto_attack()
	check(enemy.hp == 9, "range attunement actually reaches farther enemy")
	trail.attunement = "force"
	enemy.position = Vector3(-8, 0.2, 0)
	enemy.knockback = Vector3.ZERO
	world.player.facing = Vector3.RIGHT
	world.combat.strike()
	check(enemy.knockback.length() > 7.2, "force attunement increases actual J impulse")
	trail.attunement = "reach"
	world.hitstop = 0
	var snapshot: Dictionary = world.snapshot()
	trail.restore(snapshot.exploration)
	check(trail.attunement == "reach" and trail.discovered.size() == 3 and trail.crystals() == 0, "discovery and spent resources survive restore")
	world.player.hp = 1
	world.player.invulnerability = 0
	world.player.hurt()
	check(world.player.position == world.Landscape.on_ground(trail.SITES.shelter.at,0.2) and world.player.hp == 5, "death returns to prepared shelter without losing progress")
	trail.restore({"discovered": ["shelter", "shelter", "invalid"], "attunement": "force"})
	check(trail.discovered.size() == 1 and trail.attunement == "", "restore filters duplicates and unearned attunement")
	trail.restore({})
	check(trail.discovered.is_empty() and trail.respawn_point().x == -15, "legacy save defaults safely")
	# Walk through actual entrance and both bends using physics input, no teleports between waypoints.
	world.player.position = Vector3(14, 0.2, -10)
	world.player.set_physics_process(true)
	var route := [Vector3(14, 0, -18), Vector3(10, 0, -19), Vector3(10, 0, -24), Vector3(8, 0, -26), Vector3(8, 0, -27.5), Vector3(15, 0, -27.5), Vector3(16, 0, -33)]
	for target in route:
		var reached := false
		for tick in range(300):
			for key in ["left", "right", "up", "down"]:
				Input.action_release(key)
			var offset: Vector3 = target - world.player.position
			if Vector2(offset.x, offset.z).length() < 0.5:
				reached = true
				break
			if absf(offset.x) > 0.2:
				Input.action_press("right" if offset.x > 0 else "left")
			if absf(offset.z) > 0.2:
				Input.action_press("down" if offset.z > 0 else "up")
			await physics_frame
			trail.update()
		check(reached, "walkable route waypoint %s" % target)
		if not reached:
			print("AT ",world.player.position," velocity=",world.player.velocity," floor=",world.player.is_on_floor())
	check(trail.discovered.size() == 3, "walking naturally discovers all three sites")
	print("RESULT failures=", failures)
	quit(1 if failures else 0)
