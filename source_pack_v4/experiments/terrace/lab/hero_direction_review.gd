extends Node3D
# Visual comparison only: shared textures and renderer, no world or save access.
var visual = preload("res://game/approved_hero_visual.gd").new()
var cards: Array[Sprite3D] = []
var clock := 0.0
var frozen := false
var slow := false
var mode := 0
var title: Label
var captures := 0
const NAMES = ["RIGHT", "FRONT-RIGHT", "FRONT", "FRONT-LEFT", "LEFT", "BACK-LEFT", "BACK", "BACK-RIGHT"]
func _ready() -> void:
	if not "--test" in OS.get_cmdline_user_args():get_tree().quit(2);return
	RenderingServer.set_default_clear_color(Color("252c35"))
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=10.5
	camera.position=Vector3(0,0.788,0.616)*24
	camera.look_at(Vector3.ZERO)
	camera.current=true
	for i in range(8):
		var anchor := Node3D.new()
		add_child(anchor)
		anchor.position=Vector3((i%4-1.5)*4.0,0,0)+Vector3(0,0.616,-0.788)*(1.1 if i<4 else -3.2)
		var card := Sprite3D.new()
		anchor.add_child(card)
		card.shaded=false
		card.double_sided=true
		cards.append(card)
		var label := Label3D.new()
		anchor.add_child(label)
		label.text=NAMES[i]
		label.font_size=36
		label.pixel_size=0.008
		label.position=Vector3(0,-0.35,0)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test=true
	var layer := CanvasLayer.new()
	add_child(layer)
	title=Label.new()
	layer.add_child(title)
	title.position=Vector2(24,16)
	title.add_theme_font_size_override("font_size",20)
	var help := Label.new()
	layer.add_child(help)
	help.position=Vector2(24,680)
	help.text="0 Auto   1 Idle   2 Walk   3 Run   4 Combo   Space Pause   Q 1/4 speed   Right Step"
	update_cards()
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode>=KEY_0 and event.keycode<=KEY_4:mode=event.keycode-KEY_0;clock=0
	if event.keycode==KEY_SPACE:frozen=not frozen
	if event.keycode==KEY_Q:slow=not slow
	if event.keycode==KEY_RIGHT:frozen=true;clock+=1.0/30.0
	update_cards()
func _process(delta: float) -> void:
	if not frozen:clock+=delta*(0.25 if slow else 1.0)
	update_cards()
	if "--capture" in OS.get_cmdline_user_args():
		# Sample all four phases instead of accidentally capturing the same stride twice.
		var moments := [0.1,1.37,1.54,1.70,1.87,3.08,3.20,3.31,3.43,5.25,6.05,6.85]
		if captures<moments.size() and clock>=moments[captures]:
			var index := captures
			captures+=1
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://art_review/hero_reskin_v1/direction_loop_%02d.png"%index)
		if clock>7.5:print("PASS eight-direction visual loop captured; art acceptance pending");get_tree().quit()
func update_cards() -> void:
	var t := fposmod(clock,7.4)
	var state := mode
	if state==0:state=1 if t<1 else (2 if t<3 else (3 if t<5 else 4))
	var phase := clock*TAU*(2.2 if state==3 else 1.5)
	var attack_time := fposmod(clock if mode==4 else maxf(t-5,0),2.4)
	var step := int(attack_time/0.8)+1
	var part := fposmod(attack_time,0.8)
	for i in range(8):
		visual.idle(cards[i],i)
		if state==2 or state==3:
			var direction := Vector3(cos(i*PI/4.0),0,sin(i*PI/4.0))
			visual.locomotion.apply(cards[i],direction,state==3,phase+PI*0.5 if state==3 else phase)
		elif state==4:visual.animated.apply(cards[i],"attack",-1 if part<0.18 else 0,step,part>0.42,i)
	title.text="8 DIRECTIONS  |  %s  |  %s%s"%[["AUTO","IDLE","WALK","RUN","COMBO %d"%step][state],"PAUSED" if frozen else "PLAYING","  1/4" if slow else ""]
