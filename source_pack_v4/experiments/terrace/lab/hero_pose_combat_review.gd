extends "res://lab/hero_art_playground.gd"
# Real existing combat timing in a right-view art fixture; incomplete art is explicit.
var poses := preload("res://lab/hero_pose_player.gd").new()
var strike_events: Array=[]
var windup_left := 0.0
var queued_step := 0
var sweep_visuals: Array=[]
var attack_buffer := 0.0
func _ready() -> void:
	super._ready()
	locomotion.motion_enabled=false
	player.facing=Vector3.RIGHT
	update_art()
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if Input.is_action_just_pressed("pulse"):
		attack_buffer=maxf(0.18,combat.recovery+windup_left+0.12)
	attack_buffer=maxf(0,attack_buffer-delta)
	if windup_left>0:
		windup_left=maxf(0,windup_left-delta)
		if player.dash_left>0:
			windup_left=0;queued_step=0;attack_buffer=0;player.swing_left=0
		elif windup_left==0:
			player.facing=Vector3(1,0,1).normalized()
			combat.strike()
			queued_step=0
	else:
		combat.recovery=maxf(0,combat.recovery-delta)
		combat.chain_window=maxf(0,combat.chain_window-delta)
		if combat.chain_window<=0 and combat.recovery<=0:combat.combo_step=0
		if (Input.is_action_pressed("pulse") or attack_buffer>0) and combat.recovery<=0 and player.dash_left<=0:begin_swing()
	for effect in sweep_visuals.duplicate():
		effect.age+=delta
		if effect.age>=effect.duration:
			effect.node.queue_free();sweep_visuals.erase(effect)
		else:draw_sweep(effect)
func attack_profile() -> Dictionary:
	var profile := super.attack_profile()
	profile.combo_count=3
	return profile
func begin_swing() -> void:
	queued_step=combat.combo_step%3+1
	windup_left=0.08 if queued_step==3 else 0.05
	attack_buffer=0
	player.swing_step=queued_step
	player.swing_duration=windup_left+0.1
	player.swing_left=player.swing_duration
	player.casting_direction=Vector3(1,0,1).normalized()
	player.velocity.x=0;player.velocity.z=0
	update_art()
func update_art() -> void:
	if not is_instance_valid(art_sprite):return
	super.update_art()
	locomotion.hide()
	art_sprite.show()
	player.portrait.hide()
	var moving := Vector2(player.velocity.x,player.velocity.z).length()>0.1
	if windup_left>0:
		poses.apply(art_sprite,"attack",-1,queued_step,false,1)
	elif player.swing_left>0:
		poses.apply(art_sprite,"attack",0,player.swing_step,player.swing_left<player.swing_duration*0.42,1)
	elif moving:
		poses.apply(art_sprite,"run" if player.current_speed>=8.9 else "walk",player.walk_phase,0,false,art_index)
	# Idle is the approved exact right view; super already assigned its texture.
	art_label.text="  이동 오른쪽·정면 / 공격 앞오른쪽 후보 / 최종 8방향 미완료\n  WASD 이동 · J 가로→되치기→사선내려치기 · Space 회피 · R 초기화\n  미제작 방향은 정지 원화 / 메시 변형 없음 / 공격 %d  "%player.swing_step
func spell_strike(_at: Vector3, direction: Vector3, step: int) -> void:
	update_art()
	var points := poses.hands(art_sprite,step)
	strike_events.append({"step":step,"pose":poses.current.frame,"hands":points.size(),"direction":direction})
	var node := MeshInstance3D.new()
	var surface := ImmediateMesh.new()
	node.mesh=surface
	var material := StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo=true
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=material
	add_child(node)
	node.position=player.position+Vector3.UP*1.5+Vector3(0,0.788,0.616)*0.7
	var event := {"node":node,"mesh":surface,"step":step,"direction":direction,"age":0.0,"duration":0.18 if step<3 else 0.24}
	sweep_visuals.append(event)
	draw_sweep(event)
	for p in points:
		# A diagnostic marker at the authored palm anchor, not a substitute effect.
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius=0.055;sphere.height=0.11
		marker.mesh=sphere
		var mat := StandardMaterial3D.new()
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color=Color.CYAN
		marker.material_override=mat
		add_child(marker)
		marker.global_position=player.body.to_global(p)
		effects.append({"node":marker,"time":0.18})
func draw_sweep(event: Dictionary) -> void:
	var surface: ImmediateMesh=event.mesh
	surface.clear_surfaces()
	surface.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var t: float=event.age/event.duration
	var end := lerpf(-1.3,1.3,t)
	var up := Vector3(0,0.616,-0.788)
	var across := Vector3.UP.cross(event.direction).normalized()
	var axis := across if event.step<3 else (across*0.6-Vector3.UP*0.8).normalized()
	var sign_value := -1.0 if event.step==2 else 1.0
	for i in range(12):
		var a := end-0.8+i*0.8/12
		var b := end-0.8+(i+1)*0.8/12
		var p: Vector3=axis*sin(a)*1.5*sign_value+event.direction*cos(a)*0.6
		var q: Vector3=axis*sin(b)*1.5*sign_value+event.direction*cos(b)*0.6
		for v in [p-up*0.025,p+up*0.025,q+up*0.025,p-up*0.025,q+up*0.025,q-up*0.025]:
			surface.surface_set_color(Color("b899ff") if event.step==3 else Color("9ae6ff"))
			surface.surface_add_vertex(v)
	surface.surface_end()

