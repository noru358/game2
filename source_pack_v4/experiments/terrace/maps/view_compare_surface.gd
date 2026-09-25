extends RefCounted
const Land=preload("res://game/landscape.gd")
var map_id := "view_compare"
func ground(at: Vector3,lift: float=0.0) -> Vector3:return Land.on_ground(at,lift)
func height_at(at: Vector3) -> float:return Land.height_at(at)
func normal_at(at: Vector3) -> Vector3:return Land.normal_at(at)

