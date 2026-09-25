extends CanvasLayer

var ignore_pause_until_release := false
var combat_caption_hold := 0.0
var story_panel: PanelContainer
var story_copy: Label
var location: Label
var status: Label
var dodge_label: Label
var dodge_meter: ProgressBar
var goal: Label
var toast: Label
var pause_panel: PanelContainer
var pause_title: Label
var pause_heading: Label
var world: Node3D
var hud_header: PanelContainer
var hud_bottom: VBoxContainer
var pause_veil: ColorRect
var upgrade_box: VBoxContainer
var regular_buttons: Array[Button] = []
var journal: AcceptDialog
var journal_copy: RichTextLabel
var help_copy: RichTextLabel
var attune_buttons: Array[Button] = []
var upgrade_buttons: Array[Button] = []
var weave_buttons: Array[Button] = []
var journal_tabs: TabContainer
var record_list: ItemList
var crystal_count: Label
var ability_copy: RichTextLabel
var journal_records: Array = []

func text(parent: Node, value: String, size: int, color: Color = Color("e8eedf")) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func button(parent: Node, caption: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(0, 48)
	b.focus_mode = Control.FOCUS_ALL
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.16,0.32,0.32,0.6)
	focus.border_color = Color("ffe2a5")
	focus.set_border_width_all(3)
	b.add_theme_stylebox_override("focus",focus)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world = get_parent()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	var font := preload("res://assets/fonts/NanumGothic-Regular.ttf")
	theme.default_font = font
	theme.default_font_size = 17
	root.theme = theme
	add_child(root)
	pause_veil=ColorRect.new()
	pause_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_veil.color=Color(0.015,0.025,0.03,0.65)
	pause_veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(pause_veil)
	var header := PanelContainer.new()
	hud_header=header
	header.position = Vector2(24, 20)
	header.custom_minimum_size = Vector2(420, 0)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.04, 0.09, 0.10, 0.88)
	header_style.content_margin_left = 18
	header_style.content_margin_right = 18
	header_style.content_margin_top = 12
	header_style.content_margin_bottom = 12
	header.add_theme_stylebox_override("panel", header_style)
	root.add_child(header)
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 5)
	header.add_child(top)
	location = text(top, "", 16, Color("b0c8bc"))
	var vitals := HBoxContainer.new()
	vitals.add_theme_constant_override("separation",12)
	top.add_child(vitals)
	status = text(vitals, "", 20)
	status.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	dodge_label=text(vitals,"",16,Color("abe0c6"))
	dodge_meter=ProgressBar.new()
	dodge_meter.custom_minimum_size=Vector2(80,8)
	dodge_meter.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	dodge_meter.show_percentage=false
	dodge_meter.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var meter_fill:=StyleBoxFlat.new()
	meter_fill.bg_color=Color("abe0c6")
	dodge_meter.add_theme_stylebox_override("fill",meter_fill)
	var meter_back:=StyleBoxFlat.new()
	meter_back.bg_color=Color("334b4c")
	dodge_meter.add_theme_stylebox_override("background",meter_back)
	vitals.add_child(dodge_meter)
	goal = text(top, "", 18, Color("eed5a0"))
	goal.custom_minimum_size.x = 400
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bottom := VBoxContainer.new()
	hud_bottom=bottom
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 32
	bottom.offset_right = -32
	bottom.offset_top = -58
	bottom.offset_bottom = -14
	root.add_child(bottom)
	toast = text(bottom, "", 18, Color("fff1c8"))
	for label_size in [toast]:
		label_size.add_theme_color_override("font_shadow_color", Color("102326"))
		label_size.add_theme_constant_override("shadow_offset_x", 1)
		label_size.add_theme_constant_override("shadow_offset_y", 2)
	text(bottom, "J  연속 마법     Space  회피     Esc  메뉴", 14, Color("bbcec2"))
	story_panel = PanelContainer.new()
	story_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	story_panel.offset_left = -415
	story_panel.offset_right = 415
	story_panel.offset_top = -186
	story_panel.offset_bottom = -78
	story_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var story_style: StyleBoxFlat = header_style.duplicate()
	story_style.border_color = Color("bfa5ae")
	story_style.border_width_left = 2
	story_panel.add_theme_stylebox_override("panel", story_style)
	root.add_child(story_panel)
	var story_items := VBoxContainer.new()
	story_panel.add_child(story_items)
	text(story_items, "변화의 흔적   /   Esc에서 다시 읽기", 14, Color("d5b7c4"))
	story_copy = text(story_items, "", 21)
	story_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_panel.hide()
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -340
	pause_panel.offset_top = -315
	pause_panel.offset_right = 340
	pause_panel.offset_bottom = 315
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172e31")
	style.border_color = Color("7eab98")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	pause_panel.add_theme_stylebox_override("panel", style)
	root.add_child(pause_panel)
	var items := VBoxContainer.new()
	items.add_theme_constant_override("separation", 13)
	pause_panel.add_child(items)
	pause_heading=text(items, "잠깐, 쉬어가기", 28)
	pause_title = text(items, "", 16)
	pause_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade_box = VBoxContainer.new()
	upgrade_box.add_theme_constant_override("separation", 10)
	items.add_child(upgrade_box)
	regular_buttons.append(button(items, "계속 탐험하기  ·  Esc", world.resume_game))
	if world.demo_mode:
		regular_buttons.append(button(items, "설정", func():preload("res://game/demo_menu.gd").overlay(world,"settings")))
	else:
		regular_buttons.append(button(items, "소리 켜기 / 끄기", world.toggle_sound))
	regular_buttons.append(button(items, "탐험 기록", func(): show_journal(0)))
	regular_buttons.append(button(items, "능력 확인", func(): show_journal(1)))
	journal = AcceptDialog.new()
	journal.title = "여정과 능력"
	journal.ok_button_text = "닫기 · Enter"
	journal.theme = theme
	journal.add_theme_font_size_override("font_size",20)
	var panel := StyleBoxFlat.new()
	panel.bg_color=Color("10292c")
	panel.border_color=Color("8dbaa5")
	panel.set_border_width_all(2)
	panel.content_margin_left=22
	panel.content_margin_right=22
	panel.content_margin_top=18
	panel.content_margin_bottom=16
	journal.add_theme_stylebox_override("panel",panel)
	root.add_child(journal)
	var journal_items := VBoxContainer.new()
	journal_items.custom_minimum_size = Vector2(890,0)
	journal_items.add_theme_constant_override("separation",16)
	journal.add_child(journal_items)
	crystal_count=text(journal_items,"",26,Color("ffe2a5"))
	text(journal_items,"Q / E 탭 전환    ↑↓ 항목 이동    PgUp / PgDn 본문    Esc 닫기",17,Color("c4dcd1"))
	journal_tabs=TabContainer.new()
	journal_tabs.custom_minimum_size=Vector2(890,440)
	journal_tabs.add_theme_font_size_override("font_size",21)
	journal_items.add_child(journal_tabs)
	var records := HBoxContainer.new()
	records.name="장소와 여정"
	records.add_theme_constant_override("separation",24)
	journal_tabs.add_child(records)
	record_list=ItemList.new()
	record_list.custom_minimum_size=Vector2(245,380)
	record_list.add_theme_font_size_override("font_size",20)
	record_list.add_theme_constant_override("v_separation",16)
	record_list.add_theme_color_override("font_color",Color("eef4e5"))
	record_list.item_selected.connect(show_record)
	records.add_child(record_list)
	journal_copy=RichTextLabel.new()
	journal_copy.bbcode_enabled=true
	journal_copy.add_theme_font_override("bold_font",preload("res://assets/fonts/NanumGothic-Bold.ttf"))
	journal_copy.custom_minimum_size=Vector2(590,380)
	journal_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	journal_copy.add_theme_font_size_override("normal_font_size",22)
	journal_copy.add_theme_font_size_override("bold_font_size",26)
	journal_copy.add_theme_constant_override("line_separation",10)
	journal_copy.add_theme_color_override("default_color",Color("f1f2dc"))
	records.add_child(journal_copy)
	var upgrades := VBoxContainer.new()
	upgrades.name="능력"
	upgrades.add_theme_constant_override("separation",12)
	journal_tabs.add_child(upgrades)
	ability_copy=RichTextLabel.new()
	ability_copy.bbcode_enabled=true
	ability_copy.focus_mode=Control.FOCUS_ALL
	ability_copy.custom_minimum_size=Vector2(850,380)
	ability_copy.add_theme_font_size_override("normal_font_size",21)
	ability_copy.add_theme_constant_override("line_separation",5)
	ability_copy.add_theme_font_override("bold_font",preload("res://assets/fonts/NanumGothic-Bold.ttf"))
	ability_copy.add_theme_font_size_override("bold_font_size",21)
	upgrades.add_child(ability_copy)
	var help := VBoxContainer.new()
	help.name="조작과 전투"
	journal_tabs.add_child(help)
	help_copy=RichTextLabel.new()
	help_copy.bbcode_enabled=true
	help_copy.focus_mode=Control.FOCUS_ALL
	help_copy.custom_minimum_size=Vector2(840,380)
	help_copy.size_flags_vertical=Control.SIZE_EXPAND_FILL
	help_copy.add_theme_font_override("bold_font",preload("res://assets/fonts/NanumGothic-Bold.ttf"))
	help_copy.add_theme_font_size_override("normal_font_size",22)
	help_copy.add_theme_font_size_override("bold_font_size",24)
	help_copy.add_theme_constant_override("line_separation",8)
	help_copy.text="[b]이동과 회피[/b]\nWASD로 이동합니다. 계속 움직이면 달리기로 빨라집니다.\nSpace는 바라보는 방향으로 짧게 회피합니다. 이동 키로 방향을 정한 뒤 사용하세요.\n\n[b]자동 마법과 J[/b]\n가까운 적은 자동으로 공격합니다. 공격할 위치를 잡고 위험한 전조를 살피세요.\nJ는 앞쪽 적을 밀어내는 마법입니다. 누르고 있거나 연이어 누르면 세 번의 공격이 이어집니다. 마지막 공격은 더 강합니다.\n회피하면 J 연속 공격이 끊깁니다. 저수전 수호자가 시전할 때 가까이서 J를 맞히면 중단시킬 수 있습니다.\n\n[b]발견과 조사[/b]\n화면 위 목표를 따라가세요. 장소의 빛나는 표식에 다가가면 발견이 기록됩니다.\nF 안내가 나타난 물건은 F로 조사합니다. 주변 적을 먼저 정리해야 하는 곳도 있습니다.\n\n[b]레벨과 강화[/b]\n적을 쓰러뜨리면 경험치를 얻습니다. 레벨이 오르면 게임이 멈추고 강화 하나를 선택합니다.\n선택한 능력은 능력 탭에서 확인하며, 종료해도 유지됩니다. 발견과 조사는 이야기와 길을 엽니다.\n\n[b]쉬어가기와 저장[/b]\nEsc로 멈추고 기록·설정을 확인합니다. 쓰러져도 열린 길과 발견한 능력은 유지됩니다.\n종료할 때는 ‘저장하고 종료’ 또는 ‘저장하고 시작 화면으로’를 선택하세요."
	help.add_child(help_copy)
	journal_tabs.tab_changed.connect(func(_tab): focus_journal())
	for control in [record_list,journal_copy,help_copy,ability_copy,journal_tabs.get_tab_bar(),journal.get_ok_button()]+attune_buttons+weave_buttons:
		control.gui_input.connect(journal_key)
	var quit_button := button(items, "저장하고 종료", func():
		world.save_now()
		if not world.save_error:
			get_tree().quit()
		else:
			pause_title.text = "저장 실패 · 저장 공간을 확인한 뒤 재시도해주세요")
	regular_buttons.append(quit_button)
	if world.demo_mode:
		regular_buttons.append(button(items,"저장하고 시작 화면으로",world.demo_title))
		pause_panel.hide()
		return
	var reset := button(items, "새 탐험 시작…", func(): pass)
	regular_buttons.append(reset)
	var confirm := ConfirmationDialog.new()
	confirm.title = "새 탐험"
	confirm.dialog_text = "이 체험용 진행만 초기화할까요? 기존 플레이 저장은 유지됩니다." if world.save_slot!=world.Store.PATH else "현재 시험판 진행을 초기화하고 처음부터 시작할까요?"
	confirm.confirmed.connect(func():
		# Preserve the previous save as a backup before replacing the current run.
		get_tree().set_meta("fresh_run", true)
		world.test_mode = true
		get_tree().paused = false
		get_tree().reload_current_scene())
	root.add_child(confirm)
	reset.pressed.connect(func(): confirm.popup_centered())
	pause_panel.hide()

