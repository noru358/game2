extends CharacterBody3D

const Warning=preload("res://game/ground_warning.gd")
const V = preload("res://game/visuals.gd")
var keeper: RefCounted
var caster: RefCounted
var stable_id := ""
var elite := false
var hp := 12
var home := Vector3.ZERO
var attack_wait := 0.0
var windup := 0.0
var flash := 0.0
var impact_hold := 0.0
var body: MeshInstance3D
var telegraph: MeshInstance3D
var dead := false
var max_hp := 12
var health_bar: Node3D
var stun := 0.0
var base_color: Color
var knockback := Vector3.ZERO
var role := "wanderer"
var charge_left := 0.0
var charge_direction := Vector3.ZERO
var charge_hit := false
var charge_lane: Node3D
var portrait: Sprite3D
var visual: RefCounted
var facing := Vector3(0, 0, 1)
var gait := 0.0
var attack_recoil := 0.0
var prepared := false

func _ready() -> void:
	max_hp = maximum_health(stable_id, elite)
	if role=="caster":
		caster=preload("res://game/ridge_caster.gd").new(self)
		tree_exiting.connect(caster.clear_warnings)
	if stable_id == "facility_keeper":
		keeper = preload("res://game/reservoir_keeper.gd").new(self)
		tree_exiting.connect(keeper.clear_warnings)
	collision_layer = 4
	collision_mask = 1
	home = position
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.6 if elite else 0.34
	collision.shape = shape
	collision.position.y = shape.radius
	add_child(collision)
	body = V.sphere(self, Vector3(0, 0.75 if elite else 0.45, 0), 0.8 if elite else 0.43, Color("d88a64") if elite else Color("ab7187"))
	body.visible = false
	visual = preload("res://game/enemy_visual.gd").new(elite, role == "charger")
	portrait = Sprite3D.new()
	portrait.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	portrait.shaded = false
	portrait.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(portrait)
	visual.apply(portrait, facing, false)
	base_color = Color("d88a64") if elite else Color("ab7187")
	if role == "charger" and not elite:
		base_color = Color("bc6943")
		body.material_override.albedo_color = base_color
		charge_lane = Warning.make(self,global_position,0.1,Color("e5aa68"))
		charge_lane.visible = false
		attack_wait = 2.0
	telegraph = Warning.make(self,global_position,2.5 if elite else 1.1,Color("ff8768"))
	telegraph.visible = false
	var bar_at := Vector3(0, cos(deg_to_rad(52)), -sin(deg_to_rad(52))) * (2.95 if elite else (1.4 if role == "charger" else 1.15))
	V.box(self, bar_at, Vector3(1.55 if elite else 0.65, 0.08, 0.08), Color("253f39"))
	health_bar = V.box(self, bar_at + Vector3.UP * 0.01, Vector3(1.5 if elite else 0.6, 0.09, 0.09), Color("ffd29b"))
	health_bar.scale.x = clampf(float(hp) / max_hp, 0.01, 1.0)

func _physics_process(delta: float) -> void:
	if dead or get_parent().hitstop>0 or impact_hold>0:
		simulate(delta)
		return
	var before:=position
	simulate(delta)
	if dead:return
	var distance:=Vector2(position.x-before.x,position.z-before.z).length()
	var preparing:bool=windup>0 or (caster!=null and caster.phase=="warning") or (keeper!=null and keeper.phase=="warning")
	if prepared and not preparing and stun<=0:attack_recoil=0.22
	prepared=preparing
	attack_recoil=maxf(0,attack_recoil-delta)
	gait+=distance*8.0
	visual.animate(portrait,facing,gait,distance>0.002,preparing,attack_recoil,flash>0)

