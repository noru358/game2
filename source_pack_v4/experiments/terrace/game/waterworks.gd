extends RefCounted
const Land = preload("res://game/landscape.gd")
const V = preload("res://game/visuals.gd")
const SITES := {
	"junction":{"name":"수로 갈림터","at":Vector3(16,0,-42)},
	"overlook":{"name":"붉은 제방 · 관리인 길","at":Vector3(4,0,-62)},
	"water_record":{"name":"잠긴 숲 · 물가 기록","at":Vector3(34,0,-56)},
	"sluice":{"name":"옛 수문 마당","at":Vector3(28,0,-76)}
}
const NOTES := {
	"junction":"같은 마름모 표석 아래 길이 갈라진다. 낮은 길은 물을 나르고, 높은 길은 수로를 살피던 길이다. 두 길 모두 위쪽 수문으로 향한다.",
	"overlook":"붉은 흙으로 쌓은 제방 위에는 비에도 마른 길이 남아 있다. 관리인은 높은 둑을 따라 물높이를 살피고 수문으로 향했다. 아래쪽 나무 밑동의 어두운 선은 지난 우기의 수위다.",
	"water_record":"판처럼 넓은 나무뿌리가 탁한 물을 붙잡고 있다. 물속으로 이어지는 돌길은 지금 건널 수 없다. 석판의 화살표는 상류 수문을 가리킨다. 물길을 바꾸면 이곳에 무엇이 드러날까?",
	"sluice":"높은 관리인 길과 낮은 운반길이 이 마당에서 만난다. 멈춘 수문 너머로 더 오래된 시설이 이어진다. 마른 마당에 다음 탐험을 위한 자리를 마련했다."
}
var world: Node3D
var discovered: Array = []
var populated := false
var markers := {}
var terrain: MeshInstance3D
var sluice_open := false
var reclaimed := false
var basin_block: StaticBody3D
var causeway: Array[MeshInstance3D] = []
var shutter: Node3D
var operating_wheel: MeshInstance3D
var hoist: Node3D
const GATE_LIFT := 5.8
var water_level := 0.0
const CACHE_AT := Vector3(44,0,-72)
var weave := ""
var charge := 0
var return_shots := 0
const NOTE_AT := Vector3(42,0,-70)
var notebook: Node3D
var note_recovered := false
const NOTE_BODY := "비에 불은 장부에는 사람들의 이름이 먼저 적혀 있었다.\n\n‘아래 마을의 물독부터 채울 것. 운반꾼이 돌아오기 전에는 낮은 길로 물을 보내지 말 것.’\n\n수로를 관리하던 사람은 물의 양만 적지 않았다. 누가 언제 이 길을 지나는지도 살폈다. 이곳은 누군가의 생활을 이어 주던 길이었다.\n\n남은 장을 말려 챙겼다. 이 장부만으로 관리인의 행방이나 시설이 멈춘 이유까지 알 수는 없다."
const WEAVES := {"reserve":"모아치는 손", "return":"되돌아오는 빛"}
func _init(owner: Node3D) -> void: world = owner
func ground(at: Vector3,lift: float=0.0) -> Vector3:
	return Land.on_ground(Land.expand_old_waterworks(at),lift)

