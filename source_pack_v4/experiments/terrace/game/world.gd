extends Node3D

const V = preload("res://game/visuals.gd")
const Player = preload("res://game/player.gd")
const Enemy = preload("res://game/enemy.gd")
const Store = preload("res://game/save_store.gd")
const Hud = preload("res://game/hud.gd")
const Combat = preload("res://game/combat.gd")
const Exploration = preload("res://game/exploration.gd")
const Landscape = preload("res://game/landscape.gd")
const Waterworks = preload("res://game/waterworks.gd")
const Journey = preload("res://game/journey.gd")
const Story = preload("res://game/story.gd")
const Facility = preload("res://game/facility.gd")
var demo_mode := false
var demo_ending_seen := false
var facility: RefCounted
var story: RefCounted
var journey: RefCounted
var waterworks: RefCounted
var exploration: RefCounted
const LEVEL_THRESHOLDS := [4, 10, 18, 28, 40]
const UPGRADE_NAMES := {"split": "분열", "chain": "연쇄", "echo": "잔향", "reach":"먼 빛", "force":"밀어내는 손", "reserve":"모아치는 손", "return":"되돌아오는 빛"}
const UPGRADE_DESCRIPTIONS := {"split": "자동 표적 1 → 2명 · 두 갈래 빛으로 함께 공격", "chain": "맞은 적에서 가까운 적 1명에게 번짐 · 추가 피해 3", "echo": "자동 6회 적중: 폭발 피해 4 · J 막타: 폭발 피해 6", "reach":"자동 공격 사거리 +1", "force":"직접 공격 밀침 +25%", "reserve":"자동 공격 6회 적중 → 다음 직접 공격 피해 +8", "return":"직접 공격 적중 → 다음 자동 공격 3회 피해 +2"}
var combat: RefCounted
var upgrades: Array = []
var choices_claimed := 0
var auto_hits := 0
var hitstop := 0.0
var shake := 0.0
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var garden_marker: MeshInstance3D
var gate: Node3D
var kills := 0
var chain := false
var opened := false
var guardian_defeated := false
var complete := false
var attack_wait := 0.0
var pulse_wait := 0.0
var elapsed := 0.0
var save_wait := 0.0
var message := "WASD로 이동 · 가까운 적은 자동 공격합니다"
var message_left := 8.0
var silent := false
var test_mode := false
var save_error := false
var save_slot := Store.PATH
var effects: Array[Dictionary] = []
var audio: Node
var ambience: Node

func _ready() -> void:
	test_mode = "--test" in OS.get_cmdline_user_args()
	if "--preview" in OS.get_cmdline_user_args(): save_slot="user://first_journey_preview.json"
	demo_mode = get_tree().get_meta("demo_mode",false)
	if demo_mode: save_slot=preload("res://game/demo_menu.gd").slot(test_mode)
	if not test_mode:
		Engine.max_fps = 60
	get_tree().auto_accept_quit = false
	setup_inputs()
	build_world()
	exploration = Exploration.new(self)
	exploration.build()
	waterworks = Waterworks.new(self)
	waterworks.build()
	facility=Facility.new(self)
	facility.build()
	player = Player.new()
	add_child(player)
	player.position = Vector3(-15, 0.2, 0)
	combat = Combat.new(self)
	camera = Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24
	camera.near = 0.1
	camera.far = 100.0
	camera.current = true
	update_camera(1.0)
	audio = preload("res://game/sound_bank.gd").new()
	add_child(audio)
	ambience=preload("res://game/ambience.gd").new()
	add_child(ambience)
	journey=Journey.new(self)
	story=Story.new(self)
	story.build()
	var fresh: bool = get_tree().get_meta("fresh_run", false)
	get_tree().remove_meta("fresh_run")
	var saved := {} if (test_mode and not demo_mode) or fresh else Store.read_data(save_slot)
	if saved.is_empty():
		spawn_initial()
		if fresh:
			save_now()
	else:
		restore(saved)
	hud = Hud.new()
	add_child(hud)
	if not saved.is_empty():
		pause_game("이어서 탐험 · 준비되면 재개하세요")

