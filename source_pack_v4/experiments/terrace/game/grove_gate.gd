extends Node3D
const V=preload("res://game/visuals.gd")
var leaves:Array[Node3D]=[]
var releasing:=false

func _ready()->void:
	for side in [-1,1]:
		var leaf:=V.box(self,Vector3(0,1.25,side*1.5),Vector3(0.8,2.5,3),Color.WHITE,true)
		leaf.get_child(0).hide()
		leaves.append(leaf)
		# Separate courses have recessed joints; all relief is outside the stone face.
		for row in range(5):
			V.stone_box(leaf,Vector3(0,-1.0+row*0.5,0),Vector3(0.8,0.48,2.97),Color("9d875f"))
		for z in [-1.34,1.34]:
			V.stone_box(leaf,Vector3(-0.46,0,z),Vector3(0.12,2.5,0.18),Color("b49e75"))
		for y in [-1.12,1.12]:
			V.stone_box(leaf,Vector3(-0.46,y,0),Vector3(0.12,0.24,2.5),Color("b49e75"))
		# Paired stepped water-channel relief, echoing the region's hydraulic ruins.
		for level in range(3):
			var span:=1.7-level*0.42
			V.stone_box(leaf,Vector3(-0.46,-0.64+level*0.55,0),Vector3(0.12,0.14,span),Color("b9a780"))
		V.box(leaf,Vector3(-0.53,0,0),Vector3(0.025,1.7,0.055),Color("64b9ab"))
		# The fixed high camera sees the cap most clearly: carry the seal onto it.
		V.stone_box(leaf,Vector3(0,1.30,0),Vector3(0.7,0.12,2.78),Color("b9a780"))
		V.box(leaf,Vector3(0,1.37,0),Vector3(0.075,0.02,2.2),Color("64b9ab"))
		for z in [-0.92,0.0,0.92]:
			V.stone_box(leaf,Vector3(0,1.40,z),Vector3(0.62,0.06,0.15),Color("c4b28d"))
		for mesh in leaf.find_children("*","MeshInstance3D",true,false):
			if mesh.material_override is ShaderMaterial:
				mesh.material_override.set_shader_parameter("follow_object",true)

func release(animated:bool)->void:
	if not animated:
		queue_free()
		return
	if releasing:return
	releasing=true
	var motion:=create_tween().set_parallel(true).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	for i in range(leaves.size()):
		motion.tween_property(leaves[i],"position:y",-1.55,0.8).set_delay(i*0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	motion.chain().tween_callback(queue_free)
