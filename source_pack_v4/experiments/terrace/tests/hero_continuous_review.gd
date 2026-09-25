extends SceneTree
# Record real input/physics/combat in sequence; --write-movie can preserve playback.
var world
var trace: Array=[]
var idle_gaps := 0
var states: Dictionary={}
var combo_steps: Dictionary={}
func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func input(actions: Array) -> void:
	for action in ["right","left","up","down","pulse","dash"]:
		if action in actions:Input.action_press(action)
		else:Input.action_release(action)
func run() -> void:
	root.size=Vector2i(1152,720);root.content_scale_size=root.size
	world=load("res://lab/character_integration.tscn").instantiate()
	root.add_child(world);current_scene=world
	world.player.invulnerability=999
	var sheet := Image.create(1120,480,false,Image.FORMAT_RGBA8)
	for tick in range(360):
		if tick==0:input([])
		if tick==30:input(["up"])
		if tick==70:input(["right"])
		if tick==100:input(["pulse"])
		if tick==155:input(["left","dash"])
		if tick==157:input(["left"])
		if tick==180:input([])
		# Include both rear diagonals explicitly after feedback about boot direction and tail roots.
		if tick==210:input(["up","right"])
		if tick==250:input(["left","up"])
		if tick==280:input(["pulse","right"])
		if tick==340:input([])
		if paused:
			world.choose_upgrade("split");world.resume_game()
		await process_frame
		await RenderingServer.frame_post_draw
		var p=world.player
		var state: String=p.hero_visual.last_state
		states[state]=true
		if state=="strike":combo_steps[p.swing_step]=true
		if world.combat.recovery>0 and p.dash_left<=0 and state=="idle":idle_gaps+=1
		trace.append({"frame":tick,"state":state,"step":p.swing_step,"direction":p.hero_visual.direction_index(p.facing),"phase":p.walk_phase,"speed":Vector2(p.velocity.x,p.velocity.z).length(),"position":[p.position.x,p.position.y,p.position.z],"footfalls":p.footfalls,"cooldown":world.combat.recovery,"dash":p.dash_left})
		if tick%15==0:
			var foot: Vector2=world.camera.unproject_position(p.global_position)
			var crop := Rect2i(clampi(int(foot.x)-70,0,1012),clampi(int(foot.y)-120,0,560),140,160)
			var cell := int(tick/15)
			sheet.blit_rect(root.get_texture().get_image(),crop,Vector2i((cell%8)*140,int(cell/8)*160))
	input([])
	var result := {"frames":trace,"idle_gaps":idle_gaps,"states":states.keys(),"combo_steps":combo_steps.keys(),"swings":world.combat.swings,"kills":world.kills,"save_queue_absent":world.save_queue==null,"art_acceptance":false}
	var f := FileAccess.open("res://art_review/hero_pose_v2/continuous_trace.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	sheet.save_png("res://art_review/hero_pose_v2/continuous_gpu_sheet.png")
	print("continuous states=",states.keys()," idle gaps=",idle_gaps," swings=",world.combat.swings," kills=",world.kills)
	quit(0 if idle_gaps==0 and states.has("walk") and states.has("run") and states.has("prepare") and states.has("recovery") and states.has("dash") and combo_steps.size()==3 and world.save_queue==null else 1)
