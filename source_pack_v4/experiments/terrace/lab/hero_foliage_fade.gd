extends RefCounted
# Experimental screen-ray alpha test; geometry/collisions remain unchanged.
var entries: Array=[]
var images: Dictionary={}
var active_count := 0
var enabled := true

func collect(world: Node) -> void:
	for e in entries:
		if is_instance_valid(e.sprite):e.sprite.modulate=e.color
	entries.clear()
	for node in world.get_children():
		if not node is Sprite3D or not node.texture is AtlasTexture:continue
		var texture: AtlasTexture=node.texture
		if not texture.atlas.resource_path.ends_with("monsoon_props_v1.png"):continue
		var key := str(texture.region)
		if not images.has(key):images[key]=texture.get_image()
		entries.append({"sprite":node,"color":node.modulate,"image":images[key]})

func obscures(sprite: Sprite3D, image: Image, camera: Camera3D, point: Vector3) -> bool:
	var normal := camera.global_basis.z.normalized()
	var depth: float=(sprite.global_position-point).dot(normal)
	# Depth eligibility is checked against the actor foot, not each upper-body sample.
	var hit := point+normal*depth-sprite.global_position
	var scale_x := sprite.pixel_size*sprite.global_basis.x.length()
	var scale_y := sprite.pixel_size*sprite.global_basis.y.length()
	var pixel := Vector2(hit.dot(camera.global_basis.x)/scale_x+image.get_width()*0.5-sprite.offset.x,
		-hit.dot(camera.global_basis.y)/scale_y+image.get_height()*0.5+sprite.offset.y)
	if pixel.x<0 or pixel.y<0 or pixel.x>=image.get_width() or pixel.y>=image.get_height():return false
	return image.get_pixel(int(pixel.x),int(pixel.y)).a>0.35

func update(camera: Camera3D, points: Array[Vector3], delta: float) -> void:
	active_count=0
	for e in entries:
		if not is_instance_valid(e.sprite):continue
		var blocked := false
		if enabled and (e.sprite.global_position-points[0]).dot(camera.global_basis.z)>-0.75:
			for point in points:
				if obscures(e.sprite,e.image,camera,point):blocked=true;break
		if blocked:active_count+=1
		var color: Color=e.color
		color.a*=0.20 if blocked else 1.0
		e.sprite.modulate=e.sprite.modulate.lerp(color,1.0-exp(-delta*14.0))

