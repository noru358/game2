extends RefCounted
## A cue occupies one local plane. Never fold its vertices over terrace faces.
const Land=preload("res://game/landscape.gd")
static var override_surface
static var override_revision:=0

static func set_override(surface) -> void:
	override_surface=surface
	override_revision+=1

static func clear_override(surface) -> void:
	if override_surface==surface:
		override_surface=null
		override_revision+=1

static func signature() -> Array:
	return [override_revision,override_surface.get_instance_id() if override_surface!=null else 0]

static func height_at(at: Vector3) -> float:
	return override_surface.height_at(at) if override_surface!=null else Land.height_at(at)

static func normal_at(at: Vector3) -> Vector3:
	return override_surface.normal_at(at) if override_surface!=null else Land.normal_at(at)

static func slope(center:Vector3) -> Vector2:
	var n:=normal_at(center)
	if n.y<0.72:return Vector2.ZERO
	return Vector2(-n.x/n.y,-n.z/n.y)
static func point(center:Vector3,offset:Vector3,lift:float=0.16) -> Vector3:
	return plane_point(center,offset,sample_plane(center),lift)
static func sample_plane(center:Vector3)->Vector3:
	var gradient:=slope(center)
	return Vector3(gradient.x,gradient.y,height_at(center))
static func plane_point(center:Vector3,offset:Vector3,plane:Vector3,lift:float=0.16)->Vector3:
	return Vector3(center.x+offset.x,plane.z+plane.x*offset.x+plane.y*offset.z+lift,center.z+offset.z)
static func plane_supported(center:Vector3,offset:Vector3,plane:Vector3)->bool:
	var at:=plane_point(center,offset,plane,0)
	return absf(at.y-height_at(at))<=0.25 and normal_at(at).y>=0.65
static func supported(center:Vector3,offset:Vector3) -> bool:
	return plane_supported(center,offset,sample_plane(center))
