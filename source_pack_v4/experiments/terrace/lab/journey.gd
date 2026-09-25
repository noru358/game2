extends "res://lab/world.gd"
## Three persistent places, traversable both ways. Combat time is never a gate.
const TITLES=["물길 입구","뿌리의 단상","얼굴 사원"]
const NOTES=["몸의 맥동이 이 물길을 따라 이어진다.","뿌리 아래 돌에 같은 흔적이 남아 있다.","사원의 흔적은 더 먼 곳을 가리킨다."]
const CLUES=[Vector3(134,0,4),Vector3(105,0,-12)]
const EXIT=Vector3(110,0,-29)
const ENTRY=Vector3(110,0,10)
const LOOKOUT=Vector3(128,0,-28)
var chapter:=0
var chapters:Dictionary={}
var discoveries:Array=[]
var guard_down:=false
var finished:=false
var journey_seconds:=0.0
var travel_lock:=0.0
func storage_key(_field:String) -> String:return "user://journey_v2.json"
func build_hud() -> void:
	super.build_hud()
	status.get_parent().hide()
	var compact:=preload("res://lab/compact_hud.gd").new()
	compact.world=self
	hud.add_child(compact)
func _ready() -> void:
	var data:Dictionary=get_tree().get_meta("journey_restore",{})
	if not "--test" in OS.get_cmdline_user_args() and not get_tree().get_meta("lab_fresh",false):data=Store.read_data(storage_key(""))
	chapter=clampi(int(data.get("chapter",0)),0,2)
	chapters=data.get("chapters",{})
	get_tree().set_meta("lab_flat",chapter==0)
	super._ready()
	if "--test" in OS.get_cmdline_user_args() and not data.is_empty():restore(data)
	notice(NOTES[chapter]+" · F로 흔적 조사 / 위쪽 길로 전진")
func build_world() -> void:
	Landscape.lab_region=chapter
	super.build_world()
	preload("res://lab/routes.gd").build(self,chapter)
	preload("res://lab/thresholds.gd").build(self,chapter)
	# Region-specific foreground composition, kept outside traversal lanes.
	if chapter==0:
		pass # The reservoir banks are built by Routes.
	elif chapter==1:
		for p in [Vector3(103,0,-3),Vector3(137,0,-12),Vector3(106,0,-28)]:V.tropical_prop(self,Landscape.on_ground(p),0,10.0)
	else:
		for x in [106.0,135.0]:
			for z in [-3.0,-12.0]:V.carved_waystone(self,Landscape.on_ground(Vector3(x,0,z)),4.8)
	for i in range(CLUES.size()):
		V.carved_waystone(self,Landscape.on_ground(CLUES[i]),2.5)
		var label:=Label3D.new()
		label.text="흔적 · F"
		label.font_size=30
		label.pixel_size=0.014
		label.position=Landscape.on_ground(CLUES[i],3.0)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
	if chapter==1:
		var label:=Label3D.new()
		label.font=preload("res://assets/fonts/NanumGothic-Regular.ttf")
		label.text="숲 너머 · F"
		label.font_size=27
		label.pixel_size=0.012
		label.position=Landscape.on_ground(LOOKOUT,1.1)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
func build_landmark() -> void:
	if chapter==2:
		super.build_landmark()
		Landscape.paving(self,Vector3(123,0,-26),Vector2(8.2,4.0),Landscape.PAVING_LIFT,Color("9e947b"))
		for x in [105.0,135.0]:
			V.stone_box(self,Landscape.on_ground(Vector3(x,0,-21),0.45),Vector3(2.5,0.9,5.2),Color("7e826f"),true)
	else:
		var base:=Landscape.on_ground(Vector3(123,0,-28))
		V.tropical_prop(self,base,0,11.0) if chapter==1 else V.carved_waystone(self,base,5.5)
func populate_field() -> void:
	for group in range(3):
		var center:Vector3=[Vector3(110,0,0),Vector3(132,0,-12),Vector3(114,0,-23)][group]
		if chapter==1 and group==0:center.z=1.5
		for i in range(8):
			var at:=center+Vector3((i%3-1)*1.8+sin(i*2.4)*0.5,0,(int(i/3)-1)*1.7+cos(i*1.9)*0.6)
			var role:="caster" if chapter>0 and i==7 else ("charger" if i%4==3 else "wanderer")
			var enemy:=spawn_enemy("journey_%d_%d"%[group,i],Landscape.on_ground(at,0.1),false,[20,30,40][chapter],role)
			enemy.max_hp=enemy.hp
	var guard:=spawn_enemy("journey_guard",Landscape.on_ground(Vector3(130,0,-23) if chapter==1 else Vector3(125,0,-22),0.1),true,[90,140,200][chapter])
	guard.max_hp=guard.hp
	configure_guard(guard)
	call_deferred("settle_restored_position")
