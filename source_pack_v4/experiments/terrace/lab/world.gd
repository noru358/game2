extends "res://game/world.gd"

var flat := false
var shortcut := false
var vista := false
var shortcut_body: Node3D
var status: Label
var prompt: Label
var pause_panel: PanelContainer
var buttons: VBoxContainer
var cleared: Array = []
const Growth=preload("res://lab/spell_growth.gd")
var view_weight:=0.0
var save_queue:Node
func attack_profile() -> Dictionary:return Growth.profile(kills)
func on_growth_auto_hit(at: Vector3) -> void:
	if Growth.stage(kills)==2 and auto_hits%4==0:
		burst_at(at,2.5,3)
const SPAWNS := [Vector3(108,0,1),Vector3(111,0,0),Vector3(109,0,-2),Vector3(113,0,-1),Vector3(129,0,-10),Vector3(132,0,-12),Vector3(130,0,-14),Vector3(133,0,-11),Vector3(113,0,-23),Vector3(116,0,-25),Vector3(119,0,-24),Vector3(116,0,-21)]

func _ready() -> void:
	test_mode="--test" in OS.get_cmdline_user_args()
	flat=get_tree().get_meta("lab_flat",false)
	Landscape.lab_flat=flat
	var field:="plain" if flat else "terrace"
	save_slot=storage_key(field)
	get_tree().auto_accept_quit=false
	setup_inputs()
	build_world()
	exploration=preload("res://lab/exploration.gd").new(self)
	waterworks=Waterworks.new(self)
	player=Player.new()
	add_child(player)
	player.position=exploration.respawn_point()
	combat=Combat.new(self)
	camera=Camera3D.new()
	add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=34
	camera.far=110
	camera.current=true
	update_camera(1)
	audio=preload("res://game/sound_bank.gd").new()
	add_child(audio)
	var fresh:bool=get_tree().get_meta("lab_fresh",false)
	get_tree().remove_meta("lab_fresh")
	var data: Dictionary={} if test_mode or fresh else Store.read_data(save_slot)
	# Import the previous experiment once without writing its live save slot.
	if allow_legacy_import() and not test_mode and not fresh and data.is_empty() and not FileAccess.file_exists(save_slot) and not FileAccess.file_exists(save_slot+".bak"):
		data=Store.read_data("user://%s_v2.json"%field)
		if data.is_empty():data=Store.read_data("user://%s.json"%field)
	if data.is_empty():
		populate_field()
	else: restore(data)
	build_hud()
	if fresh:save_now()
	notice("물길 위의 얼굴 사원을 찾아보세요 · 무리를 지나쳐 돌아가도 좋습니다")
	Engine.max_fps=60

