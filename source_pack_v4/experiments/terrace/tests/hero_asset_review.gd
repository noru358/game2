extends SceneTree

# Isolated asset viewer. Does not instantiate the game or touch saves.
const DIR = "res://art_review/hero_idle_v1/"

class ReviewBoard extends Control:
	var atlas: Texture2D
	var frames: Array
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 800), Color("20252b"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(24, 32), "FENNEC IDLE / CANDIDATE / not integrated", HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		draw_string(font, Vector2(24, 59), "8 direct views, no mirroring. Cyan marks = registered foot/root. 74px = target window scale.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		var heights := [222.0, 74.0, 74.0, 74.0]
		var baselines := [340.0, 462.0, 594.0, 726.0]
		var backgrounds := [Color("353941"), Color("f1ead8"), Color("15201c"), Color("687344")]
		for row in range(4):
			var panel_y: float = 90 if row == 0 else baselines[row] - 98
			draw_rect(Rect2(16, panel_y, 1248, baselines[row] - panel_y + 26), backgrounds[row])
			for i in range(8):
				var d: Dictionary = frames[i]
				var region: Array = d.region
				var scale_factor: float = heights[row] / (float(d.foot) - float(d.top))
				var anchor := Vector2(94 + i * 156, baselines[row])
				var dest := Rect2(anchor - Vector2(d.root_x, d.foot) * scale_factor, Vector2(region[2], region[3]) * scale_factor)
				draw_texture_rect_region(atlas, dest, Rect2(region[0], region[1], region[2], region[3]))
				draw_line(anchor - Vector2(12, 0), anchor + Vector2(12, 0), Color.CYAN)
				draw_line(anchor - Vector2(0, 4), anchor + Vector2(0, 4), Color.CYAN)
				if row == 0:
					draw_string(font, Vector2(28 + i * 156, 83), str(i) + " " + str(d.direction), HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		draw_string(font, Vector2(24, 785), "Top: 3x inspection. Lower rows: 1x on light, dark and vegetation colors. Esc closes. No user saves.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 800)
	var asset_dir := DIR
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--asset-dir="):
			asset_dir = arg.trim_prefix("--asset-dir=").trim_suffix("/") + "/"
	var image := Image.load_from_file(ProjectSettings.globalize_path(asset_dir + "candidate.png"))
	var data = JSON.parse_string(FileAccess.get_file_as_string(asset_dir + "frames.json"))
	if image == null or not data is Array or data.size() != 8:
		push_error("Invalid atlas or eight-direction metadata")
		quit(1)
		return
	for i in range(8):
		var d: Dictionary = data[i]
		var r: Array = d.region
		if d.engine_index != i or d.foot <= d.top or d.root_x < 0 or d.root_x >= r[2] or r[0] + r[2] > image.get_width() or r[1] + r[3] > image.get_height():
			push_error("Invalid frame contract at " + str(i))
			quit(1)
			return
	var board := ReviewBoard.new()
	image.fix_alpha_edges()
	image.generate_mipmaps()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	board.atlas = ImageTexture.create_from_image(image)
	board.frames = data
	root.add_child(board)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path(asset_dir + "review.png")
	var error := root.get_texture().get_image().save_png(output)
	print("HERO_REVIEW: eight frame contracts valid; GPU capture ", error, " -> ", output)
	if "--test" in OS.get_cmdline_user_args():
		quit(0 if error == OK else 1)

func _process(_delta: float) -> bool:
	if Input.is_key_pressed(KEY_ESCAPE):
		quit()
	return false
