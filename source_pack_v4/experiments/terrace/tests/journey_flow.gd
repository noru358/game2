extends SceneTree
var failures:=0
var world
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func shot(name:String):
	world.update_camera(1)
	world.update_hud()
	var start:Vector3=world.camera.position
	for frame in range(24):
		world.camera.position=start+Vector3(frame*0.012,0,frame*0.007)
		await process_frame
		await RenderingServer.frame_post_draw
		if frame in [0,23]:root.get_texture().get_image().save_png(OS.get_environment("DEMO_QA_OUTPUT")+"/journey-"+name+("" if frame==0 else "-23")+".png")
func run():
	world=load("res://lab/journey.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	check(ProjectSettings.get_setting("application_config/version")=="0.10-core-response","expected 0.10 runtime")
	check(world.enemies().size()==25,"first region 24 enemies and guardian")
	check(world.save_slot=="user://journey_v2.json","separate journey save")
	for chapter in range(3):
		for enemy in world.enemies():enemy.set_physics_process(false)
		var valid:=true
		for node in world.get_children():
			if not node.has_meta("ground_clearance"):continue
			var vertices:PackedVector3Array=node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for i in range(0,vertices.size(),3):
				var at:Vector3=(vertices[i]+vertices[i+1]+vertices[i+2])/3.0
				valid=valid and absf(at.y-world.Landscape.height_at(at)-float(node.get_meta("ground_clearance")))<0.001
		check(valid,"all region paving follows shared height")
		world.player.position=world.Landscape.on_ground(Vector3(110,0,8),0.1)
		await shot("%d-entry"%chapter)
		var size:float=world.camera.size
		for i in range(2):
			world.player.position=world.Landscape.on_ground(world.CLUES[i],0.1)
			world.interact_journey()
		check(world.discoveries.size()==2,"two quiet discoveries region "+str(chapter))
		world.player.position=world.Landscape.on_ground(world.EXIT,0.1)
		world.interact_journey()
		check(world.chapter==chapter and not world.finished,"guardian blocks exit")
		for enemy in world.enemies():enemy.hit(9999)
		await process_frame
		check(world.guard_down,"guardian defeat recorded")
		world.player.position=world.Landscape.on_ground(world.EXIT,0.1)
		world.update_camera(1)
		check(is_equal_approx(size,world.camera.size) and size==22,"no combat or exploration zoom")
		await shot("%d-court"%chapter)
		if chapter==0:
			world.choose_upgrade("split")
			check(world.upgrades.has("split"),"permanent growth selected")
		if chapter==1:
			var saved:Dictionary=world.snapshot()
			var slot:="user://journey_qa_%d.json"%OS.get_process_id()
			check(world.Store.write(saved,slot)==OK,"atomic isolated save")
			var data:Dictionary=world.Store.read_data(slot)
			world.free()
			set_meta("journey_restore",data)
			world=load("res://lab/journey.tscn").instantiate()
			root.add_child(world)
			current_scene=world
			world.set_physics_process(false)
			world.player.set_physics_process(false)
			check(world.chapter==1 and world.guard_down and world.discoveries.size()==2,"fresh scene restores region and discoveries")
			check(world.enemies().is_empty(),"defeated enemies remain defeated")
			world.travel(0)
			check(world.guard_down and world.discoveries.size()==2 and world.enemies().is_empty(),"return trip preserves previous region")
			world.travel(1)
			world.player.position=world.Landscape.on_ground(world.EXIT,0.1)
		if world.pending_choices()>0:world.choose_upgrade(world.available_upgrades()[0])
		world.interact_journey()
		check(world.chapter==mini(2,chapter+1),"forward travel region "+str(chapter))
	check(world.finished and paused,"complete ending with no timed gate")
	check(root.gui_get_focus_owner() is Button,"ending keyboard focus")
	await shot("ending")
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
