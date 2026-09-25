extends RefCounted
## Small mesh kit. Prototype styling, not final approved environment artwork.
var surface
var parent: Node3D
var crowns: Array[MeshInstance3D]=[]

func mesh(at: Vector3,geometry: Mesh,color: Color,solid: bool=false) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh=geometry
	m.position=at
	var mat := StandardMaterial3D.new()
	mat.albedo_color=color
	mat.roughness=1
	m.material_override=mat
	parent.add_child(m)
	if solid:m.create_trimesh_collision()
	return m

func block(at: Vector3,size: Vector3,color: Color,solid: bool=true) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size=size
	return mesh(at,box,color,solid)

func rock(at: Vector3,size: Vector3,color: Color=Color("80928a"),solid: bool=true) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius=1
	sphere.height=2
	sphere.radial_segments=7
	sphere.rings=3
	var m := mesh(surface.ground(at)+Vector3.UP*size.y*0.32,sphere,color)
	m.scale=size
	if solid:m.create_trimesh_collision()
	return m

func tree(at: Vector3,height: float,seed_value: int) -> void:
	var base: Vector3=surface.ground(at)
	var trunk := CylinderMesh.new()
	trunk.top_radius=0.22
	trunk.bottom_radius=0.5
	trunk.height=height*0.72
	trunk.radial_segments=7
	mesh(base+Vector3.UP*height*0.36,trunk,Color("686955"),true)
	for i in range(3):
		var s := SphereMesh.new()
		s.radius=1
		s.height=1.5
		s.radial_segments=9
		s.rings=4
		var offset := Vector3(cos(seed_value+i*2.1)*0.85,height*(0.63+i*0.12),sin(seed_value+i*2.1)*0.65)
		var crown := mesh(base+offset,s,Color("3d7464").lightened(i*0.055))
		crown.scale=Vector3(2.5,1.5,2.0)*(height/6.0)
		crowns.append(crown)

func gate(at: Vector3,along_x: bool) -> void:
	var side := Vector3(1.8,0,2.5) if along_x else Vector3(3,0,0)
	for sign_value in [-1,1]:
		var p: Vector3=surface.ground(at+side*sign_value)
		block(p+Vector3.UP*1.8,Vector3(1.1,3.6,1.1),Color("8c9c85"))
		block(p+Vector3.UP*3.55,Vector3(1.6,0.45,1.6),Color("bdc1a1"))
	var beam := block(surface.ground(at)+Vector3.UP*3.9,Vector3(7,0.55,1.1),Color("a7b191"),false)
	beam.rotation.y=-atan2(side.z,side.x)

func build(world: Node3D,land) -> void:
	parent=world
	surface=land
	crowns.clear()
	var b: Rect2=surface.bounds
	# Visible rock banks delimit the map; no rectangular wall corridor.
	for i in range(19):
		var x: float=lerpf(b.position.x,b.end.x,float(i)/18)
		rock(Vector3(x,0,b.position.y+0.9*sin(i)),Vector3(2.2+0.3*sin(i*2),2.7+sin(i)*1.1,1.7))
		rock(Vector3(x,0,b.end.y+0.8*sin(i*1.3)),Vector3(2.1,1.8+0.6*cos(i*1.3),1.8))
	for i in range(16):
		var z: float=lerpf(b.position.y,b.end.y,float(i)/15)
		rock(Vector3(b.position.x+0.6*sin(i),0,z),Vector3(1.8,2.5+sin(i),2.1))
		rock(Vector3(b.end.x+0.5*cos(i),0,z),Vector3(1.8,3.1+cos(i),2.1))
	if surface.map_id=="water_entry":
		for at in [Vector3(-23,0,5),Vector3(-23,0,-10),Vector3(-20,0,-20),Vector3(-9,0,-23),Vector3(3,0,-23),Vector3(15,0,-22),Vector3(24,0,2),Vector3(17,0,12),Vector3(-10,0,18)]:tree(at,6.2,roundi(at.x))
		for at in [Vector3(-9,0,3),Vector3(9,0,5),Vector3(6,0,13),Vector3(-3,0,-8)]:rock(at,Vector3(1.5,0.7,1.0),Color("a0ad94"))
		# Retaining face along the north shore makes the raised ground readable.
		for i in range(7):
			var p := Vector3(-5+i*2,0,-9.5)
			block(surface.ground(p)+Vector3(0,-0.4,0),Vector3(1.85,1.4,0.8),Color("889b86"))
		gate(Vector3(24,0,-11),true)
	else:
		for at in [Vector3(-15,0,-13),Vector3(15,0,-13),Vector3(15,0,12),Vector3(-13,0,-20)]:tree(at,8,roundi(at.x))
		gate(Vector3(-15,0,9),true)
		build_altar()

func build_altar() -> void:
	# Capstones follow the upper terrace. Front wall itself is the terrain mesh.
	for x in [-7.0,7.0]:
		block(surface.ground(Vector3(x,0,-3.2))+Vector3.UP*0.22,Vector3(5.6,0.44,0.7),Color("c1baa0"))
	for x in [-9.8,9.8]:
		block(surface.ground(Vector3(x,0,-10))+Vector3.UP*0.2,Vector3(0.65,0.4,12.5),Color("b8b399"))
	# Decorative altar is solid furniture on floor 2, not a third walkable floor.
	block(surface.ground(Vector3(0,0,-12))+Vector3.UP*0.35,Vector3(4.8,0.7,3.4),Color("c1b698"))
	block(surface.ground(Vector3(0,0,-12))+Vector3.UP*0.9,Vector3(3.8,0.4,2.5),Color("d0c5a6"))
	block(surface.ground(Vector3(0,0,-12.7))+Vector3.UP*1.8,Vector3(1.5,1.5,0.8),Color("899b85"))
	for x in [-4.2,4.2]:
		block(surface.ground(Vector3(x,0,6.5))+Vector3.UP*0.8,Vector3(1.15,1.6,1.15),Color("a2ac91"))

func update_occlusion(camera: Camera3D,hero: Vector3) -> void:
	var screen := camera.unproject_position(hero+Vector3.UP*1.2)
	for crown in crowns:
		var p := camera.unproject_position(crown.global_position)
		crown.transparency=0.72 if p.distance_to(screen)<140 and crown.global_position.z>hero.z-1 else 0.0