func show_pause(reason: String) -> void:
	story_panel.hide()
	pause_title.text = "강화 하나를 선택하세요 · ↑↓ 이동 / Enter 선택" if world.pending_choices()>0 else world.journey.recap()
	upgrade_buttons.clear()
	for child in upgrade_box.get_children():
		upgrade_box.remove_child(child)
		child.queue_free()
	var choosing: bool = world.pending_choices() > 0
	pause_heading.text="레벨 업" if choosing else ("저수전의 기록" if world.facility.studied else ("첫 여정의 기록" if world.waterworks.reclaimed else "잠깐, 쉬어가기"))
	for b in regular_buttons:
		b.visible = not choosing
	upgrade_box.visible = choosing
	if choosing:
		for id in world.available_upgrades():
			if id in world.upgrades:
				continue
			var card := button(upgrade_box, "%s\n%s" % [world.UPGRADE_NAMES[id], world.UPGRADE_DESCRIPTIONS[id]], func():
				if world.choose_upgrade(id):
					world.resume_game())
			card.add_theme_font_size_override("font_size", 20)
			card.custom_minimum_size.y = 80
			upgrade_buttons.append(card)
	var half_height: float = (150.0 + upgrade_buttons.size()*90.0)*0.5 if choosing else 315.0
	pause_panel.offset_top=-half_height
	pause_panel.offset_bottom=half_height
	pause_panel.offset_left=-340
	pause_panel.offset_right=340
	pause_panel.show()
	if choosing and not upgrade_buttons.is_empty():
		focus_choices(upgrade_buttons)
	else:
		focus_choices(regular_buttons)

