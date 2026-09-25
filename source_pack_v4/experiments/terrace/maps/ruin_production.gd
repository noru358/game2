extends "res://maps/forest_pilgrimage_graybox.gd"
const Layouts=preload("res://maps/ruin_layouts.gd")
var kit=preload("res://maps/environment_art.gd").new()
var layout_id:="A"
var data: Dictionary
var plain:=false
var scenery: Node3D

func _ready() -> void:
	layout_id=get_tree().get_meta("ruin_layout","B" if "--layout-b" in OS.get_cmdline_user_args() else "A")
	data=Layouts.get_layout(layout_id)
	surface=preload("res://maps/ruin_builder.gd").new()
	surface.configure(data)
	camera_pitch=float(data.get("pitch",55.0));view_yaw=deg_to_rad(float(data.get("yaw",30.0)))
	super._ready()
	overview=true;update_camera(1);update_hud()
	DisplayServer.window_set_title("수로 유적 · 공통 제작 A/B")

func checkpoint() -> Vector3:return surface.ground(data.spawn,0.1)
func build_world() -> void:
	var environment:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("254a43")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("e1e7d5");env.ambient_light_energy=0.58
	environment.environment=env;add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-35,0)
	sun.light_color=Color("fff3d7");sun.light_energy=0.83;sun.shadow_enabled=true
	sun.directional_shadow_max_distance=120;add_child(sun)
	props=Node3D.new();add_child(props)
	kit.prepare();surface.build(props,kit.stone_texture)
	scenery=Node3D.new();add_child(scenery)
	kit.parent=scenery;kit.surface=surface;kit.camera_pitch=camera_pitch
	for d in data.plants:
		kit.card(Vector3(d[0],0,d[1]),d[2],d[3],0.88)
		kit.shadow(Vector3(d[0],0,d[1]),Vector2(d[3]*0.7,d[3]*0.4),0.22)
	# Landmark reuse is a scale reference, not a newly approved sanctuary asset.
	var landmark:=Sprite3D.new();landmark.texture=load("res://assets/environment/temple_face_v1.png")
	landmark.pixel_size=0.012;landmark.shaded=false
	landmark.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	landmark.rotation=Vector3(-deg_to_rad(camera_pitch),view_yaw,0)
	landmark.position=surface.ground(data.landmark)+Vector3(0,cos(deg_to_rad(camera_pitch)),-sin(deg_to_rad(camera_pitch))).rotated(Vector3.UP,view_yaw)*6
	scenery.add_child(landmark)
	landmark.visible=not data.get("volume_gate",false)
	for sprite in kit.cards:
		var at: Vector3=sprite.get_meta("base_at");var baseline: float=sprite.get_meta("baseline")
		sprite.rotation=Vector3(-deg_to_rad(camera_pitch),view_yaw,0)
		sprite.position=surface.ground(at)+(Vector3(0,sin(deg_to_rad(camera_pitch)),cos(deg_to_rad(camera_pitch)))*0.025+Vector3(0,cos(deg_to_rad(camera_pitch)),-sin(deg_to_rad(camera_pitch)))*baseline).rotated(Vector3.UP,view_yaw)

func update_camera(delta: float) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player):return
	var center: Vector3=data.center if overview else player.position+Vector3.UP*0.8
	camera.size=54.0 if overview else 22.0
	camera.rotation_degrees=Vector3(-camera_pitch,rad_to_deg(view_yaw),0)
	var goal:=center+Vector3(0,sin(deg_to_rad(camera_pitch)),cos(deg_to_rad(camera_pitch))).rotated(Vector3.UP,view_yaw)*60
	camera.position=camera.position.lerp(goal,minf(delta*9,1))

func reset_encounter(active: bool=true) -> void:
	set_frozen(false)
	for enemy in enemies():remove_child(enemy);enemy.free()
	for effect in effects:
		if is_instance_valid(effect.node):effect.node.queue_free()
	effects.clear();combat.reset_transient();combat.swings=0
	hitstop=0;shake=0;kills=0;auto_hits=0;attack_wait=0.7
	player.position=checkpoint();player.velocity=Vector3.ZERO;player.hp=5;player.invulnerability=0
	player.facing=movement_direction(Vector2.DOWN);encounter_on=active
	if active:
		for i in range(data.enemies.size()):
			var p: Array=data.enemies[i];var enemy=CompareEnemy.new()
			enemy.stable_id="ruin_%d"%i;enemy.role="charger" if i==2 else "wanderer";enemy.hp=12
			enemy.position=surface.ground(Vector3(p[0],0,p[1]),0.1);add_child(enemy)
	update_camera(1)

func update_hud() -> void:
	if not is_instance_valid(ui):return
	ui.text="  %s\n  같은 지형 생성기 · 배치 데이터만 변경  "%data.title
	prompt.text="1/2 배치 A/B · Tab 조감/플레이 · G 구조만 · P 대표 위치 · WASD 이동 · J 공격 · Space 회피 · Esc 종료"

func set_plain(value: bool) -> void:
	plain=value;surface.set_plain(value);scenery.visible=not value

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_1,KEY_2:
			get_tree().set_meta("ruin_layout","A" if event.keycode==KEY_1 else "B")
			get_tree().reload_current_scene()
		KEY_G:set_plain(not plain)
		KEY_P:
			player.position=surface.ground(data.hero_view,0.1);overview=false;update_camera(1)
		KEY_TAB:overview=not overview;update_camera(1)
		KEY_F:set_frozen(not frozen)
		KEY_B:auto_enabled=not auto_enabled
		KEY_R:reset_encounter(true)
		KEY_ESCAPE:get_tree().quit()
