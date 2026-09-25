extends SceneTree
var failures:=0
var world
const FX=preload("res://game/combat_effect.gd")
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func clear_effects() -> void:
	for effect in world.effects:effect.node.free()
	world.effects.clear()
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await process_frame
	await RenderingServer.frame_post_draw
	var folder:=OS.get_environment("DEMO_QA_OUTPUT")
	if folder.is_empty():folder="res://docs/validation/d100"
	check(root.get_texture().get_image().save_png(folder+"/"+name+".png")==OK,"capture "+name)
func run() -> void:
	world=load("res://lab/world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	for e in world.enemies():e.free()
	world.player.position=world.Landscape.on_ground(Vector3(110,0,3),0.1)
	world.update_camera(1)
	await physics_frame
	for direction_index in range(8):
		var dir:=Vector3(cos(direction_index*PI/4),0,sin(direction_index*PI/4))
		var a:=FX.swing_axis(dir,1)
		var b:=FX.swing_axis(dir,2)
		check(absf(a.dot(b))<0.7,"distinct crossing axes direction "+str(direction_index))
		world.kills=4
		for step in [1,2]:
			clear_effects()
			world.player.facing=dir
			world.combat.reset_transient()
			world.combat.combo_step=step-1
			world.combat.strike()
			check(world.player.casting_direction.dot(dir)>0.99,"combo keeps facing %d/%d"%[direction_index,step])
			world.player.swing_left=world.player.swing_duration-0.055
			world.player.update_visual(0)
			for effect in world.effects:effect.node.advance(0.055)
			world.update_hud()
			await capture("swing-%d-%d"%[direction_index,step])
	for kills in [0,4,8]:
		world.kills=kills
		world.combat.reset_transient()
		var observed: Array=[]
		for i in range(4):
			world.combat.recovery=0
			world.combat.strike()
			observed.append(world.combat.combo_step)
		check(observed==([1,2,1,2] if kills==0 else [1,2,3,1]),"growth combo sequence "+str(kills))
		clear_effects()
		world.player.facing=Vector3.RIGHT
		world.combat.recovery=0
		world.combat.combo_step=0 if kills==0 else 2
		world.combat.strike()
		world.player.swing_left=world.player.swing_duration-0.055
		world.player.update_visual(0)
		for effect in world.effects:effect.node.advance(0.055)
		world.update_hud()
		await capture("growth-manual-"+str(kills))
		clear_effects()
		var target=world.spawn_enemy("growth_probe",world.player.position+Vector3(4,0,0),false,1000)
		target.set_physics_process(false)
		world.upgrades=[]
		world.chain=false
		world.auto_hits=0
		world.player.swing_left=0
		world.player.update_visual(0)
		for i in range(4):
			clear_effects()
			world.auto_attack()
		check(target.hp==1000-int(world.attack_profile().auto_damage)*4-(3 if kills==8 else 0),"auto damage and fourth-hit burst "+str(kills))
		check(world.effects.any(func(e):return e.node.kind=="burst")== (kills==8),"burst only unlocked at Lv3")
		for effect in world.effects:effect.node.advance(0.06)
		await capture("growth-auto-"+str(kills))
		target.free()
	world.auto_hits=7
	var data: Dictionary=world.snapshot()
	world.kills=0
	world.auto_hits=0
	world.restore(data)
	check(world.attack_profile().tier==2 and world.auto_hits==7,"save restores growth and automatic cycle")
	world.kills=4
	world.player.facing=Vector3.RIGHT
	for step in [1,2]:
		for at in [0.0,0.04,0.08,0.12]:
			clear_effects()
			world.combat.reset_transient()
			world.combat.combo_step=step-1
			world.combat.strike()
			world.player.swing_left=world.player.swing_duration-at
			world.player.update_visual(0)
			for effect in world.effects:effect.node.advance(at)
			await capture("sequence-%d-%02d"%[step,int(at*100)])
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