func simulate(delta: float) -> void:
	if dead:
		return
	var world = get_parent()
	if world.hitstop > 0:
		return
	if impact_hold > 0:
		impact_hold = maxf(0,impact_hold-delta)
		return
	var offset: Vector3 = world.player.position - position
	offset.y = 0
	if charge_left > 0 or (role == "charger" and windup > 0):
		facing = charge_direction
	elif offset.length_squared() > 0.01 and offset.length() < 10:
		facing = offset.normalized()
	attack_wait = maxf(0, attack_wait - delta)
	flash = maxf(0, flash - delta)
	body.scale = Vector3(1.25, 0.8, 1.25) if flash > 0 else body.scale.lerp(Vector3.ONE, minf(1, delta * 22))
	body.material_override.albedo_color = Color("fff5d5") if flash > 0 else base_color
	visual.apply(portrait, facing, flash > 0)
	if role=="caster" and flash<=0:portrait.modulate=Color("ddb1f1")
	portrait.scale = Vector3(1.18, 0.86, 1) if flash > 0 else portrait.scale.lerp(Vector3.ONE, minf(1, delta * 22))
	stun = maxf(0, stun - delta)
	if stun > 0 or knockback.length() > 0.5:
		velocity.x = knockback.x
		velocity.z = knockback.z
		velocity.y -= 25 * delta
		move_and_slide()
		knockback = knockback.move_toward(Vector3.ZERO, delta * 35)
		return
	if keeper != null:
		keeper.update(delta, offset)
		return
	if caster != null:
		caster.update(delta,offset)
		return
	var reach := 2.5 if elite else 1.1
	if telegraph.visible:Warning.draw(telegraph,global_position,reach)
	if role == "charger" and not elite:
		update_charge(delta, offset)
		return
	if windup > 0:
		windup -= delta
		velocity.x = 0
		velocity.z = 0
		if windup <= 0:
			telegraph.visible = false
			if offset.length() < reach and melee_accessible():
				world.player.hurt()
			attack_wait = 1.6 if elite else 1.1
	elif offset.length() < reach and attack_wait <= 0 and melee_accessible():
		windup = 0.85 if elite else 0.55
		telegraph.visible = true
		Warning.draw(telegraph,global_position,reach)
	elif offset.length() < (10.0 if elite else 8.5):
		var target := offset.normalized() * (1.65 if elite else 2.0)
		velocity.x = target.x
		velocity.z = target.z
	else:
		velocity.x = 0
		velocity.z = 0
	velocity.y -= 25 * delta
	move_and_slide()

func melee_accessible() -> bool:
	var world = get_parent()
	return absf(position.y - world.player.position.y) < 1.5 and preload("res://game/effect_surface.gd").supported(position,world.player.position-position) and world.visible_target(self, world.player.position)

func update_charge(delta: float, offset: Vector3) -> void:
	if windup>0:Warning.draw_lane(charge_lane,global_position,charge_direction)
	var world = get_parent()
	velocity.x = 0
	velocity.z = 0
	if charge_left > 0:
		charge_left = maxf(0, charge_left - delta)
		velocity.x = charge_direction.x * 9.0
		velocity.z = charge_direction.z * 9.0
	elif windup > 0:
		windup = maxf(0, windup - delta)
		if windup <= 0:
			charge_lane.visible = false
			charge_left = 0.55
			charge_hit = false
			attack_wait = 5.0
	elif attack_wait <= 0 and offset.length() < 6.0 and world.visible_target(self, world.player.position):
		# Only one telegraphed charge at a time; lock aim so walking aside works.
		var busy := false
		for other in world.enemies():
			if other != self and other.role == "charger" and (other.windup > 0 or other.charge_left > 0):
				busy = true
		if not busy:
			charge_direction = offset.normalized() if offset.length() > 0.01 else Vector3.RIGHT
			facing = charge_direction
			visual.apply(portrait, facing, flash > 0)
			windup = 0.95
			Warning.draw_lane(charge_lane,global_position,charge_direction)
			charge_lane.visible = true
	elif attack_wait <= 0 and offset.length() < 9.0:
		velocity.x = offset.normalized().x * 1.5
		velocity.z = offset.normalized().z * 1.5
	velocity.y -= 25 * delta
	move_and_slide()
	if charge_left > 0:
		if is_on_wall():
			charge_left = 0
		elif not charge_hit and position.distance_to(world.player.position) < 0.9 and world.visible_target(self, world.player.position):
			world.player.hurt()
			charge_hit = true
			charge_left = 0

func hit(damage: int, push: Vector3 = Vector3.ZERO) -> void:
	if dead:
		return
	hp -= damage
	health_bar.scale.x = clampf(float(hp) / max_hp, 0.01, 1.0)
	flash = 0.12
	# Impulse resolves over time with physics collision, instead of a one-frame teleport.
	if push.length_squared() > 0.01:
		knockback += push * (3.0 if elite else 9.0)
		knockback = knockback.limit_length(16.0)
	if hp <= 0:
		dead = true
		get_parent().enemy_defeated(self)
		queue_free()

func stagger(seconds: float) -> void:
	if caster!=null:caster.interrupt()
	if keeper != null:
		keeper.interrupt()
	stun = seconds * (0.4 if elite else 1.0)
	windup = 0
	telegraph.visible = false
	attack_wait = maxf(attack_wait, stun + 0.2)
	if role == "charger":
		charge_left = 0
		charge_lane.visible = false
		attack_wait = maxf(attack_wait, 3.0)

static func maximum_health(id: String, is_elite: bool) -> int:
	if id == "facility_keeper":
		return 150
	if id == "waterworks_keeper":
		return 60
	return 120 if is_elite else 12

func auto_impact() -> void:
	# Local contact hold only: does not pause the player or cancel a boss/caster telegraph.
	impact_hold=0.035
	visual.apply(portrait,facing,true)
	portrait.scale=Vector3(1.28,0.80,1)
