extends SceneTree
const Probe = preload("res://lab/hero_gait_probe.gd")
const OUT = "res://art_review/hero_walk_v1/"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,800)
	root.content_scale_size=Vector2i(1280,800)
	var probe := Probe.new()
	root.add_child(probe)
	var errors: Array=[]
	var max_drift := 0.0
	var stride := 60.0
	var cycle := 0.8
	var speed := 2.0*stride/cycle
	# During stance, root displacement and local foot motion must cancel.
	for offset in [0.0,0.5]:
		for j in range(1,49):
			var p: float = float(j)/100.0
			var t: float = (p-offset)*cycle
			var foot := Probe.leg(p,stride,18)
			var world_x: float = t*speed+foot.position.x
			var expected: float = stride*0.5-offset*cycle*speed
			max_drift=maxf(max_drift,absf(world_x-expected))
	for j in range(100):
		var a := Probe.leg(float(j)/100.0,stride,18)
		var b := Probe.leg(float(j)/100.0+0.5,stride,18)
		if a.stance==b.stance:errors.append(j)
	var seam: float = Probe.leg(0,stride,18).position.distance_to(Probe.leg(1,stride,18).position)
	var quick_cycle := 3.4/7.5
	var quick_stride := 7.5*quick_cycle*0.12/2.25*467
	var quick_drift := 0.0
	for j in range(1,12):
		var p := float(j)/100.0
		var local := Probe.leg(p,quick_stride,18,0.12)
		var x: float = p*quick_cycle*7.5/2.25*467+local.position.x
		quick_drift=maxf(quick_drift,absf(x-quick_stride*0.5))
	var report := {"kind":"rendering cutout prototype, not accepted character motion","target_directions":8,"implemented_direction_probes":[0],"max_stance_drift_source_pixels":max_drift,"phase_pair_errors":errors,"loop_position_seam":seam,"current_game_step_world":1.7,"current_game_walk_cycle_seconds":3.4/7.5,"required_stride_source_pixels":1.7/2.25*467,"production_integrated":false}
	report["quick_step"]={"support_fraction":0.12,"stance_distance_source_pixels":quick_stride,"max_drift_source_pixels":quick_drift,"airborne_fraction":0.76,"human_accepted":false}
	if max_drift>0.001 or quick_drift>0.001 or not errors.is_empty() or seam>0.001:
		push_error(JSON.stringify(report))
		quit(1)
		return
	if "--test" in OS.get_cmdline_user_args():
		probe.running=false
		for phase in range(4):
			probe.phase_time=phase*0.2
			probe.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT+"gait_probe_"+str(phase)+".png"))
			if result!=OK:errors.append(result)
		var file := FileAccess.open(OUT+"gait_probe.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
		print(JSON.stringify(report))
		quit(0 if errors.is_empty() else 1)
