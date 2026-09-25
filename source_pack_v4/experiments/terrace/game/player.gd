extends CharacterBody3D

const V = preload("res://game/visuals.gd")
const Land = preload("res://game/landscape.gd")
@export var move_speed: float = 7.5
@export var run_speed: float = 10.0
@export var run_ramp_seconds: float = 0.75
@export var dash_bonus_speed: float = 17.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.9
var dash_left := 0.0
var dash_wait := 0.0
var facing := Vector3.RIGHT
var invulnerability := 0.0
var hp := 5
var body: Node3D
var moving_seconds := 0.0
var current_speed := 7.5
var dash_velocity := Vector3.ZERO
var weapon: Node3D
var second_focus:Node3D
var swing_left := 0.0
var swing_step := 0
var portrait: Sprite3D
var occluded_portrait: Sprite3D
var walk_phase := 0.0
var hero_visual := preload("res://game/hero_visual.gd").new()
var casting_direction := Vector3.RIGHT
var auto_cast_left := 0.0
var auto_cast_direction := Vector3.RIGHT
var running_visual := false
var contact_shadow: MeshInstance3D
var footfalls := 0
var hurt_flash := 0.0
var orbit_clock := 0.0
var familiars: Array[Node3D] = []
var familiar_flare := 0.0
var familiar_flashes := [0.0,0.0]
var familiar_shot := 0
var swing_duration := 0.18
var was_planted := false
var attack_windup := false
var stride_active := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.45
	floor_constant_speed = true
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.35
	collision.shape = shape
	collision.position.y = 0.7
	add_child(collision)
	body = Node3D.new()
	add_child(body)
	portrait = Sprite3D.new()
	# The camera has a fixed pitch. Billboard mode discarded the combo roll.
	portrait.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	portrait.rotation.x = deg_to_rad(-52)
	portrait.shaded = false
	portrait.pixel_size = 0.0042
	portrait.position = Vector3(0, 0.92, 0)
	portrait.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	body.add_child(portrait)
	# Draw a muted locator first; the normal portrait covers it in clear view.
	# This preserves the current pose even behind tall foreground scenery.
	occluded_portrait = Sprite3D.new()
	occluded_portrait.no_depth_test = true
	occluded_portrait.shaded = false
	occluded_portrait.render_priority = -10
	occluded_portrait.modulate = Color(0.35, 0.95, 0.86, 0.7)
	occluded_portrait.visible = false
	occluded_portrait.texture_filter = portrait.texture_filter
	body.add_child(occluded_portrait)
	weapon = preload("res://game/combat_effect.gd").new()
	weapon.kind = "focus"
	weapon.duration = 0.18
	body.add_child(weapon)
	second_focus=preload("res://game/combat_effect.gd").new()
	second_focus.kind="focus"
	body.add_child(second_focus)
	for i in range(2):
		var familiar = preload("res://game/combat_effect.gd").new()
		familiar.kind = "familiar"
		familiar.tint = Color("a9e7ff") if i == 0 else Color("ceb7ff")
		add_child(familiar)
		familiars.append(familiar)
	contact_shadow = MeshInstance3D.new()
	var shadow_plane := PlaneMesh.new()
	shadow_plane.size = Vector2(1.1,0.65)
	contact_shadow.mesh = shadow_plane
	var shadow_mat := ShaderMaterial.new()
	shadow_mat.shader = preload("res://game/contact.gdshader")
	contact_shadow.material_override = shadow_mat
	add_child(contact_shadow)
	update_visual(0)

func planted_attack() -> bool:
	# These whole-body paintings have planted feet, not a moving lower body.
	return hero_visual.baked_motion() and dash_left<=0 and (attack_windup or swing_left>0 or (swing_step>0 and get_parent().combat.recovery>0))

