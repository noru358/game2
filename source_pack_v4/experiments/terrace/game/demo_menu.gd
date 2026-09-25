extends Control
const Store = preload("res://game/save_store.gd")
const SAVE := "user://steam_demo_v1.json"
var world: Node3D
var page := "title"
var volume := 75
var ambience_volume := 100
var fullscreen := false
var panel: VBoxContainer
var choices: Array[Button] = []
var message: Label
var config_path: String

static func slot(test: bool) -> String:
	return "user://steam_demo_test.json" if test else SAVE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().set_meta("demo_mode",true)
	get_tree().set_meta("demo_overlay",true)
	config_path = "user://steam_demo_settings_test.cfg" if "--test" in OS.get_cmdline_user_args() else "user://steam_demo_settings.cfg"
	var cfg := ConfigFile.new()
	if cfg.load(config_path)==OK:
		volume=clampi(int(cfg.get_value("audio","volume",75)),0,100)
		ambience_volume=clampi(int(cfg.get_value("audio","ambience_volume",100)),0,100)
		fullscreen=bool(cfg.get_value("display","fullscreen",false))
	apply_settings()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme := Theme.new()
	var font := preload("res://assets/fonts/NanumGothic-Regular.ttf")
	theme.default_font=font
	theme.default_font_size=22
	self.theme=theme
	var backdrop := ColorRect.new()
	backdrop.color=Color("102729")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel=VBoxContainer.new()
	panel.custom_minimum_size=Vector2(680,0)
	panel.add_theme_constant_override("separation",14)
	center.add_child(panel)
	show_page(page)

func copy(value: String, size: int=22) -> void:
	var label := Label.new()
	label.text=value
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("e8eedf"))
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)

func action(caption: String, callback: Callable, disabled: bool=false) -> void:
	var b := Button.new()
	b.text=caption
	b.custom_minimum_size.y=48
	b.disabled=disabled
	b.pressed.connect(callback)
	panel.add_child(b)
	choices.append(b)

func show_page(next: String) -> void:
	page=next
	for node in panel.get_children():
		panel.remove_child(node)
		node.queue_free()
	choices.clear()
	copy("첫 여정",40)
	copy("플레이 가능한 데모 · 개발 중",17)
	if page=="settings":
		copy("설정",28)
		action("전체 음량  %d%%  ·  Enter로 변경"%volume,func(): volume=(volume+25)%125; apply_settings(); persist(); show_page("settings"))
		action("화면  ·  "+("전체 화면" if fullscreen else "창 모드"),func(): fullscreen=not fullscreen; apply_settings(); persist(); show_page("settings"); choices[1].grab_focus())
		action("환경음  %d%%  ·  Enter로 변경"%ambience_volume,func(): ambience_volume=(ambience_volume+25)%125; apply_settings(); persist(); show_page("settings"); choices[2].grab_focus())
		action("돌아가기 · Esc",back)
	elif page=="confirm":
		copy("데모 진행을 새 탐험으로 바꿀까요?\n현재 데모 진행은 덮어씁니다.")
		action("취소",func():show_page("title"))
		action("새 탐험 시작",func():start(true))
	elif page=="intro":
		copy("낯선 맥박",30)
		copy("남의 변이를 살피던 내가, 이제 내 몸의 징후를 좇는다.\n술법을 거두어도 손안의 빛은 사라지지 않는다.\n\n숲 안쪽에 오래된 유적이 있다.\n그곳부터 이 빛의 흔적을 찾아보려 한다.\n\n내 몸에 무슨 일이 생겼는지, 직접 알아내야 한다.")
		copy("가까운 적은 자동으로 공격합니다.\n위험할 때 J로 밀어내고, Space로 피하세요.\n찾아낸 단서는 Esc → 탐험 기록에서 다시 읽을 수 있습니다.",19)
		action("숲으로 들어가기",func():start(true))
		action("시작 화면으로 · Esc",func():show_page("title"))
	elif page=="ending":
		copy("이곳의 연결은 끊었다",30)
		copy("덧새긴 봉인에서 조각을 확보했습니다.\n몸의 변화는 남아 있습니다.\n하지만 누군가 연결을 만들었다는 증거를 얻었습니다.\n\n현재 데모의 이야기는 여기까지입니다.\n남은 회랑과 기록은 계속 살펴볼 수 있습니다.")
		action("남은 장소 탐험하기",close_overlay)
		action("저장하고 시작 화면으로",to_title)
	else:
		copy("몸에 시작된 변화를 따라, 열대 숲의 오래된 저수전으로.\n자동 마법으로 싸우고, 위험할 때 J로 흐름을 끊으세요.")
		var saved := Store.read_data(slot("--test" in OS.get_cmdline_user_args()))
		action("이어서 탐험",func():start(false),saved.is_empty())
		action("새 탐험",func(): show_page("confirm") if not saved.is_empty() else start(true))
		action("설정",func():show_page("settings"))
		action("종료",func():get_tree().quit())
	copy("↑↓ / Tab 이동   Enter 선택   WASD 이동   Space 회피",17)
	message=Label.new()
	message.add_theme_font_size_override("font_size",16)
	panel.add_child(message)
	var enabled: Array[Button] = []
	for b in choices:
		if not b.disabled: enabled.append(b)
	for i in range(enabled.size()):
		var b := enabled[i]
		b.focus_neighbor_bottom=b.get_path_to(enabled[(i+1)%enabled.size()])
		b.focus_next=b.focus_neighbor_bottom
		b.focus_neighbor_top=b.get_path_to(enabled[(i-1+enabled.size())%enabled.size()])
		b.focus_previous=b.focus_neighbor_top
	if not enabled.is_empty(): enabled[0].grab_focus()

