extends RefCounted

# Uses the proven grove_scholar gait geometry and timing, with only the approved
# current character appearance reskinned onto the four original motion sheets.
const DIR := "res://assets/hero_reskin_v1/"
const HeroVisual = preload("res://game/hero_visual.gd")

var walks: Array[AtlasTexture] = []
var walk_passes: Array[AtlasTexture] = []
var runs: Array[AtlasTexture] = []
var run_passes: Array[AtlasTexture] = []
var walk_meta: Array = []
var walk_pass_meta: Array = []
var run_meta: Array = []
var run_pass_meta: Array = []
var current: Dictionary = {}

func _init() -> void:
	walk_meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "walk_contact.json"))
	walk_pass_meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "walk_pass.json"))
	run_meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "run_contact.json"))
	run_pass_meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "run_pass.json"))
	build_frames(load_texture("walk_contact.png"), walk_meta, walks)
	build_frames(load_texture("walk_pass.png"), walk_pass_meta, walk_passes)
	build_frames(load_texture("run_contact.png"), run_meta, runs)
	build_frames(load_texture("run_pass.png"), run_pass_meta, run_passes)

func load_texture(name: String) -> Texture2D:
	var image := Image.load_from_file(ProjectSettings.globalize_path(DIR + name))
	image.fix_alpha_edges()
	return ImageTexture.create_from_image(image)

func build_frames(texture: Texture2D, metadata: Array, output: Array[AtlasTexture]) -> void:
	for data in metadata:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(data.region[0], data.region[1], data.region[2], data.region[3])
		frame.filter_clip = true
		output.append(frame)

func apply(sprite: Sprite3D, direction: Vector3, running: bool, phase: float) -> void:
	var direction_index := HeroVisual.direction_index(direction)
	var index := direction_index
	var mirrored := index in [3, 4, 5]
	if mirrored:
		index = {3: 1, 4: 0, 5: 7}[index]
	var frame := int(fposmod(phase, TAU) / (PI / 2.0))
	var step := frame
	if index == 2 and step >= 2:
		mirrored = true
		step -= 2
	index += 8 * int(step / 2)
	var metadata: Array
	if step % 2 == 1:
		sprite.texture = run_passes[index] if running else walk_passes[index]
		metadata = run_pass_meta if running else walk_pass_meta
	else:
		sprite.texture = runs[index] if running else walks[index]
		metadata = run_meta if running else walk_meta
	var data: Dictionary = metadata[index]
	current = data.duplicate(true)
	current.state = "run" if running else "walk"
	current.frame = frame
	current.direction = direction_index
	current.gait_role = "support" if running and frame % 2 == 1 else ("flight" if running else ("passing" if frame % 2 == 1 else "contact"))
	sprite.flip_h = mirrored
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	# The legacy motion sheets carry very faint keyed edge residue. The source
	# alpha was cleaned, and a small runtime cutoff prevents filtered atlas-edge
	# samples from reappearing as one-pixel slivers between direction cards.
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.08
	sprite.pixel_size = (2.08 if running else 2.25) / maxf(1.0, float(data.foot) - float(data.top))
	sprite.offset.x = (float(data.region[2]) * 0.5 - float(data.root_x)) * (-1.0 if mirrored else 1.0)
	var baseline := (float(data.foot) - float(data.region[3]) * 0.5) * sprite.pixel_size
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.rotation = Vector3.ZERO
	sprite.scale = Vector3(1, 1.0 / cos(deg_to_rad(52)), 1)
	sprite.position = Vector3.UP * (baseline / cos(deg_to_rad(52)) + 0.04) + Vector3(0, 0.788, 0.616) * 0.65
