extends SceneTree

const BossScript = preload("res://scene/boss.gd")
const ConfigScript = preload("res://resourse/config/boss_config.gd")
const BulletScene = preload("res://scene/bullet.tscn")

var failures: Array[String] = []
var defeat_events := 0
var timeout_events := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = get_root().get_node_or_null("GameSession")
	if session == null:
		session = Node.new()
		session.set_script(load("res://scene/game_session.gd"))
		session.name = "GameSession"
		get_root().add_child(session)
	else:
		session.reset_run()
		session.current_round = 3
		session.current_coins = 10
	var config = ConfigScript.new()
	config.spawn_round = 3
	config.reward_coins = 25
	if config == null or int(config.spawn_round) != 3:
		failures.append("BossConfig spawn_round is not loadable")
	var boss = BossScript.new()
	boss.setup(config)
	boss.defeated.connect(func(_r): defeat_events += 1)
	boss.timed_out.connect(func(): timeout_events += 1)
	get_root().add_child(boss)
	var bullet = BulletScene.instantiate() as Bullet
	get_root().add_child(bullet)
	bullet.global_position = boss.global_position
	bullet.set("damage", 40)
	await physics_frame
	if boss.current_health >= config.max_health:
		failures.append("Bullet did not damage Boss through Area2D chain")
	boss.apply_damage(1000)
	boss.apply_damage(1000)
	if defeat_events != 1:
		failures.append("Boss defeat signal was not one-shot")
	if not session.add_boss_reward(config.reward_coins):
		failures.append("Boss reward was not accepted")
	if session.current_coins != 10 + config.reward_coins:
		failures.append("Boss reward did not reach GameSession coins")
	if session.add_boss_reward(config.reward_coins):
		failures.append("Boss reward was paid twice")
	var timeout_boss = BossScript.new()
	var timeout_config = ConfigScript.new()
	timeout_config.max_health = 10
	timeout_config.time_limit = 0.01
	timeout_boss.setup(timeout_config)
	timeout_boss.timed_out.connect(func(): timeout_events += 1)
	get_root().add_child(timeout_boss)
	await create_timer(0.1).timeout
	if timeout_events != 1:
		failures.append("Boss timeout did not emit")
	if failures.is_empty():
		print("Phase 5 integration smoke passed")
	else:
		for failure in failures: push_error(failure)
	quit(1 if not failures.is_empty() else 0)
