extends SceneTree
var failed := 0
func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	print("PASS " if ok else "FAIL ",message)
	if not ok:failed+=1
func run() -> void:
	var world=load("res://lab/character_integration.tscn").instantiate()
	root.add_child(world);current_scene=world
	world.set_physics_process(false);world.player.set_physics_process(false)
	world.player.position=world.Landscape.on_ground(Vector3(110,0,3),0.1)
	world.player.update_visual(0)
	for enemy in world.enemies():
		enemy.set_physics_process(false)
		enemy.position+=Vector3(60,0,0)
	var target=world.enemies()[0]
	target.position=world.Landscape.on_ground(world.player.position+Vector3.FORWARD*4,0.1)
	target.hp=100;target.dead=false
	var before: int=target.hp
	world.auto_attack()
	var shots=world.effects.filter(func(e):return e.node.get("kind")=="fireball")
	check(shots.size()==1 and target.hp==before,"launch creates a fireball without premature damage")
	if shots.is_empty():quit(1);return
	var shot=shots[0].node
	check(shot.global_position.distance_to(world.player.auto_origin()+Vector3.UP*0.85)<0.001,"fireball launches from the firing fox flame")
	shot.advance(shot.duration*0.5)
	check(target.hp==before and world.auto_hits==0,"mid-flight has no damage or impact count")
	if DisplayServer.get_name()!="headless":
		world.update_camera(1);world.camera.size=12
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art_review/hero_pose_v2/fox_fire_midflight.png")
	shot.advance(shot.duration)
	check(target.hp<before and world.auto_hits==1,"arrival deals damage and one impact")
	if DisplayServer.get_name()!="headless":
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art_review/hero_pose_v2/fox_fire_arrival.png")
	var after: int=target.hp
	shot.advance(shot.duration)
	check(target.hp==after and world.auto_hits==1,"arrival cannot damage twice")
	world.kills=0
	var low: float=world.attack_profile().manual_speed
	world.kills=24
	check(world.attack_profile().manual_speed>low,"manual attack speed increases with growth")
	check(world.save_queue==null,"projectile test never touches user saves")
	print("RESULT failures=",failed)
	quit(1 if failed else 0)
