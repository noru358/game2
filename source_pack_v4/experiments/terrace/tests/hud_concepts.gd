extends SceneTree
var stage:Control
const FONT=preload("res://assets/fonts/NanumGothic-Regular.ttf")
func _initialize():call_deferred("run")
func text_at(value:String,at:Vector2,size:int=20,color:Color=Color("e9e4cf")):
	var label:=Label.new()
	label.text=value
	label.position=at
	label.add_theme_font_override("font",FONT)
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	stage.add_child(label)
func panel(at:Vector2,size:Vector2):
	var p:=Panel.new()
	p.position=at
	p.size=size
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.09,0.16,0.12,0.94)
	style.border_color=Color("899372")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	p.add_theme_stylebox_override("panel",style)
	stage.add_child(p)
func health(at:Vector2):
	for i in range(5):
		var box:=ColorRect.new()
		box.position=at+Vector2(i*36,0)
		box.size=Vector2(29,9)
		box.color=Color("aec384") if i<4 else Color("53634e")
		stage.add_child(box)
func run():
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	var folder:=OS.get_environment("DEMO_QA_OUTPUT")
	for version in ["A","B"]:
		stage=Control.new()
		root.add_child(stage)
		stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var bg:=TextureRect.new()
		bg.texture=ImageTexture.create_from_image(Image.load_from_file(folder+"/ui-backdrop.png"))
		bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		bg.size=Vector2(1280,800)
		stage.add_child(bg)
		if version=="A":
			panel(Vector2(24,24),Vector2(240,137))
			text_at("동물 술사 · Lv.2",Vector2(42,36),16)
			text_at("세 번 잇기",Vector2(42,61),22)
			health(Vector2(42,99))
			text_at("체력 4 / 5",Vector2(42,116),14)
			panel(Vector2(982,24),Vector2(274,121))
			text_at("첫 여정 · 뿌리의 단상",Vector2(1000,39),21)
			text_at("뿌리 너머 사원으로\n살펴본 흔적 1 / 2",Vector2(1000,75),16)
			panel(Vector2(326,728),Vector2(628,50))
			text_at("J  직접 마법     Space  회피     자동 · 갈래     Esc  쉬기",Vector2(344,741),18)
		else:
			panel(Vector2(0,682),Vector2(1280,118))
			text_at("동물 술사   Lv.2",Vector2(26,694),21)
			health(Vector2(26,732))
			text_at("체력 4 / 5 · 세 번 잇기",Vector2(26,752),14)
			text_at("J  직접 마법      Space  회피      자동 · 갈래",Vector2(365,728),20)
			text_at("사원으로 가는 길\n흔적 1 / 2 · Esc 쉬기",Vector2(1020,707),19)
			text_at("첫 여정 · 뿌리의 단상",Vector2(534,24),17)
		panel(Vector2(505,640 if version=="B" else 677),Vector2(270,35))
		text_at("F  가까운 흔적 살피기",Vector2(526,646 if version=="B" else 683),17)
		for i in range(3):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"/hud-concept-"+version+".png")
		stage.free()
	print("RESULT two native HUD concept renders; not installed in game")
	quit()
