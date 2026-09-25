extends RefCounted
## One contract for damage, reach, animation timing and effect size.
static func stage(kills: int) -> int:
	return 2 if kills>=8 else (1 if kills>=4 else 0)
static func profile(kills: int) -> Dictionary:
	var tier:=stage(kills)
	return {"cone_dot":0.25,"tier":tier,"combo_count":2 if tier==0 else 3,
		"damage":[[4,5,5],[6,7,10],[7,8,14]][tier],
		"reach":[2.5,2.9,3.4][tier],"effect_scale":[0.78,1.0,1.2][tier],
		"auto_damage":[2,3,4][tier],"auto_interval":[0.42,0.34,0.30][tier],
		"hitstop":[0.018,0.022,0.027][tier]}
