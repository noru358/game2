extends Node3D
## Condensed spell strikes and woven companion energy. World owns clock, so pause and hitstop freeze all layers.
var age := 0.0
var duration := 0.3
var kind := "bolt"
var direction := Vector3.RIGHT
var destination := Vector3.ZERO
var strength := 1
var tier := 1
var size_factor := 1.0
var strike_reach := 2.7
var cone_dot := 0.25
var gesture_sweeps := false
var emission_offsets:Array[Vector3]=[]
var tint := Color("91f8da")
var surface := ImmediateMesh.new()
var ink := ShaderMaterial.new()
const SCREEN_UP := Vector3(0, 0.616, -0.788)
const VIEW := Vector3(0, 0.788, 0.616)
static func swing_axis(toward: Vector3, step: int) -> Vector3:
	# Reversing BOTH terms draws the same line. Keep lateral basis stable,
	# change its slope, then animate the return stroke in the opposite direction.
	var forward_screen: Vector3=(Vector3.RIGHT*toward.x+SCREEN_UP*toward.dot(SCREEN_UP)).normalized()
	var across: Vector3=VIEW.cross(forward_screen).normalized()
	return SCREEN_UP if step==3 else (across+forward_screen*(0.55 if step==1 else -0.55)).normalized()
static var familiar_shader: Shader

func _init() -> void:
	ink.shader = preload("res://game/astral_energy.gdshader")
	if familiar_shader == null:
		# Companions double as player-location cues behind tall scenery.
		# Keep depth testing for all attack effects sharing the base shader.
		familiar_shader = Shader.new()
		familiar_shader.code = ink.shader.code.replace("depth_draw_never,", "depth_draw_never, depth_test_disabled,")
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface
	mesh.material_override = ink
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

func advance(delta: float) -> void:
	age = minf(duration, age + delta)
	redraw()

func vertex(at: Vector3, color: Color, uv: Vector2, lens: bool = false) -> void:
	surface.surface_set_color(color)
	surface.surface_set_uv(uv)
	surface.surface_set_uv2(Vector2(1 if lens else 0, 0))
	surface.surface_add_vertex(at)

func ribbon(points: Array[Vector3], width: float, color: Color) -> void:
	for i in range(points.size() - 1):
		var a := float(i) / (points.size() - 1)
		var b := float(i + 1) / (points.size() - 1)
		var p := points[i]
		var q := points[i + 1]
		var tangent := (q - p).normalized()
		var side := VIEW.cross(tangent).normalized()
		if side.length_squared() < 0.01: side = Vector3.RIGHT
		var wa := width * (0.08 + sin(a * PI) * 0.92)
		var wb := width * (0.08 + sin(b * PI) * 0.92)
		vertex(p - side * wa, color, Vector2(a, 0))
		vertex(p + side * wa, color, Vector2(a, 1))
		vertex(q + side * wb, color, Vector2(b, 1))
		vertex(p - side * wa, color, Vector2(a, 0))
		vertex(q + side * wb, color, Vector2(b, 1))
		vertex(q - side * wb, color, Vector2(b, 0))

func glow(at: Vector3, radius: float, color: Color) -> void:
	var x := Vector3.RIGHT * radius
	var y := SCREEN_UP * radius
	vertex(at - x - y, color, Vector2(0, 0), true)
	vertex(at + x - y, color, Vector2(1, 0), true)
	vertex(at + x + y, color, Vector2(1, 1), true)
	vertex(at - x - y, color, Vector2(0, 0), true)
	vertex(at + x + y, color, Vector2(1, 1), true)
	vertex(at - x + y, color, Vector2(0, 1), true)

func shade(alpha: float, pale: float = 0.0) -> Color:
	var c := tint.lerp(Color("efffff"), pale)
	c.a = alpha
	return c

