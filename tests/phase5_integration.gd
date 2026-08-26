extends Node

const ConfigScript = preload("res://resourse/config/boss_config.gd")
const BossScript = preload("res://scene/boss.gd")
const BulletScene = preload("res://scene/bullet.tscn")

var failures: Array[String] = []
var defeats := 0
var telegraphs := 0
var timeouts := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var session = get_node_or_null("/root/GameSession")
	if session == null:
		failures.append("autoload GameSession missing")
	else:
		session.reset_run()
		session.current_round = 3
		session.current_coins = 10
	var config = ConfigScript.new()
	config.spawn_round = 3
	config.max_health = 50
	config.reward_coins = 25
	config.attack_interval = 0.01
	var container := Node2D.new()
	container.name = "EnemyContainer"
	add_child(container)
	var boss = BossScript.new()
	container.add_child(boss)
	boss.setup(config)
	boss.defeated.connect(func(_reward): defeats += 1)
	boss.attack_telegraph.connect(func(_mode, _duration): telegraphs += 1)
	var bullet = BulletScene.instantiate()
	container.add_child(bullet)
	bullet.global_position = boss.global_position
	bullet.set("damage", 20)
	await get_tree().physics_frame
	if boss.current_health >= config.max_health:
		failures.append("Bullet did not damage Boss through Area2D collision")
	# The bullet already dealt 20 damage (50 -> 30); one more damage remains in phase 1.
	boss.apply_damage(1)
	if boss.current_phase != 1:
		failures.append("Boss phase did not transition at HP threshold")
	await get_tree().create_timer(0.1).timeout
	if telegraphs == 0:
		failures.append("Boss attack telegraph was not emitted")
	boss.apply_damage(100)
	boss.apply_damage(100)
	if defeats != 1:
		failures.append("Boss defeat was not one-shot")
	if not session.add_boss_reward(config.reward_coins) or session.current_coins != 35:
		failures.append("Boss reward did not reach GameSession")
	if session.add_boss_reward(config.reward_coins):
		failures.append("Boss reward was paid twice")
	var timeout_config = ConfigScript.new()
	timeout_config.time_limit = 0.01
	var timeout_boss = BossScript.new()
	timeout_boss.setup(timeout_config)
	timeout_boss.timed_out.connect(func(): timeouts += 1)
	container.add_child(timeout_boss)
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	if timeouts == 0 or session.current_coins != 35:
		failures.append("Boss timeout incorrectly rewarded or did not fire")
	if failures.is_empty():
		print("Phase 5 integration runtime passed")
	else:
		for failure in failures: push_error(failure)
	get_tree().quit(1 if not failures.is_empty() else 0)