func build() -> void:
	terrain=Land.make_terrain(world,Rect2(-8,-86,60,48))
	for x in [-8,52]:
		for z in range(-85,-37,2):
			Land.masonry(world,Land.on_ground(Vector3(x,0,z),0.65),Vector3(0.8,1.3,2),Color("705344"),true)
	for info in [[8.4,32.0],[41.6,20.0]]:
		Land.masonry(world,Land.on_ground(Vector3(info[0],0,-86),0.65),Vector3(info[1],1.3,0.8),Color("705344"),true)
	for info in [[2.7,20.6],[35.3,32.6]]:
		Land.masonry(world,Land.on_ground(Vector3(info[0],0,-38),0.65),Vector3(info[1],1.3,0.8),Color("705344"),true)
	var stones: Array[Vector3] = []
	for route in [Land.LOW_ROUTE,Land.HIGH_ROUTE]:
		for i in range(route.size()-1):
			var a: Vector3 = route[i]
			var b: Vector3 = route[i+1]
			var count := maxi(1,int(a.distance_to(b)/1.7))
			for step in range(count):
				var p := a.lerp(b,float(step)/count)
				if p.z > -38: continue
				var clear := true
				for old in stones:
					if old.distance_to(p)<1.4: clear=false
				if not clear: continue
				stones.append(p)
				Land.paving(world,p,Vector2(1.1,0.6),Land.PAVING_LIFT,Color("84907a"))
	# A ruined middle terrace separates the two routes without closing either entrance.
	for z in range(-52,-44,2):
		Land.masonry(world,ground(Vector3(18,0,z),1.0),Vector3(5.2,2.0,3.6),Color("895f44"),true)
		V.tropical_prop(world,ground(Vector3(18,0,z),2.05),1,1.2)
	for p in [Vector3(6,0,-41),Vector3(6,0,-49),Vector3(7,0,-56),Vector3(31,0,-42),Vector3(32,0,-54),Vector3(29,0,-60)]:
		V.tropical_prop(world,ground(p),0,8.5)
	# A working gatehouse spans the watercourse; its scale is independent of map markers.
	for x in [22.0,34.0]:
		preload("res://game/sluice_masonry.gd").tower(world,x)
	# Rear lintel leaves the forward winding shaft visible below the tower caps.
	Land.masonry(world,Land.on_ground(Vector3(28,0,-82.3),12.1),Vector3(17.6,1.2,1.4),Color("8b7658"))
	shutter=V.stone_box(world,Land.on_ground(Vector3(28,0,-81),2.7),Vector3(6.8,5.4,0.65),Color("58685e"))
	for x in [26.0,30.0]:
		V.box(shutter,Vector3(x-28,0,0.38),Vector3(0.18,5.0,0.12),Color("494a3c"))
	hoist=preload("res://game/sluice_hoist.gd").new()
	world.add_child(hoist)
	hoist.position=Land.on_ground(Vector3(28,0,-81))
	hoist.build(shutter)
	Land.masonry(world,Land.on_ground(Vector3(26.3,0,-77.4),0.75),Vector3(0.8,1.5,0.8),Color("897555"),true)
	operating_wheel=MeshInstance3D.new()
	var wheel_shape:=TorusMesh.new()
	wheel_shape.inner_radius=0.53
	wheel_shape.outer_radius=0.72
	operating_wheel.mesh=wheel_shape
	operating_wheel.material_override=V.material(Color("c4a16b"))
	operating_wheel.position=Land.on_ground(Vector3(26.3,0,-77.4),1.65)
	operating_wheel.rotation.x=PI/2
	world.add_child(operating_wheel)
	for angle in [0.0,PI/3,PI*2/3]:
		var spoke:=V.box(operating_wheel,Vector3.ZERO,Vector3(1.1,0.12,0.1),Color("c4a16b"))
		spoke.rotation.y=angle
	V.tropical_prop(world,Land.on_ground(Vector3(38,0,-79)),3,3.8)
	for z in [-48,-55,-63,-71]:
		V.tropical_prop(world,Land.on_ground(Vector3(-3,0,z)),0,9.0)
		V.tropical_prop(world,Land.on_ground(Vector3(49,0,z-3)),1,3.3)
	for p in [Vector3(41,0,-55),Vector3(47,0,-58),Vector3(48,0,-69),Vector3(43,0,-78)]:
		V.tropical_prop(world,Land.on_ground(p),1,2.8)
	# Water owns one opaque terrain surface; only the traversal blocker changes.
	basin_block=V.box(world,Vector3(Land.FLOOD_CENTER.x,0,Land.FLOOD_CENTER.y),Vector3(14,20,22),Color.TRANSPARENT,true)
	basin_block.get_child(0).hide()
	var flood_shape:=ConvexPolygonShape3D.new()
	var outline:=PackedVector3Array()
	for i in range(48):
		var angle:=TAU*i/48.0
		for y in [0.0,20.0]:outline.append(Vector3(cos(angle)*Land.FLOOD_RADII.x,y,sin(angle)*Land.FLOOD_RADII.y))
	flood_shape.points=outline
	basin_block.get_child(1).shape=flood_shape
	for z in range(-54,-72,-2):
		var slab:=Land.paving(world,Vector3(44,0,z),Vector2(3.0,0.8),Land.PAVING_LIFT,Color("a08058"))
		causeway.append(slab)
	var landing:=Land.paving(world,CACHE_AT,Vector2(4,4),Land.PAVING_LIFT,Color("a08058"))
	causeway.append(landing)
	var relic:=V.stone_box(world,Land.on_ground(CACHE_AT,0.75),Vector3(0.65,1.3,0.3),Color("b9a078"))
	relic.set_meta("relic",true)
	notebook=Node3D.new()
	world.add_child(notebook)
	notebook.position=Land.on_ground(NOTE_AT,0.12)
	notebook.quaternion=Quaternion(Vector3.UP,Land.normal_at(NOTE_AT))
	V.box(notebook,Vector3(0,0.10,0),Vector3(0.85,0.12,1.05),Color("623e2d"))
	V.box(notebook,Vector3(0,0.20,0),Vector3(0.73,0.08,0.93),Color("d4c79c"))
	V.box(notebook,Vector3(-0.30,0.26,0),Vector3(0.12,0.03,0.98),Color("87513a"))
	V.ring(notebook,Vector3(0,0.30,0),0.8,Color("efce8c"))
	apply_sluice_state(true)
	for id in SITES:
		var at := Land.on_ground(SITES[id].at)
		markers[id] = V.ring(world,at+Vector3.UP*Land.MARKER_LIFT,1.0,Color("efce8c"))
		markers[id].hide()
		markers[id].quaternion = Quaternion(Vector3.UP,Land.normal_at(at))
		var label := Label3D.new()
		var font := preload("res://assets/fonts/NanumGothic-Regular.ttf")
		label.font = font
		label.text = SITES[id].name
		label.font_size = 36
		label.pixel_size = 0.012
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = at+Vector3(0,0.6157,-0.788)*2.7
		world.add_child(label)
		label.add_to_group("place_captions")
