extends "res://lab/world.gd"
## Independent composition proof: authored masses first, existing art and combat second.
const Kit=preload("res://maps/environment_art.gd")
const ComparePlayer=preload("res://maps/view_compare_player.gd")
const CompareEnemy=preload("res://maps/view_compare_enemy.gd")
const EffectSurface=preload("res://game/effect_surface.gd")
var surface=preload("res://maps/composition_proof_surface.gd").new()
var kit=Kit.new()
var camera_pitch:=52.0
var view_yaw:=deg_to_rad(20.0)
var overview:=true
var encounter_on:=true
var auto_enabled:=true
var frozen:=false
var ui: Label
var props: Node3D

func _ready() -> void:
	if not "--test" in OS.get_cmdline_user_args():get_tree().quit(2);return
	EffectSurface.set_override(surface)
	super._ready()
	remove_child(player)
	player.free()
	player=ComparePlayer.new()
	add_child(player)
	player.position=checkpoint()
	DisplayServer.window_set_title("맵 철학 시안 · 물길 위의 사원")
	reset_encounter(true)
	set_frozen(true)
	set_view(20)

func checkpoint() -> Vector3:return surface.ground(Vector3(122,0,8),0.1)
func near_threshold() -> bool:return false
func populate_field() -> void:pass
func storage_key(_field: String) -> String:return "user://unused_composition_proof.json"
func save_now() -> void:pass
func flush_save() -> void:pass
func pending_choices() -> int:return 0
func attack_profile() -> Dictionary:return Growth.profile(4)
func on_growth_auto_hit(_at: Vector3) -> void:pass

func build_world() -> void:
	var environment:=WorldEnvironment.new()
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("173734")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("cedbbd")
	env.ambient_light_energy=0.72
	environment.environment=env
	add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-52,-38,0)
	light.light_color=Color("fff0c4")
	light.light_energy=0.88
	light.shadow_enabled=true
	add_child(light)
	surface.build(self)
	build_safety_edges()
	props=Node3D.new()
	props.name="AuthoredComposition"
	add_child(props)
	kit.parent=props
	kit.surface=surface
	kit.camera_pitch=camera_pitch
	kit.prepare()
	build_bridge()
	build_landmark()
	decorate_landforms()
	align_cards()

func safety_segment(a: Vector2,b: Vector2,height: float) -> void:
	var direction: Vector2=(b-a).normalized()
	var midpoint: Vector2=(a+b)*0.5
	var wall:=V.box(self,Vector3(midpoint.x,height+1.05,midpoint.y),Vector3(a.distance_to(b),2.1,0.52),Color("203932"),true)
	wall.rotation.y=-atan2(direction.y,direction.x)
	wall.get_child(0).hide()

func safety_polygon(polygon: PackedVector2Array,height: float,open_edges: Array[int]) -> void:
	for i in range(polygon.size()):
		if i in open_edges:continue
		safety_segment(polygon[i],polygon[(i+1)%polygon.size()],height)

func build_safety_edges() -> void:
	# Collision follows the visible cliff rim. Only the authored bridge and stair
	# openings stay open; this prevents combat knockback from dropping actors into water.
	safety_polygon(surface.entry_polygon(),surface.MAIN_Y,[2])
	safety_polygon(surface.main_polygon(),surface.MAIN_Y,[4,10])
	safety_polygon(surface.upper_polygon(),surface.UPPER_Y,[8])

func build_bridge() -> void:
	var a:=Vector2(100.5,19.5)
	var b:=Vector2(108.0,16.0)
	var direction:=(b-a).normalized()
	var midpoint:=(a+b)*0.5
	var bridge:=kit.block(Vector3(midpoint.x,surface.MAIN_Y-0.16,midpoint.y),Vector3(a.distance_to(b)+0.8,0.34,3.0),Color.WHITE,true)
	bridge.rotation.y=-atan2(direction.y,direction.x)
	for t in [0.16,0.84]:
		var p:=a.lerp(b,t)
		var side:=Vector2(-direction.y,direction.x)*1.8
		for sign_value in [-1.0,1.0]:
			var q: Vector2=p+side*sign_value
			kit.block(Vector3(q.x,surface.MAIN_Y+0.65,q.y),Vector3(0.65,1.3,0.65),Color.WHITE,true)

