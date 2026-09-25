extends RefCounted

const V = preload("res://game/visuals.gd")
const Land = preload("res://game/landscape.gd")
const SITES := {
	"rain_path": {"name": "빗물길", "at": Vector3(14, 0, -18)},
	"stone_arch": {"name": "오래된 석문", "at": Vector3(8, 0, -26)},
	"shelter": {"name": "숲속 쉼터", "at": Vector3(14, 0, -32.5)}
}
var world: Node3D
var discovered: Array = []
var markers := {}
var attunement := ""
var shelter_ready := false
var rest_left := 0.0
var rest_origin := Vector3.ZERO
const REST_SECONDS := 1.5
const SHELTER_BODY := Vector3(12.8, 0, -36.1)
const SHELTER_SIZE := Vector3(6.2, 5.0, 2.2)
var shelter_art: Sprite3D
const NOTES := {
	"rain_path": "높은 숲에서 내려온 빗물이 정원으로 흐른다. 젖은 흙에 반쯤 묻힌 포석과 마름모 표석이 물길 옆의 옛길을 가리킨다.",
	"stone_arch": "물길을 건너는 석문 곁에서 인장을 찾았다. 표석과 같은 마름모가 새겨져 있다. 이곳은 수로와 길을 함께 돌보던 사람들의 검문소였던 모양이다.",
	"shelter": "젖은 길보다 높은 둔덕 위에 마른 장작과 접힌 천이 남아 있다. 석문의 관리인들이 쉬던 자리다. 물소리를 따라 내려가면 지나온 관문과 정원으로 돌아갈 수 있다."
}

func _init(owner: Node3D) -> void:
	world = owner

func build() -> void:
	Land.make_terrain(world,Rect2(4,-38,18,24))
	Land.build_connections(world)
	for x in [4,22]:
		for z in range(-37,-13,2):
			Land.masonry(world,Land.on_ground(Vector3(x,0,z),0.7),Vector3(0.9,1.5,2.0),Color("47584b"),true)
	for id in SITES:
		var at: Vector3 = Land.on_ground(SITES[id].at)
		markers[id] = V.discovery_marker(world, at + Vector3.UP * Land.MARKER_LIFT)
		if id == "shelter": markers[id].hide()
		markers[id].quaternion = Quaternion(Vector3.UP,Land.normal_at(at))
		var label := Label3D.new()
		var font := preload("res://assets/fonts/NanumGothic-Regular.ttf")
		label.font = font
		label.text = SITES[id].name
		label.font_size = 42
		label.pixel_size = 0.012
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.render_priority = 20
		label.position = at + Vector3(0, cos(deg_to_rad(52)), -sin(deg_to_rad(52))) * (4.7 if id == "stone_arch" else 3.1)
		if id == "shelter": label.position = Land.on_ground(Vector3(12.8,0,-35)) + Vector3(0,0.616,-0.788) * 6.0
		world.add_child(label)
		label.add_to_group("place_captions")
	for x in [6.2, 9.8]:
		var pillar := V.box(world, Land.on_ground(Vector3(x,0,-26),1.3), Vector3(0.7, 2.6, 0.8), Color("89948a"), true)
		pillar.get_child(0).visible = false
	V.tropical_prop(world, Land.on_ground(Vector3(8,0,-26)), 2, 4.2)
	var shelter_body := V.box(world, Land.on_ground(SHELTER_BODY, SHELTER_SIZE.y * 0.5), SHELTER_SIZE, Color.WHITE, true)
	shelter_body.get_child(0).hide()
	shelter_art = Sprite3D.new()
	shelter_art.texture = preload("res://assets/environment/canal_shelter_v1.png")
	shelter_art.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shelter_art.shaded = false
	shelter_art.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	shelter_art.pixel_size = 5.5 / 978.0
	shelter_art.position = Land.on_ground(Vector3(12.8,0,-35)) + Vector3(0,0.616,-0.788) * ((990.0 - 512.0) * shelter_art.pixel_size)
	world.add_child(shelter_art)
	for i in range(12):
		var x := 5.1 if i % 2 == 0 else 21.0
		var z := -16.5 - (i / 2) * 3.7
		V.tropical_prop(world, Land.on_ground(Vector3(x,0,z)), 0 if i % 3 == 0 else 1, 4.0 if i % 3 == 0 else 1.8)

func update(delta: float = 1.0 / 60.0) -> void:
	var safe:=not threatened()
	for id in markers:
		V.update_discovery_marker(markers[id],world.player.position,world.opened and id != "shelter" and not id in discovered and safe,delta)
	if not world.opened:
		return
	update_rest(delta)
	if Input.is_action_just_pressed("interact"): interact()
	for id in SITES:
		if id in discovered:
			continue
		var at: Vector3 = Land.on_ground(SITES[id].at)
		if world.player.position.distance_to(at) < (3.0 if id == "shelter" else 1.9):
			discovered.append(id)
			refresh()
			if id == "shelter":
				world.notice("숲속 쉼터 발견 · F로 쉬면 체력을 회복하고 복귀 지점을 마련합니다")
			else:
				world.notice("%s 발견 · Esc에서 기록 읽기 (%d/3)" % [SITES[id].name, discovered.size()])
			world.sound("reward")
			world.save_now()

