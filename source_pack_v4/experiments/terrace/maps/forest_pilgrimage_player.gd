extends "res://game/player.gd"
## Approved hero motion adapted to the fixed yaw and custom graybox surface.

func _ready() -> void:
	hero_visual=preload("res://game/approved_hero_visual.gd").new()
	super._ready()
	update_visual(0)

func update_visual(delta: float) -> void:
	if not is_instance_valid(get_parent()) or not get_parent().has_method("movement_direction"):
		super.update_visual(delta)
		return
	var yaw: float=get_parent().view_yaw
	var original_facing:=facing
	var original_casting:=casting_direction
	var original_dash:=dash_velocity
	facing=facing.rotated(Vector3.UP,-yaw)
	casting_direction=casting_direction.rotated(Vector3.UP,-yaw)
	dash_velocity=dash_velocity.rotated(Vector3.UP,-yaw)
	super.update_visual(delta)
	facing=original_facing
	casting_direction=original_casting
	dash_velocity=original_dash
	portrait.rotation.y=yaw
	portrait.position=portrait.position.rotated(Vector3.UP,yaw)
	weapon.position=weapon.position.rotated(Vector3.UP,yaw)
	second_focus.position=second_focus.position.rotated(Vector3.UP,yaw)
	var pitch: float=get_parent().camera_pitch
	portrait.scale.y*=cos(deg_to_rad(52.0))/cos(deg_to_rad(pitch))
	var terrain=get_parent().surface
	contact_shadow.position.y=terrain.height_at(position)-position.y+0.035
	contact_shadow.quaternion=Quaternion(Vector3.UP,terrain.normal_at(position))
	occluded_portrait.texture=portrait.texture
	occluded_portrait.pixel_size=portrait.pixel_size
	occluded_portrait.offset=portrait.offset
	occluded_portrait.flip_h=portrait.flip_h
	occluded_portrait.transform=portrait.transform
