extends Control
# Rendering-only cutout experiment. Original PNG bytes are never modified.
# Not production art: boot region reused for the occluded far leg.
const SOURCE = "res://art_review/hero_idle_exact_v1/right.png"
const HEIGHT = 467.0
const ROOT_X = 179.5
const FOOT = 486.0
const BOOT = Rect2(141,447,78,40)
var texture: Texture2D
var phase_time := 0.0
var running := true
var frames_advanced := 0

static func leg(phase: float, stride: float, lift: float, support: float = 0.5) -> Dictionary:
	var p := fposmod(phase,1.0)
	if p < support:
		return {"position":Vector2(stride*0.5-p/support*stride,0),"stance":true}
	var u := (p-support)/(1.0-support)
	# Swing eases smoothly at toe-off and contact; stance has constant speed.
	return {"position":Vector2(lerpf(-stride*0.5,stride*0.5,u),-sin(u*PI)*lift),"stance":false}

func _ready() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	image.fix_alpha_edges()
	image.generate_mipmaps()
	texture=ImageTexture.create_from_image(image)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _process(delta: float) -> void:
	if running:
		phase_time+=delta
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_SPACE: running=not running
		if event.keycode==KEY_RIGHT:
			running=false
			phase_time+=0.1
			queue_redraw()
		if event.keycode==KEY_ESCAPE: get_tree().quit()

func boot(at: Vector2, offset: Vector2, scale_factor: float, color: Color) -> void:
	var dest := Rect2(at+Vector2(BOOT.position.x-ROOT_X,BOOT.position.y-FOOT)*scale_factor+offset*scale_factor,BOOT.size*scale_factor)
	draw_texture_rect_region(texture,dest,BOOT,color)

func body(at: Vector2, scale_factor: float, bob: float) -> void:
	# Rectangular cutout leaves robe/tassels to the right of the boot intact.
	# The notch is deliberately explicit so review can catch any art discontinuity.
	for rect in [Rect2(0,0,328,447),Rect2(0,447,141,45),Rect2(219,447,109,45)]:
		var dest := Rect2(at+Vector2(rect.position.x-ROOT_X,rect.position.y-FOOT+bob)*scale_factor,rect.size*scale_factor)
		draw_texture_rect_region(texture,dest,rect)

func figure(at: Vector2, phase: float, stride: float, size: float, support: float = 0.5) -> void:
	var s := size/HEIGHT
	var near := leg(phase,stride,18,support)
	var far := leg(phase+0.5,stride,18,support)
	boot(at,far.position,s,Color(0.78,0.78,0.78,1))
	body(at,s,-2.0*(1.0-cos(phase*TAU*2)))
	boot(at,near.position,s,Color.WHITE)
	draw_circle(at+near.position*s,2,Color("5bedd1") if near.stance else Color("ffbf69"))
	draw_circle(at+far.position*s,2,Color("9bacec") if far.stance else Color("ffbf69"))

func _draw() -> void:
	if texture==null:return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0,0,1280,800),Color("222d32"))
	draw_string(font,Vector2(20,30),"RIGHT GAIT ENGINE PROBE / FINAL TARGET 8 DIRECTIONS / NOT PRODUCTION",HORIZONTAL_ALIGNMENT_LEFT,-1,21)
	draw_string(font,Vector2(20,58),"Original art + runtime boot cutout. Space pause, Right step, Esc close. Green/blue=stance; orange=swing.",HORIZONTAL_ALIGNMENT_LEFT,-1,15)
	for i in range(4):
		figure(Vector2(150+i*310,300),i*0.25,60,185)
		draw_string(font,Vector2(90+i*310,330),["CONTACT A","PASS B","CONTACT B","PASS A"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,16)
	var phase := fposmod(phase_time/0.8,1.0)
	figure(Vector2(195,680),phase,60,222)
	figure(Vector2(355,680),phase,60,74)
	draw_string(font,Vector2(28,720),"Controlled 0.8s cycle / 60 source px stride",HORIZONTAL_ALIGNMENT_LEFT,-1,16)
	# Actual game's 1.7 world-unit stance distance at 2.25-unit hero height.
	var game_stride := 1.7/2.25*HEIGHT
	var game_cycle := 2.0*1.7/7.5
	var game_phase := fposmod(phase_time/game_cycle,1.0)
	figure(Vector2(650,680),game_phase,game_stride,148)
	var short_support := 0.12
	var short_stride := 7.5*game_cycle*short_support/2.25*HEIGHT
	figure(Vector2(1030,680),game_phase,short_stride,185,short_support)
	figure(Vector2(1200,680),game_phase,short_stride,74,short_support)
	draw_string(font,Vector2(520,720),"50% support: unreachable",HORIZONTAL_ALIGNMENT_LEFT,-1,16)
	draw_string(font,Vector2(910,720),"12% support: quick-step trial",HORIZONTAL_ALIGNMENT_LEFT,-1,16)
	draw_string(font,Vector2(20,775),"Quick-step has airborne phases, not a completed walk cycle. Same game speed/cadence; original PNG unchanged.",HORIZONTAL_ALIGNMENT_LEFT,-1,16)
