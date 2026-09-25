extends Node3D
# Visual linkage only. Waterworks owns progress, collision and saved state.
const V = preload("res://game/visuals.gd")
var cables: Array[MeshInstance3D] = []
var drums: Array[Node3D] = []
const TOP := 11.45
const LIFT := 5.8

func rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = a.distance_to(b)
	shape.radial_segments = 12
	mesh.mesh = shape
	mesh.material_override = V.material(color)
	parent.add_child(mesh)
	mesh.position = (a+b)*0.5
	mesh.quaternion = Quaternion(Vector3.UP, (b-a).normalized())
	return mesh

func build(shutter: Node3D) -> void:
	var metal := Color("8f7350")
	var dark := Color("49483a")
	# Forward of the masonry: a visible shaft winds both lifting cables together.
	rod(self, Vector3(-3.8,TOP,-0.05), Vector3(3.8,TOP,-0.05), 0.16, dark)
	for x in [-3.55,3.55]:
		V.box(self,Vector3(x,TOP,-0.05),Vector3(0.4,0.65,0.65),metal)
	for x in [-2.0,2.0]:
		var drum := Node3D.new()
		add_child(drum)
		drum.position = Vector3(x,TOP,-0.05)
		rod(drum,Vector3(-0.28,0,0),Vector3(0.28,0,0),0.4,metal)
		for side in [-0.32,0.32]:
			rod(drum,Vector3(side-0.035,0,0),Vector3(side+0.035,0,0),0.51,dark)
		# A pale lug makes drum rotation legible without emission or warning colors.
		V.box(drum,Vector3(0,0.43,0),Vector3(0.44,0.1,0.15),Color("b5a47c"))
		drums.append(drum)
		cables.append(rod(self,Vector3(x,5.4,0.35),Vector3(x,TOP,0.35),0.065,Color("b4a078")))
		V.box(shutter,Vector3(x,2.5,0.48),Vector3(0.38,0.38,0.3),metal)
	# Brace the slab in front, with separated bands rather than coplanar decals.
	for y in [-2.1,0.0,2.1]:
		V.box(shutter,Vector3(0,y,0.43),Vector3(6.6,0.19,0.15),dark)
		for x in [-2.8,0.0,2.8]:
			rod(shutter,Vector3(x,y,0.5),Vector3(x,y,0.61),0.1,metal)
	# Enclosed drive spindle beside the operator, linked back to the overhead shaft.
	rod(self,Vector3(-1.7,1.65,3.6),Vector3(-3.7,1.65,3.6),0.12,dark)
	rod(self,Vector3(-3.7,1.65,3.6),Vector3(-3.7,TOP,3.6),0.11,metal)
	rod(self,Vector3(-3.7,TOP,3.6),Vector3(-3.7,TOP,-0.05),0.12,dark)
	for y in [2.0,6.0,10.0]:
		V.box(self,Vector3(-3.7,y,3.6),Vector3(0.42,0.35,0.42),dark)
	set_progress(0.0)

func set_progress(progress: float) -> void:
	var bottom := 5.4 + clampf(progress,0,1)*LIFT
	for cable in cables:
		cable.mesh.height = TOP-bottom
		cable.position.y = (TOP+bottom)*0.5
	for drum in drums:
		drum.rotation.x = -progress*LIFT/0.4
