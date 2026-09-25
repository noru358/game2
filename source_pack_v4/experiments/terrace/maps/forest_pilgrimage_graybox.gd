extends "res://lab/world.gd"
## Playable three-act graybox. No generated environment art is used.
const GrayboxPlayer=preload("res://maps/forest_pilgrimage_player.gd")
const CompareEnemy=preload("res://maps/view_compare_enemy.gd")
const EffectSurface=preload("res://game/effect_surface.gd")
var surface=preload("res://maps/forest_pilgrimage_graybox_surface.gd").new()
var camera_pitch:=60.0
var view_yaw:=deg_to_rad(20.0)
var overview:=false
var frozen:=false
var encounter_on:=true
var auto_enabled:=true
var ui: Label
var props: Node3D
var visited: Array[bool]=[true,false,false]

func _ready() -> void:
	if not "--test" in OS.get_cmdline_user_args():get_tree().quit(2);return
	EffectSurface.set_override(surface)
	super._ready()
	remove_child(player)
	player.free()
	player=GrayboxPlayer.new()
	add_child(player)
	player.position=checkpoint()
	DisplayServer.window_set_title("첫 숲 수로 · 세 막 그레이박스")
	reset_encounter(true)
	update_camera(1)
	update_hud()

func checkpoint() -> Vector3:return surface.ground(Vector3(-12,0,36),0.1)
func near_threshold() -> bool:return false
func populate_field() -> void:pass
func storage_key(_field: String) -> String:return "user://unused_forest_pilgrimage_graybox.json"
func save_now() -> void:pass
func flush_save() -> void:pass
func pending_choices() -> int:return 0
func attack_profile() -> Dictionary:
	var profile:=Growth.profile(4)
	profile.combo_count=3
	profile.windup_seconds=[0.05,0.05,0.08]
	profile.gesture_sweeps=true
	profile.manual_speed=1.2
	profile.hitstop=float(profile.get("hitstop",0.025))+0.012
	return profile
func on_growth_auto_hit(_at: Vector3) -> void:pass
func auto_attack() -> void:preload("res://game/fox_fire.gd").fire(self)

func build_world() -> void:
	var environment:=WorldEnvironment.new()
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("1b3534")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("c7d5bc")
	env.ambient_light_energy=0.72
	environment.environment=env
	add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-58,-38,0)
	light.light_color=Color("fff0c8")
	light.light_energy=0.9
	light.shadow_enabled=true
	add_child(light)
	surface.build(self)
	props=Node3D.new()
	props.name="ThreeActGrayboxMasses"
	add_child(props)
	build_entry_threshold()
	build_river_ascent()
	build_root_sanctuary()
	build_forest_masses()

func block(at: Vector3,size: Vector3,color: Color,solid: bool=true) -> Node3D:
	return V.box(props,at,size,color,solid)

func cylinder_between(a: Vector3,b: Vector3,radius: float,color: Color) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.height=a.distance_to(b)
	mesh.top_radius=radius*0.72
	mesh.bottom_radius=radius
	node.mesh=mesh
	node.material_override=V.material(color)
	node.position=(a+b)*0.5
	node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	props.add_child(node)
	return node

func build_entry_threshold() -> void:
	var gate_center:=surface.ground(Vector3(-6,0,29))
	for x in [-9.2,-2.8]:
		block(surface.ground(Vector3(x,0,29))+Vector3.UP*2.6,Vector3(1.65,5.2,1.65),Color("8c9078"),true)
		block(surface.ground(Vector3(x,0,29))+Vector3.UP*5.45,Vector3(2.2,0.5,2.0),Color("aaa184"),true)
	block(gate_center+Vector3.UP*5.35,Vector3(8.5,1.0,1.45),Color("9f977b"),true)
	# Broken outer stones make the threshold older than a clean architectural gate.
	block(surface.ground(Vector3(-16,0,33))+Vector3.UP*0.65,Vector3(3.8,1.3,2.4),Color("6f806c"),true).rotation.y=0.22
	block(surface.ground(Vector3(0,0,34))+Vector3.UP*0.55,Vector3(2.7,1.1,2.1),Color("6f806c"),true).rotation.y=-0.3

