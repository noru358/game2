extends "res://game/enemy.gd"

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	refresh_view()

func refresh_view() -> void:
	if dead:return
	var yaw: float=get_parent().view_yaw
	var preparing := windup>0
	visual.apply(portrait,facing.rotated(Vector3.UP,-yaw),flash>0)
	visual.animate(portrait,facing.rotated(Vector3.UP,-yaw),gait,Vector2(velocity.x,velocity.z).length()>0.1,preparing,attack_recoil,flash>0)
	portrait.position=portrait.position.rotated(Vector3.UP,yaw)
	# Health bars are meshes rather than billboard sprites.
	for child in get_children():
		if child is Node3D and child!=portrait and child!=body and child!=telegraph and child!=charge_lane and not child is CollisionShape3D:
			if not child.has_meta("view_base"):child.set_meta("view_base",child.position)
			child.position=Vector3(child.get_meta("view_base")).rotated(Vector3.UP,yaw)
			child.rotation.y=yaw
