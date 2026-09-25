extends SceneTree
var world
func _initialize():call_deferred("run")
func shot(name:String):
	world.player.update_visual(0)
	world.update_camera(1)
	var start:Vector3=world.camera.position
	for frame in range(24):
		world.camera.position=start+Vector3(frame*0.012,0,frame*0.007)
		await process_frame
		await RenderingServer.frame_post_draw
		if frame in [0,23]:root.get_texture().get_image().save_png(OS.get_environment("DEMO_QA_OUTPUT")+"/review-"+name+"-%02d.png"%frame)
func run():
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	world=load("res://lab/journey.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.travel(1)
	for enemy in world.enemies():enemy.set_physics_process(false)
	world.hud.hide()
	var sites=[Vector3(132,0,-5),Vector3(122,0,-13),Vector3(110,0,-19),world.LOOKOUT]
	for i in range(sites.size()):
		world.player.position=world.Landscape.on_ground(sites[i],0.1)
		await shot("jungle-%d"%i)
	var hud=load("res://lab/compact_hud.gd").new()
	hud.world=world
	hud.full_map=false
	var layer:=CanvasLayer.new()
	world.add_child(layer)
	layer.add_child(hud)
	hud.reveal(Vector3(110,0,-19))
	hud.reveal(Vector3(132,0,-5))
	world.message_left=0
	await shot("hud-fog")
	hud.full_map=true
	await shot("hud-full")
	layer.hide()
	world.player.position=world.Landscape.on_ground(Vector3(132,0,-5),0.1)
	for i in range(8):
		world.player.facing=Vector3(cos(i*PI/4),0,sin(i*PI/4))
		await shot("idle-%d"%i)
	world.player.facing=Vector3.RIGHT
	for combo in range(1,4):
		world.combat.reset_transient()
		world.kills=24
		world.combat.combo_step=combo-1
		world.combat.strike()
		await shot("strike-%d"%combo)
		for effect in world.effects:effect.node.free()
		world.effects.clear()
	world.combat.reset_transient()
	world.player.swing_left=0
	world.travel(2)
	for enemy in world.enemies():enemy.set_physics_process(false)
	for i in range(2):
		world.player.position=world.Landscape.on_ground(Vector3(132,0,-12-i*14),0.1)
		await shot("east-valley-%d"%i)
	for i in range(3):
		world.player.position=world.Landscape.on_ground([Vector3(115,0,-16),Vector3(115,0,-19),Vector3(115,0,-22)][i],0.1)
		await shot("occlusion-%d"%i)
	print("RESULT review captures complete; pixel review required")
	quit()