func build_landmark() -> void:
	var base:=surface.ground(Vector3(132,0,-21))
	kit.block(base+Vector3.UP*0.4,Vector3(12.0,0.8,6.2),Color.WHITE,true)
	kit.block(base+Vector3(-4.4,3.1,-1.0),Vector3(2.0,6.2,2.0),Color.WHITE,true)
	kit.block(base+Vector3(4.4,3.1,-1.0),Vector3(2.0,6.2,2.0),Color.WHITE,true)
	kit.block(base+Vector3(0,3.8,-1.5),Vector3(5.4,7.6,1.6),Color.WHITE,true)
	kit.block(base+Vector3(0,6.4,-1.0),Vector3(10.6,1.1,2.2),Color.WHITE,true)
	var sigil:=V.box(props,base+Vector3(0,3.6,-0.62),Vector3(0.42,2.8,0.18),Color("8ef0dc"))
	sigil.get_child(0).material_override=V.material(Color("8ef0dc"),1.4)
	for x in [126.2,137.8]:kit.card(Vector3(x,0,-17.0),3,5.4)

func decorate_landforms() -> void:
	for data in [
		[Vector3(93,0,22),7.4],[Vector3(100,0,25),6.8],
		[Vector3(104,0,10),8.2],[Vector3(108,0,-2),7.5],[Vector3(141,0,12),8.3],
		[Vector3(118,0,-23),8.6],[Vector3(145,0,-23),9.0],[Vector3(145,0,-12),7.8]
	]:kit.tree(data[0],data[1],roundi(data[0].x+data[0].z))
	for at in [Vector3(106,0,18),Vector3(110,0,13),Vector3(107,0,1),Vector3(138,0,15),Vector3(140,0,4),Vector3(116,0,-7),Vector3(121,0,-16),Vector3(143,0,-17)]:kit.card(at,2,3.5)
	for at in [Vector3(112,0,18),Vector3(105,0,7),Vector3(136,0,18),Vector3(142,0,7),Vector3(120,0,-11),Vector3(141,0,-11)]:kit.card(at,1,2.6)
	for at in [Vector3(113,0,15),Vector3(136,0,13),Vector3(115,0,-5),Vector3(142,0,-3),Vector3(123,0,-15)]:kit.card(at,4,2.3)
	# Short capstone phrases reinforce planes without tracing every contour.
	for x in [110.0,113.0,116.0]:kit.block(surface.ground(Vector3(x,0,19.2))+Vector3.UP*0.24,Vector3(2.5,0.48,0.75),Color.WHITE,true)
	for x in [140.0,143.0]:kit.block(surface.ground(Vector3(x,0,11.5))+Vector3.UP*0.24,Vector3(2.5,0.48,0.75),Color.WHITE,true)

func align_cards() -> void:
	for sprite in kit.cards:
		var at: Vector3=sprite.get_meta("base_at")
		var baseline: float=sprite.get_meta("baseline")
		sprite.rotation=Vector3(-deg_to_rad(camera_pitch),view_yaw,0)
		sprite.position=surface.ground(at)+(Vector3(0,sin(deg_to_rad(camera_pitch)),cos(deg_to_rad(camera_pitch)))*0.025+Vector3(0,cos(deg_to_rad(camera_pitch)),-sin(deg_to_rad(camera_pitch)))*baseline).rotated(Vector3.UP,view_yaw)

func build_hud() -> void:
	hud=CanvasLayer.new()
	add_child(hud)
	var panel:=PanelContainer.new()
	panel.position=Vector2(18,14)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.04,0.10,0.09,0.88)
	style.content_margin_left=10
	style.content_margin_right=10
	style.content_margin_top=6
	style.content_margin_bottom=6
	panel.add_theme_stylebox_override("panel",style)
	hud.add_child(panel)
	ui=Label.new()
	ui.add_theme_font_override("font",preload("res://assets/fonts/NanumGothic-Regular.ttf"))
	ui.add_theme_font_size_override("font_size",18)
	panel.add_child(ui)
	update_hud()