func focus_choices(choices: Array[Button]) -> void:
	for i in range(choices.size()):
		choices[i].focus_neighbor_top = choices[i].get_path_to(choices[(i-1+choices.size())%choices.size()])
		choices[i].focus_neighbor_bottom = choices[i].get_path_to(choices[(i+1)%choices.size()])
	choices[0].grab_focus()

func style_upgrade_card(card: Button) -> void:
	card.custom_minimum_size=Vector2(425,118)
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.add_theme_font_size_override("font_size",20)
	card.add_theme_color_override("font_color",Color("f6f2da"))
	card.add_theme_color_override("font_disabled_color",Color("b5c8bd"))
	var fill:=StyleBoxFlat.new()
	fill.bg_color=Color("234747")
	fill.set_corner_radius_all(8)
	card.add_theme_stylebox_override("normal",fill)
	var locked: StyleBoxFlat=fill.duplicate()
	locked.bg_color=Color("1b3335")
	card.add_theme_stylebox_override("disabled",locked)

func show_record(index: int) -> void:
	if index<0 or index>=journal_records.size():
		journal_copy.text="[b]아직 발견한 기록이 없습니다[/b]\n\n빛나는 표식에 가까이 가면 장소와 이야기가 기록됩니다."
		return
	var entry: Dictionary=journal_records[index]
	journal_copy.text="[color=#9fd7bf]"+entry.region+"[/color]\n\n[b]"+entry.title+"[/b]\n\n"+entry.body
	journal_copy.scroll_to_line(0)

