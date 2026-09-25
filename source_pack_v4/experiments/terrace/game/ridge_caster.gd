extends RefCounted
const Warning=preload("res://game/ground_warning.gd")
const Land=preload("res://game/landscape.gd")
const V=preload("res://game/visuals.gd")
const RADIUS:=1.4
const WINDUP:=1.3
var enemy:CharacterBody3D
var phase:="rest"
var remaining:=1.4
var center:=Vector3.ZERO
var cue:=""
var warnings:Array[MeshInstance3D]=[]
var focus:MeshInstance3D
func _init(owner:CharacterBody3D)->void:
	enemy=owner
	focus=V.sphere(enemy,Vector3(0,1.3,0),0.22,Color("d9a2ff"))
	focus.hide()
func clear_warnings()->void:
	for node in warnings:
		if is_instance_valid(node):node.queue_free()
	warnings.clear()
	if is_instance_valid(focus):focus.hide()
func interrupt()->void:
	clear_warnings()
	phase="rest"
	remaining=2.8
	cue="시전 끊김 · 제방의 적에게 접근할 기회"
func update(delta:float,offset:Vector3)->void:
	var world=enemy.get_parent()
	enemy.velocity.x=0
	enemy.velocity.z=0
	remaining=maxf(0,remaining-delta)
	if phase=="warning":
		Warning.draw(warnings[1],center,RADIUS*lerpf(0.15,1,1-remaining/WINDUP))
		focus.scale=Vector3.ONE*(1+0.25*sin(remaining*18))
		if remaining<=0:
			var distance:=Vector2(world.player.position.x-center.x,world.player.position.z-center.z).length()
			if distance<RADIUS and absf(world.player.position.y-center.y)<2 and preload("res://game/effect_surface.gd").supported(center,world.player.position-center) and world.visible_target(enemy,world.player.position):world.player.hurt()
			world.impact(center,false)
			clear_warnings()
			phase="rest"
			remaining=2.5
			cue=""
	elif remaining<=0 and offset.length()<11 and world.visible_target(enemy,world.player.position):
		var busy:bool=world.enemies().any(func(other):return other!=enemy and other.caster!=null and other.caster.phase=="warning")
		if not busy:
			center=Land.on_ground(world.player.position)
			phase="warning"
			remaining=WINDUP
			cue="제방의 포자술 · 표식 밖으로 이동하거나 J로 끊기"
			warnings.append(Warning.make(world,center,RADIUS,Color("e09bff")))
			warnings.append(Warning.make(world,center,RADIUS*0.15,Color("ffe0b5")))
			focus.show()
			world.sound("warning")
	enemy.velocity.y-=25*delta
	enemy.move_and_slide()
