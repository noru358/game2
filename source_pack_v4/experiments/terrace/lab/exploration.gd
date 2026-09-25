extends RefCounted
var world: Node3D
var attunement := ""
func _init(owner: Node3D) -> void: world=owner
func respawn_point() -> Vector3:
	if world.has_method("checkpoint"):return world.checkpoint()
	return world.Landscape.on_ground(Vector3(110,0,8),0.1)