func refresh_journal() -> void:
	crystal_count.text=world.growth_label()
	var previous:=record_list.get_selected_items()
	journal_records.clear()
	record_list.clear()
	for source in [world.exploration,world.waterworks,world.facility]:
		for id in source.discovered:
			journal_records.append({"title":source.SITES[id].name,"body":source.NOTES[id],"region":"빗물길" if source==world.exploration else ("거대 저수전" if source==world.facility else "상류 수리시설")})
	if world.waterworks.reclaimed:
		journal_records.append({"title":"드러난 석길", "region":"잠긴 숲 · 수로 복구", "body":"물 아래 남은 석판에는 물높이를 재던 눈금이 새겨져 있다. 상류에서 물길을 바꾸자 낮은 숲의 옛 통행로가 다시 드러났다. 수문과 숲은 하나의 시설이었다."})
	journal_records.append_array(world.waterworks.records())
	journal_records.append_array(world.story.records())
	for entry in journal_records: record_list.add_item(entry.title)
	var selected:=mini(previous[0] if not previous.is_empty() else 0,journal_records.size()-1)
	if selected>=0: record_list.select(selected)
	show_record(selected)
	ability_copy.text="[b]현재 능력[/b]\n\n자동 공격 · 주변 마력체가 가까운 적을 공격합니다.\n직접 공격 · J를 연달아 눌러 3연격을 이어갑니다.\n\n"
	for id in world.upgrades:
		ability_copy.text += "[b]"+world.UPGRADE_NAMES[id]+"[/b]  ·  "+world.UPGRADE_DESCRIPTIONS[id]+"\n"
	ability_copy.text += "적을 쓰러뜨려 레벨을 올리면 강화 선택이 열립니다.\n선택한 능력은 저장됩니다."
	if journal.visible: focus_journal()

