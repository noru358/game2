extends "res://lab/world.gd"
## One geometry, one encounter, three fixed yaws. No production save access.
const Kit=preload("res://maps/environment_art.gd")
const ComparePlayer=preload("res://maps/view_compare_player.gd")
const CompareEnemy=preload("res://maps/view_compare_enemy.gd")
var surface=preload("res://maps/view_compare_surface.gd").new()
var kit=Kit.new()
var camera_pitch := 52.0
var view_yaw := deg_to_rad(20.0)
var encounter_count := 8
var encounter_on := false
var ui: Label
var props: Node3D
var terrain: MeshInstance3D
var previous_region := -1
var previous_flat := false
var auto_enabled := true
var frozen := false
var comparison_anchor := Vector3(122,0,0)

func _ready() -> void:
	if not "--test" in OS.get_cmdline_user_args():get_tree().quit(2);return
	previous_region=Landscape.lab_region
	previous_flat=Landscape.lab_flat
	get_tree().set_meta("lab_flat",false)
	super._ready()
	remove_child(player)
	player.free()
	player=ComparePlayer.new()
	add_child(player)
	player.position=checkpoint()
	DisplayServer.window_set_title("배경 시점 비교 · 0° / 20° / 45°")
	reset_encounter(true)
	set_frozen(true)
	set_view(20)

func checkpoint() -> Vector3:return Landscape.on_ground(comparison_anchor,0.1)
func near_threshold() -> bool:return false # Preserve explicit lab_region in base setup.
func build_world() -> void:
	Landscape.lab_region=1
	Landscape.lab_flat=false
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("243e3b")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("d6dfc4")
	env.ambient_light_energy=0.8
	environment.environment=env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-30,0)
	light.light_energy=0.8
	light.shadow_enabled=true
	add_child(light)
	terrain=Landscape.make_terrain(self,Rect2(90,-35,64,61))
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://maps/assets/surface_materials_v1.png"))
	var half := image.get_width()/2
	var textures: Array[Texture2D]=[]
	for i in range(4):
		var part := image.get_region(Rect2i((i%2)*half,(i/2)*half,half,half))
		part.generate_mipmaps()
		textures.append(ImageTexture.create_from_image(part))
	var mat := ShaderMaterial.new()
	mat.shader=preload("res://maps/view_compare_ground.gdshader")
	for i in range(4):mat.set_shader_parameter(["grass_tex","dirt_tex","paving_tex","masonry_tex"][i],textures[i])
	terrain.material_override=mat
	props=Node3D.new()
	add_child(props)
	kit.parent=props
	kit.surface=surface
	kit.camera_pitch=camera_pitch
	kit.prepare()
	# Irregular vegetation pockets frame a broad, deliberately quiet combat clearing.
	var rng := RandomNumberGenerator.new()
	rng.seed=924
	for i in range(180):
		var at := Vector3(rng.randf_range(96,149),0,rng.randf_range(-32,23))
		if at.x>108 and at.x<138 and at.z>-10 and at.z<9:continue
		if absf(at.x-132)<5 and at.z>-15 and at.z<4:continue
		if absf(at.x-110)<4 and at.z< -10:continue
		kit.card(at,1 if i%4<3 else 2,rng.randf_range(2.4,4.7),rng.randf_range(0.8,1))
	for at in [Vector3(106,0,1),Vector3(142,0,-12),Vector3(118,0,-18),Vector3(99,0,-16),Vector3(145,0,13),Vector3(104,0,15)]:kit.tree(at,8.5,0)
	for at in [Vector3(120,0,-11),Vector3(128,0,-16),Vector3(109,0,9)]:kit.card(at,3,5.0)
	# Broken masonry follows the curved shelf; each piece has real collision.
	for i in range(6):
		var at := Vector3(111+i*2.0,0,-9+sin(i*0.6))
		var block=kit.block(surface.ground(at)+Vector3.UP*0.25,Vector3(1.65,0.5,0.8),Color.WHITE)
		block.rotation.y=deg_to_rad(-15+i*5)
	# The existing slope and paving share Landscape geometry, no floating stair art.
	for z in range(-10,2,2):
		var paving=Landscape.paving(self,Vector3(132,0,z),Vector2(4.4,1.35),Landscape.PAVING_LIFT,Color("b5b497"))
		var paving_mat := StandardMaterial3D.new()
		paving_mat.albedo_texture=textures[2]
		paving_mat.albedo_color=Color("aaa88f")
		paving_mat.uv1_scale=Vector3(0.17,0.17,1)
		paving.material_override=paving_mat
	for x in [100.0,144.0]:
		var wall=V.box(self,Vector3(x,5,-5),Vector3(0.5,20,52),Color.BLACK,true)
		wall.get_child(0).hide()
	for z in [-30.0,19.0]:
		var wall=V.box(self,Vector3(122,5,z),Vector3(44,20,0.5),Color.BLACK,true)
		wall.get_child(0).hide()

