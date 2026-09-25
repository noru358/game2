extends SceneTree
const Hero=preload("res://game/hero_visual.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var stage:=Node3D.new()
	root.add_child(stage)
	var env:=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("263a3a")
	stage.add_child(env)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=18
	camera.position=Vector3(0,23,18)
	camera.rotation_degrees=Vector3(-52,0,0)
	stage.add_child(camera)
	var visual:=Hero.new()
	var sprites: Array[Sprite3D]=[]
	for mode in range(2):
		for d in range(8):
			var anchor:=Node3D.new()
			anchor.position=Vector3(-12.25+d*3.5,0,-3 if mode==0 else 3)
			stage.add_child(anchor)
			var sprite:=Sprite3D.new()
			sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			anchor.add_child(sprite)
			sprites.append(sprite)
			var label:=Label3D.new()
			label.text=("WALK " if mode==0 else "RUN ")+["E","SE","S","SW","W","NW","N","NE"][d]
			label.position=Vector3(0,-0.4,0.5)
			label.font_size=32
			label.pixel_size=0.018
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			anchor.add_child(label)
			var frames: Array=[]
			for step in range(4):
				visual.apply(sprite,Vector3(cos(d*PI/4),0,sin(d*PI/4)),true,step*PI/2+0.01,false,mode==1)
				var pose := [sprite.texture,sprite.flip_h]
				if not pose in frames: frames.append(pose)
			var ok:=frames.size()==4
			print("PASS " if ok else "FAIL ","four distinct gait phases mode=",mode," direction=",d)
			if not ok: failures+=1
	for frame in range(48):
		for mode in range(2):
			for d in range(8):
				var phase:=float(frame)/24.0*(10.0/1.9 if mode==1 else 7.5/1.7)*PI
				visual.apply(sprites[mode*8+d],Vector3(cos(d*PI/4),0,sin(d*PI/4)),true,phase,false,mode==1)
		await process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			if frame in [0,3,6,9]:
				var folder:=OS.get_environment("DEMO_QA_OUTPUT")
				if folder.is_empty():folder="res://docs/validation"
				var error:=root.get_texture().get_image().save_png(folder+"/gait-cycle-%02d.png"%frame)
				if error!=OK:
					failures+=1
					print("FAIL gait capture ",error)
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
