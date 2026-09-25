extends SceneTree
# Anatomical construction reference only. Never used as the game character.
const HEADING = Vector3(0.38268343,0,-0.92387953)
const RIGHT = Vector3(0.92387953,0,0.38268343)
const SCREEN_UP = Vector3(0,0.94,-0.342)
var scene: Node3D
func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func part(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh=mesh
	var material := StandardMaterial3D.new()
	material.albedo_color=color
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	if color==Color("edd96e"):material.no_depth_test=true
	node.material_override=material
	parent.add_child(node);node.position=at
	return node
func sphere(parent: Node3D, at: Vector3, radius: float, color: Color) -> void:
	var mesh := SphereMesh.new();mesh.radius=radius;mesh.height=radius*2
	part(parent,mesh,at,color)
func bone(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=a.distance_to(b)
	var node := part(parent,mesh,(a+b)*0.5,color)
	node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	sphere(parent,a,radius,color);sphere(parent,b,radius,color)
func box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new();mesh.size=size
	var node := part(parent,mesh,at,color)
	node.basis=Basis(RIGHT,Vector3.UP,-HEADING)
func leg(parent: Node3D, side: float, forward: float, lift: float, color: Color) -> void:
	var hip := RIGHT*side*0.23+Vector3.UP*0.66
	var ankle := RIGHT*side*0.23+HEADING*forward+Vector3.UP*(0.09+lift)
	var axis := (ankle-hip).normalized()
	var bend := (HEADING-axis*HEADING.dot(axis)).normalized()
	var length := 0.40
	var knee := (hip+ankle)*0.5+bend*sqrt(maxf(0.0,length*length-hip.distance_squared_to(ankle)*0.25))
	bone(parent,hip,knee,0.095,color)
	bone(parent,knee,ankle,0.075,color.lightened(0.2))
	box(parent,ankle+HEADING*0.085,Vector3(0.18,0.15,0.33),color.darkened(0.25))
	sphere(parent,ankle+HEADING*0.23,0.07,Color("edd96e"))
func pose(index: int) -> void:
	var body := Node3D.new();scene.add_child(body)
	body.position=Vector3((index-1.5)*2.8,0,0)-SCREEN_UP*0.9
	var right_front := index<2
	var flight := index%2==0
	var lead := 1.0 if right_front else -1.0
	leg(body,lead,0.25 if flight else 0.03,0.16 if flight else 0.0,Color("df7559") if lead>0 else Color("528fd8"))
	leg(body,-lead,-0.25 if flight else -0.17,0.24 if flight else 0.34,Color("df7559") if lead<0 else Color("528fd8"))
	box(body,Vector3.UP*0.78,Vector3(0.47,0.22,0.28),Color("afa789"))
	box(body,Vector3.UP*1.11+HEADING*0.06,Vector3(0.57,0.47,0.30),Color("ded3b1"))
	for side in [-1.0,1.0]:
		var shoulder: Vector3 = RIGHT*side*0.32+Vector3.UP*1.30+HEADING*0.06
		var hand: Vector3 = shoulder+HEADING*(-side*lead*0.29)+Vector3.DOWN*0.33
		bone(body,shoulder,hand,0.08,Color("df7559") if side>0 else Color("528fd8"))
	sphere(body,Vector3.UP*1.80+HEADING*0.12,0.49,Color("f3d2a2"))
	sphere(body,Vector3.UP*1.71+HEADING*0.53,0.17,Color("bd9059"))
	for side in [-1.0,1.0]:
		var ear := CylinderMesh.new();ear.top_radius=0.01;ear.bottom_radius=0.16;ear.height=0.69
		part(body,ear,Vector3.UP*2.34+RIGHT*side*0.27+HEADING*0.1,Color("eabf89"))
	# A centerline root behind the pelvis, independent of which leg supports.
	sphere(body,Vector3.UP*0.80-HEADING*0.18,0.08,Color("7cd493"))
func run() -> void:
	root.size=Vector2i(2048,768);root.content_scale_size=root.size
	scene=Node3D.new();root.add_child(scene);current_scene=scene
	RenderingServer.set_default_clear_color(Color("333943"))
	var camera := Camera3D.new();scene.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.8
	# Sprite artwork has a shallow illustration view; this is not the world camera.
	camera.position=Vector3(0,0.342,0.94)*20;camera.look_at(Vector3.ZERO);camera.current=true
	for index in range(4):pose(index)
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art_review/hero_pose_v2/rear_gait_anatomy_guide.png")
	root.size=Vector2i(768,1024);root.content_scale_size=root.size
	camera.size=3.6
	for index in range(4):
		for j in range(4):scene.get_child(j+1).visible=j==index
		var center := Vector3((index-1.5)*2.8,0,0)+SCREEN_UP*0.35
		camera.position=center+Vector3(0,0.342,0.94)*20;camera.look_at(center)
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art_review/hero_pose_v2/rear_gait_anatomy_%d.png"%index)
	print("Anatomy reference rendered: right support and left support are independent, all feet share heading. Not game art.")
	quit()
