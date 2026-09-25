extends RefCounted
## Two outdoor terraces, not overlapping interior floors.
const LOWER := 1.0
const UPPER := 5.2
const RISE := UPPER-LOWER
const STAIR_START := 6.0
const STAIR_END := -3.0
const STAIR_HALF_WIDTH := 3.2
const STEPS := 18
const PLATFORM := Rect2(-10,-17,20,14)

static func height(x: float,z: float) -> float:
	var inside_x := smoothstep(-10.5,-10.0,x)*(1.0-smoothstep(10.0,10.5,x))
	var inside_z := smoothstep(-17.5,-17.0,z)*(1.0-smoothstep(-3.0,-2.5,z))
	var platform := inside_x*inside_z
	var ramp_x := 1.0-smoothstep(STAIR_HALF_WIDTH,STAIR_HALF_WIDTH+0.5,absf(x))
	var progress := clampf((STAIR_START-z)/(STAIR_START-STAIR_END),0,1)*STEPS
	var index := floorf(progress)
	var phase := progress-index
	# Each half-meter tread has a shallow bevel (40 degrees max at .25 grid).
	# The visible stairs and collision use this same surface, no hidden ramp.
	var step_progress := minf(phase*2.0,1.0)*0.9+maxf(phase*2.0-1.0,0.0)*0.1
	var ramp := (index+step_progress)/STEPS*ramp_x
	if z<STAIR_END:ramp=0.0
	return LOWER+RISE*maxf(platform,ramp)

static func route() -> Array[Vector2]:
	return [Vector2(-12,9),Vector2(-6,9),Vector2(0,6),Vector2(0,1),Vector2(0,-4),Vector2(0,-8)]
