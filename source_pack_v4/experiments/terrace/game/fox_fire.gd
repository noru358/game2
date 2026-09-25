extends "res://game/combat_effect.gd"
var target_ref: WeakRef
var arrival: Callable
var arrived := false
func advance(delta: float) -> void:
	var target = target_ref.get_ref() if target_ref else null
	if is_instance_valid(target) and not target.dead:
		destination=target.global_position+Vector3.UP*0.85-global_position
	super.advance(delta)
	if age>=duration and not arrived:
		arrived=true
		if is_instance_valid(target) and not target.dead:arrival.call(target)
static func fire(world: Node3D) -> void:
	var profile: Dictionary=world.attack_profile()
	var candidates: Array=world.enemies()
	candidates.sort_custom(func(a,b):return world.player.position.distance_squared_to(a.position)<world.player.position.distance_squared_to(b.position))
	var remaining := 2 if "split" in world.upgrades else 1
	var fired := false
	for target in candidates:
		if target.dead:continue
		if world.player.position.distance_to(target.position)>(8.0 if world.exploration.attunement=="reach" else 7.0):break
		if not world.visible_target(target,world.player.position):continue
		world.player.show_auto_cast(target.position-world.player.position)
		var shot=load("res://game/fox_fire.gd").new()
		shot.kind="fireball"
		world.add_child(shot)
		shot.global_position=world.player.auto_origin()+Vector3.UP*0.85
		shot.destination=target.global_position+Vector3.UP*0.85-shot.global_position
		shot.direction=shot.destination.normalized()
		shot.duration=clampf(shot.destination.length()/32.0,0.09,0.22)
		shot.target_ref=weakref(target)
		shot.tint=Color("a9e7ff")
		shot.tier=int(profile.tier)
		shot.arrival=func(enemy):resolve(world,enemy,int(profile.auto_damage)+world.waterworks.auto_bonus())
		shot.redraw()
		world.effects.append({"node":shot,"time":shot.duration})
		world.attack_wait=float(profile.auto_interval)
		if not fired:world.sound("fireball")
		fired=true
		remaining-=1
		if remaining<=0:break
	if not fired:world.attack_wait=0.08
static func resolve(world: Node3D, enemy: Node3D, damage: int) -> void:
	var origin: Vector3=enemy.position
	enemy.hit(damage,(origin-world.player.position).normalized()*0.5)
	world.waterworks.on_auto_hit()
	if not enemy.dead:enemy.auto_impact()
	preload("res://game/combat_effect.gd").spawn(world,"impact",origin,Vector3.ZERO,1,Color("a9e7ff"))
	world.auto_hits+=1
	if world.has_method("on_growth_auto_hit"):world.on_growth_auto_hit(origin)
	if "echo" in world.upgrades and world.auto_hits%6==0:world.burst_at(origin,2.7,4)
	if world.chain:
		for other in world.enemies():
			if other!=enemy and not other.dead and origin.distance_to(other.position)<4 and world.visible_target(other,origin):
				world.beam(origin,other.position,Color("f4d488"))
				other.hit(3);world.impact(other.position,false);break