func populate_field() -> void:pass
func storage_key(_field: String) -> String:return "user://unused_view_compare.json"
func save_now() -> void:pass
func flush_save() -> void:pass
func pending_choices() -> int:return 0
func attack_profile() -> Dictionary:return Growth.profile(4)
func on_growth_auto_hit(_at: Vector3) -> void:pass
func enemy_defeated(_enemy: Node3D) -> void:kills+=1
func movement_direction(input: Vector2) -> Vector3:
	return Vector3(input.x,0,input.y).rotated(Vector3.UP,view_yaw)

func build_hud() -> void:
	hud=CanvasLayer.new()
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position=Vector2(18,14)
	var style := StyleBoxFlat.new()
	style.bg_color=Color(0.06,0.13,0.12,0.92)
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
	ui.text="  같은 지형 · 같은 전투 / 시점 %.0f° / 체력 %d/5  \n  1: 0°   2: 20°   3: 45°   R: 같은 전투 재시작 (%d마리)  \n  WASD 이동 · Space 회피 · J 직접 공격 · F: 정지/재개  \n  N: 8/24마리 · T: 탐험 · B: 자동 공격 %s · Esc 종료  \n  %s · 정지 캐릭터 / 기존 적·효과 임시 미술  "%[rad_to_deg(view_yaw),player.hp,encounter_count,"켜짐" if auto_enabled else "꺼짐","정지 중 · F를 누르면 시작" if frozen else ("전투 중 · 남은 적 %d / 처치 %d"%[enemies().size(),kills] if encounter_on else "탐험 중 · 오른쪽 포석 경사로로 고지대 진입")]

func update_camera(_delta: float) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player):return
	camera.size=26
	camera.rotation_degrees=Vector3(-camera_pitch,rad_to_deg(view_yaw),0)
	# Fixed world anchor during combat gives strictly comparable scene framing.
	var center: Vector3=surface.ground(comparison_anchor)+Vector3.UP*1.0 if encounter_on else player.position+Vector3.UP*1.0
	camera.position=center+Vector3(0,sin(deg_to_rad(camera_pitch)),cos(deg_to_rad(camera_pitch))).rotated(Vector3.UP,view_yaw)*34

func set_view(degrees: float) -> void:
	view_yaw=deg_to_rad(degrees)
	for sprite in kit.cards:
		var at: Vector3=sprite.get_meta("base_at")
		var baseline: float=sprite.get_meta("baseline")
		sprite.rotation=Vector3(-deg_to_rad(camera_pitch),view_yaw,0)
		sprite.position=surface.ground(at)+(Vector3(0,sin(deg_to_rad(camera_pitch)),cos(deg_to_rad(camera_pitch)))*0.025+Vector3(0,cos(deg_to_rad(camera_pitch)),-sin(deg_to_rad(camera_pitch)))*baseline).rotated(Vector3.UP,view_yaw)
	player.update_visual(0)
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
	player.facing=Vector3.RIGHT
	encounter_on=active
	if active:
		for i in range(encounter_count):
			var angle := TAU*float(i)/encounter_count
			var at := comparison_anchor+Vector3(cos(angle)*5.3,0,sin(angle)*3.6)
			var e=CompareEnemy.new()
			e.stable_id="view_%02d"%i
			e.role="charger" if i%4==3 else "wanderer"
			e.hp=12
			e.position=surface.ground(at,0.1)
			add_child(e)
	set_view(rad_to_deg(view_yaw))

func _physics_process(delta: float) -> void:
	if frozen:update_camera(delta);update_hud();return
	combat.update(delta)
	if hitstop>0:hitstop=maxf(0,hitstop-delta);return
	elapsed+=delta
	attack_wait-=delta
	if encounter_on and auto_enabled and attack_wait<=0:auto_attack()
	update_effects(delta)
	update_camera(delta)
	update_foliage()
	update_hud()

func set_frozen(value: bool) -> void:
	frozen=value
	if is_instance_valid(player):player.set_physics_process(not frozen)
	for enemy in enemies():enemy.set_physics_process(not frozen)

func update_foliage() -> void:
	var hero_screen := camera.unproject_position(player.position+Vector3.UP)
	for sprite in kit.cards:
		var base: Vector3=surface.ground(sprite.get_meta("base_at"))
		var near_screen := camera.unproject_position(base+Vector3.UP).distance_to(hero_screen)<90
		var in_front := (base-player.position).dot(camera.global_basis.z)>0
		var faded := near_screen and in_front
		sprite.modulate.a=0.24 if faded else 1.0
		sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISABLED if faded else SpriteBase3D.ALPHA_CUT_DISCARD

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_1:set_view(0)
		KEY_2:set_view(20)
		KEY_3:set_view(45)
		KEY_R:reset_encounter()
		KEY_T:reset_encounter(false)
		KEY_N:
			encounter_count=24 if encounter_count==8 else 8
			reset_encounter()
		KEY_B:auto_enabled=not auto_enabled
		KEY_F:set_frozen(not frozen)
		KEY_ESCAPE:get_tree().quit()

func _exit_tree() -> void:
	Landscape.lab_region=previous_region
	Landscape.lab_flat=previous_flat