func populate() -> void:
	if populated: return
	populated = true
	for i in range(6):
		var p := Vector3(32+(i%2)*2,0,-50-int(i/2)*5)
		world.spawn_enemy("waterworks_low_%d"%i,p,false,12,"charger" if i==3 else "wanderer")
	for i in range(3):
		world.spawn_enemy("waterworks_high_%d"%i,Land.expand_old_waterworks(Vector3(10+(i%2)*2,0,-46-i*3)),false,12,"wanderer" if i==1 else "caster")
	world.spawn_enemy("waterworks_keeper",Land.expand_old_waterworks(Vector3(22,0,-55)),true,60)
func update(delta: float=1.0/60.0) -> void:
	water_level=move_toward(water_level,1.0 if sluice_open else 0.0,delta*0.5)
	update_gate_visuals()
	if not world.opened: return
	if Input.is_action_just_pressed("interact"): interact()
	if world.player.position.z < -38: populate()
	for id in SITES:
		if id in discovered: continue
		if world.player.position.distance_to(Land.on_ground(SITES[id].at)) >= 4.5: continue
		if id=="sluice" and (world.enemies().any(func(e): return e.stable_id=="waterworks_keeper") or threatened_at(SITES.sluice.at)): continue
		discovered.append(id)
		refresh()
		if id=="sluice":
			world.player.hp=5
			world.notice("옛 수문 마당 발견 · 체력 회복 · 새로운 복귀 지점 기록")
		else:
			world.notice(SITES[id].name+" 발견 · 기록은 Esc에서 확인")
		world.save_now()
