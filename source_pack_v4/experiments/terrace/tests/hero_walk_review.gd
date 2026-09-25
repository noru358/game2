extends SceneTree
const DIR = "res://art_review/hero_walk_v1/"
class Board extends Control:
	var atlas: Texture2D
	var frames: Array
	var animated := false
	var playing := true
	var phase := 0
	var elapsed := 0.0
	var advances := 0
	func _process(delta: float) -> void:
		if animated and playing:
			elapsed += delta
			if elapsed >= 1.0/6.0:
				phase = (phase + 1) % 4
				advances += 1
				elapsed = fmod(elapsed,1.0/6.0)
				queue_redraw()
	func _input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_SPACE: playing = not playing
			if event.keycode == KEY_RIGHT:
				playing = false
				phase = (phase + 1) % 4
				queue_redraw()
			if event.keycode == KEY_ESCAPE: get_tree().quit()
	func _draw() -> void:
		draw_rect(Rect2(0,0,1280,900),Color("303940"))
		var font := ThemeDB.fallback_font
		draw_string(font,Vector2(20,28),"8-DIRECTION TARGET / 4-DIRECTION WALK CANDIDATE / NOT ACCEPTED",HORIZONTAL_ALIGNMENT_LEFT,-1,21)
		for i in range(16):
			var d: Dictionary = frames[i]
			var row := i / 4
			var col := i % 4
			if animated:
				if col != phase: continue
				col = 1
			var region: Array = d.region
			var anchor := Vector2(95 + col*310, 230 + row*210)
			for size in [148.0,74.0]:
				var scale_factor: float = size / 310.0
				var point := anchor + (Vector2(125,0) if size == 74 else Vector2.ZERO)
				var dest := Rect2(point - Vector2(d.root_x,d.foot)*scale_factor,Vector2(region[2],region[3])*scale_factor)
				draw_texture_rect_region(atlas,dest,Rect2(region[0],region[1],region[2],region[3]))
				draw_line(point-Vector2(10,0),point+Vector2(10,0),Color.CYAN)
				draw_line(point-Vector2(0,4),point+Vector2(0,4),Color.CYAN)
			draw_string(font,Vector2(20+col*310,64+row*210),str(d.direction)+" / phase "+str(d.phase+1),HORIZONTAL_ALIGNMENT_LEFT,-1,16)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,900)
	root.content_scale_size=Vector2i(1280,900)
	var image := Image.load_from_file(ProjectSettings.globalize_path(DIR+"candidate.png"))
	var board := Board.new()
	image.generate_mipmaps()
	board.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	board.atlas=ImageTexture.create_from_image(image)
	board.frames=JSON.parse_string(FileAccess.get_file_as_string(DIR+"frames.json"))
	var motion_test := "--motion-test" in OS.get_cmdline_user_args()
	board.animated = motion_test or not "--test" in OS.get_cmdline_user_args()
	root.add_child(board)
	if motion_test:
		await create_timer(2.0).timeout
		print("WALK_LOOP: advances=",board.advances,"; phase=",board.phase)
		if board.advances < 8:
			quit(1)
			return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(DIR+("motion.png" if board.animated else "review.png")))
	print("WALK_REVIEW: GPU capture result ",result,"; 16 candidate frames, final target 8 directions")
	if motion_test or "--test" in OS.get_cmdline_user_args():
		quit(0 if result==OK else 1)
