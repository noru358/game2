extends RefCounted
# Encounter membership is saved separately from surviving enemies: never respawn a cleared pack.
var world: Node3D
var entered: Array = []
# Fixed authored pockets keep encounter IDs stable across saves.
const ARRIVAL=[Vector2(-11.2,-1.6),Vector2(-9.4,-0.7),Vector2(-10.3,2.0),Vector2(-8.1,2.7)]
const GROWTH=[Vector2(-5.8,-3.9),Vector2(-4.2,-5.3),Vector2(-2.6,-4.7),Vector2(-4.8,-1.8),Vector2(-0.9,-2.1),Vector2(0.4,-3.7),Vector2(-1.8,0.6),Vector2(0.8,-0.6)]
const GUARDIAN=[Vector2(-3.8,4),Vector2(-2.4,5.9),Vector2(-0.5,4.7),Vector2(1.8,6.5),Vector2(2.4,3.4),Vector2(-4.7,7.5),Vector2(-1.3,8.6),Vector2(1.3,9.3)]
const GARDEN=[Vector2(9.4,-3.4),Vector2(11.2,-5.0),Vector2(12.8,-3.9),Vector2(15.6,-5.8),Vector2(10.6,3.2),Vector2(12.0,5.1),Vector2(15.3,4.1),Vector2(17.7,6.0)]
func at(point:Vector2)->Vector3:return Vector3(point.x,0,point.y)
func _init(owner: Node3D) -> void: world=owner
func begin() -> void:
	entered=["arrival"]
	for i in range(4):
		world.spawn_enemy("grove_%02d"%i,at(ARRIVAL[i]),false,12,"wanderer")
func populate(id: String) -> void:
	if id in entered: return
	entered.append(id)
	if id=="growth":
		for i in range(4,12):
			world.spawn_enemy("grove_%02d"%i,at(GROWTH[i-4]),false,12,"charger" if i==10 else "wanderer")
		world.notice("새 마법을 시험해 보세요 · 앞쪽 무리를 지나 수호자에게")
	elif id=="guardian":
		for i in range(12,20):
			world.spawn_enemy("grove_%02d"%i,at(GUARDIAN[i-12]),false,12,"charger" if i==18 else "wanderer")
		world.spawn_enemy("gatekeeper_01",Vector3(2,0,0),true)
	elif id=="garden":
		for i in range(8):
			world.spawn_enemy("garden_%02d"%i,at(GARDEN[i]))
	world.save_now()
func update() -> void:
	if not world.upgrades.is_empty() and world.player.position.x>-13: populate("growth")
	if world.kills>=8 and world.player.position.x>-7: populate("guardian")
	if world.opened: populate("garden")
func restore(data: Variant) -> void:
	# Older saves already contained all three packs; absence must never repopulate them.
	entered=["arrival","growth","guardian","garden"]
	if data is Dictionary and data.get("entered") is Array:
		entered=[]
		for id in data.entered:
			if id in ["arrival","growth","guardian","garden"] and not id in entered: entered.append(id)
func snapshot() -> Dictionary: return {"entered":entered.duplicate()}
func location() -> String:
	var p: Vector3=world.player.position
	if p.z<-112: return "거대 저수전 · 봉인 회랑"
	if p.z<-86: return "거대 저수전 · 남쪽 회랑"
	if p.z<-54 and p.x>39: return "잠긴 숲 · 드러난 석길" if world.waterworks.sluice_open else "잠긴 숲"
	if p.z<-70: return "옛 수문 마당"
	if p.z<-38: return "잠긴 숲" if p.x>26 else "붉은 제방"
	if p.z<-29: return "숲속 쉼터"
	if p.z<-14: return "빗물길"
	return "동쪽 정원" if p.x>5 else "숲 입구"
func recap() -> String:
	return "%s%s · 발견 %d곳 · %s\n%s"%["첫 여정 체험 · " if world.save_slot!=world.Store.PATH else "",location(),world.exploration.discovered.size()+world.waterworks.discovered.size()+world.facility.discovered.size()+(1 if world.waterworks.reclaimed else 0),world.growth_label(),world.objective()]
