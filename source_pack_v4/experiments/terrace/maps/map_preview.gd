extends Node3D
const Surface=preload("res://maps/map_surface.gd")
const Kit=preload("res://maps/environment_kit.gd")
const ArtKit=preload("res://maps/environment_art.gd")
const Player=preload("res://maps/preview_player.gd")
const FONT=preload("res://assets/fonts/NanumGothic-Regular.ttf")
const MAPS={
	"water_entry":{"title":"물길 입구","entry":Vector3(-19,0,15),"exit":Vector3(21,0,-11),"entries":{"start":Vector3(-19,0,15),"east_forest":Vector3(17,0,-11)},"exit_id":"east_forest","destination_entry":"west_low","next":"roots_terrace","discovery":Vector3(-20,0,-3)},
	"roots_terrace":{"title":"뿌리의 단상 · 2층 제단","entry":Vector3(-8,0,9),"exit":Vector3(-12,0,9),"entries":{"start":Vector3(-8,0,9),"west_low":Vector3(-8,0,9)},"exit_id":"west_low","destination_entry":"east_forest","next":"water_entry","discovery":Vector3(0,0,-8.5)}
}
var surface=Surface.new()
var kit=Kit.new()
var terrain_root: Node3D
var player
var camera: Camera3D
var map_id := "water_entry"
var states: Dictionary={"water_entry":{},"roots_terrace":{}}
var transition_wait := 0.0
var transitions := 0
var hitstop := 0.0
var combat
var exploration
var hud: Label
var prompt: Label
var discovery_mesh: MeshInstance3D
var overview := false
var notice_text := ""
var notice_left := 0.0
var save_path := ""
var arrival_id := "start"
var art_enabled := true
var camera_pitch := 45.0

func _ready() -> void:
	get_window().title="물길과 2층 제단 · 환경 화면 03"
	if not "--test" in OS.get_cmdline_user_args():
		push_error("Map preview requires --test; production saves are never read.")
		get_tree().quit(2)
		return
	exploration=self
	combat=preload("res://game/combat.gd").new(self)
	save_path=OS.get_environment("TEMP").path_join("codex_map_preview_%d.json"%OS.get_process_id())
	setup_inputs()
	make_lighting()
	make_hud()
	player=Player.new()
	add_child(player)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=22
	camera.rotation_degrees=Vector3(-52,0,0)
	camera.current=true
	add_child(camera)
	load_map("water_entry","start")
	if "--env-focus" in OS.get_cmdline_user_args():focus_section()
	if "--altar-focus" in OS.get_cmdline_user_args():focus_altar()

func setup_inputs() -> void:
	for entry in [["left",KEY_A,KEY_LEFT],["right",KEY_D,KEY_RIGHT],["up",KEY_W,KEY_UP],["down",KEY_S,KEY_DOWN],["dash",KEY_SPACE,KEY_SHIFT],["interact",KEY_F,KEY_F]]:
		if not InputMap.has_action(entry[0]):InputMap.add_action(entry[0])
		for key in [entry[1],entry[2]]:
			var ev := InputEventKey.new()
			ev.physical_keycode=key
			InputMap.action_add_event(entry[0],ev)

func make_lighting() -> void:
	var environment := Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("8eafa5")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("a4c8ba")
	environment.ambient_light_energy=0.45
	environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	var node := WorldEnvironment.new()
	node.environment=environment
	add_child(node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-53,-32,0)
	sun.light_color=Color("fff2dc")
	sun.light_energy=0.7
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=110
	add_child(sun)

func make_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position=Vector2(20,18)
	var style := StyleBoxFlat.new()
	style.bg_color=Color(0.055,0.12,0.12,0.92)
	style.content_margin_left=16
	style.content_margin_right=16
	style.content_margin_top=10
	style.content_margin_bottom=10
	style.corner_radius_top_left=8
	style.corner_radius_bottom_right=8
	panel.add_theme_stylebox_override("panel",style)
	canvas.add_child(panel)
	hud=Label.new()
	hud.add_theme_font_override("font",FONT)
	hud.add_theme_font_size_override("font_size",18)
	panel.add_child(hud)
	var bottom := PanelContainer.new()
	bottom.position=Vector2(20,710)
	bottom.add_theme_stylebox_override("panel",style)
	canvas.add_child(bottom)
	prompt=Label.new()
	prompt.add_theme_font_override("font",FONT)
	prompt.add_theme_font_size_override("font_size",20)
	bottom.add_child(prompt)

func load_map(id: String,entry_id: String) -> void:
	if is_instance_valid(terrain_root):terrain_root.free()
	map_id=id
	arrival_id=entry_id
	surface.configure(id)
	surface.art_enabled=art_enabled
	kit=ArtKit.new() if art_enabled else Kit.new()
	if art_enabled:kit.camera_pitch=camera_pitch
	terrain_root=Node3D.new()
	add_child(terrain_root)
	surface.build(terrain_root)
	kit.build(terrain_root,surface)
	var data: Dictionary=MAPS[id]
	player.position=surface.ground(data.entries[entry_id],0.12)
	player.velocity=Vector3.ZERO
	player.facing=Vector3.LEFT if id=="water_entry" and entry_id!="start" else Vector3.RIGHT
	player.dash_left=0
	player.moving_seconds=0
	transition_wait=0.8
	discovery_mesh=kit.block(surface.ground(data.discovery)+Vector3.UP*0.6,Vector3(0.8,1.2,0.55),Color("d0c991"),false)
	var label := Label3D.new()
	label.font=FONT
	label.text="숲 안쪽 · F" if id=="water_entry" else "물길 입구 · F"
	label.font_size=34
	label.pixel_size=0.012
	label.position=surface.ground(data.exit)+Vector3.UP*4.5
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	terrain_root.add_child(label)
	update_camera(1)
	update_hud()