func _physics_process(delta: float) -> void:
	if get_parent().hitstop > 0:
		return
	invulnerability = maxf(0.0, invulnerability - delta)
	hurt_flash = maxf(0, hurt_flash - delta)
	orbit_clock += delta
	familiar_flare = maxf(0, familiar_flare - delta)
	for i in range(2): familiar_flashes[i]=maxf(0,float(familiar_flashes[i])-delta)
	dash_wait = maxf(0.0, dash_wait - delta)
	var input := Input.get_vector("left", "right", "up", "down")
	var direction := Vector3(input.x, 0, input.y)
	# Optional fixed-camera adapter; existing scenes retain world-axis controls.
	if get_parent().has_method("movement_direction"):
		direction=get_parent().movement_direction(input)
	# Net movement intent charges the run. Turns retain momentum, while release or
	# opposing keys stop immediately and cannot pre-charge a stationary sprint.
	if direction.length_squared() > 0.01 and not planted_attack():
		moving_seconds = minf(run_ramp_seconds, moving_seconds + delta)
	else:
		moving_seconds = 0.0
	current_speed = lerpf(move_speed, run_speed, clampf(moving_seconds / maxf(0.01, run_ramp_seconds), 0.0, 1.0))
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
	if Input.is_action_just_pressed("dash") and dash_wait <= 0:
		get_parent().combat.reset_transient()
		auto_cast_left = 0
		swing_left = 0
		dash_left = dash_duration
		dash_wait = dash_cooldown * (0.75 if get_parent().has_method("has_windstep") and get_parent().has_windstep() else 1.0)
		dash_velocity = facing * (current_speed + dash_bonus_speed)
		invulnerability = dash_duration + 0.05
		get_parent().sound("dash")
	if dash_left > 0:
		dash_left -= delta
		velocity.x = dash_velocity.x
		velocity.z = dash_velocity.z
	else:
		# Speed builds up, but direction and release remain exact: no lateral drift.
		var stance := 1.0
		if planted_attack():
			stance = 0.0
		elif swing_left > 0:
			stance = 0.0 if swing_duration - swing_left < 0.13 else 0.55
		velocity.x = direction.x * current_speed * stance
		velocity.z = direction.z * current_speed * stance
	velocity.y -= 25 * delta
	var before := position
	move_and_slide()
	var distance := Vector2(position.x-before.x,position.z-before.z).length()
	advance_stride(distance)
	swing_left = maxf(0, swing_left - delta)
	auto_cast_left = maxf(0, auto_cast_left - delta)
	update_visual(delta)
	body.visible = true
	portrait.modulate = Color("ffb5ad") if hurt_flash > 0 else Color.WHITE
	if position.y < -5:
		position = get_parent().exploration.respawn_point()
		velocity = Vector3.ZERO

func show_auto_cast(toward: Vector3) -> void:
	familiar_flare = 0.22
	familiar_shot += 1
	familiar_flashes[familiar_shot%2]=0.22
	if swing_left > 0 or dash_left > 0: return
	toward.y = 0
	if toward.length_squared() < 0.001: return
	auto_cast_direction = toward.normalized()
	auto_cast_left = 0.14
	update_visual(0)

func update_visual(delta: float) -> void:
	var moving := Vector2(velocity.x, velocity.z).length() > 0.1
	var planted := swing_left > 0 and not moving
	# Resume with feet passing under the body, not an extended contact pose.
	if was_planted and moving and not hero_visual.baked_motion(): walk_phase = PI * 0.5
	was_planted = planted
	var auto_pose := false
	var pose_combo := swing_step if swing_left>0 else 0
	# Keep the painted follow-through across the cooldown tail. Otherwise the
	# 0.28 s pose returned to idle before the 0.36 s combo could continue.
	if hero_visual.baked_motion() and dash_left<=0 and swing_step>0 and get_parent().combat.recovery>0:
		pose_combo=swing_step
	var recovering := swing_left > 0 and swing_left < swing_duration * 0.42 and not moving
	if hero_visual.baked_motion():recovering=pose_combo>0 and swing_left<swing_duration*0.42
	var direction := casting_direction if swing_left > 0 and not moving else facing
	if hero_visual.baked_motion() and pose_combo>0:direction=casting_direction
	if dash_left > 0:
		direction = dash_velocity.normalized()
	running_visual = Vector2(velocity.x,velocity.z).length() >= 8.9 and dash_left <= 0
	hero_visual.apply(portrait, direction, moving, walk_phase, (swing_left > 0 and not moving) or auto_pose, running_visual, pose_combo, recovering)
	if attack_windup and hero_visual.has_method("prepare"):
		hero_visual.prepare(portrait,casting_direction,swing_step)
	if dash_left>0 and hero_visual.has_method("dash"):
		hero_visual.dash(portrait,direction,1.0-dash_left/dash_duration)
	var lift := sin(fmod(walk_phase,PI)) * (0.08 if running_visual else 0.035) if moving else 0.0
	if not hero_visual.baked_motion():
		portrait.position.y += maxf(0,lift)
		portrait.scale = Vector3(1.03,0.97 / cos(deg_to_rad(52)),1) if moving and fmod(walk_phase,PI) < 0.35 else Vector3(1,1.0 / cos(deg_to_rad(52)),1)
	contact_shadow.position.y = Land.height_at(position) - position.y + 0.028
	contact_shadow.quaternion = contact_shadow.quaternion.slerp(Quaternion(Vector3.UP, Land.normal_at(position)),minf(1,delta*14))
	contact_shadow.scale = Vector3.ONE * (1.0 - maxf(0,lift)*0.7)
	# The painted shoulder/arm pose carries the strike. Do not rock the whole card.
	portrait.rotation.z = 0
	# Camera-axis bias preserves the foot's screen position and avoids front-side
	# portrait/stone intersections without drawing an x-ray copy through walls.
	portrait.position += Vector3(0,0.788,0.616)*0.65
	body.rotation.z = clampf(-velocity.x * 0.003, -0.05, 0.05) if swing_left <= 0 else 0.0
	occluded_portrait.texture = portrait.texture
	occluded_portrait.pixel_size = portrait.pixel_size
	occluded_portrait.offset = portrait.offset
	occluded_portrait.flip_h = portrait.flip_h
	occluded_portrait.transform = portrait.transform
	for i in range(familiars.size()):
		var familiar = familiars[i]
		var angle := orbit_clock * 2.0 + i * PI
		# Flank the silhouette: a full orbit put the wisps inside the hero twice per lap.
		var side := -1.0 if i == 0 else 1.0
		var recoil := sin(clampf(float(familiar_flashes[i])/0.22,0,1)*PI)*0.18
		familiar.position = Vector3(side*(1.65+sin(angle)*0.18),1.75+cos(angle)*0.18,-0.35+sin(angle)*0.18)-auto_cast_direction*recoil
		familiar.age = orbit_clock
		familiar.strength = 3 if float(familiar_flashes[i]) > 0 else 1
		familiar.redraw()
	weapon.visible = swing_left > 0 and not moving and not recovering and not attack_windup
	var hands:=hero_visual.focus_points(portrait,casting_direction,swing_step)
	weapon.position = hands[0]
	second_focus.visible=weapon.visible and hands.size()>1
	if weapon.visible:
		weapon.tint = Color("bda9ff") if swing_left > 0 and swing_step == 3 else Color("9edfff")
		weapon.duration = swing_duration
		weapon.age = swing_duration - swing_left
		weapon.redraw()
	if second_focus.visible:
		second_focus.position=hands[1]
		second_focus.tint=weapon.tint
		second_focus.duration=weapon.duration
		second_focus.age=weapon.age
		second_focus.redraw()

