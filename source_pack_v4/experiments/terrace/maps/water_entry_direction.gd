extends "res://maps/ruin_production.gd"
## A bounded zone-1 direction study. No zone transition or final temple asset.
var architecture: Node3D
var camera_option:=0
var roof_parts: Array[Node3D]=[]

func _ready() -> void:
	get_tree().set_meta("ruin_layout","C")
	super._ready()
	reset_encounter(false);overview=false
	player.position=surface.ground(data.hero_view,0.1)
	update_camera(1);update_hud()

func gate_block(at: Vector3,size: Vector3,mat: Material,solid: bool=false) -> Node3D:
	var part=preload("res://game/visuals.gd").box(architecture,at,size,Color.WHITE,solid)
	part.get_child(0).material_override=mat
	return part

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_instance_valid(player):return
	var behind_gate:=player.position.z<-8.5 and absf(player.position.x-9.0)<9.5
	for part in roof_parts:part.visible=not behind_gate

func build_world() -> void:
	super.build_world()
	for child in get_children():
		if child is DirectionalLight3D:child.light_color=Color("fff8e8");child.light_energy=0.68
	architecture=Node3D.new();architecture.name="VolumetricEntranceGate";add_child(architecture)
	var mat=surface.stone(true,kit.stone_texture)
	var top=surface.stone(false,kit.stone_texture)
	# Real depth, open center, stepped masonry: front/side/top all share projection.
	for x in [4.6,13.4]:
		gate_block(Vector3(x,5.2,-11),Vector3(2.6,0.8,3.6),top,true)
		gate_block(Vector3(x,7.4,-11),Vector3(1.7,3.6,2.6),mat,true)
		gate_block(Vector3(x,9.3,-11),Vector3(2.2,0.4,3.2),top)
	roof_parts.append(gate_block(Vector3(9,9.9,-11),Vector3(11.5,0.8,3.8),mat))
	roof_parts.append(gate_block(Vector3(9,10.5,-11),Vector3(12.0,0.4,4.2),top))
	roof_parts.append(gate_block(Vector3(9,11.0,-11),Vector3(9.0,0.6,3.4),mat))
	roof_parts.append(gate_block(Vector3(9,11.6,-11),Vector3(6.2,0.6,2.6),top))
	roof_parts.append(gate_block(Vector3(9,12.2,-11),Vector3(3.3,0.6,1.8),mat))
	# Short side walls establish an actual threshold, not a frontal picture card.
	gate_block(Vector3(0.2,6.1,-11),Vector3(6.8,2.6,1.2),mat,true)
	gate_block(Vector3(18.4,6.1,-11),Vector3(7.0,2.6,1.2),mat,true)
	for material in surface.materials:
		if material.shader==preload("res://maps/ruin_stone.gdshader"):material.set_shader_parameter("entry_palette",true)

func update_camera(delta: float) -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player):return
	var center: Vector3=data.center if overview else player.position+Vector3(-1.2,1.0,-5.5)
	camera.size=54.0 if overview else 22.0
	camera.rotation_degrees=Vector3(-camera_pitch,rad_to_deg(view_yaw),0)
	var goal:=center+Vector3(0,sin(deg_to_rad(camera_pitch)),cos(deg_to_rad(camera_pitch))).rotated(Vector3.UP,view_yaw)*60
	camera.position=camera.position.lerp(goal,minf(delta*9,1))

func align_foliage() -> void:
	for sprite in kit.cards:
		var at: Vector3=sprite.get_meta("base_at");var baseline: float=sprite.get_meta("baseline")
		sprite.rotation=Vector3(-deg_to_rad(camera_pitch),view_yaw,0)
		sprite.position=surface.ground(at)+Vector3(0,cos(deg_to_rad(camera_pitch)),-sin(deg_to_rad(camera_pitch))).rotated(Vector3.UP,view_yaw)*baseline

func set_view(pitch: float,yaw: float) -> void:
	camera_pitch=pitch;view_yaw=deg_to_rad(yaw);align_foliage();update_camera(1)

func set_plain(value: bool) -> void:
	super.set_plain(value)

func update_hud() -> void:
	if not is_instance_valid(ui):return
	ui.text="  물가 입구 · 공간 제작안\n  사선 %.0f° / 내려다봄 %.0f° · 실제 건축 부피"%[rad_to_deg(view_yaw),camera_pitch]
	prompt.text="WASD 이동 · 1 현재안 45/45 · 2 이전 55/30 · 3 낮은안 40/45 · G 구조 · Tab 조감 · P 대표위치 · Esc"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:set_view(45,45);update_hud();return
			KEY_2:set_view(55,30);update_hud();return
			KEY_3:set_view(40,45);update_hud();return
	super._unhandled_input(event)