func update_camera(weight: float) -> void:
	if overview:
		camera.size=64 if map_id=="water_entry" else 42
		camera.position=Vector3(0,58,39)
		camera.look_at(Vector3(0,0,-3))
	else:
		camera.size=22 if map_id=="water_entry" else 26
		camera.rotation_degrees=Vector3(-camera_pitch,0,0)
		var look_ahead := Vector3.ZERO if map_id=="water_entry" else Vector3(0,1.2,-3)
		camera.position=camera.position.lerp(player.position+look_ahead+Vector3(0,sin(deg_to_rad(camera_pitch)),cos(deg_to_rad(camera_pitch)))*25,weight)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):return
	transition_wait=maxf(0,transition_wait-delta)
	notice_left=maxf(0,notice_left-delta)
	update_camera(minf(1,delta*8))
	kit.update_occlusion(camera,player.position)
	if Input.is_action_just_pressed("interact"):interact()
	update_hud()

func interact() -> void:
	if transition_wait>0:return
	var data: Dictionary=MAPS[map_id]
	if player.position.distance_to(surface.ground(data.exit))<2.4:
		var next: String=data.next
		transitions+=1
		load_map(next,data.destination_entry)
		save_now()
	elif player.position.distance_to(surface.ground(data.discovery))<2.5:
		states[map_id]["found"]=true
		notice("물가의 흔적을 살폈습니다 · 돌아와도 발견은 유지됩니다" if map_id=="water_entry" else "2층 제단의 흔적을 살폈습니다 · 돌아와도 발견은 유지됩니다")
		save_now()

func update_hud() -> void:
	var floor_label := "" if map_id=="water_entry" else (" · 2층" if player.position.y>4.9 else (" · 계단" if player.position.y>1.2 else " · 1층"))
	hud.text="%s%s\nWASD 이동 · Space 회피 · F 조사/이동 · Tab 전체보기\nV 이전 재질 · C 시점 %.0f° · P 물가 · 2 제단\n승인 정지8방향 / 전투 없음 · Esc 종료"%[MAPS[map_id].title,floor_label,camera_pitch]
	var data: Dictionary=MAPS[map_id]
	var hint := "물가의 둑길을 따라 동쪽 숲으로" if map_id=="water_entry" else "중앙 계단으로 2층 제단에 올라가세요 · 왼쪽 석문은 물길 입구"
	if player.position.distance_to(surface.ground(data.exit))<2.4:hint="F · "+MAPS[data.next].title+"으로 이동"
	elif player.position.distance_to(surface.ground(data.discovery))<2.5:hint="살펴본 흔적" if states[map_id].get("found",false) else ("F · 물가의 흔적 살피기" if map_id=="water_entry" else "F · 제단의 흔적 살피기")
	if notice_left>0:hint=notice_text
	prompt.text=hint
	discovery_mesh.material_override.albedo_color=Color("7f9b88") if states[map_id].get("found",false) else Color("d0c991")

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_ESCAPE:get_tree().quit()
		KEY_TAB:
			overview=not overview
			update_camera(1)
		KEY_R:
			player.position=respawn_point()
			player.velocity=Vector3.ZERO
			update_camera(1)
		KEY_P:
			focus_section()
		KEY_2:
			focus_altar()
		KEY_V:
			art_enabled=not art_enabled
			rebuild_view()
		KEY_C:
			camera_pitch=52.0 if camera_pitch==45.0 else 45.0
			rebuild_view()

func focus_section() -> void:
	if map_id!="water_entry":load_map("water_entry","start")
	player.position=surface.ground(Vector3(-9,0,-12),0.1)
	player.velocity=Vector3.ZERO
	player.facing=Vector3(1,0,1).normalized()
	update_camera(1)

func focus_altar() -> void:
	load_map("roots_terrace","start")
	player.position=surface.ground(Vector3(0,0,8),0.1)
	player.facing=Vector3.FORWARD
	overview=false
	update_camera(1)

func rebuild_view() -> void:
	var at: Vector3=player.position
	var facing: Vector3=player.facing
	load_map(map_id,arrival_id)
	player.position=surface.ground(at,0.05)
	player.facing=facing
	player.update_visual(0)
	update_camera(1)

func respawn_point() -> Vector3:return surface.ground(MAPS[map_id].entry,0.1)
func sound(_kind: String) -> void:pass
func notice(message: String) -> void:
	notice_text=message
	notice_left=3
func save_now() -> void:
	var file := FileAccess.open(save_path,FileAccess.WRITE)
	if file:file.store_string(JSON.stringify({"schema":1,"map_id":map_id,"entry_id":arrival_id,"states":states}))
func restore_preview(path: String) -> bool:
	if path!=save_path or not FileAccess.file_exists(path):return false
	var data=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("schema",0)!=1 or not MAPS.has(data.get("map_id","")):return false
	if not MAPS[data.map_id].entries.has(data.get("entry_id","")):return false
	states=data.states
	load_map(data.map_id,data.entry_id)
	return true
func _exit_tree() -> void:
	if not save_path.is_empty() and FileAccess.file_exists(save_path):DirAccess.remove_absolute(save_path)
