extends SceneTree
# Read-only reference/candidate display. No runtime manifest writes.
func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1200,680)
	root.content_scale_size=root.size
	RenderingServer.set_default_clear_color(Color("303844"))
	var canvas := Node2D.new()
	root.add_child(canvas)
	var paths := ["hero_idle_exact_v1/back_right.png","hero_pose_v2/back_right_walk_center_first.png","hero_repair_v3/walk_F2_candidate_08.png"]
	var names := ["APPROVED DESIGN / DIRECTION","CURRENT WALK F0 / NOT APPROVED","NEW WALK F2 / REVIEW REQUIRED"]
	for index in range(3):
		var im := Image.load_from_file("res://art_review/"+paths[index])
		if index==1:im=im.get_region(Rect2i(0,0,1024,1024))
		im.fix_alpha_edges()
		var tex := ImageTexture.create_from_image(im)
		var used := im.get_used_rect()
		var atlas := AtlasTexture.new()
		atlas.atlas=tex
		atlas.region=used
		for height in [430.0,74.0]:
			var sprite := Sprite2D.new()
			canvas.add_child(sprite)
			sprite.texture=atlas
			sprite.scale=Vector2.ONE*height/used.size.y
			sprite.position=Vector2(index*400+200,55+height*0.5 if height>100 else 550+height*0.5)
		var label := Label.new()
		canvas.add_child(label)
		label.text=names[index]
		label.position=Vector2(index*400+12,20)
		label.add_theme_font_size_override("font_size",17)
	var note := Label.new()
	canvas.add_child(note)
	note.text="Top: equal display height for visual comparison. Bottom: 74px. Candidate is NOT installed."
	note.position=Vector2(20,650)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art_review/hero_repair_v3/walk_F2_compare_08.png")
	print("Reference/F0/candidate display saved; no art acceptance claim.")
	quit()