func interaction_hint() -> String:
	if sluice_open and not reclaimed and near_cache():
		return "석판 주변의 적을 정리한 뒤 조사" if threatened_at(CACHE_AT) else "F · 석판의 개방식 읽기 · 저수전으로 가는 단서"
	if sluice_open and not note_recovered and world.player.position.distance_to(Land.on_ground(NOTE_AT))<3:
		return "주변 위협을 정리한 뒤 수첩 조사" if note_threatened() else "F · 물에 젖은 수첩 건져 올리기"
	if world.player.position.distance_to(Land.on_ground(SITES.sluice.at))<3.5:
		if reclaimed: return "수문 북쪽 문 앞에서 F · 석판의 개방식 사용"
		if sluice_open: return "수문 개방됨 · 잠긴 숲으로 돌아가 드러난 석길 탐험"
		return "주변 위협을 정리한 뒤 권양기 조작" if threatened_at(SITES.sluice.at) else ("F · 권양기를 돌려 수문 들어 올리기" if "sluice" in discovered else "수문 수호자를 쓰러뜨린 뒤 마당으로")
	if not sluice_open and world.player.position.distance_to(Land.on_ground(SITES.water_record.at))<4: return "앞의 석길은 물에 잠겼습니다 · 상류 수문에서 물길 조절"
	if not sluice_open and world.player.position.distance_to(Land.on_ground(SITES.junction.at))<5:
		return "왼쪽 제방 · 원거리 시전자 / 오른쪽 물가 · 추격과 돌진 · 두 길 모두 수문으로"
	return ""
func interact() -> bool:
	if sluice_open and not reclaimed and near_cache():
		if threatened_at(CACHE_AT): return false
		reclaimed=true
		world.notice("개방식을 읽었다 · 수문 북쪽 문에서 F로 사용")
		world.sound("reward")
		world.save_now()
		return true
	if sluice_open and not note_recovered and world.player.position.distance_to(Land.on_ground(NOTE_AT))<3:
		if note_threatened(): return false
		note_recovered=true
		notebook.hide()
		world.notice("관리인의 수첩 회수 · 물길을 기다리던 사람들의 기록 · Esc → 탐험 기록")
		world.message_left=10.0
		world.sound("reward")
		world.save_now()
		return true
	if sluice_open or not "sluice" in discovered or world.player.position.distance_to(Land.on_ground(SITES.sluice.at))>=3.5 or threatened_at(SITES.sluice.at): return false
	sluice_open=true
	apply_sluice_state(false)
	# Once-only inhabitants of the newly exposed route; saved as living enemies.
	for i in range(4):
		world.spawn_enemy("reclaimed_path_%d"%i,Land.on_ground(Vector3(42.5+(i%2)*3,0,-66-int(i/2)*3)),false,12,"charger" if i==3 else "wanderer")
	world.notice("수문을 열었습니다 · 잠긴 숲의 물이 빠지고 옛 석길이 드러납니다")
	world.save_now()
	return true
func apply_sluice_state(immediate: bool) -> void:
	if immediate: water_level=1.0 if sluice_open else 0.0
	update_gate_visuals()
	if is_instance_valid(basin_block): basin_block.get_child(1).set_deferred("disabled",sluice_open)
	for slab in causeway: slab.visible=sluice_open
	if is_instance_valid(notebook): notebook.visible=sluice_open and not note_recovered

func update_gate_visuals() -> void:
	terrain.material_override.set_shader_parameter("drained",water_level)
	shutter.position.y=Land.height_at(Vector3(28,0,-81))+2.7+water_level*GATE_LIFT
	operating_wheel.quaternion=Quaternion(Vector3.RIGHT,PI/2)*Quaternion(Vector3.UP,water_level*TAU*2)
	hoist.set_progress(water_level)

func near_cache() -> bool:
	return world.player.position.distance_to(Land.on_ground(CACHE_AT)) < 3.0

func threatened_at(at: Vector3) -> bool:
	var center := Land.on_ground(at,0.1)
	return world.enemies().any(func(e): return not e.dead and e.position.distance_to(center)<8.0 and world.visible_target(e,center))

func note_threatened() -> bool:
	return world.enemies().any(func(e): return e.position.distance_to(world.player.position)<8.0)

func records() -> Array:
	return [{"title":"물길을 기다리던 사람들","body":NOTE_BODY,"region":"잠긴 숲 · 관리인의 수첩"}] if note_recovered else []
func refresh() -> void:
	for id in markers: markers[id].material_override.albedo_color=Color("8ad6c0") if id in discovered else Color("efce8c")
