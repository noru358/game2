extends Control
## Full terrain, discovered landmarks only. Approved D105.
var world:Node3D
var full_map:=true
var mapped_state:=""
var cells:Dictionary={}
var seen:Dictionary={}
var timer:=0.0
const FONT=preload("res://assets/fonts/NanumGothic-Regular.ttf")
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	rebuild_map()
func rebuild_map():
	mapped_state=str(world.chapter)+str(world.shortcut)
	cells.clear()
	await get_tree().physics_frame
	var query:=PhysicsShapeQueryParameters3D.new()
	var shape:=SphereShape3D.new()
	shape.radius=0.43
	query.shape=shape
	query.collision_mask=1
	for x in range(101,140):
		for z in range(-31,14):
			var at:Vector3=world.Landscape.on_ground(Vector3(x,0,z),0.65)
			query.transform=Transform3D(Basis.IDENTITY,at)
			if world.Landscape.normal_at(at).y>0.70 and world.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():cells[Vector2i(x,z)]=true
	reveal(world.player.position)
	queue_redraw()
func reveal(at:Vector3):
	for x in range(int(at.x)-7,int(at.x)+8):
		for z in range(int(at.z)-7,int(at.z)+8):
			if Vector2(x-at.x,z-at.z).length()<7:seen[Vector2i(x,z)]=true
func _process(delta:float):
	timer+=delta
	if timer>0.15:
		timer=0
		if mapped_state!=str(world.chapter)+str(world.shortcut):rebuild_map()
		reveal(world.player.position)
		queue_redraw()
func map_point(at:Vector3)->Vector2:return Vector2(1075+(at.x-100)*4,66+(at.z+32)*4)
func _draw():
	for i in range(5):
		var at:=Vector2(35+i*30,40)
		var points:=PackedVector2Array([at+Vector2(0,-8),at+Vector2(11,0),at+Vector2(0,8),at+Vector2(-11,0)])
		draw_colored_polygon(points,Color("d2dfb2") if i<world.player.hp else Color(0.18,0.24,0.18,0.8))
		draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]),Color("6c7e5b"),1,true)
	draw_string(FONT,Vector2(1075,42),world.TITLES[world.chapter],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("e9e3cb"))
	draw_rect(Rect2(1067,58,177,200),Color(0.025,0.06,0.045,0.46))
	for cell in cells:
		if not full_map and not seen.has(cell):continue
		var h:float=world.Landscape.height_at(Vector3(cell.x,0,cell.y))
		draw_rect(Rect2(map_point(Vector3(cell.x,0,cell.y)),Vector2(4,4)),Color(0.40+h*0.025,0.50+h*0.023,0.37+h*0.02,0.52))
	for i in range(world.CLUES.size()):
		if not i in world.discoveries:continue
		draw_circle(map_point(world.CLUES[i]),3,Color("d7c891"))
	if world.chapter==1 and world.vista:draw_circle(map_point(world.LOOKOUT),3,Color("d7c891"))
	var p:=map_point(world.player.position)
	var direction:=Vector2(world.player.facing.x,world.player.facing.z).normalized()
	var side:=Vector2(-direction.y,direction.x)
	draw_colored_polygon(PackedVector2Array([p+direction*6,p-direction*4+side*3,p-direction*4-side*3]),Color("fff5d4"))