func apply_settings() -> void:
	get_tree().set_meta("ambience_gain",ambience_volume/100.0)
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.001,volume/100.0)))
	AudioServer.set_bus_mute(0,volume==0)
	if "--test" not in OS.get_cmdline_user_args() or ("--display-qa" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func persist() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio","volume",volume)
	cfg.set_value("audio","ambience_volume",ambience_volume)
	cfg.set_value("display","fullscreen",fullscreen)
	if cfg.save(config_path)!=OK: call_deferred("settings_error")

func settings_error() -> void:
	message.text="설정을 저장하지 못했습니다 · 저장 공간을 확인해주세요"

func start(fresh: bool) -> void:
	if fresh and page!="intro":
		show_page("intro")
		return
	get_tree().set_meta("fresh_run",fresh)
	get_tree().set_meta("demo_overlay",false)
	get_tree().paused=false
	get_tree().change_scene_to_file("res://game/world.tscn")

func back() -> void:
	if is_instance_valid(world): close_overlay()
	else: show_page("title")

func close_overlay() -> void:
	if page=="ending":
		world.demo_ending_seen=true
		world.save_now()
	get_tree().set_meta("demo_overlay",false)
	world.hud.ignore_pause_until_release=true
	if page=="ending": world.resume_game()
	else: world.hud.regular_buttons[1].grab_focus()
	get_parent().queue_free()

func to_title() -> void:
	world.demo_ending_seen=true
	world.demo_title()
	if world.save_error: message.text="저장하지 못했습니다 · 다시 시도해주세요"

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and page in ["settings","confirm","ending","intro"]:
		if page=="ending":close_overlay()
		else:back()
		get_viewport().set_input_as_handled()

static func overlay(owner: Node3D, mode: String) -> void:
	owner.pause_game()
	var layer := CanvasLayer.new()
	layer.layer=20
	layer.process_mode=Node.PROCESS_MODE_ALWAYS
	owner.add_child(layer)
	var menu = load("res://game/demo_menu.gd").new()
	menu.world=owner
	menu.page=mode
	layer.add_child(menu)

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and not is_instance_valid(world):
		get_tree().quit()

