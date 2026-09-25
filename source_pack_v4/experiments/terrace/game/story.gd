extends RefCounted
# Trial scene writing. Gameplay evidence and presentation progress are separate.
const V = preload("res://game/visuals.gd")
const ORDER := ["awakening", "recognition", "answer", "direction", "inscription"]
const BEATS := {
	"awakening": {"title":"낯선 맥박", "line":"술법을 거뒀는데도 손안의 맥박이 멎지 않는다.\n남의 변이만 살피던 내가, 이제 그 징후를 좇는다.", "body":"손을 거둔 뒤에도 낯선 빛이 남았다. 내 의지와 다른 박자로 되살아나는 술식. 위험한 변이를 다루며 보아 온 징후가 이제 내 몸에서 시작됐다.\n\n숲 안쪽의 오래된 유적부터 조사한다. 아직 이 변화의 주인은 알 수 없다."},
	"recognition": {"title":"돌에 남은 같은 맥박", "line":"석문에 가까이 서자 손의 빛과 돌의 흔적이 함께 뛴다.\n우연한 병은 아니다. 이 길에 단서가 있다.", "body":"석문의 마모된 흔적에 다가서자 손안의 빛이 같은 간격으로 뛰었다. 몸의 이상과 이 유적 사이에 연결이 있다.\n\n표석은 생활용 수로를 안내한다. 수로를 만든 사람들과 이 흔적을 남긴 자가 같은지는 아직 모른다."},
	"answer": {"title":"시전을 멈춘 뒤", "line":"수호자는 쓰러졌다. 그런데 손의 빛은 여전히 안쪽을 향한다.\n누가 이 연결을 붙들고 있는지 찾아야 한다.", "body":"수문 수호자를 쓰러뜨렸지만 반응은 사라지지 않았다. 수호자가 변화의 근원이라는 가설은 맞지 않는다.\n\n이곳에서 확보한 안전한 자리를 발판으로, 물 아래 묻힌 통행 기록을 조사한다. 수문 복구는 길을 드러내는 수단이다."},
	"direction": {"title":"물 아래의 행선지", "line":"석판의 수로는 모두 수문 너머 큰 시설로 이어진다.\n그곳에서 이 연결의 근원을 찾겠다.", "body":"드러난 석판에는 흩어진 수로가 하나의 큰 시설에 모이는 배치가 남아 있다. 손안의 반응과 시설의 흔적을 함께 추적할 다음 목적지가 생겼다.\n\n여기까지는 첫 단서다. 누가 이 연결을 붙들고 있는지, 왜 나인지는 아직 밝혀지지 않았다.\n\n석판에서 회랑 문을 여는 개방식도 읽었다. 수문 북쪽 문 앞에서 F로 사용해 거대 저수전에 들어간다."},
	"inscription": {"title":"누군가 덧새긴 연결", "line":"낡은 물길 위에 새 술식이 있다. 이 연결은 누군가 만든 것이다.\n이곳의 선은 끊었다. 이제 남은 봉인편으로 근원을 좇겠다.", "body":"저수전의 오래된 눈금 위에 새 연결선이 덧새겨져 있었다. 선을 끊자 벽의 맥동만 꺼졌고, 몸의 이상은 남았다.\n\n봉인편을 확보했다. 병의 원인을 막연히 찾던 조사에서, 이 시설을 이용하는 누군가를 추적하는 일로 바뀌었다. 상대의 정체와 목적을 단정할 증거는 아직 없다."}
}
var world: Node3D
var unlocked: Array = []
var presented: Array = []
var active := ""
var remaining := 0.0
var pulse_time := 0.0
var stone_mark: Node3D
var mark: Node3D

func _init(owner: Node3D) -> void: world = owner

func build() -> void:
	mark = Node3D.new()
	world.player.add_child(mark)
	mark.position = Vector3(0.42, 1.25, 0.35)
	for radius in [0.22, 0.34]:
		var ring := V.ring(mark, Vector3.ZERO, radius, Color("dda9bd"))
		ring.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring.material_override.emission_enabled = false
		ring.quaternion = Quaternion(Vector3.UP, Vector3(0, 0.8, 0.6))
	mark.hide()
	stone_mark = V.ring(world, world.Landscape.on_ground(Vector3(8, 0, -26), 2.6), 0.55, Color("dda9bd"))
	stone_mark.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stone_mark.material_override.emission_enabled = false
	stone_mark.quaternion = Quaternion(Vector3.UP, Vector3(0, 0.8, 0.6))
	stone_mark.hide()

func available() -> Array:
	var result: Array = ["awakening"]
	if "stone_arch" in world.exploration.discovered: result.append("recognition")
	if "sluice" in world.waterworks.discovered: result.append("answer")
	if world.waterworks.reclaimed: result.append("direction")
	if world.facility.studied: result.append("inscription")
	return result

func sync_evidence() -> void:
	var changed := false
	for id in available():
		if id not in unlocked:
			unlocked.append(id)
			changed = true
	if changed: world.save_now()

func safe_to_read() -> bool:
	return world.pending_choices() == 0 and not world.enemies().any(func(e): return e.position.distance_to(world.player.position) < 8.0)

func update(delta: float) -> void:
	sync_evidence()
	var safe := safe_to_read()
	# A new discovery replaces outdated location commentary. All evidence stays
	# in the journal; skipped captions are not falsely recorded as read.
	var latest := ""
	for id in ORDER:
		if id in unlocked: latest = id
	if active != latest:
		active = ""
		remaining = 0.0
	if active.is_empty() and safe and not latest.is_empty() and latest not in presented:
		active = latest
		remaining = 12.0
	if not active.is_empty() and safe:
		remaining -= delta
		pulse_time += delta
		if remaining <= 0:
			presented.append(active)
			active = ""
			world.save_now()
	mark.visible = safe and not active.is_empty()
	mark.scale = Vector3.ONE * (0.85 + sin(pulse_time * 3.0) * 0.15)
	stone_mark.visible = mark.visible and active == "recognition"
	stone_mark.scale = mark.scale

func caption() -> String:
	return BEATS[active].line if not active.is_empty() and safe_to_read() else ""

func lead() -> String:
	if "inscription" in unlocked: return "추적 단서 · 누군가 덧새긴 봉인편 확보"
	if "direction" in unlocked: return "추적 · 수문 북쪽 거대 저수전의 안쪽 흔적 조사"
	if "answer" in unlocked: return "추적 · 물 아래 통행 기록에서 안쪽 시설의 단서 찾기"
	if "recognition" in unlocked: return "추적 · 몸의 반응과 이어진 상류 유적 조사"
	return "여행의 이유 · 내 몸에서 시작된 변화의 근원 찾기"

func records() -> Array:
	var result: Array = []
	for id in ORDER:
		if id in unlocked: result.append({"title":BEATS[id].title,"body":BEATS[id].body,"region":"변화의 흔적 · 여정 기록"})
	return result

func snapshot() -> Dictionary:
	return {"unlocked":unlocked.duplicate(), "presented":presented.duplicate()}

func restore(data: Variant) -> void:
	unlocked = available()
	presented = []
	active = ""
	remaining = 0
	if data is Dictionary:
		if data.get("presented") is Array:
			for id in data.presented:
				if id in unlocked and id not in presented: presented.append(id)
	else:
		# Legacy saves receive evidence without replaying every past scene.
		presented = unlocked.duplicate()
	mark.hide()
	stone_mark.hide()