func build_river_ascent() -> void:
	# Sparse retaining fragments mark progress without enclosing rectangular rooms.
	for data in [[Vector3(-11,0,14),Vector3(4.5,1.2,1.1),0.22],[Vector3(5,0,2),Vector3(5.2,1.4,1.0),-0.28],[Vector3(-5,0,-10),Vector3(4.0,1.5,1.2),0.35],[Vector3(2,0,-20),Vector3(3.5,1.6,1.1),-0.18]]:
		var at: Vector3=surface.ground(data[0])+Vector3.UP*float(data[1].y)*0.5
		var piece:=block(at,data[1],Color("7d876f"),true)
		piece.rotation.y=data[2]
	for at in [Vector3(6,0,18),Vector3(9,0,7),Vector3(5,0,-6),Vector3(2,0,-17)]:
		var base:=surface.ground(at)
		block(base+Vector3.UP*1.6,Vector3(0.9,3.2,0.9),Color("888b72"),true)
		block(base+Vector3.UP*3.3,Vector3(1.4,0.35,1.4),Color("aaa17e"),true)

func build_root_sanctuary() -> void:
	var base:=surface.ground(Vector3(-2,0,-42))
	block(base+Vector3.UP*0.45,Vector3(15.0,0.9,6.5),Color("9e977a"),true)
	for x in [-7.0,3.0]:block(base+Vector3(x+2.0,3.4,0),Vector3(2.1,6.8,2.1),Color("8b8870"),true)
	block(base+Vector3(0,4.2,-1.0),Vector3(7.2,8.4,2.0),Color("938d71"),true)
	block(base+Vector3(0,7.3,-0.4),Vector3(13.5,1.2,2.8),Color("aaa080"),true)
	block(base+Vector3(0,3.0,0.2),Vector3(2.4,5.0,2.3),Color("30423a"),true)
	# Large roots are compositional masses, not finished sculpture assets.
	for pair in [
		[base+Vector3(-8,0.2,3),base+Vector3(-4.5,7.0,-0.5),0.72],
		[base+Vector3(7,0.2,3.5),base+Vector3(3.8,6.5,-0.7),0.82],
		[base+Vector3(-1,0.2,4),base+Vector3(1.8,8.4,-0.5),0.58]
	]:cylinder_between(pair[0],pair[1],pair[2],Color("514c3b"))

func build_forest_masses() -> void:
	# Large quiet masses frame the route; they deliberately avoid prop-by-prop detail.
	for data in [[-25,34,5.5],[-21,20,6.5],[-24,5,7.0],[-20,-12,6.2],[-24,-29,7.5],[12,34,5.2],[10,24,5.8],[14,12,6.8],[13,-3,6.2],[8,-19,6.5]]:
		var at:=surface.ground(Vector3(data[0],0,data[1]))
		V.sphere(props,at+Vector3.UP*data[2]*0.55,data[2]*0.55,Color("365b46"))

func build_hud() -> void:
	hud=CanvasLayer.new()
	add_child(hud)
	var panel:=PanelContainer.new()
	panel.position=Vector2(18,14)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.04,0.10,0.09,0.88)
	style.content_margin_left=12
	style.content_margin_right=12
	style.content_margin_top=7
	style.content_margin_bottom=7
	panel.add_theme_stylebox_override("panel",style)
	hud.add_child(panel)
	ui=Label.new()
	ui.add_theme_font_override("font",preload("res://assets/fonts/NanumGothic-Regular.ttf"))
	ui.add_theme_font_size_override("font_size",18)
	panel.add_child(ui)
	prompt=Label.new()
	prompt.position=Vector2(22,672)
	prompt.add_theme_font_override("font",preload("res://assets/fonts/NanumGothic-Regular.ttf"))
	prompt.add_theme_font_size_override("font_size",18)
	hud.add_child(prompt)
	update_hud()

func zone_name(index: int) -> String:
	return ["ACT 1 · 물가 입구 / 유적의 문턱","ACT 2 · 굽이치는 강가 / 상승하는 순례길","ACT 3 · 뿌리 성소 / 높은 고대 성소"][index]