func redraw() -> void:
	surface.clear_surfaces()
	ink.set_shader_parameter("phase", age / duration)
	ink.shader = familiar_shader if kind == "familiar" else preload("res://game/astral_energy.gdshader")
	ink.set_shader_parameter("solid_lens",kind in ["familiar","fireball"])
	ink.set_shader_parameter("dense_strike",kind in ["sweep","impact","auto_impact"])
	ink.set_shader_parameter("depth_lift",1.2 if kind in ["sweep","focus"] else 0.0)
	if age >= duration and kind != "familiar": return
	var t := fposmod(age / duration,1.0) if kind == "familiar" else age / duration
	var fade := pow(1.0 - t, 1.35)
	surface.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	if kind == "familiar":
		var pulse := 0.5 + 0.5 * sin(age * 3)
		# Dark silhouette under a substantial colored core stays legible on wet stone and foliage.
		glow(-VIEW*0.012,0.70,Color(0.025,0.06,0.12,0.96))
		glow(Vector3.ZERO,0.56 if strength == 1 else 0.68,shade(1.0,0.10))
		glow(VIEW*0.01+SCREEN_UP*0.08,0.27 if strength == 1 else 0.42,shade(1.0,0.85))
		for wing in [-1,1]:
			var points: Array[Vector3] = []
			for i in range(21):
				var u := float(i)/20
				points.append(Vector3.RIGHT * wing * sin(u*PI) * (0.42+pulse*0.06) + SCREEN_UP * (u-0.4)*1.1)
			ribbon(points,0.18,shade(0.95,0.3))
		var tail: Array[Vector3] = []
		for i in range(17):
			var u := float(i)/16
			tail.append(-SCREEN_UP*u*0.9+Vector3.RIGHT*sin(u*5-age*3)*u*0.20)
		ribbon(tail,0.14,shade(0.85))
	elif kind == "focus":
		glow(Vector3.ZERO, 0.75, shade(pow(1.0-t,0.65), 0.65))
		glow(VIEW*0.02,0.30,shade(fade,1.0))
		for strand in range(3):
			var points: Array[Vector3] = []
			for i in range(25):
				var u := float(i) / 24
				var angle := u * TAU * 0.85 + strand * 2.1 - t * 4
				var r := (0.12 + u * 0.34) * (1.0 - t * 0.6)
				points.append((Vector3.RIGHT * cos(angle) + SCREEN_UP * sin(angle)) * r)
			ribbon(points, 0.16, shade(fade * 0.95, 0.5))
	elif kind == "fireball":
		var head := destination*t
		var forward := destination.normalized()
		var side := VIEW.cross(forward).normalized()
		var tail_length := minf(destination.length()*t,1.25)
		for ember in range(8,0,-1):
			var u := float(ember)/8.0
			var curl := side*sin(u*5.0-age*24.0)*u*0.10
			glow(head-forward*u*tail_length+curl,0.29*(1.0-u*0.82),shade(0.85*(1.0-u*0.5),0.1))
		for strand in range(3):
			var trail: Array[Vector3]=[]
			for i in range(13):
				var u := float(i)/12.0
				trail.append(head-forward*u*tail_length+side*sin(u*8.0-age*35.0+strand*2.1)*u*0.16)
			ribbon(trail,0.12 if strand==0 else 0.06,shade(0.55,0.15))
		glow(head-VIEW*0.012,0.38,Color(0.025,0.10,0.18,0.95))
		glow(head-forward*0.15,0.30,shade(1.0,0.15))
		glow(head,0.25,shade(1.0,0.3))
		glow(head+forward*0.13,0.13,shade(1.0,0.65))
		glow(head+VIEW*0.012,0.16,shade(1.0,0.95))
		glow(Vector3.ZERO,0.55,shade(pow(1.0-t,4),0.8))
	elif kind == "bolt":
		var side := VIEW.cross(destination.normalized()).normalized()
		if side.length_squared() < 0.01: side = Vector3.RIGHT
		# Instant-hit conduit with an after-current moving along it; no misleading delayed projectile.
		for strand in range(1 if tier==0 else (2 if tier==1 else 3)):
			var points: Array[Vector3] = []
			for i in range(33):
				var u := float(i) / 32
				var curl := sin(u * TAU * 1.4 + strand * 1.7 - t * 5.0)
				var spread := sin(u * PI) * (0.025 if tier==0 else (0.10 + strand * 0.045))
				points.append(destination * u + side * curl * spread + SCREEN_UP * sin(u * TAU + strand) * spread * 0.5)
			ribbon(points, (0.16 if tier==0 else (0.30 if tier==1 else 0.43)) if strand==0 else 0.18, shade(fade * (0.95 if strand == 0 else 0.55), 0.5 if strand == 0 else 0.0))
		glow(Vector3.ZERO, 0.72 * (1.0 - t * 0.5), shade(fade * 0.8))
		glow(destination, 0.65, shade(fade, 0.7))
		for i in range(7):
			var u := fposmod(i * 0.137 + t * 0.65, 1.0)
			glow(destination * u + side * sin(i * 2.4 + t * 6) * 0.16, 0.065, shade(fade * 0.7, 0.6))
	elif kind == "auto_impact":
		# Short bright contact followed by directional splinters; damage remains instant.
		var flash := pow(1.0-t,3)
		glow(Vector3.ZERO,0.95*(1.0-t*0.5),shade(flash,0.9))
		for i in range(5):
			var angle := i*2.399+0.35
			var ray := Vector3.RIGHT*cos(angle)+SCREEN_UP*sin(angle)
			var points: Array[Vector3] = []
			for j in range(9):
				var u := float(j)/8
				points.append(ray*(0.15+u*(0.6+t*0.6))+SCREEN_UP*sin(u*PI)*0.13)
			ribbon(points,0.18*(1.0-t),shade(fade,0.55))
	elif kind == "sweep":
		# Torn spell rim shares the exact radial/cone boundary used by Combat.
		# It is visible immediately at contact, then fades; never a delayed hit cue.
		var half_angle:=acos(cone_dot)
		var side := direction.cross(Vector3.UP)
		for strand in range(3):
			var rim:Array[Vector3]=[]
			for i in range(41):
				var u:=float(i)/40.0
				var angle:=lerpf(-half_angle,half_angle,u)
				var radial:=(direction*cos(angle)+side*sin(angle))*(strike_reach-strand*0.17-absf(sin(u*17.0+strand))*strand*0.035)
				# A spell is a coherent airborne stroke, not a cloth draped over the floor.
				radial.y=sin(u*PI)*0.10
				rim.append(radial)
			ribbon(rim,0.12 if strand==0 else 0.18,shade(fade*(0.75 if strand==0 else 0.25),0.45))
		var reverse := -1.0 if strength == 2 else 1.0
		# A compact, solid spell edge snaps through the sector, then breaks apart.
		# Contact is immediate; subsequent travel is follow-through, not a projectile.
		var center := direction * (1.9 if strength == 3 else 1.55)*size_factor
		# Connect the casting palm(s) to the stroke, without moving its hit boundary.
		for origin in emission_offsets:
			var flow:Array[Vector3]=[]
			for i in range(13):
				var u:=float(i)/12
				flow.append(origin.lerp(center,u)+SCREEN_UP*sin(u*PI)*0.16)
			ribbon(flow,0.12,shade(pow(1-t,2)*0.8,0.6))
		var axis := swing_axis(direction,strength)
		if gesture_sweeps:
			var across := direction.cross(Vector3.UP).normalized()
			axis=across if strength<3 else (across*0.6-Vector3.UP*0.8).normalized()
		var extent := (1.05 if strength == 3 else 1.4)*size_factor
		for layer in range(2):
			var points: Array[Vector3] = []
			for i in range(17):
				var u := float(i)/16
				points.append(center + axis*(u-0.5)*extent*2 + direction*sin(u*PI)*0.35 + axis*t*0.3*reverse)
			ribbon(points,(0.32 if layer == 0 else 0.085)*(1-t)*size_factor,Color(0.08,0.34,0.37,fade) if layer == 0 else shade(fade,0.85))
		var head:=center+axis*lerpf(-extent,extent,clampf(t*3,0,1))*reverse
		glow(head,0.30*size_factor,shade(pow(1-t,2),0.95))
		glow(center,0.6*(1-t),shade(pow(1-t,4),0.8))
		for i in range(5 if strength == 3 else 3):
			var ray := (axis * sin(i*2.399) + direction * cos(i*2.399)).normalized()
			var start := center + ray*(0.25+t*1.5)
			var shard: Array[Vector3] = [start,start+ray*0.16,start+ray*(0.42-t*0.2)]
			ribbon(shard,0.13*(1-t),shade(fade,0.4))
	elif kind == "impact":
		var heavy := strength == 3
		var reach := (1.3 if heavy else 0.85)*size_factor
		glow(Vector3.ZERO,(0.85 if heavy else 0.6)*(1-t),shade(pow(1-t,5),0.95))
		# Broken condensed-magic splinters kick out fast, decelerate and drop.
		for i in range(8 if heavy else 5):
			var angle := i*2.399+0.4
			var ray := Vector3.RIGHT*cos(angle)+SCREEN_UP*sin(angle)
			var start := ray*(0.12+reach*(1-pow(1-t,2)))-SCREEN_UP*t*t*0.65
			var shard: Array[Vector3] = [start,start+ray*0.12,start+ray*(0.4 if heavy else 0.27)]
			ribbon(shard,(0.16 if heavy else 0.12)*(1-t),shade(fade,0.3))
	elif kind == "burst":
		var heavy := strength == 3
		var maximum := destination.length() if kind == "burst" else (3.1 if heavy else 2.7)
		var radius := lerpf(0.5, maximum, 1.0 - pow(1.0 - t, 3))
		for layer in range(7 if heavy else 5):
			var points: Array[Vector3] = []
			for i in range(41):
				var u := float(i) / 40
				var angle := u * TAU + layer * 0.61 if kind == "burst" else lerpf(-1.22, 1.22, u) + sin(t * 3 + layer) * 0.08
				var r := radius * (1.0 - layer * 0.055) + sin(u * 13 + layer * 2 - t * 7) * 0.06
				points.append(direction.rotated(Vector3.UP, angle) * r + Vector3.UP * (sin(u * TAU * 1.3 + layer * 1.8 - t * 8) * 0.16))
			ribbon(points, (0.34 if layer == 0 else 0.16) * (1.0 - t * 0.45), shade(fade * (0.9 if layer == 0 else 0.55), 0.35 if layer == 0 else 0.0))
		for i in range(13 if heavy else 8):
			var angle := i * 2.399 if kind == "burst" else lerpf(-1.15, 1.15, float(i) / (12 if heavy else 7))
			var ray := direction.rotated(Vector3.UP, angle)
			var p := ray * radius * (0.75 + sin(i * 3.7) * 0.19) + Vector3.UP * (sin(i * 4.1) * 0.28 + t * 0.45)
			glow(p, 0.08 + fposmod(i * 0.037, 0.06), shade(fade * 0.85, 0.5))
		glow(direction * 0.55, 0.48 * (1.0 - t), shade(fade * 0.6, 0.5))
	else:
		var heavy := strength == 3
		var radius := (1.15 if heavy else 0.68) * (0.3 + t)
		glow(Vector3.ZERO, (0.7 if heavy else 0.42) * (1.0 - t * 0.8), shade(pow(1.0 - t, 3), 0.85))
		# Uneven curling fragments peel away; no radial star or uniform expanding ring.
		for i in range(9 if heavy else 6):
			var points: Array[Vector3] = []
			var angle := i * 2.399 + 0.3
			for j in range(13):
				var u := float(j) / 12
				var a := angle + u * (0.65 + t * 0.9)
				var r := radius * (0.2 + u * (0.7 + sin(i * 4.7) * 0.2))
				points.append((Vector3.RIGHT * cos(a) + SCREEN_UP * sin(a)) * r + SCREEN_UP * t * t * (0.8 if kind == "defeat" else 0.2))
			ribbon(points, 0.10 if heavy else 0.075, shade(fade * 0.8, 0.3))
			glow(points[-1], 0.075, shade(fade, 0.6))
	surface.surface_end()

static func spawn(world: Node3D, type: String, at: Vector3, vector: Vector3, power: int, color: Color) -> Node3D:
	var effect = load("res://game/combat_effect.gd").new()
	effect.kind = type
	effect.direction = vector.normalized() if vector.length_squared() > 0.001 else Vector3.RIGHT
	effect.destination = vector
	effect.strength = power
	if world.has_method("attack_profile"):
		var profile: Dictionary=world.attack_profile()
		effect.tier=profile.tier
		effect.size_factor=profile.effect_scale
		effect.strike_reach=profile.reach
		effect.cone_dot=float(profile.get("cone_dot",0.25))
		effect.gesture_sweeps=bool(profile.get("gesture_sweeps",false))
	effect.tint = color
	effect.duration = 0.22 if type in ["bolt","auto_impact"] else (0.42 if type == "defeat" or type == "burst" else 0.28)
	world.add_child(effect)
	effect.position = at + Vector3.UP * 0.85
	if type=="sweep":
		for point in world.player.hero_visual.focus_points(world.player.portrait,world.player.casting_direction,world.player.swing_step):
			effect.emission_offsets.append(world.player.body.to_global(point)-effect.position)
	effect.redraw()
	world.effects.append({"node": effect, "time": effect.duration})
	return effect
