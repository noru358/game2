extends RefCounted
const V=preload("res://game/visuals.gd")
const Land=preload("res://game/landscape.gd")
static func build(world:Node3D) -> void:
	# Continuous earth extends past the collision edge. Dense peripheral vegetation
	# supplies a visible boundary; distant tiers are darker and less saturated.
	for side in [-1,1]:
		if Land.lab_region==2 and side==1:continue # Open eastern cliff towards the valley.
		for row in range(2):
			for i in range(11):
				var x:float=120.0+side*(23.0+row*5.0)+sin(i*2.1)*1.1
				var z:=19.0-i*6.3+row*2.0
				var tree:=V.tropical_prop(world,Land.on_ground(Vector3(x,0,z)),0,8.0+sin(i*1.7)*1.2+row*2)
				tree.modulate=Color("829d8b") if row==0 else Color("536f68")
				if row==0:V.tropical_prop(world,Land.on_ground(Vector3(x-side*1.2,0,z+1.4)),1,2.7)
	for i in range(10):
		var x:float=94.0+i*5.8
		if world.has_method("near_threshold") and x>101 and x<139:continue
		var tree:=V.tropical_prop(world,Land.on_ground(Vector3(x,0,-39-sin(i)*2)),0,10.0+sin(i*1.7)*2)
		tree.modulate=Color("6c897a")
	for x in [102.0,138.0]:
		for z in [7.0,-3.0,-13.0,-24.0]:
			# Low edge stones connect the planting into banks without hiding the path.
			V.stone_box(world,Land.on_ground(Vector3(x,0,z),0.3),Vector3(1.7,0.6,4.3),Color("747d67"),true)
			V.tropical_prop(world,Land.on_ground(Vector3(x,0,z-1)),1,2.2)