func update_hud() -> void:
	if not is_instance_valid(ui) or not is_instance_valid(player):return
	var zone:=surface.zone_at(player.position)
	ui.text="  첫 숲 수로 · 세 막 그레이박스\n  %s\n  실제 플레이: pitch %.0f° / yaw %.0f° / size %.0f  "%[zone_name(zone),camera_pitch,rad_to_deg(view_yaw),camera.size]
	prompt.text="WASD 이동 · Space 회피 · J 3연타 · 1/2/3 구간 이동 · Tab 조감 · F 정지 · R 전투 재배치 · B 자동공격 · Esc 종료"

func movement_direction(input: Vector2) -> Vector3:
	return Vector3(input.x,0,input.y).rotated(Vector3.UP,view_yaw)

func update_camera(delta: float) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player):return
	var center: Vector3=Vector3(-2,3,-3) if overview else player.position+player.facing*1.35+Vector3.UP*0.75
	var size:=82.0 if overview else 22.0
	camera.size=lerpf(camera.size,size,minf(1.0,delta*8.0))
	camera.rotation_degrees=Vector3(-camera_pitch,rad_to_deg(view_yaw),0)
	var distance:=62.0 if overview else 31.0
	var goal: Vector3=center+Vector3(0,sin(deg_to_rad(camera_pitch)),cos(deg_to_rad(camera_pitch))).rotated(Vector3.UP,view_yaw)*distance
	camera.position=camera.position.lerp(goal,minf(1.0,delta*9.0))

func review_point(index: int) -> Vector3:
	return surface.ground([Vector3(-12,0,36),Vector3(5,0,4),Vector3(-2,0,-31)][index],0.1)

func focus_zone(index: int) -> void:
	player.position=review_point(index)
	player.velocity=Vector3.ZERO
	player.facing=movement_direction(Vector2.UP)
	visited[index]=true
	overview=false
	update_camera(1)
	update_hud()

func reset_encounter(active: bool=true) -> void:
	set_frozen(false)
	for enemy in enemies():remove_child(enemy);enemy.free()
	for effect in effects:
		if is_instance_valid(effect.node):effect.node.queue_free()
	effects.clear()
	combat.reset_transient()
	combat.swings=0
	hitstop=0;shake=0;kills=0;auto_hits=0;attack_wait=0.7
	player.position=checkpoint()
	player.velocity=Vector3.ZERO
	player.hp=5;player.invulnerability=0;player.dash_left=0;player.dash_wait=0;player.swing_left=0
	player.moving_seconds=0
	player.hurt_flash=0;player.auto_cast_left=0;player.attack_windup=false
	player.facing=movement_direction(Vector2.UP)
	encounter_on=active
	if active:
		var spawns:=[Vector3(-6,0,13),Vector3(-2,0,9),Vector3(5,0,3),Vector3(-3,0,-5),Vector3(-1,0,-12),Vector3(-4,0,-18),Vector3(-4,0,-27)]
		for i in range(spawns.size()):
			var enemy=CompareEnemy.new()
			enemy.stable_id="pilgrimage_%02d"%i
			enemy.role="charger" if i in [2,5] else "wanderer"
			enemy.hp=12
			enemy.position=surface.ground(spawns[i],0.1)
			add_child(enemy)
	update_camera(1)

func enemy_defeated(_enemy: Node3D) -> void:kills+=1

func set_frozen(value: bool) -> void:
	frozen=value
	if is_instance_valid(player):player.set_physics_process(not frozen)
	for enemy in enemies():enemy.set_physics_process(not frozen)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):return
	var zone:=surface.zone_at(player.position)
	visited[zone]=true
	if frozen:
		update_camera(delta);update_hud();return
	combat.update(delta)
	if hitstop>0:hitstop=maxf(0,hitstop-delta);return
	elapsed+=delta
	attack_wait-=delta
	if encounter_on and auto_enabled and attack_wait<=0:auto_attack()
	update_effects(delta)
	update_camera(delta)
	update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_1:focus_zone(0)
		KEY_2:focus_zone(1)
		KEY_3:focus_zone(2)
		KEY_TAB:overview=not overview;update_camera(1);update_hud()
		KEY_F:set_frozen(not frozen)
		KEY_R:reset_encounter(true)
		KEY_B:auto_enabled=not auto_enabled
		KEY_ESCAPE:get_tree().quit()

func _exit_tree() -> void:
	EffectSurface.clear_override(surface)
