extends "res://maps/preview_player.gd"

func update_visual(delta: float) -> void:
	var yaw: float=get_parent().view_yaw
	var original := facing
	facing=facing.rotated(Vector3.UP,-yaw)
	super.update_visual(delta)
	facing=original
	portrait.rotation.y=yaw
	portrait.position=portrait.position.rotated(Vector3.UP,yaw)

func auto_origin() -> Vector3:
	# Static hero comparison has no visible familiars; emit from the hero's torso.
	return global_position+Vector3.UP*1.0