func setup_inputs() -> void:
	var keys := {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "dash": [KEY_SPACE, KEY_SHIFT], "pulse": [KEY_J], "pause": [KEY_ESCAPE], "interact": [KEY_F]}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("14292d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("abc7ba")
	env.ambient_light_energy = 0.65
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_color = Color("fff0cc")
	light.light_energy = 1.15
	light.shadow_enabled = true
	add_child(light)
	var foundation := V.box(self, Vector3(0, -0.6, 0), Vector3(44, 1.2, 28), Color("324f43"), true)
	foundation.get_child(0).visible = false
	Landscape.make_terrain(self, Rect2(-22,-14,44,28), false)
	# End caps meet side walls at their inner face; equal-height tops must not overlap.
	var grove_masonry=preload("res://game/grove_masonry.gd")
	grove_masonry.wall(self, Vector3(0, 0.5, 14), Vector3(43.3, 2, 0.7))
	# North garden exit connects to the rain path.
	grove_masonry.wall(self, Vector3(-5.325, 0.5, -14), Vector3(32.65, 2, 0.7))
	grove_masonry.wall(self, Vector3(19.325, 0.5, -14), Vector3(4.65, 2, 0.7))
	for x in [-22.0, 22.0]:
		grove_masonry.wall(self, Vector3(x, 0.5, 0), Vector3(0.7, 2, 28))
	for z in [-8.325, 8.325]:
		grove_masonry.wall(self, Vector3(5, 1.0, z), Vector3(0.9, 2.0, 10.65))
	gate = preload("res://game/grove_gate.gd").new()
	add_child(gate)
	gate.position = Vector3(5,0,0)
	for z in [-3.3, 3.3]:
		var pillar := V.stone_box(self, Vector3(5, 1.7, z), Vector3(1.4, 3.4, 1.4), Color("b0b7a0"), true)
		pillar.get_child(0).hide()
		var carving := V.carved_waystone(self,Vector3(5,0.04,z),4.2)
		# Facade art sits in front of the adjoining wall, without shifting its screen anchor.
		carving.position += Vector3(0,0.788,0.616)*2.2
		carving.name = "GateCarvingNorth" if z < 0 else "GateCarvingSouth"
	# Uneven canopy pockets frame the clearing; the east gate and north exit stay open.
	for entry in [[-20.0,-11.6,6.4],[-16.6,-12.1,4.4],[-10.0,-11.3,5.7],[-6.8,-12.0,4.2],[0.5,-11.8,6.0],[8.2,-12.0,5.1],[20.0,-11.5,6.2]]:
		var at:=Vector3(entry[0],0,entry[1])
		var trunk:=V.box(self,at+Vector3.UP*1.2,Vector3(0.48,2.4,0.48),Color("78664c"),true)
		trunk.get_child(0).hide()
		trunk.add_to_group("grove_trunks")
		var crown:=V.tropical_prop(self,at,0,entry[2])
		crown.flip_h=entry[0] in [-16.6,-6.8,20.0]
		crown.add_to_group("grove_border")
	# Low undergrowth has no invisible solid trunk and does not cover combatants.
	for entry in [[-19.0,-10.5,1.4],[-17.7,-10.9,0.9],[-8.1,-11.0,1.1],[1.9,-11.7,1.3],[19.0,-10.6,1.0],[-20.0,11.9,1.4],[-18.2,11.5,0.9],[-2.0,12.0,1.15],[0.1,12.3,0.8],[17.5,11.8,1.2],[19.0,12.2,0.8]]:
		var plant:=V.tropical_prop(self,Vector3(entry[0],0,entry[1]),1,entry[2])
		plant.flip_h=entry[0]>0
		plant.add_to_group("grove_border")
	for i in range(8):
		Landscape.paving(self, Vector3(10 + (i % 4) * 2.5, 0, -5 + (i / 4) * 9), Vector2(1.6,1.8), Landscape.PAVING_LIFT, Color("607c69"))
	garden_marker = V.discovery_marker(self, Vector3(17,0.07,0))
	var garden_stone := V.stone_box(self, Vector3(17, 0.6, 0), Vector3(0.9, 1.2, 0.9), Color("e4d8ae"), true)
	garden_stone.get_child(0).hide()
	var garden_art := V.carved_waystone(self,Vector3(17,0.04,0),2.3)
	garden_art.name = "GardenWaystoneArt"

func spawn_enemy(id: String, at: Vector3, is_elite: bool = false, health: int = -1, role: String = "") -> Node3D:
	var enemy = Enemy.new()
	enemy.stable_id = id
	enemy.elite = is_elite
	enemy.role = role if role in ["wanderer", "charger", "caster"] else ("charger" if id in ["grove_03", "grove_18", "garden_06"] else "wanderer")
	if is_elite:
		enemy.role = "wanderer"
	enemy.hp = health if health > 0 else Enemy.maximum_health(id, is_elite)
	add_child(enemy)
	enemy.position = Vector3(at.x,maxf(at.y,Landscape.height_at(at)+0.1),at.z)
	return enemy

func spawn_initial() -> void:
	journey.begin()

func enemies() -> Array:
	return get_children().filter(func(n): return n is CharacterBody3D and n != player and not n.dead)

func visible_target(enemy: Node3D, from: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 0.7, enemy.position + Vector3.UP * 0.7, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _physics_process(delta: float) -> void:
	combat.update(delta)
	if hitstop > 0:
		hitstop = maxf(0, hitstop - delta)
		return
	elapsed += delta
	attack_wait -= delta
	pulse_wait = maxf(0, pulse_wait - delta)
	message_left -= delta
	save_wait += delta
	update_camera(delta)
	journey.update()
	exploration.update(delta)
	waterworks.update(delta)
	facility.update()
	story.update(delta)
	if demo_mode and facility.studied and not demo_ending_seen and not get_tree().get_meta("demo_overlay",false):
		preload("res://game/demo_menu.gd").overlay(self,"ending")
		return
	if attack_wait <= 0:
		auto_attack()
	if pending_choices() > 0 and not test_mode:
		pause_game("레벨업 · 강화 하나를 선택하세요")
	if opened and not complete and player.position.distance_to(Vector3(17, 0, 0)) < 2.3:
		complete = true
		notice("정원에 도착했습니다 · 북쪽 빗물길에 남겨진 흔적을 찾아보세요")
		sound("reward")
		save_now()
	if save_wait > 3:
		save_wait = 0
		save_now()
	update_effects(delta)

func update_effects(delta: float) -> void:
	V.update_discovery_marker(garden_marker,player.position,opened and not complete and not exploration.threatened(),delta)
	for effect in effects.duplicate():
		effect.time -= delta
		if effect.node.has_method("advance"):
			effect.node.advance(delta)
		if effect.has("velocity"):
			effect.node.position += effect.velocity * delta
		if effect.time <= 0:
			effect.node.queue_free()
			effects.erase(effect)

func lookout_weight() -> float:
	return landmark_view_weight(Waterworks.SITES.overlook.at,0.0,6.0)

func sluice_view_weight() -> float:
	return landmark_view_weight(Waterworks.SITES.sluice.at,3.5,9.0)

func landmark_view_weight(at: Vector3, inner: float, outer: float) -> float:
	var distance := Vector2(player.position.x-at.x,player.position.z-at.z).length()
	var weight := 1.0-smoothstep(inner,outer,distance)
	if weight<=0: return 0.0
	# Close combat takes priority; blend out before an enemy enters attack range.
	var nearest := 14.0
	for enemy in enemies():
		if not enemy.dead: nearest=minf(nearest,enemy.position.distance_to(player.position))
	return weight*smoothstep(9.0,14.0,nearest)

func update_camera(delta: float) -> void:
	var center := Vector3(clampf(player.position.x, -10, 42 if player.position.z < -38 else 13), Landscape.height_at(player.position), clampf(player.position.z, -128, 3))
	var lookout := lookout_weight()
	var sluice := sluice_view_weight()
	center += Vector3(16,0,-6)*lookout
	center += Vector3(0,5,-5)*sluice
	camera.size = lerpf(camera.size,24.0+lookout*18.0+sluice*8.0,minf(1,delta*6))
	var goal := center + Vector3(0, 23, 18)
	camera.position = camera.position.lerp(goal, minf(1, delta * 12))
	camera.rotation_degrees = Vector3(-52, 0, 0)
	shake = maxf(0, shake - delta)
	if shake > 0:
		camera.position += Vector3(sin(elapsed * 115), 0, cos(elapsed * 93)) * shake

func auto_attack() -> void:
	var profile: Dictionary=call("attack_profile") if has_method("attack_profile") else {}
	var candidates := enemies()
	candidates.sort_custom(func(a, b): return player.position.distance_squared_to(a.position) < player.position.distance_squared_to(b.position))
	var remaining := 2 if "split" in upgrades else 1
	var fired := false
	for enemy in candidates:
		if enemy.dead:
			continue
		if player.position.distance_to(enemy.position) > (8.0 if exploration.attunement == "reach" else 7.0):
			break
		if not visible_target(enemy, player.position):
			continue
		var origin: Vector3 = enemy.position
		player.show_auto_cast(origin - player.position)
		beam(player.auto_origin(), origin, Color("a9e7ff"))
		enemy.hit(int(profile.get("auto_damage",3))+waterworks.auto_bonus(), (origin - player.position).normalized() * 0.3)
		waterworks.on_auto_hit()
		if not enemy.dead: enemy.auto_impact()
		preload("res://game/combat_effect.gd").spawn(self,"auto_impact",origin,Vector3.ZERO,1,Color("a9e7ff"))
		auto_hits += 1
		if has_method("on_growth_auto_hit"):call("on_growth_auto_hit",origin)
		if "echo" in upgrades and auto_hits % 6 == 0:
			burst_at(origin, 2.7, 4)
		if chain:
			for other in candidates:
				if other != enemy and not other.dead and origin.distance_to(other.position) < 4 and visible_target(other, origin):
					beam(origin, other.position, Color("f4d488"))
					other.hit(3)
					impact(other.position, false)
					break
		attack_wait = float(profile.get("auto_interval",0.30))
		if not fired: sound("auto")
		fired = true
		remaining -= 1
		if remaining <= 0:
			break
	if not fired:
		attack_wait = 0.08

func beam(from: Vector3, to: Vector3, color: Color) -> void:
	preload("res://game/combat_effect.gd").spawn(self, "bolt", from, to - from, 1, color)

func enemy_defeated(enemy: Node3D) -> void:
	preload("res://game/combat_effect.gd").spawn(self, "defeat", enemy.position, Vector3.ZERO, 3 if enemy.elite else 1, Color("ffcf87"))
	kills += 1
	if kills == 8:
		player.hp = 5
		notice("다음은 수호자입니다 · 오른쪽 관문으로 이동하세요")
		sound("reward")
	if enemy.stable_id == "gatekeeper_01":
		guardian_defeated = true
		notice("수호자 격파 · 봉인이 풀립니다")
		player.hp = 5
	elif enemy.stable_id == "waterworks_keeper":
		notice("수문 수호자 격파 · 마당에서 다음 탐험을 준비하세요")
	if guardian_defeated and kills >= 8 and not opened:
		open_gate(true)
		notice("봉인 해제 · 열린 문을 지나 동쪽 정원으로 가세요")
	save_now()

func open_gate(animated: bool = false) -> void:
	opened = true
	if is_instance_valid(gate):
		gate.release(animated)

func notice(text: String) -> void:
	message = text
	message_left = 7

func objective() -> String:
	if pending_choices()>0: return "새 마법 선택 · 안전하게 멈춘 동안 강화할 공격을 고르세요"
	if player.position.z < -86 or not facility.discovered.is_empty(): return facility.objective()
	if complete:
		return exploration.objective()
	if opened:
		return "동쪽 정원으로 · 열린 문을 지나 빛나는 석주에 접근 →"
	if kills >= 8:
		return "봉인 풀기 · 오른쪽 관문의 수호자 처치 →"
	if upgrades.is_empty(): return "첫 마법 깨우기 · 가까운 숲벌레 4마리 사냥 (%d/4)"%mini(kills,4)
	return "새 마법 시험하기 · 앞쪽 적 4마리 처치 (%d/4)"%clampi(kills-4,0,4)

func snapshot() -> Dictionary:
	var records: Array = []
	for enemy in enemies():
		records.append({"id": enemy.stable_id, "p": [enemy.position.x, enemy.position.y, enemy.position.z], "hp": enemy.hp, "elite": enemy.elite, "role": enemy.role})
	return {"demo_ending_seen":demo_ending_seen,"growth_revision":2,"schema": 2, "facility":facility.snapshot(), "story":story.snapshot(), "journey":journey.snapshot(), "combat_revision": 5, "exploration": exploration.snapshot(), "waterworks": waterworks.snapshot(), "upgrades": upgrades.duplicate(), "choices_claimed": choices_claimed, "auto_hits": auto_hits, "player": [player.position.x, player.position.y, player.position.z], "hp": player.hp, "kills": kills, "chain": chain, "guardian": guardian_defeated, "opened": opened, "complete": complete, "elapsed": elapsed, "pulse": pulse_wait, "enemies": records, "silent": silent}

func restore(data: Dictionary) -> void:
	demo_ending_seen=bool(data.get("demo_ending_seen",false))
	journey.restore(data.get("journey"))
	var water_data: Variant=data.get("waterworks",{})
	var old_layout: bool = not water_data is Dictionary or int(water_data.get("layout_revision",1))<2
	waterworks.restore(data.get("waterworks",{}))
	exploration.restore(data.get("exploration", {}))
	var p: Array = data.player
	if p.size() == 3:
		player.position = Vector3(float(p[0]), maxf(0.1, float(p[1])), float(p[2]))
		if old_layout: player.position=Landscape.expand_old_waterworks(player.position)
		player.position=waterworks.safe_restored_position(player.position,int(water_data.get("layout_revision",1)) if water_data is Dictionary else 1)
		player.position = exploration.safe_restored_position(player.position, data.get("exploration", {}))
		player.position.y = maxf(player.position.y, Landscape.height_at(player.position) + 0.1)
	player.hp = clampi(int(data.get("hp", 5)), 1, 5)
	player.invulnerability = 1.5
	kills = int(data.get("kills", 0))
	chain = bool(data.get("chain", false))
	upgrades = data.get("upgrades", []).duplicate()
	upgrades = upgrades.filter(func(id): return id in UPGRADE_NAMES)
	if chain and not "chain" in upgrades:
		upgrades.append("chain")
	chain = "chain" in upgrades
	choices_claimed = maxi(upgrades.size(), int(data.get("choices_claimed", upgrades.size())))
	# Legacy crystal purchases remain earned, without charging for them again.
	for id in [exploration.attunement,waterworks.weave]:
		if not id.is_empty() and not id in upgrades: upgrades.append(id)
	choices_claimed = maxi(choices_claimed,upgrades.size())
	for id in upgrades:
		if id in ["reach","force"]: exploration.attunement = id
		if id in ["reserve","return"]: waterworks.weave = id
	auto_hits = int(data.get("auto_hits", 0))
	guardian_defeated = bool(data.get("guardian", false))
	complete = bool(data.get("complete", false))
	elapsed = float(data.get("elapsed", 0))
	pulse_wait = float(data.get("pulse", 0))
	silent = bool(data.get("silent", false))
	if data.get("opened", false):
		open_gate()
	for entry in data.enemies:
		if entry is Dictionary and entry.get("p") is Array and entry.p.size() == 3:
			var at:=Vector3(float(entry.p[0]),float(entry.p[1]),float(entry.p[2]))
			if old_layout: at=Landscape.expand_old_waterworks(at)
			var safe_at:Vector3=waterworks.safe_restored_position(at,int(water_data.get("layout_revision",1)) if water_data is Dictionary else 1)
			if safe_at!=at:at=Landscape.on_ground(safe_at+Vector3(0,0,3),0.1)
			at = exploration.safe_restored_position(at, data.get("exploration", {}))
			var restored_role:=str(entry.get("role",""))
			if int(data.get("combat_revision",0))<5 and entry.get("id","") in ["waterworks_high_0","waterworks_high_2"]:restored_role="caster"
			spawn_enemy(str(entry.get("id","unknown")),at,bool(entry.get("elite",false)),int(entry.get("hp",3)),restored_role)
	facility.restore(data.get("facility"))
	story.restore(data.get("story"))
	update_camera(1)

func save_now() -> void:
	if (not test_mode or (demo_mode and save_slot=="user://steam_demo_test.json")) and is_instance_valid(player):
		save_error = Store.write(snapshot(),save_slot) != OK
		if save_error:
			notice("저장하지 못했습니다 · 종료 전 저장 공간을 확인해주세요")

func pause_game(reason: String = "잠시 쉬어가도 괜찮아요") -> void:
	save_now()
	get_tree().paused = true
	if not test_mode:
		Engine.max_fps = 15
	if is_instance_valid(hud):
		hud.show_pause(reason)

func resume_game() -> void:
	if pending_choices() > 0:
		hud.show_pause("먼저 강화를 선택해주세요 · 선택은 저장됩니다")
		return
	player.invulnerability = maxf(player.invulnerability, 0.8)
	get_tree().paused = false
	if not test_mode:
		Engine.max_fps = 60
	hud.pause_panel.hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(player) and (not test_mode or "--focus-qa" in OS.get_cmdline_user_args()) and not get_tree().paused:
		pause_game("작업으로 돌아가는 동안 안전하게 멈췄습니다")
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_now()
		if save_error:
			pause_game("저장 실패 · 진행을 보존하려면 재시도해주세요")
		else:
			get_tree().quit()

func sound(event: String) -> void:
	if silent or test_mode or not is_instance_valid(audio):return
	audio.play(event,combat.combo_step if event == "cast" else 0)

func toggle_sound() -> void:
	silent=not silent
	audio.set_muted(silent)
	if silent:ambience.stop()
	save_now()

func pending_choices() -> int:
	var earned := 0
	for threshold in LEVEL_THRESHOLDS:
		if kills >= threshold:
			earned += 1
	return maxi(0, earned - choices_claimed)

func available_upgrades() -> Array:
	var basic := ["split","chain","echo"].filter(func(id): return not id in upgrades)
	if not basic.is_empty(): return basic
	if exploration.attunement.is_empty(): return ["reach","force"]
	if waterworks.weave.is_empty(): return ["reserve","return"]
	return []

func growth_label() -> String:
	var earned := 0
	for threshold in LEVEL_THRESHOLDS:
		if kills >= threshold: earned += 1
	if earned == LEVEL_THRESHOLDS.size(): return "Lv.6"
	var previous: int = 0 if earned == 0 else LEVEL_THRESHOLDS[earned-1]
	return "Lv.%d   %d/%d" % [earned+1,kills-previous,LEVEL_THRESHOLDS[earned]-previous]

func choose_upgrade(id: String) -> bool:
	if pending_choices() <= 0 or not id in available_upgrades() or id in upgrades:
		return false
	upgrades.append(id)
	if id in ["reach","force"]: exploration.attunement = id
	if id in ["reserve","return"]: waterworks.weave = id
	choices_claimed += 1
	chain = "chain" in upgrades
	player.hp = mini(5, player.hp + 1)
	notice("%s 획득 · 능력과 조합이 저장됐습니다" % UPGRADE_NAMES[id])
	save_now()
	return true

func spell_strike(at: Vector3, direction: Vector3, step: int) -> void:
	var color: Color = [Color("79dcff"),Color("9c95ff"),Color("d8a1ff")][clampi(step-1,0,2)]
	preload("res://game/combat_effect.gd").spawn(self, "sweep", at, direction, step, color)

func impact(at: Vector3, heavy: bool) -> void:
	preload("res://game/combat_effect.gd").spawn(self, "impact", at, Vector3.ZERO, 3 if heavy else 1, Color("ffe4bb") if heavy else Color("9cdcff"))

func burst_at(at: Vector3, radius: float, damage: int) -> void:
	preload("res://game/combat_effect.gd").spawn(self, "burst", at, Vector3.RIGHT * radius, 3, Color("bdb0ff"))
	for target in enemies():
		if at.distance_to(target.position) < radius and visible_target(target, at):
			target.hit(damage, (target.position - at).normalized() * 0.25)

func hit_sound(heavy: bool) -> void:
	sound("heavy" if heavy else "hit")

func demo_title() -> void:
	save_now()
	if save_error: return
	test_mode=true # Prevent focus-loss autosave while the old scene is being replaced.
	get_tree().paused=false
	get_tree().set_meta("demo_overlay",false)
	get_tree().change_scene_to_file("res://game/demo_menu.tscn")
