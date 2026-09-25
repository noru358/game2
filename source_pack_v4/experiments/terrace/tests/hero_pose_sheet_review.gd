extends SceneTree
func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1152,720);root.content_scale_size=root.size
	var world=load("res://lab/hero_pose_combat_review.tscn").instantiate()
	root.add_child(world);current_scene=world
	for tick in range(5):await physics_frame
	world.set_process(false);world.set_physics_process(false);world.player.set_physics_process(false)
	world.reset_preview_position();world.update_camera(1)
	world.player.body.rotation=Vector3.ZERO
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art_review/hero_pose_v2/frames.json"))
	var output := Image.create(1120,manifest.coverage.size()*120,false,Image.FORMAT_RGBA8)
	for row in range(manifest.coverage.size()):
		var direction: int=manifest.coverage[row]
		for column in range(8):
			world.poses.apply(world.art_sprite,"walk" if column<4 else "run",(column%4)*PI*0.5,0,false,direction)
			await process_frame
			await RenderingServer.frame_post_draw
			var sample := root.get_texture().get_image().get_region(Rect2i(506,328,140,120))
			output.blit_rect(sample,Rect2i(0,0,140,120),Vector2i(column*140,row*120))
	var result := output.save_png("res://art_review/hero_pose_v2/motion_gpu_sheet.png")
	print("PASS GPU sheet; rows ",manifest.coverage,"; candidate only; save result ",result)
	var attacks := Image.create(1260,960,false,Image.FORMAT_RGBA8)
	for direction in range(8):
		for column in range(9):
			world.poses.apply(world.art_sprite,"attack",-1 if column%3==0 else 0,int(column/3)+1,column%3==2,direction)
			await process_frame
			await RenderingServer.frame_post_draw
			var sample := root.get_texture().get_image().get_region(Rect2i(506,328,140,120))
			attacks.blit_rect(sample,Rect2i(0,0,140,120),Vector2i(column*140,direction*120))
	var attack_result := attacks.save_png("res://art_review/hero_pose_v2/attack_gpu_sheet.png")
	print("PASS attack GPU sheet; 8 directions x 3 strikes x 3 poses; save result ",attack_result)
	quit(0 if result==OK else 1)
