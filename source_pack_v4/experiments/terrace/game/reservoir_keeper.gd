extends RefCounted
## Reservoir encounter: fixed ground targets, then a close shockwave. J can interrupt either.
const V = preload("res://game/visuals.gd")
const Land = preload("res://game/landscape.gd")
var enemy: CharacterBody3D
var phase := "rest"
var remaining := 1.0
var attack_index := 0
var centers: Array[Vector3] = []
var radius := 1.8
var warnings: Array[Node3D] = []
var fills: Array[Node3D] = []
var label: Label3D
var cue := ""

func _init(owner: CharacterBody3D) -> void:
	enemy = owner
	label = Label3D.new()
	var font := preload("res://assets/fonts/NanumGothic-Regular.ttf")
	label.font = font
	label.font_size = 30
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.616, -0.788) * 4.0
	label.text = "저수전 수호자"
	enemy.add_child(label)

func update(delta: float, offset: Vector3) -> void:
	var world = enemy.get_parent()
	enemy.velocity.x = 0
	enemy.velocity.z = 0
	remaining = maxf(0, remaining - delta)
	if phase == "warning":
		for fill in fills:
			draw_ring(fill, centers[0], radius * lerpf(0.18, 1.0, 1.0 - remaining / 1.15))
		if remaining <= 0:
			resolve()
	elif phase == "rest":
		if offset.length() < 9 and world.visible_target(enemy, world.player.position):
			if remaining <= 0:
				begin_attack()
			elif offset.length() > 4.8:
				enemy.velocity.x = offset.normalized().x * 1.2
				enemy.velocity.z = offset.normalized().z * 1.2
	enemy.velocity.y -= 25 * delta
	enemy.move_and_slide()

func begin_attack() -> void:
	clear_warnings()
	var world = enemy.get_parent()
	world.sound("warning")
	phase = "warning"
	remaining = 1.15
	if attack_index % 2 == 0:
		radius = 1.8
		centers.assign([Land.on_ground(world.player.position)])
		cue = "낙인 · 원 밖으로 이동"
	else:
		radius = 3.3
		centers.assign([Land.on_ground(enemy.position)])
		cue = "충격파 · 물러나거나 J로 끊기"
	attack_index += 1
	for center in centers:
		warnings.append(make_ring(center, radius, Color("ff7655")))
		var fill := make_ring(center, radius * 0.18, Color("ffd28a"))
		warnings.append(fill)
		fills.append(fill)

func make_ring(center: Vector3, size: float, color: Color) -> MeshInstance3D:
	return preload("res://game/ground_warning.gd").make(enemy.get_parent(),center,size,color)

func draw_ring(node: MeshInstance3D, center: Vector3, size: float) -> void:
	preload("res://game/ground_warning.gd").draw(node,center,size)

func resolve() -> void:
	var world = enemy.get_parent()
	world.hit_sound(true)
	for center in centers:
		var offset: Vector3 = world.player.position - center
		offset.y = 0
		if offset.length() < radius and absf(world.player.position.y - center.y) < 2 and preload("res://game/effect_surface.gd").supported(center,world.player.position-center) and world.visible_target(enemy, world.player.position):
			world.player.hurt()
		world.impact(center, true)
		var ring := make_ring(center, radius, Color("ffba76"))
		world.effects.append({"node":ring,"time":0.20})
	clear_warnings()
	phase = "rest"
	remaining = 1.8
	cue = "저수전 수호자 · 틈이 열렸다"

func interrupt() -> void:
	if phase != "warning": return
	clear_warnings()
	phase = "rest"
	remaining = 2.6
	cue = "시전 끊김 · 공격 기회"

func clear_warnings() -> void:
	for node in warnings:
		if is_instance_valid(node): node.queue_free()
	warnings.clear()
	fills.clear()
	centers.clear()

