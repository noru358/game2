extends RefCounted
const Land = preload("res://game/landscape.gd")
const V = preload("res://game/visuals.gd")
const SITES := {
	"threshold":{"name":"거대 저수전 · 남쪽 회랑","at":Vector3(28,0,-90)},
	"court":{"name":"갈라진 집수정","at":Vector3(28,0,-116)},
	"inscription":{"name":"덧새긴 봉인","at":Vector3(28,0,-124)}
}
const NOTES := {
	"threshold":"작은 수문 뒤로 거대한 저수벽이 드러난다. 바깥으로 물을 나르던 수로들이 이곳에서 갈라진다. 남쪽 회랑의 마른 자리에 돌아올 발판을 마련했다.",
	"court":"중앙 집수정을 사이에 두고 두 점검 회랑이 만난다. 안쪽 벽의 오래된 눈금 위로, 마모되지 않은 선이 덧새겨져 있다. 물을 다루던 시설에 누군가 다른 용도를 겹쳤다.",
	"inscription":"오래된 수위 눈금을 가로질러 새 술식이 덧새겨져 있었다. 손의 맥박은 그 선에 반응했다. 표면의 연결선을 끊자 이 벽의 반응만 꺼졌다. 몸의 변화는 남아 있다.\n\n돌에서 떼어 낸 봉인편을 확보했다. 이것은 우연한 병의 흔적이 아니다. 누군가 기존 시설을 이용해 연결을 만들었다. 그 주인의 정체와 근원은 아직 모른다."
}
const COURT_PACK=[Vector2(20.5,-115.8),Vector2(23,-117),Vector2(21.8,-119.9),Vector2(33,-118),Vector2(35.3,-116.5),Vector2(32.8,-121.3)]
const LEFT_GALLERY=[Vector2(13.4,-97.6),Vector2(15.7,-98.8),Vector2(14.6,-101.1),Vector2(17.1,-100.3)]
var world: Node3D
var discovered: Array = []
var entered: Array = []
var studied := false
var entrance: Node3D
var entrance_open := false
var marks: Array[Node3D] = []

func _init(owner: Node3D) -> void: world=owner

func build() -> void:
	Land.make_terrain(world,Rect2(-8,-134,60,48))
	for x in [-8,52]:
		for z in range(-133,-85,2):
			masonry(Land.on_ground(Vector3(x,0,z),1.1),Vector3(0.8,2.2,2),Color("675744"),true)
	masonry(Land.on_ground(Vector3(22,0,-134),1.1),Vector3(59.2,2.2,0.8),Color("675744"),true)
	entrance=V.stone_box(world,Land.on_ground(Vector3(28,0,-86),1.6),Vector3(7.2,3.2,0.5),Color("746149"),true)
	# One large silhouette, side galleries, and a clear central obstruction shape the space.
	for x in [10,46]:
		masonry(Land.on_ground(Vector3(x,0,-120),4.5),Vector3(3.4,9,22),Color("76644e"),true)
		masonry(Land.on_ground(Vector3(x,0,-120),9.35),Vector3(4.1,0.7,22.6),Color("a18b64"))
	masonry(Land.on_ground(Vector3(28,0,-130),5.8),Vector3(32.6,11.6,2.0),Color("76644e"),true)
	masonry(Land.on_ground(Vector3(28,0,-130),12),Vector3(34,0.8,2.8),Color("a18b64"))
	for x in [16,22,28,34,40]:
		masonry(Land.on_ground(Vector3(x,0,-128.8),5.4),Vector3(1.0,10.8,0.35),Color("9e8460"))
		for y in [2.0,4.0,6.0,8.0]:
			masonry(Land.on_ground(Vector3(x,0,-128.57),y),Vector3(0.7,0.18,0.08),Color("c8b587"))
	# Open cistern: water remains in the terrain shader, walls make it non-traversable.
	for x in [20.4,35.6]:
		masonry(Land.on_ground(Vector3(x,0,-105),1.15),Vector3(0.8,2.3,12),Color("7e8066"),true)
	for z in [-110.6,-99.4]:
		masonry(Land.on_ground(Vector3(28,0,z),1.15),Vector3(14.4,2.3,0.8),Color("7e8066"),true)
	for x in [14,42]:
		for z in [-96,-102,-108,-114]:
			Land.paving(world,Vector3(x,0,z),Vector2(3.2,1.8),Land.PAVING_LIFT,Color("9c9278"))
	for z in [-84,-88,-92,-116,-120,-124]:
		Land.paving(world,Vector3(28,0,z),Vector2(3.8,1.7),Land.PAVING_LIFT,Color("9c9278"))
	for x in [19,37]:
		for z in [-94,-118]:
			V.tropical_prop(world,Land.on_ground(Vector3(x,0,z)),1,2.4)
	for p in [Vector3(-3,0,-95),Vector3(49,0,-93),Vector3(1,0,-124)]:
		V.tropical_prop(world,Land.on_ground(p),0,8.5)
	V.tropical_prop(world,Land.on_ground(Vector3(34,0,-89)),3,3.2)
	# The recent inscription is a separate vertical face, standing clear of the rear wall.
	masonry(Land.on_ground(Vector3(28,0,-125.5),1.8),Vector3(4.6,3.6,0.65),Color("4d5c53"),true)
	for radius in [0.55,1.05,1.5]:
		var ring:=V.ring(world,Land.on_ground(Vector3(28,0,-125.1),1.9),radius,Color("dda9bd"))
		ring.rotation.x=PI/2
		ring.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		ring.material_override.emission_enabled=false
		marks.append(ring)
	for id in SITES:
		var label:=Label3D.new()
		var font := preload("res://assets/fonts/NanumGothic-Regular.ttf")
		label.font=font
		label.text=SITES[id].name
		label.font_size=36
		label.pixel_size=0.012
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.position=Land.on_ground(SITES[id].at)+Vector3(0,0.6157,-0.788)*3.8
		world.add_child(label)
		label.add_to_group("place_captions")

