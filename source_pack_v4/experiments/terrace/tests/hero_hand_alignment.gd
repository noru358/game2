extends SceneTree
# GPU evidence: cyan ring is the actual focus_points origin, not an invented overlay anchor.
class Marker extends Control:
	var point := Vector2.ZERO
	func _draw() -> void:
		draw_circle(point,6,Color.BLACK,false,3)
		draw_circle(point,6,Color.CYAN,false,1)
func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1152,720);root.content_scale_size=root.size
	var world=load("res://lab/character_integration.tscn").instantiate()
	root.add_child(world);current_scene=world
	world.set_process(false);world.set_physics_process(false);world.player.set_physics_process(false)
	for enemy in world.enemies():enemy.hide();enemy.set_physics_process(false)
	world.player.position=world.Landscape.on_ground(Vector3(110,0,3),0.1)
	world.update_camera(1);world.camera.size=7.33
	var layer := CanvasLayer.new();root.add_child(layer)
	var marker := Marker.new();layer.add_child(marker)
	var foot: Vector2=world.camera.unproject_position(world.player.global_position)
	var crop := Rect2i(int(foot.x)-150,int(foot.y)-265,300,300)
	for group in range(2):
		var output := Image.create(900,1200,false,Image.FORMAT_RGBA8)
		for row in range(4):
			var direction := group*4+row
			for step in range(1,4):
				var player=world.player
				player.casting_direction=Vector3(cos(direction*PI/4),0,sin(direction*PI/4))
				player.swing_step=step;player.swing_duration=0.4;player.swing_left=0.4
				player.update_visual(0);player.weapon.hide();player.second_focus.hide()
				var point: Vector3=player.hero_visual.focus_points(player.portrait,player.casting_direction,step)[0]
				marker.point=world.camera.unproject_position(player.body.to_global(point));marker.queue_redraw()
				await process_frame;await RenderingServer.frame_post_draw
				output.blit_rect(root.get_texture().get_image(),crop,Vector2i((step-1)*300,row*300))
		var result := output.save_png("res://art_review/hero_pose_v2/hand_alignment_"+str(group)+".png")
		print("hand alignment GPU group ",group," save ",result)
	quit()
