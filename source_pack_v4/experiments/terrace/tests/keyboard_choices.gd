extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func key(code: int, viewport: Viewport = root) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		viewport.push_input(event)
		await process_frame
func run() -> void:
	var world = load("res://game/world.tscn").instantiate()
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.kills = 10
	world.pause_game("Keyboard test")
	await process_frame
	check(world.hud.upgrade_buttons[0].has_focus(),"first upgrade focused on opening")
	await key(KEY_DOWN)
	check(world.hud.upgrade_buttons[1].has_focus(),"arrow navigates upgrade cards")
	await key(KEY_ENTER)
	check("chain" in world.upgrades and world.choices_claimed == 1,"Enter chooses highlighted upgrade exactly once")
	check(paused and world.hud.upgrade_buttons[0].has_focus(),"next earned choice keeps valid keyboard focus")
	await key(KEY_ENTER)
	check(world.choices_claimed == 2 and not paused,"second keyboard choice resumes game")
	world.pause_game("Journal test")
	await key(KEY_DOWN)
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	check(world.hud.journal.visible,"journal accessible from pause using keyboard only")
	world.hud.journal.hide()
	world.hud.show_journal(1)
	await process_frame
	check(world.hud.ability_copy.has_focus(),"ability summary receives keyboard focus")
	check(world.hud.attune_buttons.is_empty() and world.hud.weave_buttons.is_empty(),"no second crystal shop in journal")
	check("연쇄" in world.hud.ability_copy.text,"chosen ability displayed in summary")
	await key(KEY_ESCAPE,world.hud.journal)
	check(not world.hud.journal.visible and paused,"ability summary closes without resuming combat")
	world.hud.show_journal(0)
	await key(KEY_Q,world.hud.journal)
	check(world.hud.journal_tabs.current_tab==2 and world.hud.help_copy.has_focus(),"Q wraps from records to focused controls help")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		world.hud.journal.get_viewport().get_texture().get_image().save_png("res://docs/validation/controls-help-top.png")
	await key(KEY_PAGEDOWN,world.hud.journal)
	check(world.hud.help_copy.get_v_scroll_bar().value>0,"keyboard scrolls long controls help")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		world.hud.journal.get_viewport().get_texture().get_image().save_png("res://docs/validation/controls-help.png")
	await key(KEY_E,world.hud.journal)
	check(world.hud.journal_tabs.current_tab==0 and world.hud.record_list.has_focus(),"E wraps back to records with focus")
	await key(KEY_E,world.hud.journal)
	check(world.hud.journal_tabs.current_tab==1,"E preserves access to growth tab")
	await key(KEY_ESCAPE,world.hud.journal)
	check(not world.hud.journal.visible and paused,"Escape closes help window without resuming combat")
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