func auto_origin() -> Vector3:
	return familiars[familiar_shot % 2].global_position - Vector3.UP * 0.85

func advance_stride(distance: float) -> void:
	if distance < 0.001:
		if Vector2(velocity.x,velocity.z).length() < 0.1:
			walk_phase = 0
			stride_active = false
		return
	if dash_left > 0 or not is_on_floor() or distance > 2.0:
		stride_active = false
		return
	# Start under the hips. Frame playback and contact effects share this phase;
	# a renderer-only quarter-cycle offset made prints occur on passing poses.
	if hero_visual.baked_motion() and not stride_active:
		walk_phase = PI * 0.5
	stride_active = true
	var previous := int(walk_phase / PI)
	walk_phase += distance / (1.9 if current_speed >= 8.9 else 1.7) * PI
	if int(walk_phase / PI) != previous:
		footfalls += 1
		var world = get_parent()
		if world.effects.size() > 128:
			return
		var side := facing.cross(Vector3.UP) * (0.16 if footfalls % 2 == 0 else -0.16)
		var at := Land.on_ground(position + side,0.032)
		if Land.wet_at(at):
			var ripple := V.ring(world, at, 0.22, Color("b5d6c6"))
			ripple.quaternion = Quaternion(Vector3.UP,Land.normal_at(at))
			world.effects.append({"node":ripple,"time":0.28})
		else:
			var print_mesh := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(0.17,0.3)
			print_mesh.mesh = plane
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://game/contact.gdshader")
			mat.set_shader_parameter("tint",Color(0.09,0.10,0.06,0.48))
			print_mesh.material_override = mat
			world.add_child(print_mesh)
			print_mesh.position = at
			print_mesh.quaternion = Quaternion(Vector3.UP,Land.normal_at(at))
			print_mesh.rotate_object_local(Vector3.UP,-atan2(facing.z,facing.x))
			world.effects.append({"node":print_mesh,"time":1.4})

func hurt() -> void:
	if invulnerability > 0:
		return
	hurt_flash = 0.18
	hp -= 1
	invulnerability = 1.3
	get_parent().sound("hurt")
	if hp <= 0:
		hp = 5
		position = get_parent().exploration.respawn_point()
		velocity = Vector3.ZERO
		get_parent().notice("잠시 쉬어가기 · 발견한 능력과 열린 길은 그대로입니다")
	get_parent().save_now()