func attack_profile() -> Dictionary:
	var result:=Growth.profile(mini(int(kills/3),8))
	if chapter==2 and 0 in discoveries:
		result.damage=result.damage.map(func(value):return value+2)
	return result
func update_hud() -> void:
	status.text="  "+"● ".repeat(player.hp)+"○ ".repeat(5-player.hp)+"\n  "+TITLES[chapter]
	var hint:=""
	if near_threshold(EXIT):
		hint="F · 여정을 마무리하기" if chapter==2 else "F · 다음 장소로 이동"
		if not guard_down:hint="앞을 지키는 강적을 쓰러뜨리세요"
		elif discoveries.size()<2:hint="남은 흔적을 찾아보세요 · 아래 오른쪽 / 중간 왼쪽"
	elif chapter>0 and near_threshold(ENTRY):hint="F · 이전 장소로 돌아가기"
	for i in range(CLUES.size()):
		if player.position.distance_to(Landscape.on_ground(CLUES[i]))<3:hint="이미 살펴본 흔적" if i in discoveries else "F · 흔적 살피기 / 체력 회복"
	if chapter==1 and player.position.distance_to(Landscape.on_ground(LOOKOUT))<3:hint="숲의 숨결을 익힌 곳" if vista else "F · 숲 너머 살피기"
	if message_left>0:hint=message+"\n"+hint
	prompt.text=hint
func _physics_process(delta:float) -> void:
	super._physics_process(delta)
	journey_seconds+=delta
	travel_lock=maxf(0,travel_lock-delta)
	if Input.is_action_just_pressed("interact") and travel_lock<=0:interact_journey()
func interact_journey() -> void:
	if chapter==1 and player.position.distance_to(Landscape.on_ground(LOOKOUT))<3:
		if not vista:
			vista=true
			notice("숲의 숨결을 익혔다 · 앞으로 회피를 더 자주 쓸 수 있습니다")
			save_now()
		return
	for i in range(CLUES.size()):
		if player.position.distance_to(Landscape.on_ground(CLUES[i]))<3:
			if not i in discoveries:
				discoveries.append(i)
				player.hp=5
				if chapter==1 and i==1:
					shortcut=true
					apply_shortcut()
				notice(discovery_text(i))
				save_now()
			return
	if near_threshold(EXIT) and guard_down and discoveries.size()==2:
		if chapter<2:travel(chapter+1)
		else:
			finished=true
			save_now()
			pause_game("이번 여정 완료 · %d분 %02d초\n찾은 힘과 길은 남습니다. 다음 여행은 이 흔적 너머로 이어집니다."%[int(journey_seconds)/60,int(journey_seconds)%60])
	elif chapter>0 and near_threshold(ENTRY):travel(chapter-1)
func near_threshold(at:Vector3) -> bool:
	return absf(player.position.x-at.x)<1.9 and absf(player.position.z-at.z)<1.6 and absf(player.position.y-Landscape.height_at(at))<1
func enemy_defeated(enemy:Node3D) -> void:
	kills+=1
	preload("res://game/combat_effect.gd").spawn(self,"defeat",enemy.position,Vector3.ZERO,1,Color("ffcf87"))
	if enemy.stable_id=="journey_guard":
		guard_down=true
		player.hp=5
		notice("길을 지키던 강적이 쓰러졌습니다 · 흔적을 살핀 뒤 위쪽 길로")
	elif kills%4==0:player.hp=mini(5,player.hp+1)
	save_now()
func local_state() -> Dictionary:
	var data:=super.snapshot()
	data["discoveries"]=discoveries.duplicate()
	data["guard_down"]=guard_down
	for entry in data.enemies:entry["elite"]=entry.id=="journey_guard"
	return data
func snapshot() -> Dictionary:
	var data:=local_state()
	data["chapter"]=chapter
	data["chapters"]=chapters.duplicate(true)
	data["journey_seconds"]=journey_seconds
	data["finished"]=finished
	return data
func restore(data:Dictionary) -> void:
	for enemy in enemies():enemy.free()
	super.restore(data)
	discoveries=data.get("discoveries",[])
	guard_down=bool(data.get("guard_down",false))
	journey_seconds=float(data.get("journey_seconds",0))
	finished=bool(data.get("finished",false))
	# Base loader uses generic enemies; restore the saved elite contract explicitly.
	for enemy in enemies():
		if enemy.stable_id=="journey_guard":
			var at:Vector3=enemy.position
			var health:int=enemy.hp
			enemy.free()
			var guard:=spawn_enemy("journey_guard",at,true,health)
			guard.max_hp=[90,140,200][chapter]
			configure_guard(guard)
		else:enemy.max_hp=[20,30,40][chapter]
	call_deferred("settle_restored_position")
