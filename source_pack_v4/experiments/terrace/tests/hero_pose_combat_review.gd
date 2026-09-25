extends SceneTree
var world
var failures := 0
func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func shot(name: String) -> void:
	world.update_art()
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://art_review/hero_pose_v2/"+name+".png")==OK,name)
func run() -> void:
	root.size=Vector2i(1152,720)
	root.content_scale_size=root.size
	world=load("res://lab/hero_pose_combat_review.tscn").instantiate()
	root.add_child(world);current_scene=world
	world.close_view=true
	for i in range(5):await physics_frame
	check(world.save_queue==null,"no player save queue")
	check(not world.locomotion.visible,"rejected rubber mesh hidden")
	for step in range(1,4):
		world.combat.recovery=0
		world.begin_swing()
		check(world.poses.current.frame==0,"sweep preparation pose")
		for tick in range(8):await physics_frame
		check(world.player.swing_step==step,"existing combo step %d"%step)
		check(world.poses.current.frame==1,"hit uses release pose on same tick")
		check(world.strike_events[-1].hands==1,"single swinging hand per strike")
		await shot("attack_"+str(step))
		world.player.swing_left=world.player.swing_duration*0.3
		world.update_art()
		check(world.poses.current.frame==2,"recovery pose")
	world.player.swing_left=0
	world.combat.reset_transient()
	Input.action_press("right")
	for i in range(12):await physics_frame
	check(world.poses.current.state=="walk","actual movement selects walk frames")
	await shot("walk")
	for i in range(40):await physics_frame
	check(world.poses.current.state=="run","actual acceleration selects run frames")
	await shot("run")
	Input.action_release("right")
	for i in range(3):await physics_frame
	world.update_art()
	check(world.art_sprite.texture==world.art_regions[0],"stopped uses approved exact idle")
	world.combat.reset_transient()
	world.player.swing_left=0
	var before: int=world.strike_events.size()
	world.begin_swing()
	Input.action_press("dash")
	for tick in range(3):await physics_frame
	Input.action_release("dash")
	check(world.windup_left==0 and world.queued_step==0,"dodge cancels swing preparation")
	check(world.strike_events.size()==before,"cancelled preparation emits no strike")
	for tick in range(20):await physics_frame
	world.combat.reset_transient()
	before=world.strike_events.size()
	Input.action_press("pulse")
	for tick in range(115):await physics_frame
	Input.action_release("pulse")
	check(world.strike_events.size()>=before+3,"held J plays a full connected combo")
	if world.strike_events.size()>=before+3:
		check([world.strike_events[before].step,world.strike_events[before+1].step,world.strike_events[before+2].step]==[1,2,3],"held combo order 1 / 2 / 3")
	var f := FileAccess.open("res://art_review/hero_pose_v2/runtime_qa.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"failures":failures,"events":world.strike_events,"pose_changes":world.poses.frame_changes,"acceptance":false,"scope":"right-only candidate, no enemies, real existing combo timing"},"  "))
	quit(1 if failures else 0)
