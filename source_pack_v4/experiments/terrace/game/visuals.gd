extends RefCounted

static func carved_waystone(parent: Node3D, at: Vector3, height: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = preload("res://assets/environment/garden_waystone_v1.png")
	# Source alpha bounds: top 30, foot 1426, root x 520 in a 1024x1536 canvas.
	sprite.pixel_size = height / 1396.0
	sprite.offset.x = -8
	sprite.position = at + Vector3(0,0.616,-0.788) * (658 * sprite.pixel_size)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(sprite)
	return sprite

static func tropical_prop(parent: Node3D, at: Vector3, kind: int, height: float) -> Sprite3D:
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://assets/environment/monsoon_props_v1.png")
	var metadata: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/monsoon_props_v1.json"))
	var data: Dictionary=metadata[kind]
	atlas.region=Rect2(data.region[0],data.region[1],data.region[2],data.region[3])
	atlas.filter_clip = true
	var sprite := Sprite3D.new()
	sprite.texture = atlas
	sprite.shaded = false
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.pixel_size = height / (float(data.foot)-float(data.top))
	var baseline: float = (float(data.foot)-atlas.region.size.y*0.5)*sprite.pixel_size
	sprite.position = at + Vector3(0, cos(deg_to_rad(52)), -sin(deg_to_rad(52))) * baseline
	parent.add_child(sprite)
	return sprite

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if glow > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

static func stone_box(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid: bool = false) -> Node3D:
	var node:=box(parent,at,size,color,solid)
	node.get_child(0).material_override=stone_material(color)
	return node

static func stone_material(color:Color)->ShaderMaterial:
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://game/facility_stone.gdshader")
	mat.set_shader_parameter("stone_color",color)
	mat.set_shader_parameter("grain_texture",preload("res://assets/environment/reservoir_masonry_v1.png"))
	return mat

static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid: bool = false) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	parent.add_child(root)
	root.position = at
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	root.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		root.add_child(collision)
	return root

static func sphere(parent: Node3D, at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = at
	return mesh

static func ring(parent: Node3D, at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := TorusMesh.new()
	shape.inner_radius = radius - 0.045
	shape.outer_radius = radius + 0.045
	shape.rings = 32
	shape.ring_segments = 8
	mesh.mesh = shape
	mesh.material_override = material(color, 0.3)
	parent.add_child(mesh)
	mesh.position = at
	return mesh

static func discovery_marker(parent:Node3D,at:Vector3)->MeshInstance3D:
	var marker:=ring(parent,at,0.65,Color("c4d5ac"))
	var mat:StandardMaterial3D=marker.material_override
	mat.emission_enabled=false
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a=0
	marker.hide()
	return marker

static func update_discovery_marker(marker:MeshInstance3D,viewer:Vector3,active:bool,delta:float)->void:
	var distance:=Vector2(marker.global_position.x-viewer.x,marker.global_position.z-viewer.z).length()
	var target:=0.65*(1.0-smoothstep(5.0,9.0,distance)) if active else 0.0
	var mat:StandardMaterial3D=marker.material_override
	mat.albedo_color.a=move_toward(mat.albedo_color.a,target,maxf(delta,0)*2.0)
	marker.visible=mat.albedo_color.a>0.005
