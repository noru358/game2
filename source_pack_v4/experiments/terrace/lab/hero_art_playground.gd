extends "res://lab/journey.gd"
# Isolated asset preview on real journey geometry and the unmodified Player.
# Static 8-view artwork is explicitly labelled; no claim of finished locomotion.
const ART_DIR = "res://art_review/hero_idle_exact_v1/"
var art_texture: Texture2D
var art_frames: Array = []
var art_regions: Array[AtlasTexture] = []
var art_sprite: Sprite3D
var art_label: Label
var approved_visible := true
var art_index := 0
var preview_ticks := 0
var foliage := preload("res://lab/hero_foliage_fade.gd").new()
var locomotion := preload("res://lab/hero_locomotion.gd").new()
var close_view := false

func _ready() -> void:
	if not "--test" in OS.get_cmdline_user_args():
		push_error("Asset playground requires --test; it never opens a player save.")
		get_tree().quit(2)
		return
	super._ready()
	var image := Image.load_from_file(ProjectSettings.globalize_path(ART_DIR+"candidate.png"))
	image.fix_alpha_edges()
	image.generate_mipmaps()
	art_texture=ImageTexture.create_from_image(image)
	art_frames=JSON.parse_string(FileAccess.get_file_as_string(ART_DIR+"frames.json"))
	for d in art_frames:
		var frame := AtlasTexture.new()
		frame.atlas=art_texture
		frame.region=Rect2(d.region[0],d.region[1],d.region[2],d.region[3])
		frame.filter_clip=true
		art_regions.append(frame)
	art_sprite=Sprite3D.new()
	art_sprite.shaded=false
	art_sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR
	player.body.add_child(art_sprite)
	player.body.add_child(locomotion)
	locomotion.setup(art_texture,art_frames)
	foliage.collect(self)
	for familiar in player.familiars: familiar.hide()
	reset_preview_position()
	update_art()

func storage_key(_field: String) -> String:
	return "user://unused_hero_art_playground.json"
func allow_legacy_import() -> bool:
	return false
func save_now() -> void:
	pass
func flush_save() -> void:
	pass
func populate_field() -> void:
	pass
func build_hud() -> void:
	hud=CanvasLayer.new()
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position=Vector2(16,16)
	hud.add_child(panel)
	art_label=Label.new()
	art_label.add_theme_font_override("font",preload("res://assets/fonts/NanumGothic-Regular.ttf"))
	art_label.add_theme_font_size_override("font_size",18)
	panel.add_child(art_label)
func update_hud() -> void:
	if not is_instance_valid(art_label):return
	var mode := "승인 8방향 · 엔진 변형 모션 1차 / 숨은 다리 작화 미완료" if approved_visible else "기존 임시 캐릭터 · 기존 이동 애니메이션"
	art_label.text="  캐릭터 검수장 / 저장·전투 없음 / "+TITLES[chapter]+"  \n  "+mode+"  \n  WASD 이동 / Space 회피 / V 비교 / 1·2·3 지역 / R 시작점 / Esc 종료  \n  M 모션 %s / F 필터 %s / Z 확대 / T 식물 완화 / 속도 %.2f  "%[locomotion.state_label() if locomotion.motion_enabled else "꺼짐","부드럽게" if locomotion.soft_filter else "선명하게",Vector2(player.velocity.x,player.velocity.z).length()]
func update_camera(delta: float) -> void:
	super.update_camera(delta)
	camera.size=14.0 if close_view else 22.0
func _physics_process(delta: float) -> void:
	preview_ticks+=1
	if is_instance_valid(art_sprite):locomotion.advance(player.global_position,delta,player.dash_left>0)
	update_camera(delta)
	update_effects(delta)
	update_hud()
func _process(delta: float) -> void:
	if is_instance_valid(art_sprite):
		update_art()
		var points: Array[Vector3]=[]
		for height in [0.0,0.8,1.8,2.7]:points.append(player.global_position+Vector3.UP*height+Vector3(0,0.788,0.616)*0.65)
		foliage.update(camera,points,delta)
func update_art() -> void:
	art_index=posmod(roundi(atan2(player.facing.z,player.facing.x)/(PI/4.0)),8)
	var d: Dictionary=art_frames[art_index]
	art_sprite.texture=art_regions[art_index]
	art_sprite.flip_h=false
	art_sprite.pixel_size=2.25/(float(d.foot)-float(d.top))
	art_sprite.offset.x=float(d.region[2])*0.5-float(d.root_x)
	art_sprite.scale.y=1.0/cos(deg_to_rad(52))
	var baseline: float=(float(d.foot)-float(d.region[3])*0.5)*art_sprite.pixel_size
	art_sprite.position=Vector3.UP*(baseline/cos(deg_to_rad(52))+0.04)
	art_sprite.position+=Vector3(0,0.788,0.616)*0.65
	art_sprite.visible=false
	locomotion.visible=approved_visible
	locomotion.display(art_index,art_sprite,player.dash_left>0)
	player.portrait.visible=not approved_visible
	player.weapon.hide()
	player.second_focus.hide()
	update_hud()
func reset_preview_position() -> void:
	player.position=Landscape.on_ground(Vector3(110,0,8),0.1)
	player.velocity=Vector3.ZERO
	player.moving_seconds=0
	player.dash_left=0
	player.dash_wait=0
	locomotion.initialized=false
	locomotion.strength=0
	locomotion.run_blend=0
	locomotion.state=locomotion.State.IDLE
	update_camera(1)
func preview_region(index: int) -> void:
	if index!=chapter:travel(index)
	foliage.collect(self)
	reset_preview_position()
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_ESCAPE:get_tree().quit()
		KEY_V:approved_visible=not approved_visible
		KEY_R:reset_preview_position()
		KEY_T:foliage.enabled=not foliage.enabled
		KEY_M:locomotion.motion_enabled=not locomotion.motion_enabled
		KEY_F:locomotion.soft_filter=not locomotion.soft_filter
		KEY_Z:close_view=not close_view
		KEY_1:preview_region(0)
		KEY_2:preview_region(1)
		KEY_3:preview_region(2)
	get_viewport().set_input_as_handled()