func journal_key(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		journal.hide()
		ignore_pause_until_release=true
		regular_buttons[2].grab_focus()
		journal.set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and journal_tabs.current_tab in [0,1,2] and event.keycode in [KEY_PAGEUP,KEY_PAGEDOWN]:
		var scroll:VScrollBar=(help_copy if journal_tabs.current_tab==2 else (ability_copy if journal_tabs.current_tab==1 else journal_copy)).get_v_scroll_bar()
		scroll.value+=scroll.page*0.8*(1 if event.keycode==KEY_PAGEDOWN else -1)
		journal.set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_Q,KEY_E]:
		journal_tabs.current_tab=posmod(journal_tabs.current_tab+(1 if event.keycode==KEY_E else -1),journal_tabs.get_tab_count())
		journal.set_input_as_handled()

func focus_journal() -> void:
	if not journal.visible: return
	if journal_tabs.current_tab==0:
		record_list.grab_focus()
		return
	if journal_tabs.current_tab==2:
		help_copy.grab_focus()
		return
	ability_copy.grab_focus()

func show_journal(tab: int=1) -> void:
	refresh_journal()
	journal.popup_centered(Vector2i(960,680))
	journal_tabs.current_tab=tab
	focus_journal()

func update_combat_readability(delta: float) -> void:
	var enemies: Array=world.enemies()
	var nearby: bool=enemies.any(func(e):return e.position.distance_to(world.player.position)<10.0)
	if nearby: combat_caption_hold=0.75
	elif not get_tree().paused: combat_caption_hold=maxf(0,combat_caption_hold-delta)
	for label in get_tree().get_nodes_in_group("place_captions"):
		if world.is_ancestor_of(label): label.visible=combat_caption_hold<=0
	goal.text="\n".join(world.objective().split(" · ",true,1))
	goal.add_theme_color_override("font_color",Color("eed5a0"))
	var active_cue:RefCounted
	for enemy in enemies:
		if (enemy.keeper==null and enemy.caster==null) or enemy.position.distance_to(world.player.position)>=14: continue
		var ai=enemy.keeper if enemy.keeper!=null else enemy.caster
		if ai.phase=="warning":
			active_cue=ai
			break
		if active_cue==null and ai.remaining>0 and not ai.cue.is_empty():active_cue=ai
	if active_cue!=null:
		goal.text=active_cue.cue
		goal.add_theme_color_override("font_color",Color("ffad8c") if active_cue.phase=="warning" else Color("abe0c6"))

func _process(delta: float) -> void:
	hud_header.visible=not get_tree().paused
	hud_bottom.visible=not get_tree().paused
	pause_veil.visible=get_tree().paused
	location.text = world.journey.location()+"   ·   "+world.growth_label()
	status.text = "체력  %s%s" % ["●".repeat(world.player.hp) + "○".repeat(5 - world.player.hp), "   저장 실패 · Esc에서 확인" if world.save_error else ""]
	dodge_meter.value=100.0*(1.0-clampf(world.player.dash_wait/maxf(world.player.dash_cooldown,0.001),0,1))
	dodge_label.text="Space · "+("회피 중" if world.player.dash_left>0 else ("회복 중" if world.player.dash_wait>0 else "회피 준비"))
	dodge_label.add_theme_color_override("font_color",Color("abe0c6") if world.player.dash_wait<=0 else Color("c3caca"))
	story_copy.text = world.story.caption()
	story_panel.visible = not story_copy.text.is_empty() and not get_tree().paused
	update_combat_readability(delta)
	var hint: String=world.facility.interaction_hint()
	if hint.is_empty(): hint=world.waterworks.interaction_hint()
	if hint.is_empty(): hint=world.exploration.interaction_hint()
	toast.text = hint if not hint.is_empty() else (world.message if world.message_left > 0 else "")
	if ignore_pause_until_release:
		if not Input.is_action_pressed("pause"): ignore_pause_until_release=false
		return
	if Input.is_action_just_pressed("pause") and not get_tree().get_meta("demo_overlay",false):
		if journal.visible:
			journal.hide()
			return
		if get_tree().paused:
			world.resume_game()
		else:
			world.pause_game()