func near_shelter() -> bool:
	return world.opened and world.player.position.distance_to(Land.on_ground(SITES.shelter.at)) < 3.0

func threatened() -> bool:
	return world.enemies().any(func(e): return e.position.distance_to(world.player.position) < 9.0)

func interaction_hint() -> String:
	if not near_shelter(): return ""
	if threatened(): return "주변 위협을 정리한 뒤 쉴 수 있습니다"
	if rest_left > 0: return "숨 고르는 중 · %.1f초 · 이동하면 중단" % rest_left
	if shelter_ready and world.player.hp >= 5: return "정비된 쉼터 · 체력 충만 · 복귀 지점 기록됨"
	return "F · 잠시 쉬기 · 체력 회복 / 복귀 지점 마련"

func interact() -> bool:
	if not near_shelter() or threatened() or rest_left > 0: return false
	if shelter_ready and world.player.hp >= 5: return false
	if world.player.dash_left > 0 or Input.is_action_pressed("pulse"): return false
	rest_left = REST_SECONDS
	rest_origin = world.player.position
	return true

func update_rest(delta: float) -> void:
	if rest_left <= 0: return
	var moved: bool = world.player.position.distance_to(rest_origin) > 0.12
	var intent := Input.get_vector("left", "right", "up", "down").length_squared() > 0.01
	if not near_shelter() or moved or intent or threatened() or world.player.dash_left > 0 or Input.is_action_pressed("pulse"):
		rest_left = 0
		world.notice("쉼을 멈췄습니다 · 안전해지면 다시 F로 쉬세요")
		return
	rest_left = maxf(0, rest_left - delta)
	if rest_left == 0:
		shelter_ready = true
		world.player.hp = 5
		world.notice("숨을 고르고 젖은 옷을 정리했다 · 체력 회복 · 쉼터 복귀 지점 기록")
		world.sound("reward")
		world.save_now()

func refresh() -> void:
	for id in markers:
		if id in discovered:
			markers[id].material_override.albedo_color.a=0
			markers[id].hide()

func restore(value: Variant) -> void:
	discovered = []
	attunement = ""
	shelter_ready = false
	rest_left = 0
	if value is Dictionary and value.get("discovered") is Array:
		for id in value.discovered:
			if id is String and id in SITES and not id in discovered:
				discovered.append(id)
		if crystals() >= 3 and value.get("attunement", "") in ["reach", "force"]:
			attunement = value.attunement
		shelter_ready = "shelter" in discovered and bool(value.get("shelter_ready", true))
	refresh()

func snapshot() -> Dictionary:
	return {"layout_revision": 2, "discovered": discovered.duplicate(), "attunement": attunement, "shelter_ready": shelter_ready}

func safe_restored_position(at: Vector3, data: Variant) -> Vector3:
	var revision: int = int(data.get("layout_revision", 1)) if data is Dictionary else 1
	if revision < 2 and absf(at.x - SHELTER_BODY.x) < SHELTER_SIZE.x * 0.5 + 0.5 and absf(at.z - SHELTER_BODY.z) < SHELTER_SIZE.z * 0.5 + 0.5:
		return Land.on_ground(SITES.shelter.at, 0.2)
	return at

func crystals() -> int:
	return discovered.size() + world.waterworks.discovered.size() + (1 if world.waterworks.reclaimed else 0) - (3 if not attunement.is_empty() else 0) - (3 if not world.waterworks.weave.is_empty() else 0)

func attune(id: String) -> bool:
	return world.choose_upgrade(id) if id in ["reach","force"] else false

func journal_text() -> String:
	var result := "빗물길 %d/3\n" % discovered.size()
	for id in discovered:
		result += "\n%s — %s\n" % [SITES[id].name, NOTES[id]]
	if not attunement.is_empty():
		result += "\n새긴 마법: " + ("먼 빛 · 자동 공격 사거리 +1" if attunement == "reach" else "밀어내는 손 · J 밀침 +25%")

	if "shelter" in discovered:
		result += "\n쉼터: " + ("정비 완료 · 돌아와 F로 체력을 회복할 수 있다.\n" if shelter_ready else "아직 쉬지 않았다. F로 쉬면 체력을 회복하고 복귀 지점을 마련한다.\n")
	result += world.waterworks.journal_text()
	return result

func respawn_point() -> Vector3:
	if "threshold" in world.facility.discovered: return Land.on_ground(world.facility.SITES.threshold.at,0.2)
	if "sluice" in world.waterworks.discovered: return Land.on_ground(world.waterworks.SITES.sluice.at,0.2)
	return Land.on_ground(SITES.shelter.at,0.2) if shelter_ready else Vector3(-15,0.2,0)

func objective() -> String:
	if world.player.position.z < -38 or not world.waterworks.discovered.is_empty(): return world.waterworks.objective()
	if not "stone_arch" in discovered:
		return "물길을 따라 북쪽 석문으로 · 몸에 반응하는 문양 조사"
	if not shelter_ready:
		return "석문 너머 쉼터에서 F로 회복·복귀 준비 · 준비되면 북쪽 수문으로"
	return world.waterworks.objective()
