extends SceneTree
const Surface=preload("res://game/effect_surface.gd")
const Warning=preload("res://game/ground_warning.gd")
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func run():
	var world=load("res://lab/world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	for e in world.enemies():e.free()
	var center:Vector3=world.Landscape.on_ground(Vector3(105,0,-6.5))
	var enemy=world.spawn_enemy("warning_qa",center,false,100,"caster")
	enemy.set_physics_process(false)
	var keeper=load("res://game/reservoir_keeper.gd").new(enemy)
	for at in [Vector3(105,0,-7.5),Vector3(105.6,0,-6.5)]:
		world.player.position=world.Landscape.on_ground(at,0.1)
		var supported:bool=Surface.supported(center,world.player.position-center)
		check(supported==(at.z> -7),"height boundary classified correctly")
		world.player.hp=5
		world.player.invulnerability=0
		keeper.centers.assign([center])
		keeper.radius=2.5
		keeper.resolve()
		check((world.player.hp==4)==supported,"keeper damage agrees with supported warning plane")
		world.player.hp=5
		world.player.invulnerability=0
		enemy.caster.center=center
		enemy.caster.phase="warning"
		enemy.caster.remaining=0
		enemy.caster.warnings.append(Warning.make(world,center,1.4,Color.RED))
		enemy.caster.warnings.append(Warning.make(world,center,0.1,Color.RED))
		enemy.caster.update(0,Vector3.ZERO)
		check((world.player.hp==4)==supported,"caster damage agrees with supported warning plane")
		check(enemy.melee_accessible()==supported,"melee access agrees with warning plane")
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