func masonry(at: Vector3,size: Vector3,color: Color,solid: bool=false) -> Node3D:
	return V.stone_box(world,at,size,color,solid)

func refresh() -> void:
	entrance_open=entrance_open and world.waterworks.reclaimed
	entrance.visible=not entrance_open
	entrance.get_child(1).set_deferred("disabled",entrance_open)
	for mark in marks: mark.visible=not studied

func populate(id: String) -> void:
	if id in entered: return
	entered.append(id)
	if id=="galleries":
		for x in [14,42]:
			for i in range(4):
				# Left: clustered pack for split/chain. Right: staggered charges with room to sidestep.
				var at := Vector3(LEFT_GALLERY[i].x,0,LEFT_GALLERY[i].y)
				if x==42: at=Vector3(40+(i%2)*3,0,-96-i*3)
				world.spawn_enemy("facility_gallery_%d_%d"%[x,i],Land.on_ground(at),false,12,"charger" if x==42 and i in [1,3] else "wanderer")
	elif id=="court":
		for i in range(6):
			world.spawn_enemy("facility_court_%d"%i,Land.on_ground(Vector3(COURT_PACK[i].x,0,COURT_PACK[i].y)),false,12)
		world.spawn_enemy("facility_keeper",Land.on_ground(Vector3(28,0,-122)),true)
	world.save_now()

func update() -> void:
	if Input.is_action_just_pressed("interact"): interact()
	if not entrance_open or world.player.position.z>=-87: return
	if "threshold" not in discovered and world.player.position.distance_to(Land.on_ground(SITES.threshold.at))<2.8:
		discovered.append("threshold")
		world.player.hp=5
		world.notice("거대 저수전 도착 · 남쪽 회랑에 복귀 지점 확보")
		world.save_now()
	if world.player.position.z < -93: populate("galleries")
	if world.player.position.z < -112:
		populate("court")
		if "court" not in discovered:
			discovered.append("court")
			world.save_now()

func guarded() -> bool:
	return "court" not in entered or world.enemies().any(func(e): return e.stable_id.begins_with("facility_court_") or e.stable_id=="facility_keeper")

func interact() -> bool:
	if not entrance_open:
		if not world.waterworks.reclaimed or world.player.position.distance_to(Land.on_ground(Vector3(28,0,-84)))>=3.0: return false
		entrance_open=true
		refresh()
		world.notice("석판의 개방식으로 회랑 문을 열었습니다 · 거대 저수전으로")
		world.save_now()
		return true
	if studied or not entrance_open or guarded() or world.player.position.distance_to(Land.on_ground(SITES.inscription.at))>=3.0: return false
	studied=true
	discovered.append("inscription")
	world.player.hp=5
	refresh()
	world.notice("봉인편 확보 · 이곳의 연결선 차단 · 기록과 복귀 지점 저장")
	world.save_now()
	return true

func interaction_hint() -> String:
	if world.player.position.z>-82: return ""
	if not entrance_open:
		return "F · 석판의 개방식으로 회랑 문 열기" if world.waterworks.reclaimed else "잠긴 숲의 석판에서 시설로 들어가는 길 확인"
	if world.player.position.distance_to(Land.on_ground(SITES.inscription.at))<4:
		if studied: return "봉인편 확보됨 · Esc에서 조사 기록 다시 읽기"
		return "안쪽 수호자와 무리를 정리한 뒤 봉인 조사" if guarded() else "F · 덧새긴 봉인 조사 / 연결선 끊기"
	return ""

func objective() -> String:
	if studied: return "저수전 조사 완료 · 봉인편 확보 · 남은 회랑 자유 탐험"
	if "court" in discovered: return "저수전 수호자 처치 · 전투 후 봉인 앞에서 F"
	if "threshold" in discovered: return "집수정의 좌우 회랑을 따라 안쪽의 새 흔적 찾기"
	return "수문 북쪽에서 F · 석판의 개방식으로 거대 저수전 진입"

func snapshot() -> Dictionary:
	return {"entrance_open":entrance_open,"discovered":discovered.duplicate(),"entered":entered.duplicate(),"studied":studied}

func restore(data: Variant) -> void:
	discovered=[]
	entered=[]
	studied=false
	entrance_open=false
	if data is Dictionary:
		entrance_open=data.get("entrance_open",false)==true
		if data.get("discovered") is Array:
			for id in data.discovered:
				if id in SITES and id not in discovered: discovered.append(id)
		if data.get("entered") is Array:
			for id in data.entered:
				if id in ["galleries","court"] and id not in entered: entered.append(id)
		studied=data.get("studied",false)==true and "inscription" in discovered and "court" in entered
	refresh()

