extends "res://maps/forest_pilgrimage_graybox.gd"
## ACT 2 representative art slice. Geometry, collision and combat stay on the graybox contract.
const ArtKit=preload("res://maps/environment_art.gd")
var art_kit=ArtKit.new()
var art_root: Node3D

func _ready() -> void:
	super._ready()
	if not is_instance_valid(player):return
	DisplayServer.window_set_title("첫 숲 수로 · ACT 2 아트 슬라이스")
	focus_zone(1)
	update_hud()

func build_world() -> void:
	surface.art_enabled=true
	super.build_world()
	# The graybox lighting was intentionally neutral and bright. The slice uses a
	# quieter value range so the ivory/blue hero and warnings stay dominant.
	for node in get_children():
		if node is WorldEnvironment:
			node.environment.ambient_light_energy=0.5
			node.environment.background_color=Color("17302f")
		elif node is DirectionalLight3D:
			node.light_energy=0.72
	art_root=Node3D.new()
	art_root.name="Act2ReusableArt"
	add_child(art_root)
	art_kit.parent=art_root
	art_kit.surface=surface
	art_kit.camera_pitch=camera_pitch
	art_kit.prepare()
	style_act_two_geometry()
	decorate_act_two()
	align_cards()

func style_act_two_geometry() -> void:
	var stone:=StandardMaterial3D.new()
	stone.albedo_color=Color("9a9a82")
	stone.albedo_texture=art_kit.stone_texture
	stone.uv1_triplanar=true
	stone.uv1_scale=Vector3.ONE*0.42
	stone.roughness=1.0
	for node in props.get_children():
		if node.position.z<=-25.0 or node.position.z>=20.0:continue
		if node is MeshInstance3D:
			# Gray spheres are composition masses. Illustrated cards replace them only in ACT 2.
			node.hide()
			continue
		for child in node.get_children():
			if child is MeshInstance3D:
				child.material_override=stone
				if child.mesh is BoxMesh:
					var size: Vector3=child.mesh.size
					# Illustrated pillar cards replace the narrow post/cap meshes;
					# the StaticBody collision remains authoritative.
					if size.x<2.5 and size.z<2.5:child.hide()

func decorate_act_two() -> void:
	# One large framing mass per gameplay crop, not a wall of individual props.
	for data in [
		[Vector3(-17,0,15),6.8],[Vector3(-16,0,1),7.2],
		[Vector3(-17,0,-12),7.4],[Vector3(-15,0,-23),7.0]
	]:
		art_kit.card(data[0],5,data[1],0.9)
		art_kit.shadow(data[0],Vector2(data[1]*0.62,data[1]*0.38),0.22)
	# River-edge clusters keep the water readable while leaving combat width open.
	for data in [
		[Vector3(8.5,0,16),2,3.4],[Vector3(12.5,0,8),0,2.8],
		[Vector3(11,0,-3),1,2.7],[Vector3(5.2,0,-12),2,3.0],
		[Vector3(1.3,0,-20),0,2.6]
	]:
		art_kit.card(data[0],data[1],data[2],0.94)
	# Sparse outer-bank clusters produce depth without filling the walkable center.
	for data in [
		[Vector3(-11,0,18),1,2.3],[Vector3(-12,0,9),0,2.5],
		[Vector3(-9,0,-1),2,2.9],[Vector3(-12,0,-7),1,2.4],
		[Vector3(-10,0,-17),0,2.6],[Vector3(-11,0,-24),2,3.0]
	]:art_kit.card(data[0],data[1],data[2],0.88)
	# Existing graybox waystones retain collision; these cards are their art layer.
	for at in [Vector3(6,0,18),Vector3(9,0,7),Vector3(5,0,-6),Vector3(2,0,-17)]:
		art_kit.card(at,3,4.4,0.9)
		art_kit.shadow(at,Vector2(1.8,1.2),0.22)
	for at in [Vector3(-11,0,14),Vector3(5,0,2),Vector3(-5,0,-10),Vector3(2,0,-20)]:
		art_kit.card(at+Vector3(-0.5,0,0.4),4,2.2,0.9)

func align_cards() -> void:
	for sprite in art_kit.cards:
		var at: Vector3=sprite.get_meta("base_at")
		var baseline: float=sprite.get_meta("baseline")
		sprite.rotation=Vector3(-deg_to_rad(camera_pitch),view_yaw,0)
		var forward:=Vector3(0,sin(deg_to_rad(camera_pitch)),cos(deg_to_rad(camera_pitch))).rotated(Vector3.UP,view_yaw)
		var up_card:=Vector3(0,cos(deg_to_rad(camera_pitch)),-sin(deg_to_rad(camera_pitch))).rotated(Vector3.UP,view_yaw)
		sprite.position=surface.ground(at)+forward*0.025+up_card*baseline

func update_art_occlusion() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player):return
	var hero_screen:=camera.unproject_position(player.position+Vector3.UP)
	for sprite in art_kit.cards:
		var base: Vector3=surface.ground(sprite.get_meta("base_at"))
		var close:=camera.unproject_position(base+Vector3.UP).distance_to(hero_screen)<92.0
		var in_front:=(base-player.position).dot(camera.global_basis.z)>0.0
		var faded:=close and in_front
		sprite.modulate.a=0.24 if faded else 1.0
		sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISABLED if faded else SpriteBase3D.ALPHA_CUT_DISCARD

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	update_art_occlusion()

func update_hud() -> void:
	if not is_instance_valid(ui) or not is_instance_valid(player):return
	var zone:=surface.zone_at(player.position)
	ui.text="  첫 숲 수로 · ACT 2 아트 슬라이스\n  %s\n  재사용 자산 검증 · pitch %.0f° / yaw %.0f° / size %.0f  "%[zone_name(zone),camera_pitch,rad_to_deg(view_yaw),camera.size]
	prompt.text="WASD 이동 · Space 회피 · J 3연타 · 1/2/3 구간 이동 · Tab 조감 · F 정지 · R 전투 재배치 · B 자동공격 · Esc 종료"
