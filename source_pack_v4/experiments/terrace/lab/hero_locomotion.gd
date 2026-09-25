extends MeshInstance3D
# Runtime mesh animation, not newly drawn poses. Side views have one visible leg.
var surfaces: Array[ArrayMesh]=[]
var materials: Array[ShaderMaterial]=[]
var phase := 0.0
var strength := 0.0
var last_position := Vector3.ZERO
var initialized := false
var motion_enabled := true
var soft_filter := false
var travelled := 0.0
enum State { IDLE, WALK, RUN, DASH }
var state := State.IDLE
var run_blend := 0.0
var measured_speed := 0.0

func state_label() -> String:
	return ["멈춤","걷기","달리기","회피"][state]

func setup(texture: Texture2D, frames: Array) -> void:
	for d in frames:
		var vertices := PackedVector3Array()
		var uvs := PackedVector2Array()
		var indices := PackedInt32Array()
		var size := Vector2(d.region[2],d.region[3])
		var pixel: float=2.25/(float(d.foot)-float(d.top))
		for y in range(49):
			for x in range(33):
				var uv := Vector2(x/32.0,y/48.0)
				vertices.append(Vector3((uv.x*size.x-float(d.root_x))*pixel,(0.5-uv.y)*size.y*pixel,0))
				uvs.append((Vector2(d.region[0],d.region[1])+uv*size)/Vector2(texture.get_size()))
		for y in range(48):
			for x in range(32):
				var i := y*33+x
				indices.append_array(PackedInt32Array([i,i+33,i+1,i+1,i+33,i+34]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=vertices
		arrays[Mesh.ARRAY_TEX_UV]=uvs
		arrays[Mesh.ARRAY_INDEX]=indices
		var surface := ArrayMesh.new()
		surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		surfaces.append(surface)
		var mat := ShaderMaterial.new()
		mat.shader=preload("res://lab/hero_locomotion.gdshader")
		mat.set_shader_parameter("artwork",texture)
		mat.set_shader_parameter("artwork_soft",texture)
		mat.set_shader_parameter("region",Vector4(d.region[0]/float(texture.get_width()),d.region[1]/float(texture.get_height()),size.x/texture.get_width(),size.y/texture.get_height()))
		mat.set_shader_parameter("root_u",float(d.root_x)/size.x)
		mat.set_shader_parameter("foot_v",float(d.foot)/size.y)
		materials.append(mat)
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin=0.3

func advance(at: Vector3, delta: float, dashing: bool) -> void:
	if not initialized:last_position=at;initialized=true
	var distance := Vector2(at.x-last_position.x,at.z-last_position.z).length()
	last_position=at
	# Ignore region/reset teleports and suspend stepping while dashing.
	if distance>1.0:distance=0.0
	var moving := distance>0.0005 and not dashing and motion_enabled
	measured_speed=distance/maxf(delta,0.00001)
	if dashing and motion_enabled:state=State.DASH
	elif not moving:state=State.IDLE
	elif measured_speed>=8.9:state=State.RUN
	elif state!=State.RUN or measured_speed<8.5:state=State.WALK
	run_blend=move_toward(run_blend,1.0 if state==State.RUN else 0.0,delta*8.0)
	if moving:
		travelled+=distance
		phase=fposmod(phase+distance*PI/lerpf(1.7,1.9,run_blend),TAU)
	strength=move_toward(strength,1.0 if moving else 0.0,delta*12.0)

func display(index: int, sprite: Sprite3D, dashing: bool) -> void:
	mesh=surfaces[index]
	material_override=materials[index]
	transform=sprite.transform
	var mat := materials[index]
	mat.set_shader_parameter("phase",phase)
	mat.set_shader_parameter("amount",strength if motion_enabled else 0.0)
	mat.set_shader_parameter("lateral",cos(index*PI/4.0))
	mat.set_shader_parameter("dash",1.0 if dashing and motion_enabled else 0.0)
	mat.set_shader_parameter("soft_filter",soft_filter)
	mat.set_shader_parameter("run_blend",run_blend)
