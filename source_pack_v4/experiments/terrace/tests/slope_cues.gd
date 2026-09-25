extends SceneTree
const Warning=preload("res://game/ground_warning.gd")
var failures:=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func run():
	var world=load("res://lab/world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	for e in world.enemies():e.free()
	var reference:=PackedVector3Array()
	for index in range(4):
		var center:Vector3=world.Landscape.on_ground([Vector3(110,0,3),Vector3(110,0,-6),Vector3(114,0,-7),Vector3(127,0,-17)][index],0.1)
		world.player.position=center
		world.kills=8
		world.player.facing=Vector3.RIGHT
		world.combat.reset_transient()
		world.combat.strike()
		var warning:=Warning.make(world,center+Vector3(2,0,0),2.5,Color("ff7655"))
		var lane:=Warning.make(world,center,0.1,Color("e5aa68"))
		var renderer=Warning.new()
		if renderer.has_method("draw_lane"):renderer.call("draw_lane",lane,center,Vector3.FORWARD)
		# All emitted ring vertices must occupy one plane. The old per-vertex
		# terrain drape fails this at a terrace edge.
		var points:PackedVector3Array=warning.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		if warning.has_meta("surface_vertices") and int(warning.get_meta("surface_vertices"))>0:
			var surface=load("res://game/effect_surface.gd")
			var origin:=center+Vector3(2,0,0)
			var valid:=true
			for v in points:
				var at:=warning.to_global(v)
				valid=valid and absf(at.y-surface.point(origin,at-origin).y)<0.001
			check(valid,"warning remains planar site "+str(index))
		for effect in world.effects:
			if effect.node.get("kind")=="sweep":
				var verts:PackedVector3Array=effect.node.surface.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				var low:=100.0
				var high:=-100.0
				for v in verts:low=minf(low,v.y);high=maxf(high,v.y)
				check(high-low<4,"spell does not stretch across terrace site "+str(index))
				if index==0:reference=verts.duplicate()
				var identical:=verts.size()==reference.size()
				for i in range(mini(verts.size(),reference.size())):identical=identical and verts[i].distance_to(reference[i])<0.001
				check(identical,"same spell geometry as flat ground site "+str(index))
		world.update_camera(1)
		for frame in range(24):
			await process_frame
			await RenderingServer.frame_post_draw
			if frame in [0,23]:root.get_texture().get_image().save_png(OS.get_environment("DEMO_QA_OUTPUT")+"/slope-%d-%d.png"%[index,frame])
		warning.free()
		lane.free()
		for e in world.effects:e.node.free()
		world.effects.clear()
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
