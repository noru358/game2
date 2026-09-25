extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func run() -> void:
	for flat in [false,true]:
		set_meta("lab_flat",flat)
		var world=load("res://lab/world.tscn").instantiate()
		root.add_child(world)
		world.player.position=world.Landscape.on_ground(Vector3(110,0,2),0.1)
		world.player.facing=Vector3.FORWARD
		world.player.invulnerability=999
		Input.action_press("pulse")
		for i in range(480):
			await physics_frame
			if paused:break
		Input.action_release("pulse")
		check(world.kills>=4 and world.auto_hits>0 and world.combat.swings>0,"real automatic and J combat clears first group")
		check(paused and world.pending_choices()==1,"combat reaches exactly one permanent upgrade choice")
		world.choose_upgrade("split")
		world.resume_game()
		check(world.upgrades==["split"] and not paused,"earned split resumes travel")
		world.free()
	print("RESULT failures=",failures)
	quit(1 if failures else 0)
