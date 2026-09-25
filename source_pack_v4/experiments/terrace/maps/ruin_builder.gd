extends RefCounted
## Shared rectilinear terrain compiler: the same cell planes supply render,
## collision and height queries. There is no smoothed cliff heightfield.
const V=preload("res://game/visuals.gd")
const STEP:=0.5
const WATER:=-1.2
var map_id:="ruin_production"
var bounds:=Rect2(-36,-30,72,60)
var layout: Dictionary
var materials: Array[ShaderMaterial]=[]
var edges: Array=[]
var mesh_count:=0

func configure(data: Dictionary) -> void:layout=data
func route() -> Array:return layout.route
func zone_at(_at: Vector3) -> int:return 1
func region(p: Vector2) -> Array:
	for s in layout.stairs:
		if Rect2(s[0],s[1],s[2],s[3]).has_point(p):return s
	var best: Array=[]
	for r in layout.platforms:
		if Rect2(r[0],r[1],r[2],r[3]).has_point(p) and (best.is_empty() or r[4]>best[4]):best=r
	return best
func plane_height(r: Array,p: Vector2) -> float:
	if r.is_empty():return WATER
	if r.size()==5:return r[4]
	# A shallow bevel within each tread is walkable by the existing controller.
	var t:=clampf((r[1]+r[3]-p.y)/r[3],0,1)*16.0
	var phase:=t-floorf(t)
	var step_t:=minf(phase*2,1)*0.9+maxf(phase*2-1,0)*0.1
	return lerpf(r[4],r[5],(floorf(t)+step_t)/16.0)
func height_at(at: Vector3) -> float:
	return plane_height(region(Vector2(at.x,at.z)),Vector2(at.x,at.z))
func ground(at: Vector3,lift: float=0) -> Vector3:return Vector3(at.x,height_at(at)+lift,at.z)
func normal_at(at: Vector3) -> Vector3:
	var r:=region(Vector2(at.x,at.z))
	if r.size()!=6:return Vector3.UP
	var e:=0.02
	return Vector3(0,2*e,plane_height(r,Vector2(at.x,at.z-e))-plane_height(r,Vector2(at.x,at.z+e))).normalized()
func tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
	st.add_vertex(a);st.add_vertex(b);st.add_vertex(c)
func quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	tri(st,a,b,c);tri(st,a,c,d)
func make_mesh(parent: Node3D,st: SurfaceTool,mat: Material,title: String,collision: bool) -> void:
	st.generate_normals()
	var n:=MeshInstance3D.new();n.name=title;n.mesh=st.commit();n.material_override=mat
	parent.add_child(n)
	if collision:n.create_trimesh_collision()
	mesh_count+=1
func stone(wall: bool,texture: Texture2D) -> ShaderMaterial:
	var m:=ShaderMaterial.new();m.shader=preload("res://maps/ruin_stone.gdshader")
	m.set_shader_parameter("wall",wall);m.set_shader_parameter("grain",texture);materials.append(m)
	return m
