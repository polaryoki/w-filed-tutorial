extends Node

const GAME_SCENE := preload("res://scene/game.tscn")
const XP_SCENE := preload("res://scene/experience_pickup.tscn")
const ENEMY_SCENE := preload("res://scene/enemy.tscn")
const ENEMY_CONFIG := preload("res://resourse/config/enemy_basic.tres")

var failures: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _run() -> void:
	GameSession.reset_run()
	var game = GAME_SCENE.instantiate()
	game.initial_spawn_count = 0
	game.stage_duration = 100.0
	add_child(game)
	await get_tree().process_frame

	var player: Player = game.get_node("Player")
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	game.get_node("EnemyContainer").add_child(enemy)
	enemy.global_position = player.global_position + Vector2(120, 0)
	enemy.setup(ENEMY_CONFIG, player)
	enemy.apply_damage(999)
	await get_tree().process_frame
	await get_tree().process_frame
	var dropped_xp := game.get_node("EnemyContainer").get_node_or_null("ExperiencePickup")
	_expect(dropped_xp != null, "enemy death must spawn configured XP pickup")
	if dropped_xp != null:
		dropped_xp.queue_free()

	var pickup := XP_SCENE.instantiate() as Area2D
	pickup.setup(5)
	game.get_node("EnemyContainer").add_child(pickup)
	pickup.global_position = player.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame

	_expect(GameSession.current_level == 2, "XP pickup must level the run")
	_expect(get_tree().paused, "level-up must pause combat")
	_expect(game.level_up_panel.visible, "level-up panel must be visible while paused")
	_expect(game.current_level_up_options.size() == 3, "runtime UI must receive three options")
	if game.current_level_up_options.size() != 3:
		game.queue_free()
		_finish()
		return
	var ids: Array[StringName] = []
	for option in game.current_level_up_options:
		ids.append(StringName(option.get("id")))
	_expect(ids[0] != ids[1] and ids[0] != ids[2] and ids[1] != ids[2], "runtime options must be distinct")

	var selected: Resource = game.current_level_up_options[0]
	var before := _live_stat(player, int(selected.get("effect_type")))
	_expect(game.choose_level_up_option(0), "runtime option selection must succeed")
	var after := _live_stat(player, int(selected.get("effect_type")))
	_expect(not is_equal_approx(before, after), "selected upgrade must change the live Player stat")
	_expect(not get_tree().paused, "combat must resume after the final choice")
	_expect(not game.level_up_panel.visible, "level-up panel must close after selection")

	GameSession.reset_run()
	_expect(GameSession.current_level == 1 and GameSession.current_xp == 0, "new run must reset XP integration state")
	selected = null
	pickup = null
	enemy = null
	dropped_xp = null
	game.free()
	await get_tree().process_frame
	_finish()

func _live_stat(player: Player, effect_type: int) -> float:
	match effect_type:
		0: return float(player.max_health)
		1: return player.move_speed
		2: return float(player.damage)
		3: return player.fire_interval
		4: return player.pickup_range
		5: return player.luck
	return 0.0

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	if failures.is_empty():
		print("Phase 8 integration runtime passed")
	else:
		for failure in failures:
			push_error(failure)
	get_tree().quit(1 if not failures.is_empty() else 0)
