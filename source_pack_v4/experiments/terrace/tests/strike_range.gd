extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func run():
	set_meta("lab_flat",true)
	var world=load("res://lab/world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	for e in world.enemies():e.free()
	world.player.position=Vector3(110,0,3)
	for kills in [0,4,8]:
		world.kills=kills
		var reach:float=world.attack_profile().reach
		for angle in [0.0,PI/2,PI,PI*1.5]:
			var direction:=Vector3(cos(angle),0,sin(angle))
			world.player.facing=direction
			# Symmetric candidates cancel soft aiming; test one target at a time
			# beyond the aim-assist angle for cone tests.
			for spec in [[reach-0.15,0.0,true],[reach+0.15,0.0,false],[reach*0.8,acos(0.25)-0.10,true],[reach*0.8,acos(0.25)+0.10,false]]:
				var target=world.spawn_enemy("range",world.player.position+Vector3(cos(angle+spec[1]),0,sin(angle+spec[1]))*spec[0],false,100)
				target.set_physics_process(false)
				world.combat.reset_transient()
				world.combat.strike()
				check((target.hp<100)==spec[2],"range/cone tier %d angle %.2f spec %s"%[kills,angle,str(spec)])
				var fx=world.effects.filter(func(e):return e.node.get("kind")=="sweep").back().node
				check(is_equal_approx(fx.strike_reach,reach),"visible rim uses actual reach")
				target.free()
				for e in world.effects:e.node.free()
				world.effects.clear()
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
