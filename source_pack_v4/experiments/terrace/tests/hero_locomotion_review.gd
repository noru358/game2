extends SceneTree
var world
var failures := 0
var checks := 0
var folder := "res://art_review/playground/"
func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print("PASS " if ok else "FAIL ",label)
func capture() -> Image:
	world.update_art()
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image().get_region(Rect2i(506,328,140,120))
func key(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode=code;e.pressed=true
	world._unhandled_input(e)
func run() -> void:
	root.size=Vector2i(1152,720)
	root.content_scale_size=Vector2i(1152,720)
	world=load("res://lab/hero_art_playground.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	await physics_frame
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.reset_preview_position()
	world.player.body.rotation=Vector3.ZERO
	var rig=world.locomotion
	rig.advance(Vector3.ZERO,1.0/60,false)
	rig.advance(Vector3(0.15,0,0),1.0/60,false)
	check(rig.phase>0 and rig.strength>0,"actual displacement drives phase")
	var phase: float=rig.phase
	for i in range(20):rig.advance(Vector3(0.15,0,0),1.0/60,false)
	check(is_equal_approx(rig.phase,phase) and rig.strength==0,"blocked/stopped actor settles; phase does not march")
	rig.advance(Vector3(100,0,0),1.0/60,false)
	check(is_equal_approx(rig.phase,phase),"teleport excluded")
	rig.advance(Vector3(100.2,0,0),1.0/60,true)
	check(is_equal_approx(rig.phase,phase),"dash suppresses stepping")
	key(KEY_M);check(not rig.motion_enabled,"M disables motion")
	key(KEY_M);check(rig.motion_enabled,"M enables motion")
	key(KEY_F);check(rig.soft_filter,"F enables mip filter")
	key(KEY_F);check(not rig.soft_filter,"F restores sharp filter")
	var sheet := Image.create(560,960,false,Image.FORMAT_RGBA8)
	var changed := []
	for direction in range(8):
		world.player.facing=Vector3(cos(direction*PI/4),0,sin(direction*PI/4))
		var hashes := []
		for frame in range(4):
			rig.phase=PI*0.5*frame
			rig.strength=1
			var im: Image=await capture()
			hashes.append(hash(im.get_data()))
			sheet.blit_rect(im,Rect2i(0,0,140,120),Vector2i(frame*140,direction*120))
		check(hashes[1]!=hashes[3],"direction %d opposite gait phases visibly differ"%direction)
		changed.append(hashes)
	check(sheet.save_png(folder+"motion_contact_sheet.png")==OK,"8 directions x 4 phase contact sheet")
	var comparison := Image.create(420,120,false,Image.FORMAT_RGBA8)
	world.player.facing=Vector3(0,0,1)
	rig.strength=0
	for mode in range(3):
		world.approved_visible=mode!=0
		rig.soft_filter=mode==1
		world.player.hero_visual.apply(world.player.portrait,world.player.facing,false,0,false)
		var im: Image=await capture()
		comparison.blit_rect(im,Rect2i(0,0,140,120),Vector2i(mode*140,0))
	check(comparison.save_png(folder+"quality_old_mipmap_linear.png")==OK,"same-camera old / new mip / new linear")
	key(KEY_Z);world.update_camera(1)
	check(world.camera.size==14.0,"Z close inspection")
	key(KEY_Z);world.update_camera(1)
	check(world.camera.size==22.0,"Z restores gameplay framing")
	world.approved_visible=true
	rig.initialized=false
	rig.strength=0
	var phases := []
	for tick in range(120):
		rig.advance(Vector3(tick*7.5/60.0,0,0),1.0/60,false)
		phases.append(rig.phase)
		await process_frame
	check(phases[30]!=phases[60] and rig.strength==1,"two seconds continuous motion advances")
	for tick in range(15):rig.advance(Vector3(119*7.5/60.0,0,0),1.0/60,false)
	check(rig.strength==0,"continuous motion returns to exact idle")
	rig.initialized=false
	var at := Vector3.ZERO
	rig.advance(at,1.0/60,false)
	check(rig.state==rig.State.IDLE,"explicit idle state")
	for tick in range(20):
		at.x+=7.5/60
		rig.advance(at,1.0/60,false)
	check(rig.state==rig.State.WALK and rig.run_blend==0,"walk at 7.5")
	var walk_phase: float=rig.phase
	at.x+=7.5/60
	rig.advance(at,1.0/60,false)
	check(is_equal_approx(fposmod(rig.phase-walk_phase,TAU),7.5/60*PI/1.7),"walk stride distance 1.7")
	for tick in range(20):
		at.x+=10.0/60
		rig.advance(at,1.0/60,false)
	check(rig.state==rig.State.RUN and rig.run_blend==1,"run at 10 with blended transition")
	var run_phase: float=rig.phase
	at.x+=10.0/60
	rig.advance(at,1.0/60,false)
	check(is_equal_approx(fposmod(rig.phase-run_phase,TAU),10.0/60*PI/1.9),"run stride distance 1.9")
	at.x+=8.7/60;rig.advance(at,1.0/60,false)
	check(rig.state==rig.State.RUN,"threshold hysteresis avoids flicker")
	at.x+=8.4/60;rig.advance(at,1.0/60,false)
	check(rig.state==rig.State.WALK,"deceleration returns to walk")
	for tick in range(20):rig.advance(at,1.0/60,false)
	check(rig.state==rig.State.IDLE and rig.strength==0 and rig.run_blend==0,"stop clears run and gait")
	var states_image := Image.create(420,120,false,Image.FORMAT_RGBA8)
	world.player.facing=Vector3(1,0,1).normalized()
	var state_hashes := []
	for state in range(3):
		rig.phase=PI/2
		rig.strength=0 if state==0 else 1
		rig.run_blend=1 if state==2 else 0
		var im: Image=await capture()
		state_hashes.append(hash(im.get_data()))
		states_image.blit_rect(im,Rect2i(0,0,140,120),Vector2i(state*140,0))
	check(state_hashes[0]!=state_hashes[1] and state_hashes[1]!=state_hashes[2],"idle / walk / run render different poses")
	check(states_image.save_png(folder+"idle_walk_run.png")==OK,"three state GPU comparison")
	var f := FileAccess.open(folder+"motion_qa.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"direction_order":["RIGHT","FRONT-RIGHT","FRONT","FRONT-LEFT","LEFT","BACK-LEFT","BACK","BACK-RIGHT"],"phase_columns":[0,0.25,0.5,0.75],"pose_hashes":changed,"method":"runtime mesh deformation; hidden legs not authored; stance sliding not solved"},"  "))
	quit(1 if failures else 0)

