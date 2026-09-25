extends SceneTree
# Read-only visualization of the exact registered rear diagonal atlas regions.
func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1600,1280)
	root.content_scale_size=root.size
	RenderingServer.set_default_clear_color(Color("303844"))
	var canvas := Node2D.new()
	root.add_child(canvas)
	var frames: Array=JSON.parse_string(FileAccess.get_file_as_string("res://art_review/hero_pose_v2/frames.json")).frames
	var textures := {}
	var rows := [[7,"walk"],[7,"run"],[5,"walk"],[5,"run"]]
	for row in range(4):
		for index in range(4):
			for f in frames:
				if int(f.direction)!=rows[row][0] or f.state!=rows[row][1] or int(f.frame)!=index:continue
				if not textures.has(f.sheet):
					var im := Image.load_from_file("res://art_review/hero_pose_v2/"+f.sheet)
					im.fix_alpha_edges()
					textures[f.sheet]=ImageTexture.create_from_image(im)
				var tex := AtlasTexture.new()
				tex.atlas=textures[f.sheet]
				tex.region=Rect2(f.region[0],f.region[1],f.region[2],f.region[3])
				var sprite := Sprite2D.new()
				canvas.add_child(sprite)
				sprite.texture=tex
				sprite.flip_h=f.get("mirror_h",false)
				sprite.offset=Vector2(f.region[2]*0.5-f.root_x,f.region[3]*0.5-f.foot)
				sprite.scale=Vector2.ONE*240.0/float(f.height_reference)
				sprite.position=Vector2(index*400+200,row*320+265)
				var label := Label.new()
				canvas.add_child(label)
				label.position=Vector2(index*400+12,row*320+275)
				label.text="%s %s F%d%s\n%s"%["UP-RIGHT" if int(f.direction)==7 else "UP-LEFT",f.state,index," MIRROR" if f.get("mirror_h",false) else "",f.sheet]
				label.add_theme_font_size_override("font_size",16)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art_review/hero_repair_v3/active_rear_registered.png")
	print("16 exact registered atlas regions captured. Visual audit only; no quality PASS claim.")
	quit()
