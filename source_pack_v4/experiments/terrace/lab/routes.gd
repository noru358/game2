extends RefCounted
const V=preload("res://game/visuals.gd")
const Land=preload("res://game/landscape.gd")
static func wall(world:Node3D,at:Vector3,size:Vector3,color:Color) -> Node3D:
	return V.stone_box(world,Land.on_ground(at,size.y/2),size,color,true)
static func build(world:Node3D,chapter:int) -> void:
	if chapter==0:
		# Reservoir banks: water is part of the terrain shader, not a stacked plane.
		for x in [117.5,128.5]:wall(world,Vector3(x,0,-6),Vector3(0.7,0.85,17),Color("81846f"))
		for z in [2.5,-14.5]:wall(world,Vector3(123,0,z),Vector3(10.3,0.85,0.7),Color("81846f"))
		var water:=V.box(world,Vector3(123,1,-6),Vector3(10.3,2,16.3),Color.WHITE,true)
		water.get_child(0).hide()
	elif chapter==1:
		preload("res://lab/jungle_shelves.gd").build(world)
	else:
		# Offset thresholds form a processional approach, followed by the final open court.
		for spec in [[Vector3(107,0,-3),Vector3(14,1.9,1.3)],[Vector3(132,0,-3),Vector3(16,1.9,1.3)],[Vector3(111,0,-15),Vector3(14,1.5,1.3)]]:
			wall(world,spec[0],spec[1],Color("878773"))
		for x in [115.0,123.0]:V.carved_waystone(world,Land.on_ground(Vector3(x,0,-3)),3.5)
	for node in world.get_children():
		if node is MeshInstance3D and node.material_override is ShaderMaterial and node.material_override.shader.resource_path.ends_with("lab/ground.gdshader"):
			node.material_override.set_shader_parameter("region",chapter)