func settle_restored_position() -> void:
	# Keep v2 progress; an old position may now lie inside a visible bank.
	await get_tree().physics_frame
	var shape:=CapsuleShape3D.new()
	shape.radius=0.42
	shape.height=1.35
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.collision_mask=1
	query.transform=Transform3D(Basis.IDENTITY,player.position+Vector3.UP*0.7)
	if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
		player.position=checkpoint()
		player.velocity=Vector3.ZERO
		update_camera(1)
	# Old saves and spawn layouts may put surviving enemies on a newly steep face.
	# Preserve identity and health; move only invalid positions to nearby safe ground.
	for enemy in enemies():
		query.transform=Transform3D(Basis.IDENTITY,enemy.position+Vector3.UP*0.7)
		if Landscape.normal_at(enemy.position).y>0.70 and get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():continue
		var found:=false
		for radius in range(1,9):
			for index in range(16):
				var angle:=TAU*index/16.0
				var at:=Landscape.on_ground(enemy.position+Vector3(cos(angle),0,sin(angle))*radius,0.1)
				if at.x<102 or at.x>138 or at.z< -30 or at.z>12 or Landscape.normal_at(at).y<0.70:continue
				query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*0.7)
				if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():continue
				enemy.position=at
				found=true
				break
			if found:break
func travel(next:int) -> void:
	chapters[str(chapter)]=local_state()
	var global_kills:=kills
	var global_upgrades:=upgrades.duplicate()
	var seconds:=journey_seconds
	var shots:=auto_hits
	var was_finished:=finished
	var previous:=chapter
	chapter=next
	flat=chapter==0
	Landscape.lab_flat=flat
	for child in get_children():
		if (child is Node3D or child is WorldEnvironment) and child!=player and child!=camera:
			remove_child(child)
			child.queue_free()
	effects.clear()
	shortcut=false
	vista=false
	guard_down=false
	discoveries=[]
	build_world()
	if chapters.has(str(chapter)):restore(chapters[str(chapter)])
	else:populate_field()
	kills=global_kills
	upgrades=global_upgrades
	choices_claimed=upgrades.size()
	chain="chain" in upgrades
	auto_hits=shots
	finished=was_finished
	journey_seconds=seconds
	player.position=Landscape.on_ground(ENTRY-Vector3(0,0,2) if next>previous else EXIT+Vector3(0,0,2),0.1)
	player.velocity=Vector3.ZERO
	player.hp=5
	player.invulnerability=2
	combat.reset_transient()
	travel_lock=1
	update_camera(1)
	notice(TITLES[chapter]+" · "+NOTES[chapter])
	save_now()
func pause_game(reason:String="잠시 쉬어가기 · 진행은 저장됩니다") -> void:
	super.pause_game(reason)
	if pending_choices()>0:buttons.get_child(0).text="자동 마법 강화 · "+("두 힘 결합" if choices_claimed>0 else "첫 선택")
	for child in buttons.get_children():
		if child is Button and child.text.begins_with("비교"):child.hide()
		if child is Button and child.text=="이 필드 새 실험 시작":child.text="새 여정 시작"
func confirm_restart() -> void:
	super.confirm_restart()
	buttons.get_child(0).text="이번 여정을 처음부터 시작할까요?\n이전 실험본의 저장은 그대로입니다."

func configure_guard(guard:Node3D) -> void:
	if chapter==2:
		guard.keeper=preload("res://game/reservoir_keeper.gd").new(guard)
		guard.keeper.label.text="사원 앞 변이체"
		guard.tree_exiting.connect(guard.keeper.clear_warnings)
func pending_choices() -> int:
	return maxi(0,(2 if kills>=36 else (1 if kills>=12 else 0))-choices_claimed)
func available_upgrades() -> Array:
	return ["split","chain"].filter(func(id):return not id in upgrades)
func on_growth_auto_hit(at:Vector3) -> void:
	if int(attack_profile().tier)==2 and auto_hits%4==0:burst_at(at,2.5,3)

func discovery_text(index:int) -> String:
	return [
		["저수지 가장자리 · 물길이 북쪽으로 이어진다. 체력을 회복했다.","물가 쉼터 발견 · 쓰러지면 이곳에서 다시 출발한다."],
		["뿌리 사이의 기록 · 사원으로 향한 흔적을 확인했다.","옛 빗장 해제 · 중앙의 빠른 귀환길을 열었다. 복귀 지점 기록."],
		["석각의 호흡 · 이번 사원에서 직접 마법의 위력 +2.","사원 앞 쉼터 · 최종 마당으로 갈 준비를 마쳤다. 복귀 지점 기록."]
	][chapter][index]
func checkpoint() -> Vector3:
	return Landscape.on_ground(CLUES[1]+Vector3(2,0,0),0.1) if 1 in discoveries else Landscape.on_ground(Vector3(110,0,8),0.1)
func has_windstep() -> bool:
	return (chapter==1 and vista) or bool(chapters.get("1",{}).get("vista",false))
