extends SceneTree
# Independent 3D fixture. Same camera pitch/size and sprite projection as game.
const DIR = "res://art_review/hero_idle_exact_v1/"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1152,720)
	root.content_scale_size=Vector2i(1152,720)
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("26353a")
	world.add_child(environment)
	var camera := Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=22.0
	camera.position=Vector3(0,25*sin(deg_to_rad(52)),25*cos(deg_to_rad(52)))
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current=true
	var image := Image.load_from_file(ProjectSettings.globalize_path(DIR+"candidate.png"))
	image.fix_alpha_edges()
	image.generate_mipmaps()
	var atlas := ImageTexture.create_from_image(image)
	var frames: Array=JSON.parse_string(FileAccess.get_file_as_string(DIR+"frames.json"))
	var errors: Array=[]
	for row in range(3):
		var z: float = (row-1)*5.0
		var gradient: float = [0.0,0.2,-0.2][row]
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for point in [Vector2(-11,-1.9),Vector2(-11,1.9),Vector2(11,-1.9),Vector2(11,-1.9),Vector2(-11,1.9),Vector2(11,1.9)]:
			mesh.surface_add_vertex(Vector3(point.x,point.y*gradient,z+point.y))
		mesh.surface_end()
		var ground := MeshInstance3D.new()
		ground.mesh=mesh
		var material := StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		material.albedo_color=[Color("b8b4a2"),Color("607246"),Color("454b47")][row]
		ground.material_override=material
		world.add_child(ground)
		for i in range(8):
			var d: Dictionary=frames[i]
			var r: Array=d.region
			var frame := AtlasTexture.new()
			frame.atlas=atlas
			frame.region=Rect2(r[0],r[1],r[2],r[3])
			frame.filter_clip=true
			var sprite := Sprite3D.new()
			sprite.texture=frame
			sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sprite.shaded=false
			sprite.pixel_size=2.25/(float(d.foot)-float(d.top))
			sprite.offset.x=float(r[2])*0.5-float(d.root_x)
			sprite.scale.y=1.0/cos(deg_to_rad(52))
			var baseline: float=(float(d.foot)-float(r[3])*0.5)*sprite.pixel_size
			sprite.position=Vector3(-8.75+i*2.5,baseline/cos(deg_to_rad(52))+0.04,z)
			world.add_child(sprite)
			var sole := sprite.to_global(Vector3((float(d.root_x)-float(r[2])*0.5+sprite.offset.x)*sprite.pixel_size,(float(r[3])*0.5-float(d.foot))*sprite.pixel_size,0))
			if absf(sole.y-0.04)>0.001: errors.append([row,i,sole.y])
			var marker := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size=Vector3(0.35,0.025,0.035)
			marker.mesh=box
			marker.position=Vector3(-8.75+i*2.5,0.018,z)
			var mark_mat := StandardMaterial3D.new()
			mark_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			mark_mat.albedo_color=Color.CYAN
			marker.material_override=mark_mat
			world.add_child(marker)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path(DIR+"review_3d.png")
	var result := root.get_texture().get_image().save_png(output)
	var report := {"fixture":"isolated flat, +20% and -20% grade", "views":24,"camera_pitch":52,"camera_size":22,"sole_errors":errors,"capture_error":result,"game_integration":false}
	var file := FileAccess.open(DIR+"review_3d.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report))
	quit(0 if errors.is_empty() and result==OK else 1)
