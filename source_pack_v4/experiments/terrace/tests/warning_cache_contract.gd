extends SceneTree
const Land=preload("res://game/landscape.gd")
const Warning=preload("res://game/ground_warning.gd")
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func original_height(at:Vector3)->float:
	var x:=floorf(at.x)
	var z:=floorf(at.z)
	var a:=Land.raw_height(Vector3(x,0,z))
	var b:=Land.raw_height(Vector3(x+1,0,z))
	var c:=Land.raw_height(Vector3(x+1,0,z+1))
	var d:=Land.raw_height(Vector3(x,0,z+1))
	var u:=at.x-x
	var v:=at.z-z
	return a+(b-a)*u+(c-b)*v if u>=v else a+(c-d)*u+(d-a)*v
func original_normal(at:Vector3)->Vector3:
	var x:=floorf(at.x)
	var z:=floorf(at.z)
	var a:=Vector3(x,Land.raw_height(Vector3(x,0,z)),z)
	var b:=Vector3(x+1,Land.raw_height(Vector3(x+1,0,z)),z)
	var c:=Vector3(x+1,Land.raw_height(Vector3(x+1,0,z+1)),z+1)
	var d:=Vector3(x,Land.raw_height(Vector3(x,0,z+1)),z+1)
	return (c-a).cross(b-a).normalized() if at.x-x>=at.z-z else (d-a).cross(c-a).normalized()
func original_point(center:Vector3,offset:Vector3,lift:float=0.16)->Vector3:
	var n:=original_normal(center)
	var gradient:=Vector2(-n.x/n.y,-n.z/n.y) if n.y>=0.72 else Vector2.ZERO
	return Vector3(center.x+offset.x,original_height(center)+gradient.dot(Vector2(offset.x,offset.z))+lift,center.z+offset.z)
func original_support(center:Vector3,offset:Vector3)->bool:
	var at:=original_point(center,offset,0)
	return absf(at.y-original_height(at))<=0.25 and original_normal(at).y>=0.65
func run():
	var world:=Node3D.new()
	root.add_child(world)
	for region in [0,1,2,1,0]:
		Land.lab_region=region
		Land.lab_flat=region==0
		var valid:=true
		for x in range(100,140,2):
			for z in range(-31,13,2):
				for offset in [Vector3(.25,0,.75),Vector3(.75,0,.25)]:
					var at:Vector3=Vector3(x,0,z)+offset
					valid=valid and absf(Land.height_at(at)-original_height(at))<0.00001 and Land.normal_at(at).distance_to(original_normal(at))<0.00001
		check(valid,"uncached height/normal parity, including return travel region %d"%region)
	Land.lab_flat=false
	for center in [Vector3(110,0,-6),Vector3(114,0,-7),Vector3(132,0,-5),Vector3(128,0,-19)]:
		Land.lab_region=1 if center.x>120 else 2
		var node:=Warning.make(world,center,2.5,Color.RED)
		var expected:=PackedVector3Array()
		for i in range(64):
			var a:=Vector3(cos(i*TAU/64),0,sin(i*TAU/64))
			var b:=Vector3(cos((i+1)*TAU/64),0,sin((i+1)*TAU/64))
			for band in [[-.115,-.065],[-.065,.065],[.065,.115]]:
				var inner:float=2.5+band[0]
				var outer:float=2.5+band[1]
				var offsets=[a*inner,a*outer,b*outer,a*inner,b*outer,b*inner]
				if not offsets.all(func(offset):return original_support(center,offset)):continue
				if not original_support(center,(a+b)*.5*2.5):continue
				for offset in offsets:expected.append(original_point(center,offset))
		var actual:PackedVector3Array=node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var same:=int(node.get_meta("surface_vertices"))==expected.size()
		for i in range(expected.size()):same=same and actual[i].distance_to(expected[i])<0.0001
		check(same,"original clipped ring triangle parity "+str(center))
		var builds:int=node.get_meta("warning_builds")
		for i in range(60):Warning.draw(node,center,2.5)
		check(node.get_meta("warning_builds")==builds,"stationary warning reused for 60 ticks")
		Warning.draw(node,center,1.4)
		check(node.get_meta("warning_builds")==builds+1,"animated radius invalidates geometry")
		node.position.x+=1
		Warning.draw(node,center,1.4)
		check(node.get_meta("warning_builds")==builds+2,"parent/local transform invalidates geometry")
		node.position=Vector3.ZERO
		var direction:=Vector3(.6,0,-.8)
		Warning.draw_lane(node,center,direction)
		expected.clear()
		var side:=direction.cross(Vector3.UP).normalized()*.275
		for i in range(40):
			var a:=direction*5*float(i)/40
			var b:=direction*5*float(i+1)/40
			var offsets=[a-side,a+side,b+side,a-side,b+side,b-side]
			if not offsets.all(func(offset):return original_support(center,offset)):continue
			for offset in offsets:expected.append(original_point(center,offset))
		actual=node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		same=int(node.get_meta("surface_vertices"))==expected.size()
		for i in range(expected.size()):same=same and actual[i].distance_to(expected[i])<0.0001
		check(same,"original clipped charge lane triangle parity "+str(center))
		builds=node.get_meta("warning_builds")
		Warning.draw_lane(node,center,direction)
		check(node.get_meta("warning_builds")==builds,"stationary charge lane reused")
		Land.lab_flat=not Land.lab_flat
		Warning.draw_lane(node,center,direction)
		check(node.get_meta("warning_builds")==builds+1,"terrain mode invalidates warning")
		Land.lab_flat=false
		node.free()
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