func build_world() -> void:
	if not has_method("near_threshold"):Landscape.lab_region=-1
	var environment:=WorldEnvironment.new()
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("1c3335")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("bdd9cb")
	env.ambient_light_energy=0.75
	environment.environment=env
	add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-30,0)
	light.light_color=Color("ffebc6")
	light.light_energy=1.0
	light.shadow_enabled=true
	add_child(light)
	var terrain_rect:=Rect2(90,-32,60,67) if Landscape.lab_region==1 else Rect2(90,-55,60,90)
	if Landscape.lab_region==2:terrain_rect.size.x=51
	Landscape.make_terrain(self,terrain_rect)
	preload("res://lab/surroundings.gd").build(self)
	for x in [100.0,140.0]:
		var boundary:=V.box(self,Vector3(x,3,-9),Vector3(0.6,9,46),Color("3c574e"),true)
		boundary.get_child(0).hide()
	for z in [-32.0,14.0]:
		var boundary:=V.box(self,Vector3(120,3,z),Vector3(39.4,9,0.6),Color("3c574e"),true)
		boundary.get_child(0).hide()
	if not flat and Landscape.lab_region!=1:
		for x in [116.0,124.0]:
			V.stone_box(self,Landscape.on_ground(Vector3(x,0,-8),1.8),Vector3(4,3.6,3),Color("788774"),true)
		shortcut_body=V.stone_box(self,Landscape.on_ground(Vector3(120,0,-8),1.5),Vector3(3.9,3,3),Color("b1a77c"),true)
		for x in [105.0,135.0]:
			for z in [-17.0,-25.0]:
				V.stone_box(self,Landscape.on_ground(Vector3(x,0,z),1.4),Vector3(2.5,2.8,2.8),Color("697e6e"),true)
		for x in [110.0,132.0]:
			for z in [-5.0,-9.0,-15.0,-20.0]: Landscape.paving(self,Vector3(x,0,z),Vector2(1.7,1.9),Landscape.PAVING_LIFT,Color("939d7a"))
		for z in [-23.0,-20.0]: Landscape.paving(self,Vector3(120,0,z),Vector2(2.2,1.8),Landscape.PAVING_LIFT,Color("939d7a"))
	build_landmark()
	for p in [Vector3(102,0,9),Vector3(103,0,-8),Vector3(138,0,-3),Vector3(138,0,-22),Vector3(105,0,-30)]:
		V.tropical_prop(self,Landscape.on_ground(p),0,5.5)
	for p in [Vector3(104,0,11),Vector3(137,0,6),Vector3(136,0,-17),Vector3(109,0,-29)]:
		V.tropical_prop(self,Landscape.on_ground(p),1,1.4)

func build_hud() -> void:
	hud=preload("res://lab/hud.gd").new()
	add_child(hud)
	hud.process_mode=Node.PROCESS_MODE_ALWAYS
	var back:=PanelContainer.new()
	back.position=Vector2(24,20)
	back.custom_minimum_size=Vector2(520,82)
	hud.add_child(back)
	status=Label.new()
	status.add_theme_font_size_override("font_size",20)
	back.add_child(status)
	prompt=Label.new()
	prompt.position=Vector2(24,650)
	prompt.add_theme_font_size_override("font_size",18)
	hud.add_child(prompt)
	pause_panel=PanelContainer.new()
	pause_panel.position=Vector2(370,135)
	pause_panel.custom_minimum_size=Vector2(530,0)
	hud.add_child(pause_panel)
	buttons=VBoxContainer.new()
	buttons.add_theme_constant_override("separation",12)
	pause_panel.add_child(buttons)
	pause_panel.hide()
	update_hud()

func update_hud() -> void:
	status.text="  %s   ·   체력 %d/5\n  Lv.%d  %s   ·   처치 %d/12"%["비교 A · 열린 뜰" if flat else "비교 B · 물길의 단상",player.hp,Growth.stage(kills)+1,["두 번 잇기","세 번 잇기","응축 마법"][Growth.stage(kills)],kills]
	var hint:="WASD / 방향키 이동   ·   Space 회피   ·   J 직접 마법   ·   Esc 쉬기 / 비교"
	if not flat and not shortcut and player.position.distance_to(Landscape.on_ground(Vector3(120,0,-13)))<3:
		hint="F  빗장을 풀어 아래뜰로 바로 내려가는 길 열기"
	elif message_left>0: hint=message+"\n"+hint
	prompt.text=hint

func _physics_process(delta: float) -> void:
	combat.update(delta)
	if hitstop>0:
		hitstop=maxf(0,hitstop-delta)
		return
	elapsed+=delta
	attack_wait-=delta
	message_left-=delta
	save_wait+=delta
	if attack_wait<=0 and hitstop<=0: auto_attack()
	update_camera(delta)
	update_effects(delta)
	if not vista and player.position.distance_to(Landscape.on_ground(Vector3(120,0,-22)))<4:
		vista=true
		player.hp=5
		notice("물길의 전망 발견 · 체력 회복 · 이 발견은 남습니다")
		save_now()
	if Input.is_action_just_pressed("interact"): open_shortcut()
	if pending_choices()>0: pause_game("첫 강화 · 자동 마법을 골라주세요")
	if save_wait>3:
		save_wait=0
		save_now()
	update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused: resume_game()
		else: pause_game()
		get_viewport().set_input_as_handled()