func restore(data: Variant) -> void:
	discovered=[]
	populated=false
	weave=""
	charge=0
	return_shots=0
	sluice_open=false
	reclaimed=false
	note_recovered=false
	if data is Dictionary:
		populated=data.get("populated",false)==true
		if data.get("discovered") is Array:
			for id in data.discovered:
				if id is String and id in SITES and not id in discovered: discovered.append(id)
		if (data.get("level_growth",false) or ("sluice" in discovered and discovered.size()>=3)) and data.get("weave","") in WEAVES:
			weave=data.weave
			charge=clampi(int(data.get("charge",0)),0,6) if weave=="reserve" else 0
			return_shots=clampi(int(data.get("return_shots",0)),0,3) if weave=="return" else 0
		sluice_open=data.get("sluice_open",false)==true and "sluice" in discovered
		reclaimed=sluice_open and data.get("reclaimed",false)==true
		note_recovered=sluice_open and data.get("note_recovered",false)==true
	apply_sluice_state(true)
	refresh()
func snapshot() -> Dictionary:
	return {"level_growth":true,"note_recovered":note_recovered,"layout_revision":4,"sluice_open":sluice_open,"reclaimed":reclaimed,"populated":populated,"discovered":discovered.duplicate(),"weave":weave,"charge":charge,"return_shots":return_shots}

func safe_restored_position(at:Vector3,revision:int)->Vector3:
	if revision<4 and not sluice_open and Land.in_flood(at,0.6):return Land.on_ground(Vector3(33,0,clampf(at.z,-74,-54)),0.1)
	if revision<4 and absf(at.x-26.3)<0.9 and absf(at.z+77.4)<0.9:return Land.on_ground(SITES.sluice.at,0.1)
	if revision>=3:return at
	var in_tower:=at.z>=-83.5 and at.z<=-77.8 and ((at.x>=19 and at.x<=25) or (at.x>=31 and at.x<=37))
	var in_wheel:=absf(at.x-26.3)<0.9 and absf(at.z+76)<0.9
	return Land.on_ground(SITES.sluice.at,0.1) if in_tower or in_wheel else at
func journal_text() -> String:
	var result := "\n수로 탐험 %d/4\n"%discovered.size()
	for id in discovered: result+="\n%s — %s\n"%[SITES[id].name,NOTES[id]]
	if not weave.is_empty(): result+="\n마법 엮기: "+WEAVES[weave]+" · "+weave_status()+"\n"

	return result
func can_weave() -> bool:
	return world.pending_choices()>0 and "reserve" in world.available_upgrades()
func choose_weave(id: String) -> bool:
	return world.choose_upgrade(id) if id in WEAVES else false

func auto_bonus() -> int:
	return 2 if weave=="return" and return_shots>0 else 0
func on_auto_hit() -> void:
	if weave=="reserve": charge=mini(6,charge+1)
	if weave=="return": return_shots=maxi(0,return_shots-1)
func manual_bonus() -> int:
	return 8 if weave=="reserve" and charge==6 else 0
func on_manual_hit() -> void:
	if weave=="reserve" and charge==6:
		charge=0
		world.notice("모아치는 손 · 저장한 빛을 J에 실었습니다")
	if weave=="return": return_shots=3
func weave_status() -> String:
	if weave=="reserve": return "J 강화 준비 완료 · 필요할 때 사용" if charge==6 else "자동 공격으로 빛 모으기 %d/6"%charge
	if weave=="return": return "J 적중 후 자동탄 강화 %d/3 · 시간 제한 없음"%return_shots
	return ""
func objective() -> String:
	if not sluice_open and "sluice" in discovered: return "수문 마당에서 F · 물길을 바꾸고 잠긴 숲의 석길 열기"
	if sluice_open and not reclaimed: return "드러난 석길 조사 · 적을 정리한 뒤 끝의 석판에서 F"
	if reclaimed:
		return "개방식 확보 · 수문 북쪽 문 앞에서 F · 거대 저수전 진입"
	if "sluice" in discovered: return "옛 수문에 도착했습니다 · 남은 옆길과 기록을 탐험하세요 (%d/4)"%discovered.size()
	return "상류 수문으로 · 왼쪽 제방 또는 오른쪽 물가로 진행"

