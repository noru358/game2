extends SceneTree
var failures:=0
var world
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func key(code: int) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame
	await physics_frame
	event=InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame
func walk(to: Vector3) -> bool:
	for i in range(650):
		var difference: Vector3=to-world.player.position
		for action in ["left","right","up","down"]:Input.action_release(action)
		if Vector2(difference.x,difference.z).length()<0.5:return true
		if absf(difference.x)>0.3:Input.action_press("right" if difference.x>0 else "left")
		if absf(difference.z)>0.3:Input.action_press("down" if difference.z>0 else "up")
		await physics_frame
	return false
func run() -> void:
	world=load("res://lab/world.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	await physics_frame
	check(ProjectSettings.get_setting("application_config/version")=="0.10-core-response","expected current 0.10 runtime, not stale executable")
	check(world.save_slot.ends_with("_v4.json"),"current runtime never writes previous version save slots")
	check(world.test_mode and OS.get_user_data_dir().ends_with("FirstTrailExperienceLab"),"isolated project and test storage")
	check(world.enemies().size()==12,"three identical four-enemy groups")
	for enemy in world.enemies():enemy.set_physics_process(false)
	world.set_physics_process(false)
	check(await walk(Vector3(110,0,-19)),"left ascent traversed using movement input")
	check(absf(world.player.position.y-world.Landscape.height_at(world.player.position))<0.15,"terrain height matches physical ground")
	check(await walk(Vector3(120,0,-22)),"upper vista accessible without kills")
	for action in ["left","right","up","down"]:Input.action_release(action)
	world.attack_wait=999
	world.set_physics_process(true)
	await physics_frame
	await physics_frame
	check(world.vista,"vista records during real update")
	world.set_physics_process(false)
	check(await walk(Vector3(120,0,-13)),"upper gate approach traversable")
	for action in ["left","right","up","down"]:Input.action_release(action)
	world.set_physics_process(true)
	await key(KEY_F)
	check(world.shortcut,"F opens shortcut from upper side")
	world.set_physics_process(false)
	check(await walk(Vector3(120,0,7)),"opened shortcut physically traversable downhill")
	for action in ["left","right","up","down"]:Input.action_release(action)
	for enemy in world.enemies().slice(0,4):enemy.hit(99)
	await process_frame
	check(world.kills==4 and world.cleared.size()==1,"cleared group creates small ending")
	world.pause_game("QA")
	await process_frame
	await process_frame
	if DisplayServer.get_name()!="headless" and not OS.get_environment("DEMO_QA_OUTPUT").is_empty():
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OS.get_environment("DEMO_QA_OUTPUT")+"/upgrade-menu.png")==OK,"GPU upgrade screenshot saved")
	var first=root.gui_get_focus_owner()
	await key(KEY_DOWN)
	check(root.gui_get_focus_owner()!=first,"keyboard moves upgrade focus")
	await key(KEY_ENTER)
	check(world.upgrades.size()==1 and not paused,"keyboard chooses upgrade and returns")
	await key(KEY_ESCAPE)
	check(paused,"Escape enters pause")
	await key(KEY_ESCAPE)
	check(not paused,"Escape returns from pause")
	var data: Dictionary=world.snapshot()
	var slot="user://lab_test_%d.json"%OS.get_process_id()
	check(world.Store.write(data,slot)==OK,"test-slot atomic save")
	var loaded: Dictionary=world.Store.read_data(slot)
	check(loaded.shortcut and loaded.vista and loaded.enemies.size()==8,"saved discovery, gate and survivors")
	world.free()
	world=load("res://lab/world.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	for e in world.enemies():e.free()
	world.restore(loaded)
	await physics_frame
	check(world.shortcut and world.vista and world.upgrades.size()==1 and world.enemies().size()==8,"fresh scene restores progress")
	world.set_physics_process(false)
	for e in world.enemies():e.set_physics_process(false)
	check(await walk(Vector3(132,0,7)),"right route approached from lower court")
	check(await walk(Vector3(132,0,-22)),"narrow right ramp physically climbs both terraces")
	for action in ["left","right","up","down"]:Input.action_release(action)
	world.player.hp=1
	world.player.invulnerability=0
	world.player.hurt()
	check(world.player.hp==5 and world.shortcut and world.upgrades.size()==1,"death preserves growth and opened path")
	world.pause_game()
	await process_frame
	await process_frame
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	await process_frame
	await physics_frame
	world=current_scene
	check(world.flat and world.enemies().size()==12 and world.upgrades.is_empty(),"keyboard comparison switch starts separate baseline")
	check(world.Landscape.height_at(Vector3(120,0,-22))==0,"comparison A is flat")
	world.kills=8
	world.upgrades=["split"]
	world.choices_claimed=1
	world.pause_game()
	await process_frame
	await process_frame
	await key(KEY_DOWN)
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	await process_frame
	check(root.gui_get_focus_owner().text=="돌아가기","restart confirmation focuses cancel")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	await process_frame
	await physics_frame
	world=current_scene
	check(world.kills==0 and world.upgrades.is_empty() and world.enemies().size()==12,"confirmed keyboard restart begins fresh field")
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