func update_effects(delta: float) -> void:
	for effect in effects.duplicate():
		effect.time-=delta
		if effect.node.has_method("advance"): effect.node.advance(delta)
		if effect.has("velocity"): effect.node.position+=effect.velocity*delta
		if effect.time<=0:
			effect.node.queue_free()
			effects.erase(effect)

func update_camera(delta: float) -> void:
	# Fixed scale: enemy proximity must never resize the whole world.
	camera.size=22.0
	var center:=Vector3(clampf(player.position.x,108,132),Landscape.height_at(player.position)+0.5,clampf(player.position.z-2,-29,10))
	camera.position=camera.position.lerp(center+Vector3(0,26,20.3),1.0-exp(-delta*8.0))
	camera.rotation_degrees=Vector3(-52,0,0)

func enemy_defeated(enemy: Node3D) -> void:
	preload("res://game/combat_effect.gd").spawn(self,"defeat",enemy.position,Vector3.ZERO,1,Color("ffcf87"))
	kills+=1
	var group:=int(int(enemy.stable_id.trim_prefix("lab_"))/4)
	var alive:=enemies().any(func(e): return int(int(e.stable_id.trim_prefix("lab_"))/4)==group)
	if not alive and not group in cleared:
		cleared.append(group)
		player.hp=mini(5,player.hp+1)
		notice("무리를 정리했습니다 · 잠시 둘러보세요 · 처치와 성장은 저장됩니다")
	if kills==8:notice("Lv.3 응축 마법 · 넓은 마무리타 / 자동 4회 적중마다 폭발")
	save_now()

func open_shortcut() -> bool:
	if flat or shortcut or player.position.distance_to(Landscape.on_ground(Vector3(120,0,-13)))>=3: return false
	shortcut=true
	apply_shortcut()
	notice("아래뜰로 돌아가는 물길 개방 · 다음에도 열린 채로 남습니다")
	save_now()
	return true

func apply_shortcut() -> void:
	if shortcut and is_instance_valid(shortcut_body):
		shortcut_body.queue_free()
		shortcut_body=null

func pending_choices() -> int:
	return 1 if kills>=4 and choices_claimed==0 else 0

func available_upgrades() -> Array: return ["split","chain"]

func snapshot() -> Dictionary:
	var records: Array=[]
	for enemy in enemies(): records.append({"id":enemy.stable_id,"p":[enemy.position.x,enemy.position.y,enemy.position.z],"hp":enemy.hp,"role":enemy.role})
	return {"schema":2,"lab_revision":2,"flat":flat,"player":[player.position.x,player.position.y,player.position.z],"hp":player.hp,"enemies":records,"kills":kills,"upgrades":upgrades,"choices":choices_claimed,"shortcut":shortcut,"vista":vista,"cleared":cleared,"auto_hits":auto_hits}

func restore(data: Dictionary) -> void:
	var p: Array=data.player
	player.position=Landscape.on_ground(Vector3(clampf(float(p[0]),101,139),0,clampf(float(p[2]),-31,13)),0.1)
	player.hp=clampi(int(data.get("hp",5)),1,5)
	player.invulnerability=2
	kills=int(data.get("kills",0))
	auto_hits=maxi(0,int(data.get("auto_hits",0)))
	upgrades=data.get("upgrades",[]).filter(func(id):return id in ["split","chain"])
	choices_claimed=upgrades.size()
	chain="chain" in upgrades
	shortcut=bool(data.get("shortcut",false))
	vista=bool(data.get("vista",false))
	cleared=data.get("cleared",[])
	apply_shortcut()
	for entry in data.enemies:
		spawn_enemy(entry.id,Landscape.on_ground(Vector3(entry.p[0],0,entry.p[2]),0.1),false,int(entry.hp),entry.role)

