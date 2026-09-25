extends "res://lab/journey.gd"
# Actual journey gameplay with candidate character, always isolated from real saves.
var character_ready := false
var foliage := preload("res://lab/hero_foliage_fade.gd").new()
func _ready() -> void:
	if not "--test" in OS.get_cmdline_user_args():
		get_tree().quit(2);return
	super._ready()
	player.hero_visual=preload("res://game/approved_hero_visual.gd").new()
	character_ready=true
	player.update_visual(0)
	foliage.collect(self)
	message="캐릭터 제작 중 · WASD 이동 / J 휘두르기 3연타 / Space 회피 / 실제 저장 없음"
	message_left=12
func attack_profile() -> Dictionary:
	var profile := super.attack_profile()
	if character_ready:
		profile.combo_count=3
		profile.windup_seconds=[0.05,0.05,0.08]
		profile.gesture_sweeps=true
		profile.manual_speed=[1.12,1.20,1.28][int(profile.tier)]
		profile.hitstop=float(profile.hitstop)+0.012
	return profile
func auto_attack() -> void:
	preload("res://game/fox_fire.gd").fire(self)
func travel(next: int) -> void:
	super.travel(next)
	foliage.collect(self)
func _process(delta: float) -> void:
	if character_ready:
		var points: Array[Vector3]=[]
		for height in [0.0,0.8,1.8,2.7]:points.append(player.global_position+Vector3.UP*height+Vector3(0,0.788,0.616)*0.65)
		foliage.update(camera,points,delta)

