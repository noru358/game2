extends RefCounted

const TAP_BUFFER_SECONDS := 0.18
const RECOVERY_QUEUE_GRACE := 0.12

var world: Node3D
var combo_step := 0
var recovery := 0.0
var chain_window := 0.0
var buffered := 0.0
var swings := 0
var last_direction := Vector3.RIGHT
var windup_remaining := 0.0
var pending_step := 0
var pending_direction := Vector3.RIGHT
var pending_profile: Dictionary={}

func _init(owner_world: Node3D) -> void:
	world = owner_world

func update(delta: float) -> void:
	if world.player.dash_left > 0:
		buffered = 0
		cancel_preparation()
		return
	if Input.is_action_just_pressed("pulse"):
		# Keep one deliberate tap through the remaining recovery. Repeated taps do
		# not stack actions; dodge still clears the single queued strike.
		buffered = maxf(buffered, maxf(TAP_BUFFER_SECONDS, recovery + windup_remaining + RECOVERY_QUEUE_GRACE))
	if world.hitstop > 0:
		return
	if pending_step>0:
		windup_remaining=maxf(0,windup_remaining-delta)
		if windup_remaining==0:
			var step := pending_step
			pending_step=0
			world.player.attack_windup=false
			commit_strike(pending_profile,pending_direction,step)
		return
	buffered = maxf(0, buffered - delta)
	recovery = maxf(0, recovery - delta)
	chain_window = maxf(0, chain_window - delta)
	if chain_window <= 0 and recovery <= 0:
		combo_step = 0
	# Holding J is allowed for low-effort chaining; tapping permits deliberate timing.
	if recovery <= 0 and (buffered > 0 or Input.is_action_pressed("pulse")):
		strike()

func strike() -> void:
	if recovery > 0 or pending_step>0:
		return
	buffered = 0
	var profile: Dictionary=world.attack_profile() if world.has_method("attack_profile") else {}
	var step := combo_step % int(profile.get("combo_count",3)) + 1
	var direction: Vector3 = world.player.facing
	var nearby: Array = world.enemies()
	nearby.sort_custom(func(a, b): return world.player.position.distance_squared_to(a.position) < world.player.position.distance_squared_to(b.position))
	for target in nearby:
		var offset: Vector3 = target.position - world.player.position
		offset.y = 0
		if offset.length() < 3.5 and offset.length() > 0.01 and direction.dot(offset.normalized()) > 0.65 and world.visible_target(target, world.player.position):
			direction = direction.lerp(offset.normalized(), 0.3).normalized()
			break
	var times: Array=profile.get("windup_seconds",[0.0,0.0,0.0])
	var windup := float(times[step-1])/maxf(0.1,float(profile.get("manual_speed",1.0)))
	if windup>0:
		pending_step=step;pending_direction=direction;pending_profile=profile.duplicate(true)
		windup_remaining=windup
		world.player.attack_windup=true
		world.player.swing_step=step
		world.player.casting_direction=direction
		world.player.swing_duration=windup+0.1
		world.player.swing_left=world.player.swing_duration
		world.player.velocity.x=0;world.player.velocity.z=0
		world.player.update_visual(0)
		return
	commit_strike(profile,direction,step)

func commit_strike(profile: Dictionary, direction: Vector3, step: int) -> void:
	combo_step=step
	swings+=1
	var speed := maxf(0.1,float(profile.get("manual_speed",1.0)))
	recovery=(0.52 if combo_step==3 else 0.36)/speed
	chain_window=recovery+0.45
	var nearby: Array=world.enemies()
	last_direction = direction
	world.player.swing_duration = (0.40 if combo_step == 3 else 0.28)/speed
	world.player.swing_left = world.player.swing_duration
	world.player.swing_step = combo_step
	world.player.casting_direction = direction
	# Commit the planted pose in the hit frame, before hitstop can freeze it.
	# Waiting for player physics left a running pose frozen over the impact.
	world.player.velocity.x = 0
	world.player.velocity.z = 0
	world.player.body.rotation.z = 0
	world.player.update_visual(0)
	world.spell_strike(world.player.position, direction, combo_step)
	world.sound("cast")
	var stored_power: int = world.waterworks.manual_bonus()
	var damage: int = profile.get("damage",[6,7,12])[combo_step - 1]+stored_power
	var reach: float = float(profile.get("reach",3.1 if combo_step==3 else 2.7))
	var did_hit := false
	for target in nearby:
		if target.dead:
			continue
		var offset: Vector3 = target.position - world.player.position
		offset.y = 0
		if offset.length() > reach or (offset.length() > 0.01 and direction.dot(offset.normalized()) < float(profile.get("cone_dot",0.25))):
			continue
		if not world.visible_target(target, world.player.position):
			continue
		did_hit = true
		world.impact(target.position, combo_step == 3)
		var push_scale := 1.25 if world.exploration.attunement == "force" else 1.0
		target.hit(damage, direction * (1.5 if combo_step == 3 else 0.65) * push_scale)
		if not target.dead:
			target.stagger(0.25 if combo_step == 3 else 0.10)
	if did_hit:
		world.waterworks.on_manual_hit()
		if stored_power>0:
			world.spell_strike(world.player.position,direction,3)
		world.hitstop = float(profile.get("hitstop",0.025))+(0.012 if combo_step==3 else 0.0)
		world.shake = 0.15 if combo_step == 3 else 0.075
		world.hit_sound(combo_step == 3)
		if combo_step == 3 and "echo" in world.upgrades:
			var center: Vector3 = world.player.position + direction * 1.7
			world.burst_at(center, 3.6, 6)

func reset_transient() -> void:
	cancel_preparation()
	buffered = 0
	recovery = 0
	chain_window = 0
	combo_step = 0

func cancel_preparation() -> void:
	if pending_step>0 and is_instance_valid(world.player):
		world.player.attack_windup=false
		world.player.swing_left=0
	pending_step=0
	windup_remaining=0
	pending_profile={}