func build(parent: Node3D,texture: Texture2D) -> void:
	edges.clear();materials.clear();mesh_count=0
	var top:=SurfaceTool.new();top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides:=SurfaceTool.new();sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stair_top:=SurfaceTool.new();stair_top.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Quarter-unit subdivision resolves the stair bevel exactly.
	var step:=0.25
	for iz in range(int(bounds.size.y/step)):
		for ix in range(int(bounds.size.x/step)):
			var p:=bounds.position+Vector2(ix,iz)*step
			var r:=region(p+Vector2.ONE*step*0.5)
			if r.is_empty():continue
			var a:=Vector3(p.x,plane_height(r,p),p.y)
			var b:=Vector3(p.x+step,plane_height(r,p+Vector2(step,0)),p.y)
			var c:=Vector3(p.x+step,plane_height(r,p+Vector2.ONE*step),p.y+step)
			var d:=Vector3(p.x,plane_height(r,p+Vector2(0,step)),p.y+step)
			quad(stair_top if r.size()==6 else top,a,b,c,d)
			for pair in [[a,b,Vector2(0,-1)],[b,c,Vector2(1,0)],[c,d,Vector2(0,1)],[d,a,Vector2(-1,0)]]:
				var v: Vector3=pair[0];var w: Vector3=pair[1];var dir: Vector2=pair[2]
				var mid:=Vector2((v.x+w.x)*0.5,(v.z+w.z)*0.5)
				var nr:=region(mid+dir*0.01)
				var low1:=plane_height(nr,Vector2(v.x,v.z));var low2:=plane_height(nr,Vector2(w.x,w.z))
				if maxf(v.y-low1,w.y-low2)<0.01:continue
				quad(sides,w,v,Vector3(v.x,low1,v.z),Vector3(w.x,low2,w.z))
				if minf(v.y-low1,w.y-low2)>1.0:
					edges.append([v,w,dir])
	make_mesh(parent,top,stone(false,texture),"WalkableTerracesAndStairs",true)
	if not layout.stairs.is_empty():
		var stair_mat:=stone(false,texture);stair_mat.set_shader_parameter("stair",true)
		make_mesh(parent,stair_top,stair_mat,"BeveledStairTreads",true)
	make_mesh(parent,sides,stone(true,texture),"VerticalRetainingFaces",true)
	var water:=SurfaceTool.new();water.begin(Mesh.PRIMITIVE_TRIANGLES)
	quad(water,Vector3(-120,WATER,-120),Vector3(120,WATER,-120),Vector3(120,WATER,120),Vector3(-120,WATER,120))
	var wm:=ShaderMaterial.new();wm.shader=preload("res://maps/ruin_water.gdshader")
	wm.set_shader_parameter("water_tex",load("res://maps/assets/water_surface_v1.png"));materials.append(wm)
	make_mesh(parent,water,wm,"CanalWater",false)
	build_edges(parent,texture)

func build_edges(parent: Node3D,texture: Texture2D) -> void:
	# Merge cell edges into continuous straight wall/capstone runs.
	var runs: Dictionary={}
	for e in edges:
		var a: Vector3=e[0];var b: Vector3=e[1];var dir: Vector2=e[2]
		var along_x:=absf(a.x-b.x)>0.1
		var fixed: float=a.z if along_x else a.x
		var key:="%s:%.2f:%.2f:%s"%[along_x,fixed,a.y,dir]
		if not runs.has(key):runs[key]={"x":along_x,"fixed":fixed,"y":a.y,"dir":dir,"values":[]}
		runs[key].values.append(minf(a.x,b.x) if along_x else minf(a.z,b.z))
	var cap:=stone(false,texture)
	for data in runs.values():
		data.values.sort()
		var start: float=data.values[0];var finish:=start+0.25
		for value in data.values.slice(1):
			if absf(value-finish)>0.02:
				edge_run(parent,data,start,finish,cap);start=value
			finish=value+0.25
		edge_run(parent,data,start,finish,cap)

func edge_run(parent: Node3D,data: Dictionary,start: float,finish: float,mat: Material) -> void:
	var along_x: bool=data.x
	var mid:=(start+finish)*0.5
	var dir: Vector2=data.dir
	var at:=Vector3(mid,data.y+0.12,data.fixed) if along_x else Vector3(data.fixed,data.y+0.12,mid)
	# A visible continuous curb and its collision share the same footprint.
	var size:=Vector3(finish-start,0.24,0.5) if along_x else Vector3(0.5,0.24,finish-start)
	var rim:=V.box(parent,at,size,Color.WHITE,false);rim.get_child(0).material_override=mat
	var barrier:=V.box(parent,at+Vector3(dir.x*0.12,0.9,dir.y*0.12),Vector3(size.x,1.8,size.z),Color.WHITE,true)
	barrier.get_child(0).hide()
	if finish-start<2.0:return
	for pos in range(int(ceil(start/4.0))*4,int(finish),4):
		var foot:=Vector3(pos,data.y,data.fixed) if along_x else Vector3(data.fixed,data.y,pos)
		pillar(parent,foot,mat)

func pillar(parent: Node3D,at: Vector3,mat: Material) -> void:
	for d in [[0.18,0.95,0.36],[0.90,0.62,1.10],[1.53,0.88,0.22]]:
		var n:=V.box(parent,at+Vector3.UP*d[0],Vector3(d[1],d[2],d[1]),Color.WHITE,false)
		n.get_child(0).material_override=mat

func set_plain(value: bool) -> void:
	for m in materials:m.set_shader_parameter("plain",value)