func save_now() -> void:
	if test_mode or not is_instance_valid(player): return
	if not is_instance_valid(save_queue):
		save_queue=preload("res://game/save_queue.gd").new()
		add_child(save_queue)
		save_queue.completed.connect(func(error):
			save_error=error!=OK
			if save_error:notice("저장 실패 · 종료 전 저장 공간을 확인해주세요"))
	save_queue.request(snapshot(),save_slot)

func flush_save() -> void:
	if is_instance_valid(save_queue):save_error=save_queue.flush()!=OK

func add_button(text: String, action: Callable) -> Button:
	var button:=Button.new()
	button.text=text
	button.custom_minimum_size=Vector2(510,48)
	buttons.add_child(button)
	button.pressed.connect(action)
	return button

func pause_game(reason: String="잠시 쉬어가기 · 발견과 성장은 남습니다") -> void:
	save_now()
	get_tree().paused=true
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	var title:=Label.new()
	title.text=reason
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	buttons.add_child(title)
	var first: Button
	if pending_choices()>0:
		title.text="Lv.2 · 3연타 습득 / 자동 마법 선택"
		for id in available_upgrades():
			var b:=add_button(UPGRADE_NAMES[id]+" · "+UPGRADE_DESCRIPTIONS[id],func(): choose_upgrade(id); resume_game())
			if first==null:first=b
	else:
		first=add_button("계속 여행하기",resume_game)
		add_button("비교 B · 물길의 단상" if flat else "비교 A · 열린 뜰",switch_mode)
		add_button("이 필드 새 실험 시작",confirm_restart)
	add_button("저장하고 종료",func(): save_now(); quit_if_saved())
	pause_panel.show()
	first.grab_focus()
	update_hud()

func build_landmark() -> void:
	# Closed sanctuary: a solid footprint, with the facade registered at ground contact.
	var base:=Landscape.on_ground(Vector3(123,0,-28))
	var solid:=StaticBody3D.new()
	add_child(solid)
	solid.position=base+Vector3(0,3,0)
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(7.4,6,3.4)
	collision.shape=shape
	solid.add_child(collision)
	var shrine:=Sprite3D.new()
	shrine.texture=preload("res://assets/environment/temple_face_v1.png")
	shrine.shaded=false
	shrine.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR
	shrine.pixel_size=9.0/shrine.texture.get_height()
	shrine.rotation_degrees.x=-52
	shrine.position=base+Vector3(0,cos(deg_to_rad(52)),-sin(deg_to_rad(52)))*4.5+Vector3(0,0.04,1.7)
	add_child(shrine)

func quit_if_saved() -> void:
	flush_save()
	if not save_error:get_tree().quit()

func confirm_restart() -> void:
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	var title:=Label.new()
	title.text="이 필드의 0.3 진행을 처음부터 시작할까요?\n다른 필드와 이전 버전 저장은 그대로입니다."
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	buttons.add_child(title)
	var cancel:=add_button("돌아가기",pause_game)
	add_button("처음부터 시작",func():
		get_tree().set_meta("lab_fresh",true)
		get_tree().paused=false
		get_tree().reload_current_scene())
	cancel.grab_focus()

func resume_game() -> void:
	if pending_choices()>0:return
	get_tree().paused=false
	player.invulnerability=maxf(player.invulnerability,0.8)
	pause_panel.hide()

func switch_mode() -> void:
	save_now()
	flush_save()
	if save_error:return
	get_tree().set_meta("lab_flat",not flat)
	get_tree().paused=false
	get_tree().reload_current_scene()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(pause_panel) and not test_mode and not get_tree().paused: pause_game()
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()
		flush_save()
		if save_error:pause_game("저장 실패 · 진행을 보존하려면 재시도해주세요")
		else:get_tree().quit()

func storage_key(field:String) -> String:return "user://%s_v4.json"%field
func allow_legacy_import() -> bool:return false
func populate_field() -> void:
	for i in range(SPAWNS.size()): spawn_enemy("lab_%02d"%i,Landscape.on_ground(SPAWNS[i],0.1),false,12,"charger" if i%4==3 else "wanderer")
