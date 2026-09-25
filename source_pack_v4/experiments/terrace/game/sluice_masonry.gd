extends RefCounted
const V=preload("res://game/visuals.gd")
const Land=preload("res://game/landscape.gd")

static func tower(parent:Node3D,x:float)->void:
	var base:=Land.on_ground(Vector3(x,0,-81))
	var body:=V.box(parent,base+Vector3.UP*5.5,Vector3(5,11,4),Color.WHITE,true)
	body.get_child(0).hide()
	# Stacked plinth, shaft and receding crown stay within the existing silhouette budget.
	for course in [[0.0,0.7,5.0,4.0,"806b4d"],[0.7,1.2,4.8,3.9,"ac956b"],[1.2,7.5,4.5,3.6,"927c58"],[7.5,8.0,5.0,4.0,"b09a70"],[8.0,9.5,4.2,3.4,"927c58"],[9.5,10.0,4.7,3.8,"b09a70"],[10.0,10.7,3.7,3.0,"927c58"],[10.7,11.1,4.2,3.5,"b09a70"],[11.1,11.5,3.4,2.8,"bca67b"]]:
		V.stone_box(parent,base+Vector3.UP*(course[0]+course[1])*0.5,Vector3(course[2],course[1]-course[0],course[3]),Color(course[4]))
	# Deep-looking framed niches on the south elevation; distinct from the moving hoist.
	for offset in [-1.05,1.05]:
		V.box(parent,base+Vector3(offset,5.1,1.815),Vector3(0.64,3.4,0.03),Color("344139"))
		for side in [-1,1]:
			V.stone_box(parent,base+Vector3(offset+side*0.44,5.1,1.88),Vector3(0.24,3.9,0.16),Color("b19b71"))
		for y in [3.03,7.17]:
			V.stone_box(parent,base+Vector3(offset,y,1.88),Vector3(1.12,0.24,0.16),Color("b19b71"))
	# Preserve the original forward buttress collider and its ground footprint.
	var buttress:=V.box(parent,Land.on_ground(Vector3(x,0,-78.65),2.8),Vector3(3.2,5.6,0.7),Color.WHITE,true)
	buttress.get_child(0).hide()
	var foot:=Land.on_ground(Vector3(x,0,-78.65))
	for course in [[0.0,0.6,3.2,0.7],[0.6,3.8,2.8,0.6],[3.8,4.3,3.0,0.65],[4.3,5.2,2.2,0.5],[5.2,5.6,2.5,0.55]]:
		V.stone_box(parent,foot+Vector3(0,(course[0]+course[1])*0.5,(course[3]-0.7)*0.5),Vector3(course[2],course[1]-course[0],course[3]),Color("9c8660"))
