extends SceneTree

const STEP := 1.0 / 60.0
var failures := 0
var world

func _initialize() -> void:
	if not "--test" in OS.get_cmdline_user_args():
		quit(2)
		return
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	print("PASS " if ok else "FAIL ", label)
	if not ok:
		failures += 1

func release_actions() -> void:
	for action in ["left", "right", "up", "down", "dash", "pulse"]:
		Input.action_release(action)

func tap_pulse() -> void:
	Input.action_press("pulse")
	await physics_frame
	world.combat.update(STEP)
	Input.action_release("pulse")
	await physics_frame

func run() -> void:
	world = load("res://lab/world.tscn").instantiate()
	root.add_child(world)
	release_actions()
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	for enemy in world.enemies():
		enemy.free()
	var player = world.player
	player.position = world.Landscape.on_ground(Vector3(110, 0, 3), 0.1)

	# Movement should become brisk quickly without sacrificing exact release.
	player.moving_seconds = 0
	Input.action_press("right")
	for frame in range(45):
		player._physics_process(STEP)
	check(player.current_speed >= player.run_speed - 0.01, "run speed is reached within 0.75 seconds")
	Input.action_release("right")
	player._physics_process(STEP)
	check(Vector2(player.velocity.x, player.velocity.z).length() < 0.01, "release stops normal movement in one physics step")

	# Invalid zero-net input must not pre-charge the run ramp.
	player.moving_seconds = 0
	Input.action_press("left")
	Input.action_press("right")
	for frame in range(60):
		player._physics_process(STEP)
	check(player.moving_seconds < 0.001 and is_equal_approx(player.current_speed, player.move_speed), "opposing input cannot charge run speed while stationary")
	Input.action_release("left")
	Input.action_release("right")

	# A held turn keeps momentum and changes direction on the next step.
	Input.action_press("right")
	for frame in range(45):
		player._physics_process(STEP)
	Input.action_release("right")
	Input.action_press("left")
	player._physics_process(STEP)
	check(player.velocity.x <= -(player.run_speed - 0.01), "full-speed reversal responds in one physics step")
	Input.action_release("left")

	# One deliberate tap during recovery should queue exactly one next strike.
	world.kills = 4
	world.hitstop = 0
	world.combat.reset_transient()
	var swings_before: int = world.combat.swings
	await tap_pulse()
	check(world.combat.swings == swings_before + 1, "first tap starts a strike")
	for frame in range(4):
		world.combat.update(STEP)
		await physics_frame
	await tap_pulse()
	for frame in range(32):
		world.combat.update(STEP)
		await physics_frame
	check(world.combat.swings == swings_before + 2 and world.combat.combo_step == 2, "early recovery tap queues exactly one combo strike")

	release_actions()
	print("RESULT failures=", failures)
	quit(1 if failures else 0)