func update_hud() -> void:
	if not is_instance_valid(ui) or not is_instance_valid(player):return
	ui.text="  물길 위의 사원 · 구도 시안 / yaw %.0f°  \n  1:15°  2:20°  3:25° · Tab: %s  \n  WASD 이동 · Space 회피 · J 직접공격 · F 전투 정지/재개  \n  R 같은 전투 · T 탐험 · B 자동공격 %s · Esc 종료  \n  %s  "%[rad_to_deg(view_yaw),"플레이 시점" if overview else "전체 구도", "켜짐" if auto_enabled else "꺼짐", "정지 화면" if frozen else ("전투 중" if encounter_on else "탐험 중")]

func movement_direction(input: Vector2) -> Vector3:
	return Vector3(input.x,0,input.y).rotated(Vector3.UP,view_yaw)

func update_camera(_delta: float) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player):return
	var center:=Vector3(116.5,2.2,0.5) if overview else player.position+Vector3.UP*0.8
	camera.size=39.0 if overview else 22.0
	camera.rotation_degrees=Vector3(-camera_pitch,rad_to_deg(view_yaw),0)
	camera.position=center+Vector3(0,sin(deg_to_rad(camera_pitch)),cos(deg_to_rad(camera_pitch))).rotated(Vector3.UP,view_yaw)*35.0

func set_view(degrees: float) -> void:
	view_yaw=deg_to_rad(degrees)
	align_cards()
	if is_instance_valid(player):player.update_visual(0)
	for enemy in enemies():enemy.refresh_view()
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
		var spawns:=[Vector3(114,0,8),Vector3(118,0,2),Vector3(125,0,1),Vector3(133,0,5),Vector3(136,0,10),Vector3(129,0,14),Vector3(120,0,14),Vector3(138,0,1)]
		for i in range(spawns.size()):
			var enemy=CompareEnemy.new()
			enemy.stable_id="proof_%02d"%i
			enemy.role="charger" if i in [3,7] else "wanderer"
			enemy.hp=12
			enemy.position=surface.ground(spawns[i],0.1)
			add_child(enemy)
	set_view(rad_to_deg(view_yaw))

func enemy_defeated(_enemy: Node3D) -> void:kills+=1

func _physics_process(delta: float) -> void:
	if frozen:update_camera(delta);update_foliage();update_hud();return
	combat.update(delta)
	if hitstop>0:hitstop=maxf(0,hitstop-delta);return
	elapsed+=delta
	attack_wait-=delta
	if encounter_on and auto_enabled and attack_wait<=0:auto_attack()
	update_effects(delta)
	update_camera(delta)
	update_foliage()
	update_hud()

func update_effects(delta: float) -> void:
	for effect in effects.duplicate():
		effect.time-=delta
		if effect.node.has_method("advance"):effect.node.advance(delta)
		if effect.has("velocity"):effect.node.position+=effect.velocity*delta
		if effect.time<=0:
			effect.node.queue_free()
			effects.erase(effect)

func update_foliage() -> void:
	var hero_screen:=camera.unproject_position(player.position+Vector3.UP)
	for sprite in kit.cards:
		var base: Vector3=surface.ground(sprite.get_meta("base_at"))
		var close:=camera.unproject_position(base+Vector3.UP).distance_to(hero_screen)<90
		var in_front:=(base-player.position).dot(camera.global_basis.z)>0
		var faded:=close and in_front
		sprite.modulate.a=0.24 if faded else 1.0
		sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISABLED if faded else SpriteBase3D.ALPHA_CUT_DISCARD

func set_frozen(value: bool) -> void:
	frozen=value
	if is_instance_valid(player):player.set_physics_process(not frozen)
	for enemy in enemies():enemy.set_physics_process(not frozen)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_1:set_view(15)
		KEY_2:set_view(20)
		KEY_3:set_view(25)
		KEY_TAB:overview=not overview;update_camera(1);update_hud()
		KEY_F:set_frozen(not frozen)
		KEY_R:reset_encounter(true);set_frozen(true)
		KEY_T:reset_encounter(false)
		KEY_B:auto_enabled=not auto_enabled
		KEY_ESCAPE:get_tree().quit()

func _exit_tree() -> void:
	EffectSurface.clear_override(surface)
